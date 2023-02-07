local _, NS = ...;
local test = true;

local UIParent = UIParent;
local UnitGUID = UnitGUID;
local GetSpellPowerCost = GetSpellPowerCost;

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
end

local growCenter = {
    diretion = "CENTER",
    anchor = "CENTER",
    margin = 3,
};

local growRight = {
    direction = "RIGHT",
    anchor = "LEFT",
    margin = 3,
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
    -- Update icon group guid
    if ( not self.unitGUID ) then
        self.unitGUID = UnitGUID(self.unit);
    end

    -- If unit does not exist, will return nil
    return self.unitGUID;
end

local function ProcessCombatLogEvent(self, event, subEvent, sourceGUID, destGUID, spellId, spellName, critical)
    local guid = ValidateUnit(self);
    if ( not guid ) then return end

    -- Check resets by spell cast
    if ( subEvent == "SPELL_CAST_SUCCESS" ) and ( sourceGUID == guid ) then
        -- Check reset by power
        for i = 1, #resetByPower do
            local reset = resetByPower[i];
            if self.activeMap[reset] then
                local cost = GetSpellPowerCost(spellId);
                if cost and cost[1] and ( cost[1].type == cooldowns[reset].reduce_power_type ) then
                    local amount = cooldowns[reset].reduce_amount * cost[1].cost;
                    NS.ResetCooldownTrackingCooldown(self.activeMap[reset], amount);
                end
            end
        end

        -- Check regular resets
        if resets[spellId] then
            for resetSpellID, amount in pairs(resets[spellId]) do
                if self.activeMap[resetSpellID] then
                    NS.ResetCooldownTrackingCooldown(self.activeMap[resetSpellID], amount);
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
        if self.activeMap[spellId] then
            NS.ResetCooldownTrackingCooldown(self.activeMap[spellId]);
            return;
        end
    end

    -- Validate subEvent
    if spell.trackEvent and ( subEvent ~= spell.trackEvent ) then return end
    if ( not spell.trackEvent ) and ( subEvent ~= "SPELL_CAST_SUCCESS" ) then return end

    -- Find the icon to use
    if self.icons[spellId] then
        NS.StartCooldownTrackingIcon(self.icons[spellId]);
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

-- If unit is not specified, track all 3 arena opponents
-- Have a function that takes unit arg, and a function to call it to add all 3
local function SetupIconGroup(group, unit)
    -- Clear previous icons
    NS.IconGroup_Wipe(group);

    if unit then
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
    end
end

-- Populate icons based on class and spec
local iconGroups = {}; -- Each group tracks all 3 arena opponents
local defensiveGroups = {}; -- This one needs a group per unit

-- Create icon groups
iconGroups[SPELLCATEGORY.INTERRUPT] = NS.CreateIconGroup(setPointOptions[SPELLCATEGORY.INTERRUPT], growCenter);
iconGroups[SPELLCATEGORY.DISRUPT] = NS.CreateIconGroup(setPointOptions[SPELLCATEGORY.DISRUPT], growCenter);
iconGroups[SPELLCATEGORY.CROWDCONTROL] = NS.CreateIconGroup(setPointOptions[SPELLCATEGORY.CROWDCONTROL], growCenter);
iconGroups[SPELLCATEGORY.DISPEL] = NS.CreateIconGroup(setPointOptions[SPELLCATEGORY.DISPEL], growRight);
if test then
    defensiveGroups[1] = NS.CreateIconGroup(setPointOptions[SPELLCATEGORY.DEFENSIVE][1], growRight, "player");
else
    for i = 1, NS.MAX_ARENA_SIZE do
        defensiveGroups[i] = NS.CreateIconGroup(setPointOptions[SPELLCATEGORY.DEFENSIVE][i], growRight, "arena" .. i);
    end
end