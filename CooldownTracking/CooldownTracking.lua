local _, addon = ...;
local test = addon.isTestMode;

local UIParent = UIParent;
local UnitGUID = UnitGUID;
local GetSpellPowerCost = C_Spell.GetSpellPowerCost;
local UnitClass = UnitClass;
local GetArenaOpponentSpec = GetArenaOpponentSpec;
local GetSpecializationInfoByID = GetSpecializationInfoByID;
local CreateFrame = CreateFrame;
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo;
local Gladius = Gladius;
local sArena = sArena;

local cooldowns = addon.cooldownSpells;
local resets = addon.cooldownResets;
local SPELLCATEGORY = addon.SPELLCATEGORY;

local resetByPower = {
    853,
};

for spellID, spell in pairs(cooldowns) do
    spell.priority = spell.index or 100;

    if ( not spell.class ) then
        print("Spell missing class:", spellID);
    end

    -- Validate class
    if spell.class and ( type(spell.class) ~= "string" ) then
        print("Invalid class for spellID:", spellID);
    end

    -- Validate category
    if ( not spell.category ) or ( spell.category < 2 ) or ( spell.category > 6 ) then
        print("Invalid category for spellID:", spellID);
    end

    -- Validate trackEvent
    if spell.trackEvent and type(spell.trackEvent) ~= "string" then
        print("Invalid trackEvent for spellID:", spellID);
    end
end

local function ValidateUnit(self)
    -- If unit is specified, this is a group to track a single unit, return unitGUID
    if self.unit then
        -- Update icon group guid
        if ( not self.unitGUID ) then
            self.unitGUID = UnitGUID(self.unit);
        end

        -- If unit does not exist, will return nil
        return self.unitGUID;
    else
        self.unitGUIDs = self.unitGUIDs or {};
        for i = 1, addon.MAX_ARENA_SIZE do
            local unitId = "arena" .. i;
            -- We only need to cache GUIDs here, info such as specs are taken into account when populating icons
            if ( not self.unitGUIDs[unitId] ) then
                self.unitGUIDs[unitId] = UnitGUID(unitId);
            end
        end

        return self.unitGUIDs;
    end
end

local function IsCastByPet(guid, unitId)
    local petUnitId;
    if ( unitId == "player" ) then
        petUnitId = "pet";
    else
        petUnitId = "arenapet" .. string.sub(unitId, -1, -1);
    end

    return guid == UnitGUID(petUnitId);
end

local function ShouldResetSpell(reset, icon)
    local info = icon.info;
    -- Icon spec should be known when populated to a group
    if ( not info.spec ) or ( type(reset) ~= "table" ) then return true end

    if reset.specID then
        for i = 1, #(reset.specID) do
            if ( info.spec == reset.specID[i] ) then
                return true;
            end
        end

        return false;
    end

    return true;
end

-- Since we're tracking possibly multiple units, things need to be indexed by unitId - spellID here
local function ProcessCombatLogEventForUnit(self, unitId, guid, subEvent, sourceGUID, destGUID, spellId, spellName)
    -- Unit does not exist
    if ( not guid ) then return end

    -- Check resets by spell cast
    if ( subEvent == addon.SPELL_CAST_SUCCESS ) and ( sourceGUID == guid ) then
        -- Check reset by power
        for i = 1, #resetByPower do
            local reset = resetByPower[i];
            local iconId = unitId .. "-" .. reset;
            if self.activeMap[iconId] then
                local cost = GetSpellPowerCost(spellId);
                if cost and cost[1] and ( cost[1].type == cooldowns[reset].reduce_power_type ) then
                    local amount = cooldowns[reset].reduce_amount * cost[1].cost;
                    addon.ResetCooldownTrackingCooldown(self.activeMap[iconId], amount);
                end
            end
        end

        -- Check regular resets
        if resets[spellId] then
            for i = 1, #resets[spellId] do
                local reset = resets[spellId][i];

                local spellIdReset;
                local amount;
                if type(reset) == "table" and reset.amount then
                    spellIdReset = reset.spellID;
                    amount = reset.amount;
                else
                    if type(reset) == "table" then
                        spellIdReset = reset.spellID;
                    else
                        spellIdReset = reset;
                    end
                end

                local icon = self.activeMap[unitId .. "-" .. spellIdReset];
                if icon and ShouldResetSpell(reset, icon) then
                    addon.ResetCooldownTrackingCooldown(icon, amount);
                end
            end
        end
    end

    -- Check reset by interrupts, Counterspell, solar Beam
    -- Solar Beam only reduces 15s when interrupting main target, how do we detect it? Cache last reduce time?
    if ( subEvent == addon.SPELL_INTERRUPT ) and ( sourceGUID == guid ) then
        local icon = self.activeMap[unitId .. "-" .. spellId];
        local amount = icon and icon.spellInfo.reduce_on_interrupt;
        if icon and amount then
            addon.ResetCooldownTrackingCooldown(icon, amount, amount);
        end
    end

    -- Passed
    --print("Process combat log event:", unitId, spellId, guid, sourceGUID, subEvent);

    -- Validate spell
    if ( not cooldowns[spellId] ) then return end
    local spell = cooldowns[spellId];

    -- Validate unit
    local spellGUID = ( spell.trackDest and destGUID ) or sourceGUID;
    local validateUnit;
    if spell.trackPet then
        -- Spell cast by pet or its owner
        validateUnit = IsCastByPet(spellGUID, unitId) or ( spellGUID == guid );
    else
        validateUnit = ( spellGUID == guid );
    end
    if ( not validateUnit ) then return end

    -- Validate subEvent
    local validateSubEvent;
    if spell.trackEvent then
        validateSubEvent = ( subEvent == spell.trackEvent );
    else
        validateSubEvent = ( subEvent == addon.SPELL_CAST_SUCCESS );
    end
    if ( not validateSubEvent ) then return end

    -- Find the icon to use
    local iconId = unitId .. "-" .. spellId;
    if self.icons[iconId] then
        addon.StartCooldownTrackingIcon(self.icons[iconId]);
    end
end

local function ProcessCombatLogEvent(self, subEvent, sourceGUID, destGUID, spellId, spellName)
    local guid = ValidateUnit(self);

    if self.unit then
        ProcessCombatLogEventForUnit(self, self.unit, guid, subEvent, sourceGUID, destGUID, spellId, spellName);
    else
        for i = 1, addon.MAX_ARENA_SIZE do
            local unitId = "arena"..i;
            ProcessCombatLogEventForUnit(self, unitId, guid[unitId], subEvent, sourceGUID, destGUID, spellId, spellName);
        end
    end
end

local premadeIcons = {};

-- Premake all icons (regardless of class and category)
function SweepyBoop:PremakeCooldownTrackingIcons()
    if ( not self.db.profile.arenaEnemyDefensivesEnabled ) then return end

    local defensiveIconSize = self.db.profile.arenaEnemyDefensiveIconSize;
    if test then
        local unitId = "player";
        premadeIcons[unitId] = {};
        for spellID, spell in pairs(cooldowns) do
            local size, hideHighlight;
            if ( spell.category == SPELLCATEGORY.DEFENSIVE ) then
                size, hideHighlight = defensiveIconSize, true;
            end
            premadeIcons[unitId][spellID] = addon.CreateCooldownTrackingIcon(unitId, spellID, size, hideHighlight);
        end
    else
        for i = 1, addon.MAX_ARENA_SIZE do
            local unitId = "arena" .. i;
            premadeIcons[unitId] = {};
            for spellID, spell in pairs(cooldowns) do
                local size, hideHighlight;
                if ( spell.category == SPELLCATEGORY.DEFENSIVE ) then
                    size, hideHighlight = defensiveIconSize, true;
                end
                premadeIcons[unitId][spellID] = addon.CreateCooldownTrackingIcon(unitId, spellID, size, hideHighlight);
            end
        end
    end
end

local function GetSpecOverrides(spell, spec)
    local overrides = {};

    overrides.spec = spec;

    if type(spell.cooldown) == "table" then
        overrides.cooldown = spell.cooldown[spec] or spell.cooldown.default;
    else
        overrides.cooldown = spell.cooldown;
    end

    if type(spell.charges) == "table" then
        overrides.charges = spell.charges[spec];
    else
        overrides.charges = spell.charges;
    end

    return overrides;
end

-- If unit is not specified, track all 3 arena opponents
-- TODO: apply spec override when populating for a group (since we already know the spec here)
local function SetupIconGroupForUnit(group, category, unit, testIcons)
    -- For external "Toggle Test Mode" icons, no filtering is needed
    if testIcons then
        for spellID, spell in pairs(cooldowns) do
            testIcons[unit][spellID].info = GetSpecOverrides(spell);
            addon.IconGroup_PopulateIcon(group, testIcons[unit][spellID], unit .. "-" .. spellID);
        end

        return;
    end

    -- In arena prep phase, UnitExists returns false since enemies are not visible, but we can check spec and populate icons
    local class;
    if ( unit == "player" ) then
        class = select(2, UnitClass(unit));
    else
        -- UnitClass returns nil unless unit is in range, but arena spec is available in prep phase.
        local index = string.sub(unit, -1, -1);
        local specID = GetArenaOpponentSpec(index);
        if specID and ( specID > 0 ) then
            class = select(6, GetSpecializationInfoByID(specID));
        end
    end
    if ( not class ) then return end

    -- Pre-populate icons
    for spellID, spell in pairs(cooldowns) do
        -- A spell without class specified should always be populated, e.g., Power Infusion can be applied to any class
        if ( spell.category == category ) and ( ( not spell.class ) or ( spell.class == class ) ) then
            local enabled = true;
            local spec = addon.GetUnitSpec(unit);
            -- Does this spell filter by spec?
            if spell.spec then
                local specEnabled = false;

                if ( not spec ) then
                    specEnabled = true;
                else
                    for i = 1, #(spell.spec) do
                        if ( spec == spell.spec[i] ) then
                            specEnabled = true;
                            break;
                        end
                    end
                end

                enabled = specEnabled;
            end

            if enabled then
                -- Dynamic info for current icon
                premadeIcons[unit][spellID].info = GetSpecOverrides(spell, spec);
                addon.IconGroup_PopulateIcon(group, premadeIcons[unit][spellID], unit .. "-" .. spellID);
                --print("Populated", unit, spell.class, spellID);
            end
        end
    end
end

-- If unit is not specified, populate icons for all 3 arena opponents
local function SetupIconGroup(group, category, testIcons)
    if ( not group ) then return end

    addon.IconGroup_Wipe(group);

    if group.unit then
        SetupIconGroupForUnit(group, category, group.unit, testIcons);
    else
        for i = 1, addon.MAX_ARENA_SIZE do
            SetupIconGroupForUnit(group, category, "arena"..i, testIcons);
        end
    end
end

-- Populate icons based on class and spec
local iconGroups = {}; -- Each group tracks all 3 arena opponents
local defensiveGroups = {}; -- This one needs a group per unit

local function RefreshGroups()
    if test then
        for i = SPELLCATEGORY.INTERRUPT, SPELLCATEGORY.DISPEL do
            SetupIconGroup(iconGroups[i], i);
        end

        SetupIconGroup(defensiveGroups[1], SPELLCATEGORY.DEFENSIVE);
    else
        for i = SPELLCATEGORY.INTERRUPT, SPELLCATEGORY.DISPEL do
            SetupIconGroup(iconGroups[i], i); -- Don't specify unit, so it populates icons for all 3 arena opponents
        end

        for i = 1, addon.MAX_ARENA_SIZE do
           SetupIconGroup(defensiveGroups[i], SPELLCATEGORY.DEFENSIVE);
        end
    end
end

local function UpdateAllBorders(group)
    for i = 1, #(group.active) do
        CooldownTracking_UpdateBorder(group.active[i]);
    end
end

local growCenterUp = {
    direction = "CENTER",
    anchor = "CENTER",
    margin = 3,
    columns = 6,
    growUpward = true,
};

local growCenterDown = {
    direction = "CENTER",
    anchor = "CENTER",
    margin = 3,
    columns = 6,
    growUpward = false;
};

local growRight = {
    direction = "RIGHT",
    anchor = "LEFT",
    margin = 3,
};

local growRightDown = {
    direction = "RIGHT",
    anchor = "LEFT",
    margin = 3,
    columns = 3,
    growUpward = false,
};

local setPointOptions = {};

setPointOptions[SPELLCATEGORY.INTERRUPT] = {
    point = "CENTER",
    relativeTo = UIParent,
    relativePoint = "CENTER",
    offsetX = 0,
    offsetY = -167.5,
};
setPointOptions[SPELLCATEGORY.DISRUPT] = {
    point = "CENTER",
    relativeTo = UIParent,
    relativePoint = "CENTER",
    offsetX = 0,
    offsetY = -122.5,
};
setPointOptions[SPELLCATEGORY.CROWDCONTROL] = {
    point = "CENTER",
    relativeTo = UIParent,
    relativePoint = "CENTER",
    offsetX = 0,
    offsetY = -275,
};
setPointOptions[SPELLCATEGORY.DISPEL] = {
    point = "CENTER",
    relativeTo = UIParent,
    relativePoint = "CENTER",
    offsetX = 375,
    offsetY = -165,
};

local refreshFrame;

local externalTestIcons = {}; -- Premake icons for "Toggle Test Mode"
local externalTestGroup; -- Icon group for "Toggle Test Mode"

local function RefreshTestMode()
    addon.IconGroup_Wipe(externalTestGroup);

    local defensiveIconSize = SweepyBoop.db.profile.arenaEnemyDefensiveIconSize;
    local unitId = "player";
    if externalTestIcons[unitId] then
        local scale = defensiveIconSize / addon.DEFAULT_ICON_SIZE;
        for _, icon in pairs(externalTestIcons[unitId]) do
            icon:SetScale(scale);
        end
    else
        externalTestIcons[unitId] = {};
        for spellID, spell in pairs(cooldowns) do
            local size, hideHighlight;
            if ( spell.category == SPELLCATEGORY.DEFENSIVE ) then
                size, hideHighlight = defensiveIconSize, true;
            end
            externalTestIcons[unitId][spellID] = addon.CreateCooldownTrackingIcon(unitId, spellID, size, hideHighlight);
        end
    end

    local relativeTo = ( Gladius and "GladiusButtonFramearena1" )  or ( sArena and "sArenaEnemyFrame1" ) or "NONE";
    local offsetY;
    if SweepyBoop.db.profile.arenaEnemyOffensivesEnabled then
        -- Offensive icons enabled, show defensives below them
        offsetY = -( SweepyBoop.db.profile.arenaEnemyOffensiveIconSize*0.5 + SweepyBoop.db.profile.arenaEnemyDefensiveIconSize*0.5 + 2 );
    else
        -- Otherwise show at the center
        offsetY = 0;
    end
    offsetY = offsetY + SweepyBoop.db.profile.arenaCooldownOffsetY;
    local setPointOption = {
        point = "LEFT",
        relativeTo = relativeTo,
        relativePoint = "RIGHT",
        offsetY = offsetY,
    };

    externalTestGroup = addon.CreateIconGroup(setPointOption, growRight, unitId);
    SetupIconGroup(externalTestGroup, SPELLCATEGORY.DEFENSIVE, externalTestIcons);
end

-- Create icon groups (note the category order)
function SweepyBoop:PopulateCooldownTrackingIcons()
    if ( not self.db.profile.arenaEnemyDefensivesEnabled ) then return end

    -- Setup defensive group based on whether Gladius/sArena is loaded and user settings.
    setPointOptions[SPELLCATEGORY.DEFENSIVE] = {};
    local prefix = ( Gladius and "GladiusButtonFramearena" )  or ( sArena and "sArenaEnemyFrame" ) or "NONE";
    local offsetY;
    if self.db.profile.arenaEnemyOffensivesEnabled then
        -- Offensive icons enabled, show defensives below them
        offsetY = -( self.db.profile.arenaEnemyOffensiveIconSize*0.5 + self.db.profile.arenaEnemyDefensiveIconSize*0.5 + 2 );
    else
        -- Otherwise show at the center
        offsetY = 0;
    end
    offsetY = offsetY + SweepyBoop.db.profile.arenaCooldownOffsetY;
    for i = 1, addon.MAX_ARENA_SIZE do
        setPointOptions[SPELLCATEGORY.DEFENSIVE][i] = {
            point = "LEFT",
            relativeTo = prefix .. i,
            relativePoint = "RIGHT",
            offsetY = offsetY;
        };
    end

    if addon.internal then
        local groupToken = ( test and "player" ) or nil;
        iconGroups[SPELLCATEGORY.INTERRUPT] = addon.CreateIconGroup(setPointOptions[SPELLCATEGORY.INTERRUPT], growCenterUp, groupToken);
        iconGroups[SPELLCATEGORY.DISRUPT] = addon.CreateIconGroup(setPointOptions[SPELLCATEGORY.DISRUPT], growCenterUp, groupToken);
        iconGroups[SPELLCATEGORY.CROWDCONTROL] = addon.CreateIconGroup(setPointOptions[SPELLCATEGORY.CROWDCONTROL], growCenterDown, groupToken);
        iconGroups[SPELLCATEGORY.DISPEL] = addon.CreateIconGroup(setPointOptions[SPELLCATEGORY.DISPEL], growRightDown, groupToken);
    end

    if test then
        defensiveGroups[1] = addon.CreateIconGroup(setPointOptions[SPELLCATEGORY.DEFENSIVE][1], growRight, "player");
    else
        for i = 1, addon.MAX_ARENA_SIZE do
            defensiveGroups[i] = addon.CreateIconGroup(setPointOptions[SPELLCATEGORY.DEFENSIVE][i], growRight, "arena" .. i);
        end
    end

    -- On first login
    RefreshGroups();

    -- Refresh icon groups when zone changes, or during test mode when player switches spec
    refreshFrame = CreateFrame("Frame");
    refreshFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
    refreshFrame:RegisterEvent(addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS);
    refreshFrame:RegisterEvent(addon.PLAYER_SPECIALIZATION_CHANGED);
    refreshFrame:RegisterEvent(addon.COMBAT_LOG_EVENT_UNFILTERED);
    refreshFrame:RegisterEvent(addon.PLAYER_TARGET_CHANGED);
    refreshFrame:SetScript("OnEvent", function (frame, event, ...)
        if ( event == addon.PLAYER_ENTERING_WORLD ) or ( event == addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS ) or ( event == addon.PLAYER_SPECIALIZATION_CHANGED and test ) then
            -- Hide the external "Toggle Test Mode" group
            self:HideTestCooldownTracking();

            RefreshGroups();
        elseif ( event == addon.COMBAT_LOG_EVENT_UNFILTERED ) then
            local _, subEvent, _, sourceGUID, _, _, _, destGUID, _, _, _, spellId, spellName = CombatLogGetCurrentEventInfo();

            if addon.internal then
                -- These bars are not for publish audience...
                for i = SPELLCATEGORY.INTERRUPT, SPELLCATEGORY.DISPEL do
                    ProcessCombatLogEvent(iconGroups[i], subEvent, sourceGUID, destGUID, spellId, spellName);
                end
            end

            for i = 1, addon.MAX_ARENA_SIZE do
                if defensiveGroups[i] then
                    ProcessCombatLogEvent(defensiveGroups[i], subEvent, sourceGUID, destGUID, spellId, spellName);
                end
            end
        elseif ( event == addon.PLAYER_TARGET_CHANGED ) then
            if addon.internal then
                -- These bars are not for publish audience...
                for i = SPELLCATEGORY.INTERRUPT, SPELLCATEGORY.DISPEL do
                    UpdateAllBorders(iconGroups[i]);
                end
            end

            for i = 1, addon.MAX_ARENA_SIZE do
                if defensiveGroups[i] then
                    UpdateAllBorders(defensiveGroups[i]);
                end
            end
        end
    end)
end

function SweepyBoop:TestCooldownTracking()
    if ( not SweepyBoop.db.profile.arenaEnemyDefensivesEnabled ) then
        -- Module disabled, simply hide test icons
        self:HideTestCooldownTracking();
        return;
    end

    local shoudShow = ( not externalTestGroup ) or ( not externalTestGroup:IsShown() );

    RefreshTestMode();

    local subEvent = addon.SPELL_CAST_SUCCESS;
    local sourceGUID = UnitGUID("player");
    local destGUID = UnitGUID("player");
    local spellId = 45438; -- Ice Block
    ProcessCombatLogEvent(externalTestGroup, subEvent, sourceGUID, destGUID, spellId);

    spellId = 87024; -- Cauterize
    subEvent = addon.SPELL_AURA_APPLIED;
    ProcessCombatLogEvent(externalTestGroup, subEvent, sourceGUID, destGUID, spellId);

    if shoudShow then
        externalTestGroup:Show();
    else
        externalTestGroup:Hide();
    end
end

function SweepyBoop:HideTestCooldownTracking()
    addon.IconGroup_Wipe(externalTestGroup);
    if externalTestGroup then
        externalTestGroup:Hide();
    end
end
