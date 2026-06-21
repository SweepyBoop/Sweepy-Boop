local _, addon = ...;

-- Resto Druid raid-frame HoT helper: draw the player's own HoTs on each raid frame as our own
-- icons, so Blizzard's default raid-frame buff icons can be turned off entirely.
--
-- Two rows per frame, anchored to the right edge (the frame center is left for Blizzard's big
-- defensive-cooldown icon):
--   Row 1 - Mark of the Wild warning + Lifebloom. Lifebloom has cooldown swipe and glows while
--           inside its refresh (pandemic) window (the last 30% of its duration). The Mark warning
--           glows red while the unit is missing Mark of the Wild.
--   Row 2 - the four Swiftmend-consumable HoTs (Regrowth, Wild Growth, Rejuvenation, Germination):
--           icon + cooldown swipe, packed in Swiftmend-priority order with no gaps. When none of the
--           four are active we show a warning icon instead.
--
-- Retail (12.x) notes:
--   * Blizzard's per-buff hook (CompactUnitFrame_UtilSetBuff) and the Lua buff-frame pipeline were
--     removed, and a frame's real buff icons aren't addon-accessible. So we track each CompactUnitFrame
--     via CompactUnitFrame_UpdateAll, map unit -> frame(s), refresh on UNIT_AURA, query the player's
--     HoTs ourselves, and draw our own icons.
--   * Aura APIs are SecretWhenUnitAuraRestricted, so unrelated auras can come back as secret values in
--     active PvP. The helper only cares about the five player-applied HoTs below; unrelated secret auras
--     must not suppress the Row 2 warning.

local GetAuraDataByIndex = C_UnitAuras.GetAuraDataByIndex;
local maxAuras = 255;
local refreshFraction = 0.3; -- glow once Lifebloom is within the last 30% of its duration

-- Lifebloom (Row 1). These two are mutually exclusive on a target.
local lifeblooms = {
    [33763] = true,  -- Lifebloom
    [290754] = true, -- Lifebloom (Early Spring, PvP talent)
};

local markOfTheWild = 1126;

-- The four Swiftmend-consumable HoTs (Row 2), in the order Swiftmend is believed to consume them
-- (left = consumed first).
--
-- IMPORTANT: this order is UNVERIFIED. Swiftmend's consumption priority is server-side and is NOT
-- present in Blizzard's wow-ui-source. The list below is the commonly-cited order; reorder this single
-- list once you confirm it in-game / on Wowhead and Row 2 will re-pack accordingly.
local swiftmendPriority = {
    8936,   -- Regrowth
    48438,  -- Wild Growth
    774,    -- Rejuvenation
    155777, -- Germination (VERIFY: 155675 is the talent/passive; 155777 is the HoT aura on the target)
};

-- Lookup set built from the ordered list above so the two never drift apart.
local swiftmendHoTs = {};
for _, spellId in ipairs(swiftmendPriority) do
    swiftmendHoTs[spellId] = true;
end

-- Layout (all tunable). Both rows hug the frame's right edge; the block is centered vertically.
local LIFEBLOOM_SIZE = 20;
local HOT_SIZE = 16;       -- 4 * 16 + 3 * HOT_SPACING fits even narrow 40-man frames
local HOT_SPACING = 1;     -- gap between Row 2 icons
local ROW_SPACING = 2;     -- gap between Row 1 and Row 2
local RIGHT_PAD = 2;       -- inset from the frame's right edge
local FRAME_LEVEL_OFFSET = 10;
local ROW_CENTER_OFFSET = ROW_SPACING / 2; -- split the row gap around the raid-frame vertical center
local PACK_DIRECTION = "LEFT_TO_RIGHT"; -- "LEFT_TO_RIGHT" (priority 1 leftmost) or "RIGHT_TO_LEFT"

local glowColor = { 0, 1, 0, 1 }; -- green (RGBA)
local markWarningGlowColor = { 1, 0, 0, 1 }; -- red (RGBA)
local markOfTheWildTexture = addon.GetSpellTexture(markOfTheWild);
local warningTexture = "Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew"; -- yellow warning triangle

local isDruid = ( addon.GetUnitClass("player") == addon.DRUID ); -- class is fixed for the login session
local isRestoSpec = false; -- spec can change mid-session; refreshed on PLAYER_SPECIALIZATION_CHANGED

local cufPool = {};    -- frame -> true: raid/party CompactUnitFrames we've seen
local unitFrames = {}; -- unit token -> { [frame] = true }: which frames currently show a unit
local tracked = {};    -- frame -> { expirationTime, duration, timeMod, refreshTime }: active lifeblooms (glow timer)

local function ShouldGlow(info, now)
    if ( info.expirationTime <= now ) then return false end
    return ( ( info.expirationTime - now ) / info.timeMod ) <= info.refreshTime;
end

-- The OnUpdate loop calls this ~20x/sec, so only start/stop the glow on a transition.
local function SetIconGlow(icon, shown)
    if shown then
        if ( not icon.glowing ) then
            addon.ShowOverlayGlow(icon);
            icon.glowing = true;
        end
    elseif icon.glowing then
        addon.HideOverlayGlow(icon);
        icon.glowing = false;
    end
end

local function SetPixelGlow(icon, shown)
    if shown then
        if ( not icon.pixelGlowing ) then
            addon.ShowFixedPixelGlow(icon.fixedPixelGlow);
            icon.pixelGlowing = true;
        end
    elseif icon.pixelGlowing then
        addon.HideFixedPixelGlow(icon.fixedPixelGlow);
        icon.pixelGlowing = false;
    end
end

-- Same swipe as the Healer-in-CC indicator: dark fill + the purple Loss-of-Control sweep edge. Kept
-- non-circular so it follows the square icon (no round mask).
local function StyleCooldown(cooldown)
    cooldown:SetDrawBling(false);
    cooldown:SetReverse(true);
    cooldown:SetDrawSwipe(true);
    cooldown:SetSwipeColor(0, 0, 0, 0.5);
    cooldown:SetDrawEdge(true);
    cooldown:SetEdgeTexture("Interface\\Cooldown\\UI-HUD-ActionBar-LoC"); -- the purple LoC sweep
    cooldown:SetHideCountdownNumbers(true);
    cooldown.noCooldownCount = true; -- hide OmniCC timers
end

-- A single HoT icon: texture + cooldown swipe. Each icon is its own frame so a future Soul of the
-- Forest border can be attached per icon without touching the others.
local function CreateHoTIcon(parent, size, frameLevel, createGlow)
    local icon = CreateFrame("Frame", nil, parent);
    icon:SetSize(size, size);
    icon:SetFrameLevel(frameLevel);

    icon.texture = icon:CreateTexture(nil, "ARTWORK");
    icon.texture:SetAllPoints(icon);

    icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate");
    icon.cooldown:SetAllPoints(icon);
    StyleCooldown(icon.cooldown);

    if createGlow then
        icon.SpellActivationAlert = addon.CreateOverlayGlow(icon, size, glowColor, true);
    end

    icon:Hide();
    return icon;
end

local function ApplyIconScale(container)
    container.frame:SetScale(SweepyBoop.db.profile.raidFrames.druidHoTHelperScale or 1);
end

local function CreateWarningIcon(parent, size, frameLevel)
    local icon = CreateFrame("Frame", nil, parent);
    icon:SetSize(size, size);
    icon:SetFrameLevel(frameLevel);

    icon.texture = icon:CreateTexture(nil, "ARTWORK");
    icon.texture:SetAllPoints(icon);
    icon.texture:SetTexture(warningTexture);

    icon:Hide();
    return icon;
end

-- Build (once) the per-frame container holding both rows. Retail doesn't expose a frame's real buff
-- icons, so we draw our own.
local function EnsureContainer(frame)
    local container = frame.druidHoT;
    if container then return container end

    local frameLevel = frame:GetFrameLevel() + FRAME_LEVEL_OFFSET;

    container = {};
    container.frame = CreateFrame("Frame", nil, frame);
    container.frame:SetSize(1, 1); -- non-zero size keeps this invisible scale anchor valid
    container.frame:SetPoint("RIGHT", frame, "RIGHT", -RIGHT_PAD, 0);
    container.frame:SetFrameLevel(frameLevel);
    container.scratch = {}; -- ordered list of the currently-active Row 2 auras

    -- Row 1: Lifebloom, right edge, upper half. The bottom edge sits just above the frame center.
    container.lifebloomIcon = CreateHoTIcon(container.frame, LIFEBLOOM_SIZE, frameLevel, true);
    container.lifebloomIcon:SetPoint("TOPRIGHT", container.frame, "RIGHT", 0, LIFEBLOOM_SIZE + ROW_CENTER_OFFSET);

    -- Row 1 warning: Mark of the Wild missing, same size as the smaller Row 2 icons and left of Lifebloom.
    container.markWarningIcon = CreateHoTIcon(container.frame, HOT_SIZE, frameLevel);
    container.markWarningIcon.texture:SetTexture(markOfTheWildTexture);
    container.markWarningIcon.texture:SetDesaturated(true);
    container.markWarningIcon.cooldown:Hide();
    container.markWarningIcon.fixedPixelGlow = addon.CreateFixedPixelGlow(container.markWarningIcon, HOT_SIZE, HOT_SIZE, markWarningGlowColor, 10);
    container.markWarningIcon:SetPoint("RIGHT", container.lifebloomIcon, "LEFT", -HOT_SPACING, 0);

    -- Row 2: up to four Swiftmend HoTs, anchored dynamically in UpdateRow2 (packed, no gaps).
    container.hotIcons = {};
    for i = 1, 4 do
        container.hotIcons[i] = CreateHoTIcon(container.frame, HOT_SIZE, frameLevel);
    end

    -- Row 2 alternative: warning shown when none of the four HoTs are active. Sits in the first Row 2 slot.
    container.warningIcon = CreateWarningIcon(container.frame, HOT_SIZE, frameLevel);
    container.warningIcon:SetPoint("TOPRIGHT", container.lifebloomIcon, "BOTTOMRIGHT", 0, -ROW_SPACING);

    ApplyIconScale(container);

    frame.druidHoT = container;
    return container;
end

-- Drive the cooldown swipe from a (readable, non-secret) aura's duration/expiration.
local function SetIconCooldown(icon, aura)
    local duration = aura.duration or 0;
    if ( duration > 0 ) and aura.expirationTime then
        icon.cooldown:SetCooldown(aura.expirationTime - duration, duration);
        icon.cooldown:Show();
    else
        icon.cooldown:Hide();
    end
end

local function ClearFrame(frame)
    local container = frame.druidHoT;
    if container then
        SetIconGlow(container.lifebloomIcon, false);
        container.lifebloomIcon:Hide();
        for i = 1, #container.hotIcons do
            container.hotIcons[i]:Hide();
        end
        SetPixelGlow(container.markWarningIcon, false);
        container.markWarningIcon:Hide();
        container.warningIcon:Hide();
    end
    tracked[frame] = nil;
end

-- Throttled loop: UNIT_AURA only fires when an aura changes, but the Lifebloom refresh window is
-- time-based, so we re-evaluate its glow on a timer while any Lifebloom is active. Row 2 needs no timer
-- (the Cooldown widget animates its own swipe and aura gain/loss/expiry all fire UNIT_AURA).
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
            -- Lifebloom expired. UNIT_AURA will also fire, but stop the glow on time and only touch
            -- Row 1 here (Row 2's HoTs are independent and may still be active).
            local container = frame.druidHoT;
            if container then
                SetIconGlow(container.lifebloomIcon, false);
                container.lifebloomIcon:Hide();
            end
            tracked[frame] = nil;
        elseif frame.druidHoT then
            SetIconGlow(frame.druidHoT.lifebloomIcon, ShouldGlow(info, now));
        end
    end
end)

-- One pass over the player's helpful auras on a unit. We only track five HoTs by spellId; a secret
-- spellId (PvP-restricted) can't match any of them, so skip it rather than suppress the warning.
local scanHoTs = {}; -- per-unit scan scratch; returned data is consumed synchronously before the next wipe
local function ScanUnitHoTs(unit)
    wipe(scanHoTs);
    local lifebloomAura;
    local hasMarkOfTheWild = false;
    for i = 1, maxAuras do
        local aura = GetAuraDataByIndex(unit, i, "HELPFUL");
        if ( not aura ) then break end
        local spellId = aura.spellId;
        if ( not addon.IsSecretValue(spellId) ) then -- a secret spellId matches none of our tracked HoTs
            if ( spellId == markOfTheWild ) then
                hasMarkOfTheWild = true;
            else
                local sourceUnit = aura.sourceUnit;
                if ( not addon.IsSecretValue(sourceUnit) ) and ( sourceUnit == "player" ) then
                    if lifeblooms[spellId] then
                        lifebloomAura = aura;
                    elseif swiftmendHoTs[spellId] then
                        scanHoTs[spellId] = aura;
                    end
                end
            end
        end
    end
    return lifebloomAura, scanHoTs, hasMarkOfTheWild;
end

local function UpdateMarkWarning(frame, hasMarkOfTheWild)
    local icon = frame.druidHoT.markWarningIcon;
    if hasMarkOfTheWild then
        SetPixelGlow(icon, false);
        icon:Hide();
        return;
    end

    SetPixelGlow(icon, true);
    icon:Show();
end

local function UpdateRow1(frame, aura)
    local icon = frame.druidHoT.lifebloomIcon;
    if ( not aura ) then
        SetIconGlow(icon, false);
        icon:Hide();
        tracked[frame] = nil; -- updater self-hides once tracked is empty
        return;
    end

    icon.texture:SetTexture(aura.icon);
    SetIconCooldown(icon, aura);

    local timeMod = aura.timeMod or 1;
    if ( timeMod <= 0 ) then timeMod = 1 end

    local info = tracked[frame] or {};
    info.expirationTime = aura.expirationTime or 0;
    info.duration = aura.duration or 0;
    info.timeMod = timeMod;
    info.refreshTime = info.duration * refreshFraction;
    tracked[frame] = info;

    icon:Show();
    SetIconGlow(icon, ShouldGlow(info, GetTime()));
    updater:Show();
end

local function UpdateRow2(frame, hotAuras)
    local container = frame.druidHoT;
    local icons = container.hotIcons;

    -- Collect the active HoTs in Swiftmend-priority order.
    local present = container.scratch;
    wipe(present);
    for _, spellId in ipairs(swiftmendPriority) do
        local aura = hotAuras[spellId];
        if aura then
            present[#present + 1] = aura;
        end
    end

    local count = #present;

    if ( count == 0 ) then
        for i = 1, #icons do
            icons[i]:Hide();
        end
        if SweepyBoop.db.profile.raidFrames.druidHoTHelperWarning then
            container.warningIcon:Show(); -- none of the four Swiftmend HoTs are up
        else
            container.warningIcon:Hide();
        end
        return;
    end

    container.warningIcon:Hide();

    -- Lay the active icons out right-aligned under Lifebloom, chaining each to the left of the previous
    -- one (icons[1] is the rightmost slot). Assign auras so priority 1 ends up on the correct side per
    -- PACK_DIRECTION.
    for i = 1, count do
        local aura;
        if ( PACK_DIRECTION == "RIGHT_TO_LEFT" ) then
            aura = present[i];                 -- priority 1 placed first => rightmost
        else
            aura = present[count - i + 1];     -- LEFT_TO_RIGHT: priority 1 ends up leftmost
        end

        local icon = icons[i];
        icon.texture:SetTexture(aura.icon);
        SetIconCooldown(icon, aura);

        icon:ClearAllPoints();
        if ( i == 1 ) then
            icon:SetPoint("TOPRIGHT", container.lifebloomIcon, "BOTTOMRIGHT", 0, -ROW_SPACING);
        else
            icon:SetPoint("TOPRIGHT", icons[i - 1], "TOPLEFT", -HOT_SPACING, 0);
        end
        icon:Show();
    end

    for i = count + 1, #icons do
        icons[i]:Hide();
    end
end

local byte = string.byte;
local function IsGroupUnit(unit)
    local first = byte(unit, 1);
    if ( first == 112 ) then -- p: player / pet / party / partypet
        return string.match(unit, "^player")
                or string.match(unit, "^pet")
                or string.match(unit, "^party");
    elseif ( first == 114 ) then -- raid / raidpet
        return string.match(unit, "^raid");
    end

    return false;
end

local function UpdateFrame(frame)
    if frame:IsForbidden() then return end

    local unit = frame.displayedUnit or frame.unit;
    if ( not SweepyBoop.db.profile.raidFrames.druidHoTHelper )
            or ( not isRestoSpec )
            or ( not unit ) or ( not UnitExists(unit) )
            or ( not IsGroupUnit(unit) ) then
        ClearFrame(frame);
        return;
    end

    -- Don't show the warning on dead raiders: they have no HoTs, but a persistent warning is just noise.
    -- Check IsSecretValue first: UnitIsDeadOrGhost can be secret in rated PvP, and the `and` must not
    -- coerce a secret value to a boolean (that would error). The secret check short-circuits before `dead`.
    local dead = UnitIsDeadOrGhost(unit);
    if ( not addon.IsSecretValue(dead) ) and dead then
        ClearFrame(frame);
        return;
    end

    local container = EnsureContainer(frame);
    ApplyIconScale(container);

    local lifebloomAura, hotAuras, hasMarkOfTheWild = ScanUnitHoTs(unit);
    UpdateMarkWarning(frame, ( not UnitIsPlayer(unit) ) or hasMarkOfTheWild);
    UpdateRow1(frame, lifebloomAura);
    UpdateRow2(frame, hotAuras);
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

local function CheckSpec()
    isRestoSpec = ( addon.GetSpecForPlayerOrArena("player") == addon.SPECID.RESTORATION_DRUID );
end

local function RefreshAllFrames()
    for frame in pairs(cufPool) do
        UpdateFrame(frame);
    end
end

local function UpdateVisibleFrame(frame)
    if frame:IsShown() then
        UpdateFrame(frame);
    end
end

local function UpdateUnitFrames(unit)
    if not IsGroupUnit(unit) then return end

    local frames = unitFrames[unit];
    if frames then
        for frame in pairs(frames) do
            UpdateVisibleFrame(frame);
        end
        return;
    end

    -- Compact frames can expose the same player through different group aliases (party/raid/displayedUnit).
    -- Fall back to UnitIsUnit so a UNIT_AURA alias mismatch does not leave one visible HoT icon stale.
    for frame in pairs(cufPool) do
        if frame:IsShown() then
            local frameUnit = frame.druidHoTUnit;
            if frameUnit and UnitIsUnit(unit, frameUnit) then
                UpdateFrame(frame);
            end
        end
    end
end

local eventFrame = CreateFrame("Frame");

-- Hide Blizzard's own raid-frame buffs while the helper is enabled on a Resto druid, so our icons
-- replace them. In retail 12.x a frame's individual buff icons are forbidden/secret, so the only lever
-- is the global raidFramesDisplayBuffs CVar (all-or-nothing: it hides every buff on raid frames;
-- debuffs/dispels stay). Changing it re-runs setup on the protected raid frames, so we defer in combat.
local function ShouldHideBlizzardBuffs()
    return isRestoSpec and SweepyBoop.db.profile.raidFrames.druidHoTHelper and true or false;
end

local function ApplyHideBlizzardBuffs()
    if ( not isDruid ) or ( not addon.PROJECT_MAINLINE ) then return end -- druid-only, and retail-only

    if InCombatLockdown() then
        eventFrame:RegisterEvent(addon.PLAYER_REGEN_ENABLED); -- retry once combat ends
        return;
    end

    local desired = ShouldHideBlizzardBuffs() and "0" or "1";
    if ( GetCVar("raidFramesDisplayBuffs") ~= desired ) then
        SetCVar("raidFramesDisplayBuffs", desired); -- 0 hides all raid-frame buffs, 1 restores the default
    end
end

function SweepyBoop:SetupRaidFrameAuraModule()
    if ( not isDruid ) then return end -- nothing to do for non-druids this session

    CheckSpec();

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
    eventFrame:RegisterEvent(addon.PLAYER_SPECIALIZATION_CHANGED);
    eventFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
    eventFrame:SetScript("OnEvent", function (_, event, unitTarget)
        if ( event == addon.UNIT_AURA ) then
            if unitTarget then
                UpdateUnitFrames(unitTarget);
            end
        elseif ( event == addon.PLAYER_SPECIALIZATION_CHANGED ) then
            if ( unitTarget == "player" ) then
                local wasResto = isRestoSpec;
                CheckSpec();
                ApplyHideBlizzardBuffs(); -- entering/leaving Resto flips whether we hide Blizzard buffs
                if ( wasResto ~= isRestoSpec ) then
                    RefreshAllFrames(); -- show or clear every frame for the new spec
                end
            end
        elseif ( event == addon.PLAYER_ENTERING_WORLD ) then
            CheckSpec(); -- spec info may not have been ready at login
            ApplyHideBlizzardBuffs();
            RefreshAllFrames();
        elseif ( event == addon.PLAYER_REGEN_ENABLED ) then
            eventFrame:UnregisterEvent(addon.PLAYER_REGEN_ENABLED);
            ApplyHideBlizzardBuffs(); -- apply the buff-hiding CVar that was deferred during combat
        else -- GROUP_ROSTER_UPDATE: the unit behind a frame may have changed
            for frame in pairs(cufPool) do
                MapFrameUnit(frame);
                UpdateFrame(frame);
            end
        end
    end)

    ApplyHideBlizzardBuffs(); -- enforce the buff-hiding CVar for the current spec + toggle
end

-- Called when the Druid HoT helper toggle changes (and on profile switch): re-evaluate the buff-hiding
-- CVar and repaint every tracked frame for the new setting.
function SweepyBoop:RefreshDruidHoTHelper()
    ApplyHideBlizzardBuffs();
    RefreshAllFrames();
end
