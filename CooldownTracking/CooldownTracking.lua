local _, NS = ...;
local test = NS.isTestMode;

local UIParent = UIParent;
local UnitGUID = UnitGUID;
local GetSpellPowerCost = GetSpellPowerCost;
local UnitClass = UnitClass;
local GetArenaOpponentSpec = GetArenaOpponentSpec;
local GetSpecializationInfoByID = GetSpecializationInfoByID;
local CreateFrame = CreateFrame;
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo;

local cooldowns = NS.cooldownSpells;
local resets = NS.cooldownResets;

local resetByPower = {

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

    -- Fill options from parent
    if spell.parent then
        local parent = spell.parent;

        spell.cooldown = spell.cooldown or parent.cooldowns;
        spell.class = parent.class;
        spell.category = spell.category;
        spell.trackPet = parent.trackPet;
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
local SPELLCATEGORY = NS.SPELLCATEGORY;
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
    offsetY = -127.5,
};
setPointOptions[SPELLCATEGORY.CROWDCONTROL] = {
    point = "CENTER",
    relativeTo = UIParent,
    relativePoint = "CENTER",
    offsetX = 0,
    offsetY = -245,
};
setPointOptions[SPELLCATEGORY.DISPEL] = {
    point = "CENTER",
    relativeTo = UIParent,
    relativePoint = "CENTER",
    offsetX = 375,
    offsetY = -165,
};
setPointOptions[SPELLCATEGORY.DEFENSIVE] = {};
for i = 1, NS.MAX_ARENA_SIZE do
    setPointOptions[SPELLCATEGORY.DEFENSIVE][i] = {
        point = "LEFT",
        relativeTo = _G["sArenaEnemyFrame" .. i],
        relativePoint = "RIGHT",
        offsetX = 37.5,
        offsetY = -30,
    };
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
        for i = 1, NS.MAX_ARENA_SIZE do
            local unitId = "arena" .. i;
            -- We only need to cache GUIDs here, info such as specs are taken into account when populating icons
            if ( not self.unitGUIDs[unitId] ) then
                self.unitGUIDs[unitId] = UnitGUID(unitId);
            end
        end

        return self.unitGUIDs;
    end
end

-- Since we're tracking possibly multiple units, things need to be indexed by unitId - spellID here
local function ProcessCombatLogEventForUnit(self, unitId, guid, subEvent, sourceGUID, destGUID, spellId, spellName)
    -- Unit does not exist
    if ( not guid ) then return end

    -- Check resets by spell cast
    if ( subEvent == "SPELL_CAST_SUCCESS" ) and ( sourceGUID == guid ) then
        -- Check reset by power
        for i = 1, #resetByPower do
            local reset = resetByPower[i];
            if self.activeMap[unitId .. "-" .. reset] then
                local cost = GetSpellPowerCost(spellId);
                if cost and cost[1] and ( cost[1].type == cooldowns[reset].reduce_power_type ) then
                    local amount = cooldowns[reset].reduce_amount * cost[1].cost;
                    NS.ResetCooldownTrackingCooldown(self.activeMap[unitId .. "-" .. reset], amount);
                end
            end
        end

        -- Check reset by interrupts, Counterspell, solar Beam
        -- Solar Beam only reduces 15s when interrupting main target, how do we detect it? Cache last reduce time?

        -- Check regular resets
        if resets[spellId] then
            for resetSpellID, amount in pairs(resets[spellId]) do
                if self.activeMap[unitId .. "-" .. resetSpellID] then
                    NS.ResetCooldownTrackingCooldown(self.activeMap[unitId .. "-" .. resetSpellID], amount);
                end
            end
        end
    end

    -- Validate spell
    if ( not cooldowns[spellId] ) then return end
    local spell = cooldowns[spellId];

    -- Validate unit
    local spellGUID = ( spell.trackDest and destGUID ) or sourceGUID;
    if ( spellGUID ~= guid ) then return end

    -- Check spell dismiss
    if ( subEvent == "SPELL_AURA_REMOVED" ) then
        if self.activeMap[unitId .. "-" .. spellId] then
            NS.ResetCooldownTrackingCooldown(self.activeMap[unitId .. "-" .. spellId]);
            return;
        end
    end

    -- Validate subEvent
    if spell.trackEvent and ( subEvent ~= spell.trackEvent ) then return end
    if ( not spell.trackEvent ) and ( subEvent ~= "SPELL_CAST_SUCCESS" ) then return end

    -- Find the icon to use
    if self.icons[unitId .. "-" .. spellId] then
        NS.StartCooldownTrackingIcon(self.icons[unitId .. "-" .. spellId]);
    end
end

local function ProcessCombatLogEvent(self, subEvent, sourceGUID, destGUID, spellId, spellName)
    local guid = ValidateUnit(self);

    if self.unit then
        ProcessCombatLogEventForUnit(self, self.unit, guid, subEvent, sourceGUID, destGUID, spellId, spellName);
    else
        for i = 1, NS.MAX_ARENA_SIZE do
            ProcessCombatLogEventForUnit(self, "arena"..i, guid[i], subEvent, sourceGUID, destGUID, spellId, spellName);
        end
    end
end

local iconSize = 32;

local premadeIcons = {};

-- Premake all icons (regardless of class and category)
if test then
    local unitId = "player";
    premadeIcons[unitId] = {};
    for spellID, spell in pairs(cooldowns) do
        premadeIcons[unitId][spellID] = NS.CreateCooldownTrackingIcon(unitId, spellID);
    end
else
    for i = 1, NS.MAX_ARENA_SIZE do
        local unitId = "arena" .. i;
        premadeIcons[unitId] = {};
        for spellID, spell in pairs(cooldowns) do
            premadeIcons[unitId][spellID] = NS.CreateCooldownTrackingIcon(unitId, spellID);
        end
    end
end

local function GetSpecOverrids(spell, spec)
    local overrides = {};

    if type(spell.cooldown) == "table" then
        overrides.cooldown = spell.cooldown[spec];
    end

    if type(spell.charges) == "table" then
        overrides.charges = spell.charges[spec];
    end

    return overrides;
end

-- If unit is not specified, track all 3 arena opponents
-- TODO: apply spec override when populating for a group (since we already know the spec here)
local function SetupIconGroupForUnit(group, category, unit)
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
            local spec = NS.GetUnitSpec(unit);
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
                -- Apply spec override as a table here to premadeIcons[unit][spellID]
                -- Remember to clean up first
                -- Basically put everything known based on spec here
                premadeIcons[unit][spellID].overrides = GetSpecOverrids(spell, spec);
                -- dynamic info such as chargeExpire, start, duration
                premadeIcons[unit][spellID].dynamic = {};

                NS.IconGroup_PopulateIcon(group, premadeIcons[unit][spellID], unit .. "-" .. spellID);
                --print("Populated", unit, spell.class, spellID)
            end
        end
    end
end

-- If unit is not specified, populate icons for all 3 arena opponents
local function SetupIconGroup(group, category, unit)
    NS.IconGroup_Wipe(group);

    if unit then
        SetupIconGroupForUnit(group, category, unit);
    else
        for i = 1, NS.MAX_ARENA_SIZE do
            SetupIconGroupForUnit(group, category, "arena"..i);
        end
    end
end

-- Populate icons based on class and spec
local iconGroups = {}; -- Each group tracks all 3 arena opponents
local defensiveGroups = {}; -- This one needs a group per unit

-- Create icon groups (note the category order)
local groupToken = test and "player" or nil;
iconGroups[SPELLCATEGORY.INTERRUPT] = NS.CreateIconGroup(setPointOptions[SPELLCATEGORY.INTERRUPT], growCenterUp, groupToken);
iconGroups[SPELLCATEGORY.DISRUPT] = NS.CreateIconGroup(setPointOptions[SPELLCATEGORY.DISRUPT], growCenterUp, groupToken);
iconGroups[SPELLCATEGORY.CROWDCONTROL] = NS.CreateIconGroup(setPointOptions[SPELLCATEGORY.CROWDCONTROL], growCenterDown, groupToken);
iconGroups[SPELLCATEGORY.DISPEL] = NS.CreateIconGroup(setPointOptions[SPELLCATEGORY.DISPEL], growRightDown, groupToken);
if test then
    defensiveGroups[1] = NS.CreateIconGroup(setPointOptions[SPELLCATEGORY.DEFENSIVE][1], growRight, "player");
else
    for i = 1, NS.MAX_ARENA_SIZE do
        defensiveGroups[i] = NS.CreateIconGroup(setPointOptions[SPELLCATEGORY.DEFENSIVE][i], growRight, "arena" .. i);
    end
end

local function RefreshGroups()
    if test then
        for i = SPELLCATEGORY.INTERRUPT, SPELLCATEGORY.DISPEL do
            SetupIconGroup(iconGroups[i], i, "player");
        end

        SetupIconGroup(defensiveGroups[1], SPELLCATEGORY.DEFENSIVE, "player");
    else
        for i = SPELLCATEGORY.INTERRUPT, SPELLCATEGORY.DISPEL do
            SetupIconGroup(iconGroups[i], i); -- Don't specify unit, so it populates icons for all 3 arena opponents
        end

        for i = 1, NS.MAX_ARENA_SIZE do
           SetupIconGroup(defensiveGroups[i], "arena" .. i);
        end
    end
end

-- On first login
RefreshGroups();

local function UpdateAllBorders(group)
    for i = 1, #(group.active) do
        CooldownTracking_UpdateBorder(group.active[i]);
    end
end

-- Refresh icon groups when zone changes, or during test mode when player switches spec
local refreshFrame = CreateFrame("Frame");
refreshFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
refreshFrame:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS");
refreshFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED");
refreshFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
refreshFrame:RegisterEvent("PLAYER_TARGET_CHANGED");
refreshFrame:RegisterEvent("PLAYER_FOCUS_CHANGED");
refreshFrame:SetScript("OnEvent", function (self, event, ...)
    if ( event == "PLAYER_ENTERING_WORLD" ) or ( event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS" ) or ( event == "PLAYER_SPECIALIZATION_CHANGED") then
        RefreshGroups();
    elseif ( event == "COMBAT_LOG_EVENT_UNFILTERED" ) then
        local _, subEvent, _, sourceGUID, _, _, _, destGUID, _, _, _, spellId, spellName = CombatLogGetCurrentEventInfo();
        for i = SPELLCATEGORY.INTERRUPT, SPELLCATEGORY.DISPEL do
            ProcessCombatLogEvent(iconGroups[i], subEvent, sourceGUID, destGUID, spellId, spellName);
        end
        
        for i = 1, NS.MAX_ARENA_SIZE do
            if defensiveGroups[i] then
                ProcessCombatLogEvent(defensiveGroups[i], subEvent, sourceGUID, destGUID, spellId, spellName);
            end
        end
    elseif ( event == "PLAYER_TARGET_CHANGED" ) or ( event == "PLAYER_FOCUS_CHANGED" ) then
        for i = SPELLCATEGORY.INTERRUPT, SPELLCATEGORY.DISPEL do
            UpdateAllBorders(iconGroups[i]);
        end

        for i = 1, NS.MAX_ARENA_SIZE do
            if defensiveGroups[i] then
                UpdateAllBorders(defensiveGroups[i]);
            end
        end
    end
end)