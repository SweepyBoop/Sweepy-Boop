local _, addon = ...;

-- Resto Druid raid-frame helper: glow a unit's frame while the player's own Lifebloom
-- on it is inside its refresh window (last 30% of duration).
--
-- Retail (12.x) notes:
--   * The old hook target CompactUnitFrame_UtilSetBuff and the entire Lua buff-frame
--     pipeline were removed; raid auras are engine-rendered. So we can't hook a per-buff
--     function. Instead we track each CompactUnitFrame via CompactUnitFrame_UpdateAll,
--     map unit -> frame(s), refresh on UNIT_AURA, and drive our own glow.
--   * Aura APIs are SecretWhenUnitAuraRestricted, so in an active PvP match most auras
--     come back as secret values. Lifebloom is currently flagged "neversecret" by
--     Blizzard, so the player's own copy stays readable; the issecretvalue guards below
--     make the feature fail safe (no glow) rather than error if that ever changes.

local GetAuraDataByIndex = C_UnitAuras.GetAuraDataByIndex;
local issecretvalue = issecretvalue or function () return false end; -- no secret values pre-12.0
local maxAuras = 255;
local refreshFraction = 0.3; -- glow once the HoT is within the last 30% of its duration

local lifeblooms = {
    [33763] = true,  -- Lifebloom
    [290754] = true, -- Lifebloom (Early Spring, PvP talent)
};

local isDruid = ( addon.GetUnitClass("player") == addon.DRUID ); -- fixed for the login session

local cufPool = {};    -- frame -> true: raid/party CompactUnitFrames we've seen
local unitFrames = {}; -- unit token -> { [frame] = true }: which frames currently show a unit
local tracked = {};    -- frame -> { expirationTime, duration, timeMod, refreshTime }: active lifeblooms

local function ShouldGlow(info, now)
    if ( info.expirationTime <= now ) then return false end
    return ( ( info.expirationTime - now ) / info.timeMod ) <= info.refreshTime;
end

-- Retail no longer exposes the individual buff icons on a CompactUnitFrame, so we
-- can't glow the Lifebloom icon itself. Instead we highlight the unit's whole frame
-- with the raid-frame target-highlight atlas.
-- The highlight lives on our own child texture, so we never toggle anything directly
-- on Blizzard's (possibly forbidden) frame.
local glowAtlas = "RaidFrame-TargetFrame";
local glowColor = { 0, 1, 0 }; -- green

local function SetGlowShown(frame, shown)
    local glow = frame.druidHoTGlow;
    if ( not glow ) then
        if ( not shown ) then return end
        local glowFrame = CreateFrame("Frame", nil, frame);
        glowFrame:SetAllPoints(frame);
        glowFrame:SetFrameLevel(frame:GetFrameLevel() + 10); -- draw above the frame's contents
        glow = glowFrame:CreateTexture(nil, "OVERLAY");
        glow:SetAllPoints(glowFrame);
        glow:SetAtlas(glowAtlas);
        glow:SetDesaturated(true);
        glow:SetVertexColor(glowColor[1], glowColor[2], glowColor[3]);
        glow:Hide();
        frame.druidHoTGlow = glow;
    end

    glow:SetShown(shown);
end

local function HideFrameGlow(frame)
    SetGlowShown(frame, false);
    tracked[frame] = nil;
end

-- Throttled loop: UNIT_AURA only fires when the aura changes, but the refresh window is
-- time-based, so we re-evaluate the glow on a timer while any lifebloom is active.
local updater = CreateFrame("Frame");
updater.elapsed = 0;
updater:Hide();
updater:SetScript("OnUpdate", function (self, elapsed)
    self.elapsed = self.elapsed + elapsed;
    if ( self.elapsed < 0.05 ) then return end
    self.elapsed = 0;

    if ( next(tracked) == nil ) then
        self:Hide();
        return;
    end

    local now = GetTime();
    for frame, info in pairs(tracked) do
        if ( info.expirationTime <= now ) then
            HideFrameGlow(frame);
        else
            SetGlowShown(frame, ShouldGlow(info, now));
        end
    end
end)

-- Find the player's lifebloom on a unit (secret-safe: skip any aura whose spellId is secret).
local function FindLifebloom(unit)
    for i = 1, maxAuras do
        local aura = GetAuraDataByIndex(unit, i, "PLAYER|HELPFUL");
        if ( not aura ) then break end
        if ( not issecretvalue(aura.spellId) ) and lifeblooms[aura.spellId] then
            return aura;
        end
    end
end

local function UpdateFrame(frame)
    if frame:IsForbidden() then return end

    local unit = frame.displayedUnit or frame.unit;
    if ( not SweepyBoop.db.profile.raidFrames.druidHoTHelper )
            or ( not unit ) or ( not UnitExists(unit) )
            or string.find(unit, "target") then -- target/targettarget aren't raid members
        HideFrameGlow(frame);
        return;
    end

    local aura = FindLifebloom(unit);
    if ( not aura ) then
        HideFrameGlow(frame);
        return;
    end

    local timeMod = aura.timeMod or 1;
    if ( timeMod <= 0 ) then timeMod = 1 end

    local info = tracked[frame] or {};
    info.expirationTime = aura.expirationTime or 0;
    info.duration = aura.duration or 0;
    info.timeMod = timeMod;
    info.refreshTime = info.duration * refreshFraction;
    tracked[frame] = info;

    SetGlowShown(frame, ShouldGlow(info, GetTime()));
    updater:Show();
end

-- Maintain unit -> frame(s) so UNIT_AURA can target only the affected frames.
local function MapFrameUnit(frame)
    local unit = frame.displayedUnit or frame.unit;
    if ( frame.druidHoTUnit == unit ) then return end

    if frame.druidHoTUnit and unitFrames[frame.druidHoTUnit] then
        unitFrames[frame.druidHoTUnit][frame] = nil;
    end

    frame.druidHoTUnit = unit;
    if unit then
        unitFrames[unit] = unitFrames[unit] or {};
        unitFrames[unit][frame] = true;
    end
end

local function TrackFrame(frame)
    cufPool[frame] = true;
    MapFrameUnit(frame);
    UpdateFrame(frame);
end

local function UntrackFrame(frame)
    cufPool[frame] = nil;
    if frame.druidHoTUnit and unitFrames[frame.druidHoTUnit] then
        unitFrames[frame.druidHoTUnit][frame] = nil;
    end
    frame.druidHoTUnit = nil;
    HideFrameGlow(frame);
end

local eventFrame = CreateFrame("Frame");

function SweepyBoop:SetupRaidFrameAuraModule()
    if ( not isDruid ) then return end -- nothing to do for non-druids this session

    -- CompactUnitFrame_UpdateAll fires for every raid/party frame as it's set up / reused.
    hooksecurefunc("CompactUnitFrame_UpdateAll", function (frame)
        if frame:IsForbidden() then
            UntrackFrame(frame);
            return;
        end

        local name = frame:GetName();
        if name and string.find(name, "^Compact") then -- CompactPartyFrameMemberN, CompactRaidFrameN, ...
            TrackFrame(frame);
        else
            UntrackFrame(frame);
        end
    end)

    eventFrame:RegisterEvent(addon.UNIT_AURA);
    eventFrame:RegisterEvent(addon.GROUP_ROSTER_UPDATE);
    eventFrame:SetScript("OnEvent", function (_, event, unitTarget)
        if ( event == addon.UNIT_AURA ) then
            local frames = unitFrames[unitTarget];
            if frames then
                for frame in pairs(frames) do
                    UpdateFrame(frame);
                end
            end
        else -- GROUP_ROSTER_UPDATE: the unit behind a frame may have changed
            for frame in pairs(cufPool) do
                MapFrameUnit(frame);
                UpdateFrame(frame);
            end
        end
    end)
end
