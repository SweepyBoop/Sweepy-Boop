local _, NS = ...

-- Import spell data
local CC = NS.spellCategory.CC;
local OFFENSIVE = NS.spellCategory.OFFENSIVE;
local OFFENSIVE_AURA = NS.spellCategory.OFFENSIVE_AURA;
local OFFENSIVE_CD = NS.spellCategory.OFFENSIVE_CD;
local INTERRUPT = NS.spellCategory.INTERRUPT;
local DISPEL = NS.spellCategory.DISPEL;
local DEFENSIVE = NS.spellCategory.DEFENSIVE;

local specID = NS.specID;

local TRACK_PET = NS.TRACK_PET;
local TRACK_PET_AURA = NS.TRACK_PET_AURA;
local TRACK_AURA = NS.TRACK_AURA;
local TRACK_AURA_FADE = NS.TRACK_AURA_FADE;
local TRACK_UNIT = NS.TRACK_UNIT;

local spellData = NS.SpellData;

local RESET_FULL = NS.RESET_FULL;
local spellResets = NS.spellResets;

local classId = NS.ClassId;
local raceID = NS.RaceID;
local baselineSpells = NS.BaselineSpells;

local diminishingReturnSpells = NS.diminishingReturnSpells;

-- Only expose the triggers, make everything else local
BoopUtilsWA = {};

-- Expose certain special constants, such as HOJ/Combustion spellData
BoopUtilsWA.Constants = {};
BoopUtilsWA.Triggers = {};

local isTestMode = NS.isTestMode;

-- Event name constants
local EVENT_ENTERWORLD = "PLAYER_ENTERING_WORLD";
local EVENT_ARENA_PREP = "ARENA_PREP_OPPONENT_SPECIALIZATIONS";
local EVENT_UNITCAST = "UNIT_SPELLCAST_SUCCEEDED";
local EVENT_COMBAT = "COMBAT_LOG_EVENT_UNFILTERED";
local EVENT_GROUP_UPDATE = "GROUP_ROSTER_UPDATE";
-- Sub event name constants
local SUBEVENT_CAST = "SPELL_CAST_SUCCESS";
local SUBEVENT_AURA = "SPELL_AURA_APPLIED";
local SUBEVENT_AURA_FADE = "SPELL_AURA_REMOVED";
local SUBEVENT_DMG = "SPELL_DAMAGE";
local SUBEVENT_CAST_START = "SPELL_CAST_START";

-- With the following helper functions, we can use the same set of events for almost every single trigger:
-- PLAYER_ENTERING_WORLD,ARENA_PREP_OPPONENT_SPECIALIZATIONS, UNIT_SPELLCAST_SUCCEEDED, COMBAT_LOG_EVENT_UNFILTERED

local function shouldClearAll(event)
    return (event == EVENT_ENTERWORLD) or (event == EVENT_ARENA_PREP);
end

local function shouldCheckCombatLog(subEvent)
    return (subEvent == SUBEVENT_CAST) or (subEvent == SUBEVENT_AURA) or (subEvent == SUBEVENT_AURA_FADE) or (subEvent == SUBEVENT_DMG) or (subEvent == SUBEVENT_CAST_START);
end

-- For each spell, trigger 1 = cooldown if we're tracking it; trigger 2 = duration or short 0.5 glow on activation
-- If we use allstates and trigger 2 lives longer than trigger 1, the positioning gets messed up often (guess it jumps around when the aura state changes)
-- With trigger 1 longer, trigger 1 will always be prio and the aura state won't change

local arenaInfo = {
    -- Key: unitId (arena1, arena2, arena3), value: sourceGUID
    unitGUID = {},
    -- Key: sourceGUID, value: unitId (needed for spells that do not TRACK_UNIT, but we still need the unitId, e.g., cauterize)
    -- Naturally this should always be available since arenaUnitGUID will always be called first to update this.
    unitId = {},

    -- Only supports arena1/2/3 via GetArenaOpponentSpec
    -- Key: sourceGUID, value: spec ID
    spec = {},

    -- Key: arena unitId (arena1, etc.), value: spec ID
    unitSpec = {},
    -- UnitId to class/race mapping
    unitClass = {},
    unitRace = {},

    -- Key: sourceGUID-spellID, value: expirationTime of the (optional) 2nd charge
    -- It's a bit too complex to track 3 charges, and abilities like so are often regular rotation spells that are not worth tracking.
    spellChargeExpire = {},
    -- Key: sourceGUID-spellID, value: whether lower cooldown has been enabled
    optLowerCooldown = {},
    -- Key: sourceGUID, value: whether this unit is playing default HOJ (without cd reduction)
    defaultHoJCooldown = {},
};

local arenaOpponentFrame = CreateFrame('Frame');
arenaOpponentFrame:RegisterEvent(EVENT_ENTERWORLD);
arenaOpponentFrame:RegisterEvent(EVENT_ARENA_PREP);
arenaOpponentFrame:SetScript("OnEvent", function ()
    arenaInfo.unitGUID = {};
    arenaInfo.unitId = {};
    arenaInfo.spec = {};
    arenaInfo.unitSpec = {};
    arenaInfo.unitClass = {};
    arenaInfo.unitRace = {};
    arenaInfo.spellChargeExpire = {};
    arenaInfo.optLowerCooldown = {};
    arenaInfo.defaultHoJCooldown = {};
end);

-- Make sure you only check "arena"..i unitIds in the following helper functions
local function updateArenaInfo(sourceGUID, unitId, index)
    if unitId and (not arenaInfo.unitGUID[unitId]) then
        arenaInfo.unitGUID[unitId] = sourceGUID or UnitGUID(unitId);
    end

    if sourceGUID and (not arenaInfo.unitId[sourceGUID]) then
        arenaInfo.unitId[sourceGUID] = unitId;
    end

    if index and (not arenaInfo.spec[index]) and sourceGUID then
        arenaInfo.spec[sourceGUID] = GetArenaOpponentSpec(index);
    end

    if index and unitId and (not arenaInfo.unitSpec[unitId]) then
        arenaInfo.unitSpec[unitId] = GetArenaOpponentSpec(index);
    end

    if unitId and (not arenaInfo.unitClass[unitId]) then
        arenaInfo.unitClass[unitId] = select(3, UnitClass(unitId));
    end

    if unitId and (not arenaInfo.unitRace[unitId]) then
        arenaInfo.unitRace[unitId] = select(3, UnitRace(unitId));
    end
end

local function updatePlayerInfo()
    local unitId = "player";
    local sourceGUID = UnitGUID(unitId);
    local currentSpec = GetSpecialization();
    local specId = GetSpecializationInfo(currentSpec);

    arenaInfo.unitGUID[unitId] = sourceGUID;
    arenaInfo.unitId[sourceGUID] = unitId;

    arenaInfo.spec[sourceGUID] = specId;
    arenaInfo.unitSpec[unitId] = specId;
    arenaInfo.unitClass[unitId] = select(3, UnitClass(unitId));
    arenaInfo.unitRace[unitId] = select(3, UnitRace(unitId));
end

local function arenaUnitGUID(unitId, index)
    if (not arenaInfo.unitGUID[unitId]) and UnitExists(unitId) then
        local guid = UnitGUID(unitId);
        updateArenaInfo(guid, unitId, index);
    end

    return arenaInfo.unitGUID[unitId];
end

-- Call after ensuring unit is arena
local function unitClass(unitId)
    updateArenaInfo(nil, unitId);
    return arenaInfo.unitClass[unitId];
end

-- Call after ensuring unit is arena
local function unitRace(unitId)
    updateArenaInfo(nil, unitId);
    return arenaInfo.unitRace[unitId];
end

local MAX_ARENAOPPONENT_SIZE = 3;
local MAX_PARTY_SIZE = 10;

-- Caller ensures unitId / sourceGUID is not nil
local function isUnitArena(unitId)
    if isTestMode and unitId == "player" then
        updatePlayerInfo();
        return true;
    end

    for i = 1, MAX_ARENAOPPONENT_SIZE do
        if (unitId == "arena"..i) then
            updateArenaInfo(nil, unitId, i);
            return true;
        end
    end
end

local function isSourceArena(sourceGUID)
    if isTestMode and (sourceGUID == UnitGUID("player")) then
        updatePlayerInfo();
        return true;
    end

    for i = 1, MAX_ARENAOPPONENT_SIZE do
        if (sourceGUID == arenaUnitGUID("arena"..i, i)) then
            return true;
        end
    end
end

-- For arena pets we cannot reliably cache the GUIDs, since pets can die and players can summon a different pet.
-- This is only checked for TRACK_PET_AURA spells which is rare.
local function isSourceArenaPet(sourceGUID)
    if isTestMode then return true end

    for i = 1, MAX_ARENAOPPONENT_SIZE do
        if (sourceGUID == UnitGUID("arenapet"..i)) then
            return true;
        end
    end
end

local defaultIndex = 100;

local function clearAllStates(allstates)
    for _, state in pairs(allstates) do
        state.show = false;
        state.changed = true;
    end

    return true
end

-- duration can mean different things for different trigger types, e.g.,
-- OFFENSIVE_AURA = spell.duration, CC = spell.cooldown
-- optional params: charges
local function makeTriggerState(spellData, spellID, duration, ...)
    local charges, unit = ...;
    local state = {
        show = true,
        changed = true,
        progressType = "timed",
        duration = duration,
        expirationTime = GetTime() + duration,
        icon = select(3, GetSpellInfo(spellID)),
        sound = spellData.sound,
        index = spellData.index or defaultIndex,
        stacks = charges,
        unit = unit,
        autoHide = true,
    };

    return state;
end

-- Checck whether spell is enabled for combat log events
local function checkSpellEnabled(spell, subEvent, sourceGUID)
    -- First check if spell is disabled for current spec
    if spell.spec then
        local specEnabled = false;

        local specs = spell.spec;
        for i = 1, #specs do
            if (arenaInfo.spec[sourceGUID] == specs[i]) then
                specEnabled = true;
            end
        end

        if (not specEnabled) then return end
    end

    local track = false;
    -- Check (event && sourceGUID) based on spell tracking type
    local trackType = spell.trackType;
    if (trackType == TRACK_AURA_FADE) and (subEvent == SUBEVENT_AURA_FADE) then
        track = isSourceArena(sourceGUID);
    elseif (trackType == TRACK_AURA) and (subEvent == SUBEVENT_AURA) then
        track = isSourceArena(sourceGUID);
    elseif (trackType == TRACK_PET) and (subEvent == SUBEVENT_CAST) then
        track = isSourceArenaPet(sourceGUID);
    elseif (trackType == TRACK_PET_AURA) and (subEvent == SUBEVENT_AURA) then
        track = isSourceArenaPet(sourceGUID);
    elseif (not trackType) and (subEvent == SUBEVENT_CAST) then
        -- if trackType is missing, it tracks SPELL_CAST_SUCCESS by default
        track = isSourceArena(sourceGUID);
    end

    return track;
end

-- Check whether spell is enabled for UNIT_SPELLCAST_ events
local function unitSpellEnabled(spell, unitId)
    -- First check if spell is disabled for current spec
    if spell.spec then
        local specEnabled = false;

        local specs = spell.spec;
        for i = 1, #specs do
            if (arenaInfo.unitSpec[unitId] == specs[i]) then
                specEnabled = true;
            end
        end

        if (not specEnabled) then return end
    end

    -- Check if opponent is arena
    return isUnitArena(unitId);
end

local function checkResetSpell(allstates, sourceGUID, resetSpells)
    local stateChanged = false;

    for resetSpellID, amount in pairs(resetSpells) do
        local guid = sourceGUID.."-"..resetSpellID;
        local state = allstates[guid];
        if state then
            -- Hide if full reset, or after the reduction the cooldown gets reset
            if (amount == RESET_FULL) then
                state.show = false;
                state.changed = true;
                stateChanged = true;
            else
                state.expirationTime = state.expirationTime - amount;
                state.changed = true;
                stateChanged = true;
            end
        end
    end

    return stateChanged;
end

-- Check spell cooldown options, including charges and opt_lower_cooldown, and update allstates
-- guid: sourceGUID-spellID
-- Return value: whether state changed, remaining charges
local function checkCooldownOptions(allstates, guid, spell, spellID, unitTarget)
    -- Spell used again within cooldown timer (allstates[guid] not nil could be a glow timer that's not showing cooldown)
    -- If charge is enabled, put the 2nd charge on cooldown
    if allstates[guid] then
        local state = allstates[guid];
        -- Spell has baseline charge, put the charge on cooldown and update available stacks to 0
        if spell.opt_charges and spell.opt_lower_cooldown then
            -- e.g., Double Time
            arenaInfo.optLowerCooldown[guid] = true;
            arenaInfo.spellChargeExpire[guid] = GetTime() + spell.cooldown;
            state.stacks = 0;
            state.changed = true;
            return true;
        elseif spell.charges or spell.opt_charges then
            arenaInfo.spellChargeExpire[guid] = GetTime() + spell.cooldown;
            state.stacks = 0;
            state.changed = true;
            return true;
        elseif spell.opt_lower_cooldown then
            -- Lower the cooldown of the spell, but do not return yet
            arenaInfo.optLowerCooldown[guid] = true;
        end
    end

    -- Set to 1 if we identified there is still one charge available
    local charges;
    if spell.charges then
        -- When spell has baseline charge, it has available charge if that charge hasn't been used, or has come back
        if (not arenaInfo.spellChargeExpire[guid]) or (GetTime() >= arenaInfo.spellChargeExpire[guid]) then
            charges = 1;
        end
    elseif spell.opt_charges then
        -- For optional charge spells, the optional charge must have been used once for us to know it exists.
        if arenaInfo.spellChargeExpire[guid] and (GetTime() >= arenaInfo.spellChargeExpire[guid]) then
            charges = 1;
        end
    end

    local cooldown = (arenaInfo.optLowerCooldown[guid] and spell.opt_lower_cooldown) or spell.cooldown;
    allstates[guid] = makeTriggerState(spell, spellID, cooldown, charges, unitTarget);
    return true;
end

if isTestMode then
    -- Test
    -- Regrowth
    spellData[8936] = {
        category = OFFENSIVE,
        duration = 8,
        cooldown = 120,
        sound = true,
        opt_charges = true,
    };
    -- Rejuv
    spellData[774] = {
        category = OFFENSIVE,
        duration = 8,
        cooldown = 30,
        sound = true;
        charges = true,
    };
end

-- Duration only trigger for a spell category, used for OFFENSIVE_AURA only for now
local durationTrigger = function(category, allstates, event, ...)
    if shouldClearAll(event) then
        return clearAllStates(allstates);
    elseif (event == EVENT_UNITCAST) then
        local unitTarget, _, spellID = ...;
        if (not unitTarget) then return end
        local spell = spellData[spellID];
        if (not spell) or (spell.trackType ~= TRACK_UNIT) or (spell.category ~= category) or (not spell.duration) then return end

        if unitSpellEnabled(spell, unitTarget) then
            local guid = UnitGUID(unitTarget).."-"..spellID;
            local duration = spell.duration;
            allstates[guid] = makeTriggerState(spell, spellID, spell.duration);
            return true;
        end
    elseif (event == EVENT_COMBAT) then
        local subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellID = select(2, ...);
        if (not shouldCheckCombatLog(subEvent)) then return end
        -- Return if no valid target
        if (not sourceGUID) then return end

        -- Return if no valid spell or spell does not track cooldown
        local spell = spellData[spellID];
        if (not spell) or (spell.category ~= category) or (not spell.duration) then return end

        -- Check if an aura ended early
        if spell.dispellable and (subEvent == SUBEVENT_AURA_FADE) then
            local guid = sourceGUID .. "-" .. spellID;
            if allstates[guid] then
                local state = allstates[guid];
                state.show = false;
                state.changed = true;
                return true;
            end
        end

        if checkSpellEnabled(spell, subEvent, sourceGUID) then
            local guid = sourceGUID.."-"..spellID;
            local duration = spell.duration;
            allstates[guid] = makeTriggerState(spell, spellID, spell.duration);
            return true;
        end
    end
end

BoopUtilsWA.Triggers.OffensiveGlow = function(allstates, event, ...)
    return durationTrigger(OFFENSIVE_AURA, allstates, event, ...);
end

BoopUtilsWA.Triggers.OffensiveDuration = function (allstates, event, ...)
    return durationTrigger(OFFENSIVE, allstates, event, ...);
end

-- Cooldown trigger for a spell category, used for anything that needs cooldown tracking
local function cooldownTrigger(category, allstates, event, ...)
    if shouldClearAll(event) then
        return clearAllStates(allstates);
    elseif (event == EVENT_UNITCAST) then
        local unitTarget, _, spellID = ...;
        if (not unitTarget) then return end

        -- Check if this is a reset spell
        local reset = spellResets[spellID];
        if reset and checkResetSpell(allstates, UnitGUID(unitTarget), reset) then
            return true;
        end

        -- Return if no valid spell
        local spell = spellData[spellID];
        -- Defensive spells are automatically attached track_unit tag.
        if (not spell) or (spell.trackType ~= TRACK_UNIT) or (spell.category ~= category) or (not spell.cooldown) then return end

        if unitSpellEnabled(spell, unitTarget) then
            local guid = UnitGUID(unitTarget).."-"..spellID;
            allstates[guid] = makeTriggerState(spell, spellID, spell.cooldown, nil, unitTarget);
            return true;
        end
    elseif (event == EVENT_COMBAT) then
        local subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellID = select(2, ...);
        if (not shouldCheckCombatLog(subEvent)) then return end
        -- Return if no valid target
        if (not sourceGUID) then return end

        -- Check if this is a reset spell
        local reset = spellResets[spellID];
        if reset and (subEvent == SUBEVENT_CAST) and checkResetSpell(allstates, sourceGUID, reset) then
            return true;
        end

        -- Return if no valid spell or spell does not track cooldown
        local spell = spellData[spellID];
        if (not spell) or (spell.category ~= category) or (not spell.cooldown) then return end
        if checkSpellEnabled(spell, subEvent, sourceGUID) then
            local guid = sourceGUID.."-"..spellID;
            local unit = arenaInfo.unitId[sourceGUID];
            return checkCooldownOptions(allstates, guid, spell, spellID, unit);
        end
    end
end

-- CC is not showing in arena, other categories are; it's also showing with test mode on
BoopUtilsWA.Triggers.CooldownCC = function(allstates, event, ...)
    return cooldownTrigger(CC, allstates, event, ...);
end

BoopUtilsWA.Triggers.CooldownDefensive = function(allstates, event, ...)
    return cooldownTrigger(DEFENSIVE, allstates, event, ...);
end

BoopUtilsWA.Triggers.CooldownOffensive = function(allstates, event, ...)
    return cooldownTrigger(OFFENSIVE, allstates, event, ...);
end

BoopUtilsWA.Triggers.CooldownOffensiveCD = function (allstates, event, ...)
    return cooldownTrigger(OFFENSIVE_CD, allstates, event, ...)
end

BoopUtilsWA.Triggers.CooldownInterrupt = function (allstates, event, ...)
    return cooldownTrigger(INTERRUPT, allstates, event, ...)
end

BoopUtilsWA.Triggers.CooldownDispel = function (allstates, event, ...)
    return cooldownTrigger(DISPEL, allstates, event, ...)
end

local glowOnActivationDuration = 0.5;
-- Glow on activation (only for spells without duration)
local function glowOnActivationTrigger(category, allstates, event, ...)
    if shouldClearAll(event) then
        return clearAllStates(allstates);
    elseif (event == EVENT_COMBAT) then
        local subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellID = select(2, ...);
        if (not shouldCheckCombatLog(subEvent)) then return end
        -- Return if no valid target
        if (not sourceGUID) then return end

        -- Return if no valid spell or spell does not track cooldown
        local spell = spellData[spellID];
        if (not spell) or (spell.category ~= category) or (not spell.cooldown) then return end

        if checkSpellEnabled(spell, subEvent, sourceGUID) then
            local guid = sourceGUID.."-"..spellID;
            allstates[guid] = makeTriggerState(spell, spellID, glowOnActivationDuration);
            return true;
        end
    end
end

BoopUtilsWA.Triggers.CCGlowOnActivation = function(allstates, event, ...)
    return glowOnActivationTrigger(CC, allstates, event, ...);
end

BoopUtilsWA.Triggers.InterruptGlowOnActivation = function (allstates, event, ...)
    return glowOnActivationTrigger(INTERRUPT, allstates, event, ...);
end

-- Cooldown trigger specially made for HOJ, for glow trigger we can use the common one
-- Cooldown is reduced by spending holy power
local spellData_HOJ = {
    spellID = 853,
    cooldown = 60,
    powerType = Enum.PowerType.HolyPower,

    -- Spells that disable the cooldown reduction
    track_cast_start = 20066,
    track_cast_success = 115750,
};
BoopUtilsWA.Constants.SpellData_HOJ = spellData_HOJ;
BoopUtilsWA.Triggers.CooldownHOJ = function(allstates, event, ...)
    if shouldClearAll(event) then
        return clearAllStates(allstates);
    elseif (event == EVENT_COMBAT) then
        local subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellID = select(2, ...);
        if (not shouldCheckCombatLog(subEvent)) then return end
        -- Return if no valid target
        if (not sourceGUID) then return end

        local spell = spellData_HOJ;

        -- Check if we should disable the cooldown reduction
        if (spellID == spell.track_cast_start) and (subEvent == SUBEVENT_CAST_START) then
            arenaInfo.defaultHoJCooldown[sourceGUID] = true;
            return;
        elseif (spellID == spell.track_cast_success) and (subEvent == SUBEVENT_CAST) then
            arenaInfo.defaultHoJCooldown[sourceGUID] = true;
            return;
        end

        -- start HOJ timer (instant spells do not trigger cast start)
        if (spellID == spell.spellID) then
            if checkSpellEnabled(spell, subEvent, sourceGUID) then
                allstates[sourceGUID] = makeTriggerState(spell, spellID, spell.cooldown);
                return true;
            end
        elseif allstates[sourceGUID] and (subEvent == SUBEVENT_CAST) then
            local state = allstates[sourceGUID];
            if (not arenaInfo.defaultHoJCooldown[sourceGUID]) then
                local cost = GetSpellPowerCost(spellID);
                if (cost and cost[1] and cost[1].type == spell.powerType and cost[1].cost > 0) then
                    state.expirationTime = state.expirationTime - cost[1].cost * 2;
                    state.changed = true;
                    return true;
                end
            end
        end
    end
end

-- Cooldown trigger specially made for vendetta, for glow trigger we can use the common one
-- Cooldown is reduced by spending holy power
local spellData_Vendetta = {
    spellID = 79140,
    duration = 20,
    cooldown = 120,
    index = 1,
    sound = true,
    powerType = Enum.PowerType.Energy,
};
BoopUtilsWA.Constants.SpellData_Vendetta = spellData_Vendetta;
BoopUtilsWA.Triggers.CooldownVendetta = function(allstates, event, ...)
    if shouldClearAll(event) then
        return clearAllStates(allstates);
    elseif (event == EVENT_COMBAT) then
        local subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellID = select(2, ...);
        if (not shouldCheckCombatLog(subEvent)) then return end
        -- Return if no valid target
        if (not sourceGUID) then return end

        local spell = spellData_Vendetta;

        -- start HOJ timer (instant spells do not trigger cast start)
        if (spellID == spell.spellID) then
            if checkSpellEnabled(spell, subEvent, sourceGUID) then
                allstates[sourceGUID] = makeTriggerState(spell, spell.spellID, spell.cooldown);
                return true;
            end
        elseif allstates[sourceGUID] and (subEvent == SUBEVENT_CAST) then
            local state = allstates[sourceGUID];
            local cost = GetSpellPowerCost(spellID);
            if (cost and cost[1] and cost[1].type == spell.powerType) then
                state.expirationTime = state.expirationTime - cost[1].cost / 30;
                state.changed = true;
                return true;
            end
        end
    end
end

-- Cooldown trigger specially made for combustion
local spellData_Combust = {
    spellID = 190319,
    duration = 14,
    cooldown = 120,
    index = 1,
    sound = true,
    dispellable = true,

    resets = {
        [133] = 2, -- Pyrokinesis
        [314791] = 18, -- Shifting Power
    },
    -- Reduce cooldown by 1s (Phoenix Flames spellID somehow does not work)
    critResets = { 133, 11366, 108853, "Phoenix Flames" },
};
BoopUtilsWA.Constants.SpellData_Combust = spellData_Combust;
BoopUtilsWA.Triggers.CooldownCombust = function (allstates, event, ...)
    if shouldClearAll(event) then
        return clearAllStates(allstates);
    else
        local subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellID, spellName = select(2, ...);
        if (not shouldCheckCombatLog(subEvent)) then return end
        -- Return if no valid target
        if (not sourceGUID) then return end

        local spell = spellData_Combust;

        if (spellID == spell.spellID and checkSpellEnabled(spell, subEvent, sourceGUID)) then
            -- Start cd timer (since this is single spell, we can just use sourceGUID)
            allstates[sourceGUID] = makeTriggerState(spell, spell.spellID, spell.cooldown);
            return true;
        elseif allstates[sourceGUID] then -- There is a combustion on cooldown, check if we want to reduce it
            local state = allstates[sourceGUID];
            if (subEvent == SUBEVENT_CAST) then
                local resets = spell.resets;
                if resets[spellID] then
                    state.expirationTime = state.expirationTime - resets[spellID];
                    state.changed = true;
                    return true;
                end
            elseif (subEvent == SUBEVENT_DMG) then
                local critResets = spell.critResets;
                for i = 1, #critResets do
                    if (spellID == critResets[i]) or (spellName == critResets[i]) then
                        local crit = select(21, ...);
                        if crit then
                            state.expirationTime = state.expirationTime - 1;
                            state.changed = true;
                            return true;
                        end
                    end
                end
            end
        end
    end
end

-- Glow on activation for a specific spell, pass in the special spellID (glow duration = spell.duration or glowOnActivationDuration if that's missing)
BoopUtilsWA.Triggers.GlowForSpell = function(spell, allstates, event, ...)
    if shouldClearAll(event) then
        return clearAllStates(allstates);
    elseif (event == EVENT_COMBAT) then
        local subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellID = select(2, ...);
        if (not shouldCheckCombatLog(subEvent)) then return end
        -- Return if no valid target
        if (not sourceGUID) then return end

        -- Check if an aura ended early
        if spell.dispellable and (subEvent == SUBEVENT_AURA_FADE) then
            if allstates[sourceGUID] then
                local state = allstates[sourceGUID];
                state.show = false;
                state.changed = true;
                return true;
            end
        else
            local track = (spellID == spell.spellID) and checkSpellEnabled(spell, subEvent, sourceGUID);
            if track then
                allstates[sourceGUID] = makeTriggerState(spell, spellID, spell.duration or glowOnActivationDuration);
                return true;
            end
        end
    end
end

if isTestMode then
    baselineSpells[774] = {
        class = classId.Druid,
        cooldown = 60,
        opt_charges = true,
        index = 2,
    };
    baselineSpells[8936] = {
        class = classId.Druid,
        cooldown = 60,
        charges = true,
        index = 1,
    }
end

-- Track baseline defensives
local function baselineCooldownTrigger(baselineSpellID, allstates, event, ...)
    if shouldClearAll(event) then
        return clearAllStates(allstates);
    elseif (event == EVENT_UNITCAST) then
        local unitTarget, _, spellID = ...;
        if (not unitTarget) then return end

        -- Check if this is a reset spell
        local reset = spellResets[spellID];
        if reset and checkResetSpell(allstates, UnitGUID(unitTarget), reset) then
            return true;
        end

        -- Return if spellIDs do not match
        if (spellID ~= baselineSpellID) then return end

        if isUnitArena(unitTarget) then
            local spell = baselineSpells[spellID];
            if (not spell) then return end

            local guid = UnitGUID(unitTarget).."-"..spellID;
            return checkCooldownOptions(allstates, guid, spell, spellID, unitTarget);
        end
    end
end
BoopUtilsWA.Triggers.BaselineCooldown = baselineCooldownTrigger;

local function makeIconState(spell, spellID, unitTarget)
    local state = {
        show = true,
        changed = true,
        autoHide = false,
        icon = select(3, GetSpellInfo(spellID)),
        unit = unitTarget,
        index = spell.index,
    };

    return state;
end

local function baselineIconTrigger(baselineSpellID, allstates, event, ...)
    if shouldClearAll(event) then
        return clearAllStates(allstates);
    elseif (event == EVENT_UNITCAST) then
        local unitTarget, _, spellID = ...;
        if (not unitTarget) then return end

        if isUnitArena(unitTarget) then
            local spell = baselineSpells[baselineSpellID]; -- Note: we need to check the baselineSpellID here
            if (not spell) then return end

            local match;
            if spell.race then
                local raceId = unitRace(unitTarget);
                match = (raceId == spell.race);
            elseif spell.class then
                local classId = unitClass(unitTarget);
                match = (classId == spell.class);
            end

            if match then -- class/race matches, show icon if not currently shown
                local guid = UnitGUID(unitTarget) .. "-" .. baselineSpellID;
                if (not allstates[guid]) then
                    allstates[guid] = makeIconState(spell, baselineSpellID, unitTarget);
                    return true;
                end
            end
        end
    end
end
BoopUtilsWA.Triggers.BaselineIcon = baselineIconTrigger;

local function offensiveSpellData(spellID)
    if (spellID == spellData_Combust.spellID) then
        return spellData_Combust;
    elseif (spellID == spellData_Vendetta.spellID) then
        return spellData_Vendetta;
    else
        local spell = spellData[spellID];
        if spell and ((spell.category == OFFENSIVE) or (spell.category == OFFENSIVE_AURA)) then
            return spell;
        end
    end
end

local function isUnitParty(unitId)
    if isTestMode and unitId == "player" then
        return true;
    end

    return (unitId == "party1") or (unitId == "party2");
end

-- Really simple trigger, not checking factors such as trackType, aura being dispelled, etc.
-- Just providing a hint on when party is doing burst
local function partyBurstTrigger(allstates, event, ...)
    if shouldClearAll(event) then
        return clearAllStates(allstates);
    elseif (event == EVENT_UNITCAST) then
        local unitTarget, _, spellID = ...;
        if (not unitTarget) then return end

        if isUnitParty(unitTarget) then
            local spell = offensiveSpellData(spellID);
            if (not spell) then return end

            allstates[unitTarget] = makeTriggerState(spell, spellID, spell.duration, nil, unitTarget);
            return true;
        end
    end
end
BoopUtilsWA.Triggers.PartyBurst = partyBurstTrigger;

local partyInfo = {
    -- Convert between unitGUID and unitID
    unitGUID = {},
    unitId = {},
}

local partyInfoFrame = CreateFrame("Frame");
partyInfoFrame:RegisterEvent(EVENT_ENTERWORLD);
partyInfoFrame:RegisterEvent(EVENT_GROUP_UPDATE);
partyInfoFrame:SetScript("OnEvent", function ()
    partyInfo.unitGUID = {};
    partyInfo.unitId = {};
end);

-- Make sure only player/party1/party2 is passed into this
local function partyUnitGUID(unitId)
    if (not partyInfo.unitGUID[unitId]) then
        partyInfo.unitGUID[unitId] = UnitGUID(unitId);
    end

    return partyInfo.unitGUID[unitId];
end

-- If unitGUID matches player/party1/party2, cache and return the corresponding unitId; otherwise return nil
-- The cached unitId can later be used as "unit" in the TSU
-- Call ensures unitGUID is not nil
local function partyUnitId(unitGUID)
    if (unitGUID == partyUnitGUID("player")) then
        partyInfo.unitId[unitGUID] = "player";
    elseif (unitGUID == partyUnitGUID("party1")) then
        partyInfo.unitId[unitGUID] = "party1";
    elseif (unitGUID == partyUnitGUID("party2")) then
        partyInfo.unitId[unitGUID] = "party2";
    end

    -- If unitGUID does not match the above units, no value should be cached and nil will be returned
    return partyInfo.unitId[unitGUID];
end

local function validateUnitForDR(partyUnitId, trackUnit)
    if (not partyUnitId) then return end
    if (trackUnit == "player") then
        return (partyUnitId == "player")
    elseif (trackUnit == "party") then
        return (partyUnitId ~= "player");
    end
end

local durationDR = 15;

local diminishingReturnCategory = NS.diminishingReturnCategory;

if isTestMode then
    diminishingReturnSpells[33763] = diminishingReturnCategory.DR_DISORIENT; -- Lifebloom
    diminishingReturnSpells[8936] = diminishingReturnCategory.DR_STUN; -- Regrowth
    diminishingReturnSpells[774] = diminishingReturnCategory.DR_INCAPACITATE; -- Rejuvenation
end

-- This one only needs to check one event:
-- COMBAT_LOG_EVENT_UNFILTERED:SPELL_AURA_REMOVED
-- trackUnit: player/party
local function diminishingReturnTrigger(category, trackUnit, allstates, event, ...)
    local destGUID, _, _, _, spellID = select(8, ...);
    if (not destGUID) then return end
    if (diminishingReturnSpells[spellID] == category) then
        local partyUnitId = partyUnitId(destGUID);
        if validateUnitForDR(partyUnitId, trackUnit) then
            local stacksNew = 1 + ((allstates[destGUID] and allstates[destGUID].stacks) or 0);
            allstates[destGUID] = {
                show = true,
                changed = true,
                progressType = "timed",
                duration = durationDR,
                expirationTime = GetTime() + durationDR,
                stacks = stacksNew,
                unit = partyUnitId,
                autoHide = true,
            };
            return true;
        end
    end
end
BoopUtilsWA.Triggers.DR = diminishingReturnTrigger;