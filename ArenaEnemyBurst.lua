local _, NS = ...;

local CreateFrame = CreateFrame;
local UIParent = UIParent;
local UnitGUID = UnitGUID;
local GetSpellPowerCost = GetSpellPowerCost;
local C_UnitAuras = C_UnitAuras;
local GetSpecialization = GetSpecialization;
local GetSpecializationInfo = GetSpecializationInfo;
local GetArenaOpponentSpec = GetArenaOpponentSpec;
local UnitClass = UnitClass;
local GetSpecializationInfoByID = GetSpecializationInfoByID;
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo;

-- The first ActionBarButtonSpellActivationAlert created seems to be corrupted by other icons, so we create a dummy here that does nothing
local dummy = CreateFrame("Frame", nil, UIParent, "ActionBarButtonSpellActivationAlert");

local test = NS.isTestMode;

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
};

for spellID, spell in pairs(spellData) do
    -- Fill default priority
    spell.priority = spell.index or 100;

    -- Validate class, class is allowed to be missing if trackDest (since destGUID can be any class)
    if ( not spell.class ) and ( not spell.trackDest ) then
        print("Invalid spellID:", spellID);
    end

    -- Class should be a string of capital letters
    if spell.class and ( type(spell.class) ~= "string" ) then
        print("Invalid class for spellID:", spellID);
    end
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
    if ( subEvent == NS.SPELL_CAST_SUCCESS ) and ( sourceGUID == guid ) then
        -- Check reset by power
        for i = 1, #resetByPower do
            local reset = resetByPower[i];
            if self.activeMap[reset] then
                local cost = GetSpellPowerCost(spellId);
                if cost and cost[1] and ( cost[1].type == spellData[reset].reduce_power_type ) then
                    local amount = spellData[reset].reduce_amount * cost[1].cost;
                    NS.ResetIconCooldown(self.activeMap[reset], amount);
                end
            end
        end

        -- Check regular resets
        if spellResets[spellId] then
            for resetSpellID, amount in pairs(spellResets[spellId]) do
                if self.activeMap[resetSpellID] then
                    NS.ResetIconCooldown(self.activeMap[resetSpellID], amount);
                end
            end
        end
    end

    -- Check resets by crit damage (e.g., combustion)
    if ( subEvent == NS.SPELL_DAMAGE ) and critical and ( sourceGUID == guid ) then
        for i = 1, #resetByCrit do
            local reset = resetByCrit[i];
            if self.activeMap[reset] then
                local spells = spellData[reset].critResets;
                for i = 1, #spells do
                    if ( spellId == spells[i] ) or ( spellName == spells[i] ) then
                        NS.ResetIconCooldown(self.activeMap[reset], spellData[reset].critResetAmount);
                    end
                end
                return;
            end
        end
    end

    -- Check summon / dead
    if ( subEvent == NS.UNIT_DIED ) or ( subEvent == NS.PARTY_KILL ) then
        -- Might have already been dismissed by SPELL_AURA_REMOVED, e.g., Psyfiend
        local summonSpellId = self.npcMap[destGUID];
        if summonSpellId and self.activeMap[summonSpellId] then
            NS.ResetSweepyDuration(self.activeMap[summonSpellId]);
        end
        return;
    elseif ( subEvent == NS.SPELL_SUMMON ) and ( guid == sourceGUID ) then
        -- We don't actually show the icon from SPELL_SUMMON, just create the mapping of mob GUID -> spellID
        local npcId = NS.GetNpcIdFromGuid(destGUID);
        local summonSpellId = npcToSpellID[npcId];
        self.npcMap[destGUID] = summonSpellId;

        -- If not added yet, add by this (e.g., Guldan's Ambition: Pit Lord)
        if summonSpellId and self.icons[summonSpellId] and ( not self.activeMap[summonSpellId] ) then
            NS.StartSweepyIcon(self.icons[summonSpellId]);
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
    if ( subEvent == NS.SPELL_AURA_REMOVED ) then
        if self.activeMap[spellId] then
            NS.ResetSweepyDuration(self.activeMap[spellId]);
            return;
        end
    end

    -- Validate subEvent
    local validateSubEvent;
    if spell.trackEvent then
        validateSubEvent = ( subEvent == spell.trackEvent );
    else
        validateSubEvent = ( subEvent == NS.SPELL_CAST_SUCCESS );
    end
    if ( not validateSubEvent ) then return end

    -- Find the icon to use
    if self.icons[spellId] then
        NS.StartSweepyIcon(self.icons[spellId]);
    end
end

local function ProcessUnitSpellCast(self, event, ...)
    local guid = ValidateUnit(self);
    if ( not guid ) then return end

    local unitTarget, _, spellID = ...;
    if ( unitTarget == self.unit ) then
        local spell = spellData[spellID];
        if ( not spell ) or ( spell.trackEvent ~= NS.UNIT_SPELLCAST_SUCCEEDED ) then return end
        if self.icons[spellID] then
            NS.StartSweepyIcon(self.icons[spellID]);
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
                NS.RefreshSweepyDuration(self.activeMap[spellID]);
            end
        end
    end
end

local function ProcessUnitEvent(group, event, ...)
    if ( event == NS.UNIT_SPELLCAST_SUCCEEDED ) then
        ProcessUnitSpellCast(group, event, ...);
    elseif ( event == NS.UNIT_AURA ) then
        ProcessUnitAura(group, event, ...);
    end
end

-- Premake all icons (regardless of class)
local premadeIcons = {};
function SweepyBoop:PremakeOffensiveIcons()
    if ( not self.db.profile.arenaEnemyOffensivesEnabled ) then return end

    local iconSize = self.db.profile.arenaEnemyOffensiveIconSize;
    if test then
        local unitId = "player";
        premadeIcons[unitId] = {};
        for spellID, spell in pairs(spellData) do
            premadeIcons[unitId][spellID] = NS.CreateSweepyIcon(unitId, spellID, iconSize, true);
        end
    else
        for i = 1, NS.MAX_ARENA_SIZE do
            local unitId = "arena"..i;
            premadeIcons[unitId] = {};
            for spellID, spell in pairs(spellData) do
                premadeIcons[unitId][spellID] = NS.CreateSweepyIcon(unitId, spellID, iconSize, true);
            end
        end
    end
end

NS.GetUnitSpec = function(unit)
    if ( unit == "player" ) then
        local currentSpec = GetSpecialization();
        if currentSpec then
            return GetSpecializationInfo(currentSpec);
        end
    else
        local arenaIndex = string.sub(unit, -1, -1);
        return GetArenaOpponentSpec(arenaIndex);
    end
end

local function SetupAuraGroup(group, unit, testIcons)
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
                local spec = NS.GetUnitSpec(unit);

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
                if testIcons then
                    NS.IconGroup_PopulateIcon(group, testIcons[unit][spellID], spellID);
                else
                    NS.IconGroup_PopulateIcon(group, premadeIcons[unit][spellID], spellID);
                end
                --print("Populated", unit, spell.class, spellID)
            end
        end
    end
end

-- Populate icons based on class & spec on login
local testGroup = nil;
local arenaGroup = {};
local refreshFrame;
local growOptions = {
    direction = "RIGHT",
    anchor = "LEFT",
    margin = 3,
};

local externalTestIcons = {}; -- Premake icons for "Toggle Test Mode"
local externalTestGroup; -- Icon group for "Toggle Test Mode"

local function RefreshTestMode()
    NS.IconGroup_Wipe(externalTestGroup);

    local iconSize = SweepyBoop.db.profile.arenaEnemyOffensiveIconSize;
    local unitId = "player";
    if externalTestIcons[unitId] then
        local scale = iconSize / NS.DEFAULT_ICON_SIZE;
        for _, icon in pairs(externalTestIcons[unitId]) do
            icon:SetScale(scale);
        end
    else
        externalTestIcons[unitId] = {};
        for spellID, spell in pairs(spellData) do
            externalTestIcons[unitId][spellID] = NS.CreateSweepyIcon(unitId, spellID, iconSize, true);
        end
    end

    local relativeTo = ( Gladius and "GladiusButtonFramearena1" )  or ( sArena and "sArenaEnemyFrame1" ) or "NONE";
    local setPointOptions = {
        point = "LEFT",
        relativeTo = relativeTo,
        relativePoint = "RIGHT",
        offsetY = 0,
    };

    externalTestGroup = NS.CreateIconGroup(setPointOptions, growOptions, unitId);
    SetupAuraGroup(externalTestGroup, unitId, externalTestIcons);
end

function SweepyBoop:PopulateOffensiveIcons()
    if ( not self.db.profile.arenaEnemyOffensivesEnabled ) then return end

    local setPointOptions = {};
    local prefix = ( Gladius and "GladiusButtonFramearena" )  or ( sArena and "sArenaEnemyFrame" ) or "NONE";
    for i = 1, NS.MAX_ARENA_SIZE do
        setPointOptions[i] = {
            point = "LEFT",
            relativeTo = prefix .. i,
            relativePoint = "RIGHT",
            offsetY = 0,
        };
    end

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
    refreshFrame = CreateFrame("Frame");
    refreshFrame:RegisterEvent(NS.PLAYER_ENTERING_WORLD);
    refreshFrame:RegisterEvent(NS.ARENA_PREP_OPPONENT_SPECIALIZATIONS);
    refreshFrame:RegisterEvent(NS.PLAYER_SPECIALIZATION_CHANGED);
    refreshFrame:RegisterEvent(NS.COMBAT_LOG_EVENT_UNFILTERED);
    refreshFrame:RegisterEvent(NS.UNIT_AURA);
    refreshFrame:RegisterEvent(NS.UNIT_SPELLCAST_SUCCEEDED);
    refreshFrame:SetScript("OnEvent", function (frame, event, ...)
        if ( event == NS.PLAYER_ENTERING_WORLD ) or ( event == NS.ARENA_PREP_OPPONENT_SPECIALIZATIONS ) or ( event == NS.PLAYER_SPECIALIZATION_CHANGED and test ) then
            -- Internal test mode is disabled, but the player might have pressed "Toggle Test Mode"
            NS.IconGroup_Wipe(externalTestGroup);

            if test then
                SetupAuraGroup(testGroup, "player");
            elseif ( event ~= NS.PLAYER_SPECIALIZATION_CHANGED ) then -- This event is only for test mode
                for i = 1, NS.MAX_ARENA_SIZE do
                    SetupAuraGroup(arenaGroup[i], "arena"..i);
                end
            end
        elseif ( event == NS.COMBAT_LOG_EVENT_UNFILTERED ) then
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
end

function SweepyBoop:TestArenaEnemyBurst()
    if ( not SweepyBoop.db.profile.arenaEnemyOffensivesEnabled ) then
        -- Module disabled, simply hide test icons
        NS.IconGroup_Wipe(externalTestGroup);
        externalTestGroup:Hide();
        return;
    end

    local shoudShow = ( not externalTestGroup ) or ( not externalTestGroup:IsShown() );

    RefreshTestMode();

    local event = NS.COMBAT_LOG_EVENT_UNFILTERED;
    local subEvent = NS.SPELL_AURA_APPLIED;
    local sourceGUID = UnitGUID("player");
    local destGUID = UnitGUID("player");
    local spellId = 10060; -- Power Infusion
    ProcessCombatLogEvent(externalTestGroup, event, subEvent, sourceGUID, destGUID, spellId);

    spellId = 208963; -- Skyfury
    ProcessCombatLogEvent(externalTestGroup, event, subEvent, sourceGUID, destGUID, spellId);

    if shoudShow then
        externalTestGroup:Show();
    else
        externalTestGroup:Hide();
    end
end

function SweepyBoop:HideTestArenaEnemyBurst()
    NS.IconGroup_Wipe(externalTestGroup);
    externalTestGroup:Hide();
end
