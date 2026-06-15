local _, addon = ...;

-- Resto Druid raid-frame helper: show the player's own Lifebloom as an icon at the
-- center of the raid frame that has it, and glow that icon while it's inside its
-- refresh window (last 30% of duration).
--
-- Retail (12.x) notes:
--   * Blizzard's per-buff hook (CompactUnitFrame_UtilSetBuff) and the Lua buff-frame
--     pipeline were removed, and a frame's real buff icons aren't addon-accessible. So we
--     track each CompactUnitFrame via CompactUnitFrame_UpdateAll, map unit -> frame(s),
--     refresh on UNIT_AURA, query the player's Lifebloom ourselves, and draw our own icon.
--   * Aura APIs are SecretWhenUnitAuraRestricted, so in an active PvP match most auras
--     come back as secret values. Lifebloom is currently flagged "neversecret" by
--     Blizzard, so the player's own copy stays readable; the issecretvalue guard below
--     makes the feature fail safe (no icon) rather than error if that ever changes.

local LCG = LibStub("LibCustomGlow-1.0");
local GetAuraDataByIndex = C_UnitAuras.GetAuraDataByIndex;
local issecretvalue = issecretvalue or function () return false end; -- no secret values pre-12.0
local maxAuras = 255;
local refreshFraction = 0.3; -- glow once the HoT is within the last 30% of its duration

local iconSize = 24;
local glowColor = { 0, 1, 0, 1 }; -- green (RGBA)

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

-- Our own Lifebloom icon, in the top-right corner of the raid frame (retail doesn't expose
-- the frame's real buff icons, so we draw our own rather than reuse Blizzard's).
local function EnsureIcon(frame)
    local icon = frame.druidHoTIcon;
    if ( not icon ) then
        icon = CreateFrame("Frame", nil, frame);
        icon:SetSize(iconSize, iconSize);
        icon:SetPoint("BOTTOMRIGHT", frame, "RIGHT"); -- avoid the center (default big defensive CDs)
        icon:SetFrameLevel(frame:GetFrameLevel() + 10);

        icon.texture = icon:CreateTexture(nil, "ARTWORK");
        icon.texture:SetAllPoints(icon);

        -- Same swipe as the Healer-in-CC indicator: dark fill + the purple Loss-of-Control
        -- sweep edge. Kept non-circular so it follows the square icon (no round mask).
        icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate");
        icon.cooldown:SetAllPoints(icon);
        icon.cooldown:SetDrawBling(false);
        icon.cooldown:SetReverse(true);
        icon.cooldown:SetDrawSwipe(true);
        icon.cooldown:SetSwipeColor(0, 0, 0, 0.5);
        icon.cooldown:SetDrawEdge(true);
        icon.cooldown:SetEdgeTexture("Interface\\Cooldown\\UI-HUD-ActionBar-LoC"); -- the purple LoC sweep
        icon.cooldown:SetHideCountdownNumbers(true);
        icon.cooldown.noCooldownCount = true; -- hide OmniCC timers

        icon:Hide();
        frame.druidHoTIcon = icon;
    end
    return icon;
end

-- The OnUpdate loop calls this ~20x/sec, so only start/stop the glow on a transition.
local function SetIconGlow(icon, shown)
    if shown then
        if ( not icon.glowing ) then
            LCG.ButtonGlow_Start(icon, glowColor);
            icon.glowing = true;
        end
    elseif icon.glowing then
        LCG.ButtonGlow_Stop(icon);
        icon.glowing = false;
    end
end

local function ShowIcon(frame, aura, glow)
    local icon = EnsureIcon(frame);
    icon.texture:SetTexture(aura.icon);

    local duration = aura.duration or 0;
    if ( duration > 0 ) and aura.expirationTime then
        icon.cooldown:SetCooldown(aura.expirationTime - duration, duration);
        icon.cooldown:Show();
    else
        icon.cooldown:Hide();
    end

    icon:Show();
    SetIconGlow(icon, glow);
end

local function ClearFrame(frame)
    local icon = frame.druidHoTIcon;
    if icon then
        SetIconGlow(icon, false);
        icon:Hide();
    end
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
            ClearFrame(frame);
        elseif frame.druidHoTIcon then
            SetIconGlow(frame.druidHoTIcon, ShouldGlow(info, now));
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
        ClearFrame(frame);
        return;
    end

    local aura = FindLifebloom(unit);
    if ( not aura ) then
        ClearFrame(frame);
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

    ShowIcon(frame, aura, ShouldGlow(info, GetTime()));
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
    ClearFrame(frame);
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
