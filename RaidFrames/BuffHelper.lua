local _, addon = ...;

-- Raid-frame buff helper for supported healing specs: draw the player's own important buffs on each
-- raid frame as our own icons, so Blizzard's default raid-frame buff icons can be turned off entirely.
--
-- Two rows per frame, anchored to the right edge (the frame center is left for Blizzard's big
-- defensive-cooldown icon):
--   Row 1 - class-buff warning + the spec's primary tracked buff. Resto Druid shows Lifebloom, which
--           glows inside its refresh (pandemic) window. Preservation Evoker shows Echo without a
--           refresh-window glow because Echo is consumed by the next heal rather than refreshed.
--   Row 2 - four spec-specific player-applied buffs, packed in priority order with no gaps. When none
--           of the four are active we can show a warning icon instead.
--
-- Retail (12.x) notes:
--   * Blizzard's per-buff hook (CompactUnitFrame_UtilSetBuff) and the Lua buff-frame pipeline were
--     removed, and a frame's real buff icons aren't addon-accessible. So we track each CompactUnitFrame
--     via CompactUnitFrame_UpdateAll, map unit -> frame(s), refresh on UNIT_AURA, query the player's
--     buffs ourselves, and draw our own icons.
--   * Aura APIs are SecretWhenUnitAuraRestricted, so unrelated auras can come back as secret values in
--     active PvP. The helper only cares about the configured player-applied buffs below; unrelated secret
--     auras must not suppress the Row 2 warning.

local GetAuraDataByIndex = C_UnitAuras.GetAuraDataByIndex;
local maxAuras = 255;
local lifebloomRefreshFraction = 0.3; -- glow once Lifebloom is within the last 30% of its duration

local markOfTheWild = 1126;
local blessingOfTheBronze = 381748; -- Evoker's applied raid-buff aura; used for the warning icon
local blessingOfTheBronzeAuras = {
    [381732] = true, -- Death Knight
    [381741] = true, -- Demon Hunter
    [381746] = true, -- Druid
    [381748] = true, -- Evoker
    [381749] = true, -- Hunter
    [381750] = true, -- Mage
    [381751] = true, -- Monk
    [381752] = true, -- Paladin
    [381753] = true, -- Priest
    [381754] = true, -- Rogue
    [381756] = true, -- Shaman
    [381757] = true, -- Warlock
    [381758] = true, -- Warrior
};

local profiles = {
    [addon.SPECID.RESTORATION_DRUID] = {
        class = addon.DRUID,
        primaryBuffs = {
            [33763] = true,  -- Lifebloom
            [290754] = true, -- Lifebloom (Early Spring, PvP talent)
        },
        enabledSetting = "druidBuffHelper",
        row2WarningSetting = "druidBuffHelperWarning",
        primaryRefreshFraction = lifebloomRefreshFraction,
        classBuff = markOfTheWild,
        classBuffAuras = {
            [markOfTheWild] = true,
        },

        -- The four Swiftmend-consumable HoTs (Row 2), least-to-most important left-to-right. For
        -- Druid, that means the order Swiftmend is believed to consume them (left = consumed first).
        --
        -- IMPORTANT: this order is UNVERIFIED. Swiftmend's consumption priority is server-side and is
        -- NOT present in Blizzard's wow-ui-source. Reorder this single list once you confirm it in-game /
        -- on Wowhead and Row 2 will re-pack accordingly.
        row2Priority = {
            8936,   -- Regrowth
            48438,  -- Wild Growth
            774,    -- Rejuvenation
            155777, -- Germination (VERIFY: 155675 is the talent/passive; 155777 is the HoT aura)
        },
        row2Auras = {
            [8936] = 8936,
            [48438] = 48438,
            [774] = 774,
            [155777] = 155777,
        },
    },

    [addon.SPECID.PRESERVATION] = {
        class = addon.EVOKER,
        enabledSetting = "evokerBuffHelper",
        primaryBuffs = {
            [364343] = true, -- Echo
        },
        classBuff = blessingOfTheBronze,
        classBuffAuras = blessingOfTheBronzeAuras,
        -- Row 2 is least-to-most important left-to-right.
        row2Priority = {
            366155, -- Reversion
            355941, -- Dream Breath HoT
            373267, -- Lifebind
            357170, -- Time Dilation
        },
        row2Auras = {
            [366155] = 366155, -- Reversion
            [1256577] = 366155, -- Merithra's Blessing (Reversion upgrade)
            [355936] = 355941, -- Dream Breath cast spell, included defensively in case aura IDs drift
            [355941] = 355941, -- Dream Breath HoT
            [373267] = 373267, -- Lifebind periodic aura
            [373270] = 373267, -- Lifebind dummy aura
            [357170] = 357170, -- Time Dilation
        },
    },
};

local supportedClasses = {
    [addon.DRUID] = true,
    [addon.EVOKER] = true,
};

-- Layout (all tunable). Both rows hug the frame's right edge; the block is centered vertically.
local PRIMARY_BUFF_SIZE = 20;
local ROW2_BUFF_SIZE = 16;       -- 4 * 16 + 3 * ROW2_BUFF_SPACING fits even narrow 40-man frames
local ROW2_BUFF_SPACING = 1;     -- gap between Row 2 icons
local ROW_SPACING = 2;     -- gap between Row 1 and Row 2
local RIGHT_PAD = 2;       -- inset from the frame's right edge
local FRAME_LEVEL_OFFSET = 10;
local ROW_CENTER_OFFSET = ROW_SPACING / 2; -- split the row gap around the raid-frame vertical center
local PACK_DIRECTION = "LEFT_TO_RIGHT"; -- "LEFT_TO_RIGHT" (priority 1 leftmost) or "RIGHT_TO_LEFT"

local glowColor = { 0, 1, 0, 1 }; -- green (RGBA)
local missingClassBuffGlowColor = { 1, 0, 0, 1 }; -- red (RGBA)
local warningTexture = "Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew"; -- yellow warning triangle

local playerClass = addon.GetUnitClass("player"); -- class is fixed for the login session
local isSupportedClass = supportedClasses[playerClass] == true;
local activeProfile; -- spec can change mid-session; refreshed on PLAYER_SPECIALIZATION_CHANGED

local cufPool = {};    -- frame -> true: raid/party CompactUnitFrames we've seen
local unitFrames = {}; -- unit token -> { [frame] = true }: which frames currently show a unit
local tracked = {};    -- frame -> { expirationTime, timeMod, refreshTime }: active primary buffs with timer glows

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

-- A single buff icon: texture + cooldown swipe. Each icon is its own frame so a future Soul of the
-- Forest border can be attached per icon without touching the others.
local function CreateBuffIcon(parent, size, frameLevel, createGlow)
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

local function ApplyIconLayout(container)
    local config = SweepyBoop.db.profile.raidFrames;
    container.frame:SetScale(config.healerBuffHelperScale or 1);
    container.frame:ClearAllPoints();
    container.frame:SetPoint("RIGHT", container.parent, "RIGHT", -RIGHT_PAD + ( config.healerBuffHelperOffsetX or 0 ), config.healerBuffHelperOffsetY or 0);
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
    local container = frame.healerBuffHelper;
    if container then return container end

    local frameLevel = frame:GetFrameLevel() + FRAME_LEVEL_OFFSET;

    container = {};
    container.frame = CreateFrame("Frame", nil, frame);
    container.frame:SetSize(1, 1); -- non-zero size keeps this invisible scale anchor valid
    container.parent = frame;
    container.frame:SetFrameLevel(frameLevel);
    container.scratch = {}; -- ordered list of the currently-active Row 2 auras

    -- Row 1: primary buff, right edge, upper half. The bottom edge sits just above the frame center.
    container.primaryBuffIcon = CreateBuffIcon(container.frame, PRIMARY_BUFF_SIZE, frameLevel, true);
    container.primaryBuffIcon:SetPoint("TOPRIGHT", container.frame, "RIGHT", 0, PRIMARY_BUFF_SIZE + ROW_CENTER_OFFSET);

    -- Row 1 warning: missing class buff, same size as the smaller Row 2 icons and left of the primary buff.
    container.classBuffWarningIcon = CreateBuffIcon(container.frame, ROW2_BUFF_SIZE, frameLevel);
    container.classBuffWarningIcon.texture:SetDesaturated(true);
    container.classBuffWarningIcon.cooldown:Hide();
    container.classBuffWarningIcon.fixedPixelGlow = addon.CreateFixedPixelGlow(container.classBuffWarningIcon, ROW2_BUFF_SIZE, ROW2_BUFF_SIZE, missingClassBuffGlowColor, 10, nil, nil, 0);
    container.classBuffWarningIcon:SetPoint("RIGHT", container.primaryBuffIcon, "LEFT", -ROW2_BUFF_SPACING, 0);

    -- Row 2: up to four configured buffs, anchored dynamically in UpdateRow2 (packed, no gaps).
    container.row2Icons = {};
    for i = 1, 4 do
        container.row2Icons[i] = CreateBuffIcon(container.frame, ROW2_BUFF_SIZE, frameLevel);
    end

    -- Row 2 alternative: warning shown when none of the four buffs are active. Sits in the first Row 2 slot.
    container.warningIcon = CreateWarningIcon(container.frame, ROW2_BUFF_SIZE, frameLevel);
    container.warningIcon:SetPoint("TOPRIGHT", container.primaryBuffIcon, "BOTTOMRIGHT", 0, -ROW_SPACING);

    ApplyIconLayout(container);

    frame.healerBuffHelper = container;
    return container;
end

-- Drive the cooldown swipe from a (readable, non-secret) aura's duration/expiration.
local function SetIconCooldown(icon, aura)
    local duration = aura.duration or 0;
    if ( ( duration > 0 ) and aura.expirationTime ) then
        icon.cooldown:SetCooldown(aura.expirationTime - duration, duration);
        icon.cooldown:Show();
    else
        icon.cooldown:Hide();
    end
end

local function ClearFrame(frame)
    local container = frame.healerBuffHelper;
    if container then
        SetIconGlow(container.primaryBuffIcon, false);
        container.primaryBuffIcon:Hide();
        for i = 1, #container.row2Icons do
            container.row2Icons[i]:Hide();
        end
        SetPixelGlow(container.classBuffWarningIcon, false);
        container.classBuffWarningIcon:Hide();
        container.warningIcon:Hide();
    end
    tracked[frame] = nil;
end

-- Throttled loop: UNIT_AURA only fires when an aura changes, but a primary buff's refresh window can be
-- time-based, so we re-evaluate its glow on a timer while any timer-glow primary buff is active. Row 2
-- needs no timer (the Cooldown widget animates its own swipe and aura gain/loss/expiry all fire UNIT_AURA).
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
            -- The primary buff expired. UNIT_AURA will also fire, but stop the glow on time and only
            -- touch Row 1 here (Row 2's buffs are independent and may still be active).
            local container = frame.healerBuffHelper;
            if container then
                SetIconGlow(container.primaryBuffIcon, false);
                container.primaryBuffIcon:Hide();
            end
            tracked[frame] = nil;
        elseif frame.healerBuffHelper then
            SetIconGlow(frame.healerBuffHelper.primaryBuffIcon, ShouldGlow(info, now));
        end
    end
end)

-- One pass over the helpful auras on a unit. Secret PvP-restricted spell IDs cannot match any configured
-- aura, so skip them rather than suppressing the Row 2 warning.
local scanAuras = {}; -- per-unit scan scratch; returned data is consumed synchronously before the next wipe
local function ScanUnitAuras(unit, profile)
    wipe(scanAuras);
    local primaryAura;
    local hasClassBuff = false;
    for i = 1, maxAuras do
        local aura = GetAuraDataByIndex(unit, i, "HELPFUL");
        if ( not aura ) then break end
        local spellId = aura.spellId;
        if ( not addon.IsSecretValue(spellId) ) then
            if profile.classBuffAuras[spellId] then
                hasClassBuff = true;
            end

            local sourceUnit = aura.sourceUnit;
            if ( not addon.IsSecretValue(sourceUnit) ) and ( sourceUnit == "player" ) then
                if profile.primaryBuffs[spellId] then
                    primaryAura = aura;
                else
                    local row2SpellId = profile.row2Auras[spellId];
                    if ( row2SpellId and ( ( spellId == row2SpellId ) or ( not scanAuras[row2SpellId] ) ) ) then
                        scanAuras[row2SpellId] = aura;
                    end
                end
            end
        end
    end
    return primaryAura, scanAuras, hasClassBuff;
end

local function UpdateClassBuffWarning(frame, profile, hasClassBuff)
    local icon = frame.healerBuffHelper.classBuffWarningIcon;
    if hasClassBuff then
        SetPixelGlow(icon, false);
        icon:Hide();
        return;
    end

    icon.texture:SetTexture(addon.GetSpellTexture(profile.classBuff));
    SetPixelGlow(icon, true);
    icon:Show();
end

local function UpdateRow1(frame, aura, profile)
    local icon = frame.healerBuffHelper.primaryBuffIcon;
    if ( not aura ) then
        SetIconGlow(icon, false);
        icon:Hide();
        tracked[frame] = nil; -- updater self-hides once tracked is empty
        return;
    end

    icon.texture:SetTexture(aura.icon);
    SetIconCooldown(icon, aura);
    icon:Show();

    local refreshFraction = profile.primaryRefreshFraction;
    if ( not refreshFraction ) then
        SetIconGlow(icon, false);
        tracked[frame] = nil;
        return;
    end

    local timeMod = aura.timeMod or 1;
    if ( timeMod <= 0 ) then timeMod = 1 end

    local info = tracked[frame] or {};
    info.expirationTime = aura.expirationTime or 0;
    info.timeMod = timeMod;
    info.refreshTime = ( aura.duration or 0 ) * refreshFraction;
    tracked[frame] = info;

    SetIconGlow(icon, ShouldGlow(info, GetTime()));
    updater:Show();
end

local function IsProfileEnabled(profile)
    return ( ( not addon.IsConflictingHealerBuffHelperAddonLoaded() )
            and ( SweepyBoop.db.profile.raidFrames[profile.enabledSetting] == true ) );
end

local function UpdateRow2(frame, row2Auras, profile)
    local container = frame.healerBuffHelper;
    local icons = container.row2Icons;

    -- Collect the active buffs in profile display order: least important leftmost, most important rightmost.
    local present = container.scratch;
    wipe(present);
    for _, spellId in ipairs(profile.row2Priority) do
        local aura = row2Auras[spellId];
        if aura then
            present[#present + 1] = aura;
        end
    end

    local count = #present;

    if ( count == 0 ) then
        for i = 1, #icons do
            icons[i]:Hide();
        end
        local warningSetting = profile.row2WarningSetting;
        if ( warningSetting and ( SweepyBoop.db.profile.raidFrames[warningSetting] == true ) ) then
            container.warningIcon:Show(); -- none of the configured Row 2 buffs are up
        else
            container.warningIcon:Hide();
        end
        return;
    end

    container.warningIcon:Hide();

    -- Lay the active icons out right-aligned under the primary buff, chaining each to the left of the
    -- previous one (icons[1] is the rightmost slot). Assign auras so priority 1 ends up on the correct
    -- side per PACK_DIRECTION.
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
            icon:SetPoint("TOPRIGHT", container.primaryBuffIcon, "BOTTOMRIGHT", 0, -ROW_SPACING);
        else
            icon:SetPoint("TOPRIGHT", icons[i - 1], "TOPLEFT", -ROW2_BUFF_SPACING, 0);
        end
        icon:Show();
    end

    for i = count + 1, #icons do
        icons[i]:Hide();
    end
end

local function IsGroupUnit(unit)
    local first = string.byte(unit, 1);
    if ( first == 112 ) then -- p: player / pet / party / partypet
        return ( ( string.sub(unit, 1, 6) == "player" )
                or ( string.sub(unit, 1, 3) == "pet" )
                or ( string.sub(unit, 1, 5) == "party" ) );
    elseif ( first == 114 ) then -- raid / raidpet
        return ( string.sub(unit, 1, 4) == "raid" );
    end

    return false;
end

local function UpdateFrame(frame)
    if frame:IsForbidden() then return end

    local unit = frame.displayedUnit or frame.unit;
    local profile = activeProfile;
    if ( ( not profile )
            or ( not IsProfileEnabled(profile) )
            or ( not unit )
            or ( not UnitExists(unit) )
            or ( not IsGroupUnit(unit) ) ) then
        ClearFrame(frame);
        return;
    end

    -- Don't show the warning on dead raiders: they have no tracked buffs, but a persistent warning is just noise.
    -- Check IsSecretValue first: UnitIsDeadOrGhost can be secret in rated PvP, and the `and` must not
    -- coerce a secret value to a boolean (that would error). The secret check short-circuits before `dead`.
    local dead = UnitIsDeadOrGhost(unit);
    if ( ( not addon.IsSecretValue(dead) ) and dead ) then
        ClearFrame(frame);
        return;
    end

    local container = EnsureContainer(frame);
    ApplyIconLayout(container);

    local primaryAura, row2Auras, hasClassBuff = ScanUnitAuras(unit, profile);
    UpdateClassBuffWarning(frame, profile, ( ( not UnitIsPlayer(unit) ) or hasClassBuff ));
    UpdateRow1(frame, primaryAura, profile);
    UpdateRow2(frame, row2Auras, profile);
end

-- Maintain unit -> frame(s) so UNIT_AURA can target only the affected frames.
local function MapFrameUnit(frame)
    local unit = frame.displayedUnit or frame.unit;
    if ( frame.healerBuffHelperUnit == unit ) then return end

    if ( frame.healerBuffHelperUnit and unitFrames[frame.healerBuffHelperUnit] ) then
        unitFrames[frame.healerBuffHelperUnit][frame] = nil;
    end

    frame.healerBuffHelperUnit = unit;
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
    if ( frame.healerBuffHelperUnit and unitFrames[frame.healerBuffHelperUnit] ) then
        unitFrames[frame.healerBuffHelperUnit][frame] = nil;
    end
    frame.healerBuffHelperUnit = nil;
    ClearFrame(frame);
end

local function CheckSpec()
    local specID = addon.GetSpecForPlayerOrArena("player");
    local profile = profiles[specID];
    if ( profile and ( profile.class == playerClass ) ) then
        activeProfile = profile;
    else
        activeProfile = nil;
    end
end

local function RefreshAllFrames()
    for frame in pairs(cufPool) do
        UpdateFrame(frame);
    end
end

local function IsFrameVisible(frame)
    local shown = frame:IsShown();
    return ( ( not addon.IsSecretValue(shown) ) and shown );
end

local function UpdateVisibleFrame(frame)
    if IsFrameVisible(frame) then
        UpdateFrame(frame);
    end
end

local function ShouldTrackFrameName(name)
    if ( string.byte(name, 1) ~= 67 ) then return false end -- C: CompactPartyFrame / CompactRaid
    return ( ( string.sub(name, 1, 17) == "CompactPartyFrame" )
            or ( string.sub(name, 1, 11) == "CompactRaid" ) );
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

    -- If the event unit is not in the exact frame map, avoid UnitIsUnit here: in rated PvP it can
    -- involve restricted unit data, and GROUP_ROSTER_UPDATE/CompactUnitFrame_UpdateAll refresh mappings.
end

local eventFrame = CreateFrame("Frame");

-- Hide Blizzard's own raid-frame buffs while the helper is enabled on a supported healing spec, so our
-- icons replace them. In retail 12.x a frame's individual buff icons are forbidden/secret, so the only
-- lever is the global raidFramesDisplayBuffs CVar (all-or-nothing: it hides every buff on raid frames;
-- debuffs/dispels stay). Changing it re-runs setup on the protected raid frames, so we defer in combat.
local function ShouldHideBlizzardBuffs()
    return ( activeProfile and IsProfileEnabled(activeProfile) ) == true;
end

local function ApplyHideBlizzardBuffs()
    if ( ( not isSupportedClass ) or ( not addon.PROJECT_MAINLINE ) ) then return end -- retail-only supported classes

    if InCombatLockdown() then
        eventFrame:RegisterEvent(addon.PLAYER_REGEN_ENABLED); -- retry once combat ends
        return;
    end

    local desired;
    if ShouldHideBlizzardBuffs() then
        desired = "0";
    else
        desired = "1";
    end
    if ( GetCVar("raidFramesDisplayBuffs") ~= desired ) then
        SetCVar("raidFramesDisplayBuffs", desired); -- 0 hides buffs while active, 1 restores them when disabled
    end
end

function SweepyBoop:SetupRaidFrameAuraModule()
    if ( not isSupportedClass ) then return end -- nothing to do for unsupported classes this session

    CheckSpec();

    -- CompactUnitFrame_UpdateAll fires for every raid/party frame as it's set up / reused.
    hooksecurefunc("CompactUnitFrame_UpdateAll", function (frame)
        if frame:IsForbidden() then
            UntrackFrame(frame);
            return;
        end

        local name = frame:GetName();
        if ( name and ShouldTrackFrameName(name) ) then
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
                local oldProfile = activeProfile;
                CheckSpec();
                ApplyHideBlizzardBuffs(); -- entering/leaving a supported healer flips Blizzard buff hiding
                if ( oldProfile ~= activeProfile ) then
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

-- Called when the Healer Buff Helper settings change (and on profile switch): re-evaluate the
-- buff-hiding CVar and repaint every tracked frame for the new setting.
function SweepyBoop:RefreshHealerBuffHelper()
    ApplyHideBlizzardBuffs();
    RefreshAllFrames();
end
