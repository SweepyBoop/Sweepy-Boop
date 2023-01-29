local _, NS = ...;

local test = false;

local spellData = NS.spellData;
local spellResets = NS.spellResets;

local npcToSpellID = {
    [101398] = 211522, -- Psyfiend
    [62982] = 200174, -- Mindbender
    [196111] = 387578, -- Gul'dan's Ambition (Pit Lord)
};

local resetByPower = {
    137639, -- Storm, Earth, and Fire
    152173, -- Serenity
    1719, -- Recklessness
};

local resetByCrit = {
    190319, -- Combustion
    1459, -- Arcane Intellect (test)
};

for spellID, spell in pairs(spellData) do
    -- Fill default priority
    spell.priority = spell.index;
    if ( not spell.priority ) then
        spell.priority = 100;
    end

    -- Validate class, class is allowed to be missing if trackDest (since destGUID can be any class)
    if ( not spell.class ) and ( not spell.trackDest ) then
        print("Invalid spellID:", spellID);
    end

    -- Class should be a string of capital letters
    if spell.class and ( type(spell.class) ~= "string" ) then
        print("Invalid class for spellID:", spellID);
    end
end

local growOptions = {
    direction = "RIGHT",
    anchor = "LEFT",
    margin = 3,
};

local setPointOptions = {};
for i = 1, NS.MAX_ARENA_SIZE do
    setPointOptions[i] = {
        point = "LEFT",
        relativeTo = _G["sArenaEnemyFrame" .. i],
        relativePoint = "RIGHT",
        offsetX = 37.5,
        offsetY = 0,
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
                if cost and cost[1] and ( cost[1].type == spellData[reset].reduce_power_type ) then
                    local amount = spellData[reset].reduce_amount * cost[1].cost;
                    NS.ResetWeakAuraCooldown(self.activeMap[reset], amount);
                end
            end
        end

        -- Check regular resets
        if spellResets[spellId] then
            for resetSpellID, amount in pairs(spellResets[spellId]) do
                if self.activeMap[resetSpellID] then
                    NS.ResetWeakAuraCooldown(self.activeMap[resetSpellID], amount);
                end
            end
        end
    end

    -- Check resets by crit damage (e.g., combustion)
    if ( subEvent == "SPELL_DAMAGE" ) and critical and ( sourceGUID == guid ) then
        for i = 1, #resetByCrit do
            local reset = resetByCrit[i];
            if self.activeMap[reset] then
                local spells = spellData[reset].critResets;
                for i = 1, #spells do
                    if ( spellId == spells[i] ) or ( spellName == spells[i] ) then
                        NS.ResetWeakAuraCooldown(self.activeMap[reset], spellData[reset].critResetAmount);
                    end
                end
                return;
            end
        end
    end

    -- Check summon / dead
    if ( subEvent == "UNIT_DIED" ) then
        -- Might have already been dismissed by SPELL_AURA_REMOVED, e.g., Psyfiend
        local summonSpellId = self.npcMap[destGUID];
        if summonSpellId and self.activeMap[summonSpellId] then
            NS.ResetWeakAuraDuration(self.activeMap[summonSpellId]);
        end
        return;
    elseif ( subEvent == "SPELL_SUMMON" ) and ( guid == sourceGUID ) then
        -- We don't actually show the icon from SPELL_SUMMON, just create the mapping of mob GUID -> spellID
        local npcId = NS.GetNpcIdFromGuid(destGUID);
        local summonSpellId = npcToSpellID[npcId];
        self.npcMap[destGUID] = summonSpellId;

        -- If not added yet, add by this (e.g., Guldan's Ambition: Pit Lord)
        if summonSpellId and self.icons[summonSpellId] and ( not self.activeMap[summonSpellId] ) then
            NS.StartWeakAuraIcon(self.icons[summonSpellId]);
        end
        return;
    end
        
    -- Validate spell
    if ( not spellData[spellId] ) then return end
    local spell = spellData[spellId];

    -- Validate unit
    local spellGUID = ( spell.trackDest and destGUID ) or sourceGUID;
    if ( spellGUID ~= guid ) then return end

    -- Check spell dismiss
    if ( subEvent == "SPELL_AURA_REMOVED" ) then
        if self.activeMap[spellId] then
            NS.ResetWeakAuraDuration(self.activeMap[spellId]);
            return;
        end
    end

    -- Validate subEvent
    if spell.trackEvent and ( subEvent ~= spell.trackEvent ) then return end
    if ( not spell.trackEvent ) and ( subEvent ~= "SPELL_CAST_SUCCESS" ) then return end

    -- Find the icon to use
    if self.icons[spellId] then
        NS.StartWeakAuraIcon(self.icons[spellId]);
    end
end

local function ProcessUnitSpellCast(self, event, ...)
    local guid = ValidateUnit(self);
    if ( not guid ) then return end

    local unitTarget, _, spellID = ...;
    if ( unitTarget == self.unit ) then
        local spell = spellData[spellID];
        if ( not spell ) or ( spell.trackEvent ~= "UNIT_SPELLCAST_SUCCEEDED" ) then return end
        if self.icons[spellID] then
            NS.StartWeakAuraIcon(self.icons[spellID]);
        end
    end
end

local function ProcessUnitAura(self, event, ...)
    local guid = ValidateUnit(self);
    if ( not guid ) then return end

    local unitTarget, updateAuras = ...;
    -- Only use UNIT_AURA to extend aura
    if ( unitTarget == self.unit ) and updateAuras and updateAuras.updatedAuraInstanceIDs then
        for _, instanceID in ipairs(updateAuras.updatedAuraInstanceIDs) do
            local spellInfo = C_UnitAuras.GetAuraDataByAuraInstanceID(unitTarget, instanceID);
            if spellInfo then
                local spellID = spellInfo.spellId
                local spell = spellData[spellID]
                if ( not spell ) or ( not spell.extend ) or ( not self.activeMap[spellID] ) then return end
                NS.RefreshWeakAuraDuration(self.activeMap[spellID]);
            end
        end
    end
end

local function ProcessUnitEvent(group, event, ...)
    if ( event == "UNIT_SPELLCAST_SUCCEEDED" ) then
        ProcessUnitSpellCast(group, event, ...);
    elseif ( event == "UNIT_AURA" ) then
        ProcessUnitAura(group, event, ...);
    end
end

-- Premake all icons (regardless of class)
local premadeIcons = {};
if test then
    local unitId = "player";
    premadeIcons[unitId] = {};
    for spellID, spell in pairs(spellData) do
        premadeIcons[unitId][spellID] = NS.CreateWeakAuraIcon(unitId, spellID, 32, true);
    end
else
    for i = 1, NS.MAX_ARENA_SIZE do
        local unitId = "arena"..i;
        premadeIcons[unitId] = {};
        for spellID, spell in pairs(spellData) do
            premadeIcons[unitId][spellID] = NS.CreateWeakAuraIcon(unitId, spellID, 32, true);
        end
    end
end

local function GetUnitSpec(unit)
    if ( unit == "player" ) then
        local currentSpec = GetSpecialization();
        if currentSpec then
            return GetSpecializationInfo(currentSpec);
        end
    else
        local arenaIndex = string.sub(unit, -1, -1);
        return GetArenaOpponentSpec(index);
    end
end

local function SetupAuraGroup(group, unit)
    -- Clear previous icons
    NS.IconGroup_Wipe(group);

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
    for spellID, spell in pairs(spellData) do
        -- A spell without class specified should always be populated, e.g., Power Infusion can be applied to any class
        if ( not spell.class ) or ( spell.class == class ) then
            local enabled = true;
            -- Does this spell filter by spec?
            if spell.spec then
                local specEnabled = false;
                local spec = GetUnitSpec(unit);

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
                NS.IconGroup_PopulateIcon(group, premadeIcons[unit][spellID], spellID);
                print("Populated", unit, spell.class, spellID)
            end
        end
    end
end

-- Populate icons based on class & spec on login
local testGroup = nil;
local arenaGroup = {};
if test then
    local unitId = "player";
    testGroup = NS.CreateIconGroup(setPointOptions[1], growOptions, unitId);
    SetupAuraGroup(testGroup, unitId);
else
    for i = 1, NS.MAX_ARENA_SIZE do
        local unitId = "arena" .. i;
        arenaGroup[i] = NS.CreateIconGroup(setPointOptions[i], growOptions, unitId);
        SetupAuraGroup(arenaGroup[i], unitId);
    end
end

-- Refresh icon groups when zone changes, or during test mode when player switches spec
local refreshFrame = CreateFrame("Frame");
refreshFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
refreshFrame:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS");
refreshFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED");
refreshFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
refreshFrame:RegisterEvent("UNIT_AURA");
refreshFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");
refreshFrame:SetScript("OnEvent", function (self, event, ...)
    if ( event == "PLAYER_ENTERING_WORLD" ) or ( event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS" ) or ( event == "PLAYER_SPECIALIZATION_CHANGED") then
        if test then
            SetupAuraGroup(testGroup, "player");
        elseif ( event ~= "PLAYER_SPECIALIZATION_CHANGED" ) then -- This event is only for test mode
            for i = 1, NS.MAX_ARENA_SIZE do
                SetupAuraGroup(arenaGroup[i], "arena"..i);
            end
        end
    elseif ( event == "COMBAT_LOG_EVENT_UNFILTERED" ) then
        local _, subEvent, _, sourceGUID, _, _, _, destGUID, _, _, _, spellId, spellName, _, _, _, _, _, _, _, critical = CombatLogGetCurrentEventInfo();
        if test then
            ProcessCombatLogEvent(testGroup, event, subEvent, sourceGUID, destGUID, spellId, spellName, critical);
        else
            for i = 1, NS.MAX_ARENA_SIZE do
                ProcessCombatLogEvent(arenaGroup[i], event, subEvent, sourceGUID, destGUID, spellId, spellName, critical);
            end
        end
    else
        if test then
            ProcessUnitEvent(testGroup, event, ...);
        else
            for i = 1, NS.MAX_ARENA_SIZE do
                ProcessUnitEvent(arenaGroup[i], event, ...);
            end
        end
    end
end)
