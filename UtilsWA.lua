local _, NS = ...
local isTestMode = NS.isTestMode;

-- Import spell data
local CC = NS.spellCategory.CC;
local OFFENSIVE = NS.spellCategory.OFFENSIVE;
local OFFENSIVE_AURA = NS.spellCategory.OFFENSIVE_AURA;
local OFFENSIVE_CD = NS.spellCategory.OFFENSIVE_CD;
local INTERRUPT = NS.spellCategory.INTERRUPT;
local DISPEL = NS.spellCategory.DISPEL;
local DEFENSIVE = NS.spellCategory.DEFENSIVE;

local TRACK_UNIT = NS.trackType.TRACK_UNIT;

local spellData = NS.spellData;

local spellResets = NS.spellResets;

local baselineSpells = NS.baselineSpells;

BoopUtilsWA = {};
-- Expose certain special constants, such as HOJ/Combustion spellData
BoopUtilsWA.Constants = {};
BoopUtilsWA.Triggers = {};

-- With the following helper functions, we can use the same set of events for almost every single trigger:
-- PLAYER_ENTERING_WORLD,ARENA_PREP_OPPONENT_SPECIALIZATIONS, UNIT_SPELLCAST_SUCCEEDED, COMBAT_LOG_EVENT_UNFILTERED

local function shouldClearAllStates(event)
    return (event == NS.PLAYER_ENTERING_WORLD) or (event == NS.ARENA_PREP_OPPONENT_SPECIALIZATIONS);
end

local function shouldCheckCombatLog(subEvent)
    return (subEvent == NS.SPELL_CAST_SUCCESS) 
        or (subEvent == NS.SPELL_AURA_APPLIED) 
        or (subEvent == NS.SPELL_AURA_APPLIED_FADE) 
        or (subEvent == NS.SPELL_DAMAGE) 
        or (subEvent == NS.SPELL_CAST_START);
end

-- For each spell, trigger 1 = cooldown if we're tracking it; trigger 2 = duration or short 0.5 glow on activation
-- If we use allstates and trigger 2 lives longer than trigger 1, the positioning gets messed up often (guess it jumps around when the aura state changes)
-- With trigger 1 longer, trigger 1 will always be priority and the aura state won't change

local function clearAllStates(allstates)
    for _, state in pairs(allstates) do
        state.show = false;
        state.changed = true;
    end

    return true
end

-- duration can mean different things for different trigger types, e.g.,
-- OFFENSIVE_AURA = spell.duration, CC = spell.cooldown
-- optional params: charges, unit (for finding the raid/arena frame to attach to)
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
        index = spellData.index or NS.defaultIndex,
        stacks = charges,
        unit = unit,
        autoHide = true,
    };

    return state;
end

-- Checck whether spell is enabled for combat log events
local function checkSpellEnabled(spell, subEvent, sourceGUID)
    -- First check if spell is disabled for current spec
    if spell.spec and NS.isSourceArena(sourceGUID) then
        local specEnabled = false;
        
        local spec = NS.arenaSpec(sourceGUID);
        local specs = spell.spec;
        for i = 1, #specs do
            if (spec == specs[i]) then
                specEnabled = true;
            end
        end

        if (not specEnabled) then return end
    end

    local track = false;
    -- Check (event && sourceGUID) based on spell tracking type
    local trackType = spell.trackType;
    if (trackType == NS.trackType.TRACK_AURA_FADE) and (subEvent == NS.SPELL_AURA_REMOVED) then
        track = NS.isSourceArena(sourceGUID);
    elseif (trackType == NS.trackType.TRACK_AURA) and (subEvent == NS.SPELL_AURA_APPLIED) then
        track = NS.isSourceArena(sourceGUID);
    elseif (trackType == NS.trackType.TRACK_PET) and (subEvent == NS.SPELL_CAST_SUCCESS) then
        track = NS.isSourceArenaPet(sourceGUID);
    elseif (trackType == NS.trackType.TRACK_PET_AURA) and (subEvent == NS.SPELL_AURA_APPLIED) then
        track = NS.isSourceArenaPet(sourceGUID);
    elseif (not trackType) and (subEvent == NS.SPELL_CAST_SUCCESS) then
        -- if trackType is missing, it tracks SPELL_CAST_SUCCESS by default
        track = NS.isSourceArena(sourceGUID);
    end

    return track;
end

-- Check whether spell is enabled for UNIT_SPELLCAST_ events
local function unitSpellEnabled(spell, unitId)
    -- First check if spell is disabled for current spec
    if spell.spec then
        local specEnabled = false;

        local spec = NS.arenaUnitSpec(unitId);
        local specs = spell.spec;
        for i = 1, #specs do
            if (spec == specs[i]) then
                specEnabled = true;
            end
        end

        if (not specEnabled) then return end
    end

    -- Check if opponent is arena
    return NS.isUnitArena(unitId);
end

local function concatGUID(unitGUID, spellID)
    return unitGUID .. "-" .. spellID;
end

local function checkResetSpell(allstates, sourceGUID, resetSpells)
    local stateChanged = false;

    for resetSpellID, amount in pairs(resetSpells) do
        local guid = concatGUID(sourceGUID, resetSpellID);
        local state = allstates[guid];
        if state then
            -- Hide if full reset, or after the reduction the cooldown gets reset
            if (amount == NS.RESET_FULL) then
                state.show = false;
            else
                state.expirationTime = state.expirationTime - amount;
            end

            state.changed = true;
            stateChanged = true;
        end
    end

    return stateChanged;
end

-- Check spell cooldown options, including charges and opt_lower_cooldown, and update allstates
-- guid: sourceGUID-spellID
-- Return value: whether state changed
local function checkCooldownOptions(allstates, guid, spell, spellID, unitTarget)
    -- Spell used again within cooldown timer
    -- If charge is enabled, put the 2nd charge on cooldown
    if allstates[guid] then
        local state = allstates[guid];
        -- Spell has baseline charge, put the charge on cooldown and update available stacks to 0
        if spell.opt_charges and spell.opt_lower_cooldown then
            -- e.g., Double Time
            NS.setArenaOptLowerCooldown(guid, true);
            NS.setArenaSpellChargeExpire(guid, GetTime() + spell.cooldown);
            state.stacks = 0;
            state.changed = true;
            return true;
        elseif spell.charges or spell.opt_charges then
            NS.setArenaSpellChargeExpire(guid, GetTime() + spell.cooldown);
            state.stacks = 0;
            state.changed = true;
            return true;
        elseif spell.opt_lower_cooldown then
            -- Lower the cooldown of the spell, but do not return yet
            NS.setArenaOptLowerCooldown(guid, true);
        end
    end

    -- Set to 1 if we identified there is still one charge available
    local charges;
    if spell.charges then
        -- When spell has baseline charge, it has available charge if that charge hasn't been used, or has come off cooldown
        local spellChargeExpire = NS.arenaSpellChargeExpire(guid);
        if (not spellChargeExpire) or (GetTime() >= spellChargeExpire) then
            charges = 1;
        end
    elseif spell.opt_charges then
        -- For optional charge spells, the optional charge must have been used once for us to know it exists, so it cannot be null.
        local spellChargeExpire = NS.arenaSpellChargeExpire(guid);
        if spellChargeExpire and (GetTime() >= spellChargeExpire) then
            charges = 1;
        end
    end

    local cooldown = (NS.arenaOptLowerCooldown(guid) and spell.opt_lower_cooldown) or spell.cooldown;
    allstates[guid] = makeTriggerState(spell, spellID, cooldown, charges, unitTarget);
    return true;
end

-- Duration only trigger for a spell category, used for OFFENSIVE_AURA only for now
local durationTrigger = function(category, allstates, event, ...)
    if shouldClearAllStates(event) then
        return clearAllStates(allstates);
    elseif (event == NS.UNIT_SPELLCAST_SUCCEEDED) then
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
    elseif (event == NS.COMBAT_LOG_EVENT_UNFILTERED) then
        local subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellID = select(2, ...);
        if (not shouldCheckCombatLog(subEvent)) then return end
        -- Return if no valid target
        if (not sourceGUID) then return end

        -- Return if no valid spell or spell does not track cooldown
        local spell = spellData[spellID];
        if (not spell) or (spell.category ~= category) or (not spell.duration) then return end

        -- Check if an aura ended early
        if spell.dispellable and (subEvent == NS.SPELL_AURA_APPLIED_FADE) then
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
    if shouldClearAllStates(event) then
        return clearAllStates(allstates);
    elseif (event == NS.UNIT_SPELLCAST_SUCCEEDED) then
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
            local guid = concatGUID(UnitGUID(unitTarget), spellID);
            allstates[guid] = makeTriggerState(spell, spellID, spell.cooldown, nil, unitTarget);
            return true;
        end
    elseif (event == NS.COMBAT_LOG_EVENT_UNFILTERED) then
        local subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellID = select(2, ...);
        if (not shouldCheckCombatLog(subEvent)) then return end
        -- Return if no valid target
        if (not sourceGUID) then return end

        -- Check if this is a reset spell
        local reset = spellResets[spellID];
        if reset and (subEvent == NS.SPELL_CAST_SUCCESS) then
            return checkResetSpell(allstates, sourceGUID, reset);
        end

        -- Return if no valid spell or spell does not track cooldown
        local spell = spellData[spellID];
        if (not spell) or (spell.category ~= category) or (not spell.cooldown) then return end
        if checkSpellEnabled(spell, subEvent, sourceGUID) then
            local guid = concatGUID(sourceGUID, spellID);
            local unit = NS.arenaUnitId(sourceGUID);
            return checkCooldownOptions(allstates, guid, spell, spellID, unit);
        end
    end
end

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

local glowOnActivationDuration = 0.75;
-- Glow on activation (only for spells without duration to get a visual hint, especially when a player uses a 2nd charge)
local function glowOnActivationTrigger(category, allstates, event, ...)
    if shouldClearAllStates(event) then
        return clearAllStates(allstates);
    elseif (event == NS.COMBAT_LOG_EVENT_UNFILTERED) then
        local subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellID = select(2, ...);
        if (not shouldCheckCombatLog(subEvent)) then return end
        -- Return if no valid target
        if (not sourceGUID) then return end

        -- Return if no valid spell or spell does not track cooldown
        local spell = spellData[spellID];
        if (not spell) or (spell.category ~= category) or (not spell.cooldown) then return end

        if checkSpellEnabled(spell, subEvent, sourceGUID) then
            local guid = concatGUID(sourceGUID, spellID);
            allstates[guid] = makeTriggerState(spell, spellID, glowOnActivationDuration);
            return true;
        end
    end
end

BoopUtilsWA.Triggers.GlowOnActivationCC = function(allstates, event, ...)
    return glowOnActivationTrigger(CC, allstates, event, ...);
end

BoopUtilsWA.Triggers.GlowOnActivationInterrupt = function (allstates, event, ...)
    return glowOnActivationTrigger(INTERRUPT, allstates, event, ...);
end

BoopUtilsWA.Constants.SpellData_HOJ = NS.spellData_HOJ;
BoopUtilsWA.Triggers.CooldownHOJ = function(allstates, event, ...)
    if shouldClearAllStates(event) then
        return clearAllStates(allstates);
    elseif (event == NS.COMBAT_LOG_EVENT_UNFILTERED) then
        local subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellID = select(2, ...);
        if (not shouldCheckCombatLog(subEvent)) then return end
        -- Return if no valid target
        if (not sourceGUID) then return end

        local spell = NS.spellData_HOJ;

        -- Check if we should disable the cooldown reduction
        if (spellID == spell.track_cast_start) and (subEvent == NS.SPELL_CAST_START) then
            NS.setArenaDefaultHoJCooldown(sourceGUID, true);
            return;
        elseif (spellID == spell.track_cast_success) and (subEvent == NS.SPELL_CAST_SUCCESS) then
            NS.setArenaDefaultHoJCooldown(sourceGUID, true);
            return;
        end

        -- start HOJ timer
        if (spellID == spell.spellID) then
            if checkSpellEnabled(spell, subEvent, sourceGUID) then
                allstates[sourceGUID] = makeTriggerState(spell, spellID, spell.cooldown);
                return true;
            end
        elseif allstates[sourceGUID] and (subEvent == NS.SPELL_CAST_SUCCESS) then
            -- Found a HOJ timer, check if we should reduce it based on holy power spent.
            local state = allstates[sourceGUID];
            if (not NS.arenaDefaultHoJCooldown(sourceGUID)) then
                local cost = GetSpellPowerCost(spellID);
                if (cost and cost[1] and cost[1].type == spell.powerType) then
                    state.expirationTime = state.expirationTime - cost[1].cost * 2;
                    state.changed = true;
                    return true;
                end
            end
        end
    end
end

BoopUtilsWA.Constants.SpellData_Vendetta = NS.spellData_Vendetta;
BoopUtilsWA.Triggers.CooldownVendetta = function(allstates, event, ...)
    if shouldClearAllStates(event) then
        return clearAllStates(allstates);
    elseif (event == NS.COMBAT_LOG_EVENT_UNFILTERED) then
        local subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellID = select(2, ...);
        if (not shouldCheckCombatLog(subEvent)) then return end
        -- Return if no valid target
        if (not sourceGUID) then return end

        local spell = NS.spellData_Vendetta;

        -- start HOJ timer (instant spells do not trigger cast start)
        if (spellID == spell.spellID) then
            if checkSpellEnabled(spell, subEvent, sourceGUID) then
                allstates[sourceGUID] = makeTriggerState(spell, spell.spellID, spell.cooldown);
                return true;
            end
        elseif allstates[sourceGUID] and (subEvent == NS.SPELL_CAST_SUCCESS) then
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

BoopUtilsWA.Constants.SpellData_Combust = NS.spellData_Combust;
BoopUtilsWA.Triggers.CooldownCombust = function (allstates, event, ...)
    if shouldClearAllStates(event) then
        return clearAllStates(allstates);
    else
        local subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellID, spellName = select(2, ...);
        if (not shouldCheckCombatLog(subEvent)) then return end
        -- Return if no valid target
        if (not sourceGUID) then return end

        local spell = NS.spellData_Combust;

        if (spellID == spell.spellID and checkSpellEnabled(spell, subEvent, sourceGUID)) then
            -- Start cd timer (since this is single spell, just use sourceGUID)
            allstates[sourceGUID] = makeTriggerState(spell, spell.spellID, spell.cooldown);
            return true;
        elseif allstates[sourceGUID] then -- There is a combustion on cooldown, check if we want to reduce it
            local state = allstates[sourceGUID];
            if (subEvent == NS.SPELL_CAST_SUCCESS) then
                local resets = spell.resets;
                if resets[spellID] then
                    state.expirationTime = state.expirationTime - resets[spellID];
                    state.changed = true;
                    return true;
                end
            elseif (subEvent == NS.SPELL_DAMAGE) then
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

-- Glow for duration (or short glow on activation) for a specific spell
-- pass in the special spellData (glow duration = spell.duration or glowOnActivationDuration if that's missing)
BoopUtilsWA.Triggers.GlowForSpell = function(spell, allstates, event, ...)
    if shouldClearAllStates(event) then
        return clearAllStates(allstates);
    elseif (event == NS.COMBAT_LOG_EVENT_UNFILTERED) then
        local subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellID = select(2, ...);
        if (not shouldCheckCombatLog(subEvent)) then return end
        -- Return if no valid target
        if (not sourceGUID) then return end

        -- Check if an aura ended early
        if spell.dispellable and (subEvent == NS.SPELL_AURA_APPLIED_FADE) then
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

-- Track baseline defensives
BoopUtilsWA.Triggers.BaselineCooldown = function(baselineSpellID, allstates, event, ...)
    if shouldClearAllStates(event) then
        return clearAllStates(allstates);
    elseif (event == NS.UNIT_SPELLCAST_SUCCEEDED) then -- Use UNIT_ events since it's easier to find unitId
        local unitTarget, _, spellID = ...;
        if (not unitTarget) then return end

        -- Check if this is a reset spell
        local reset = spellResets[spellID];
        if reset then
            return checkResetSpell(allstates, UnitGUID(unitTarget), reset);
        end

        -- Return if spellIDs do not match
        if (spellID ~= baselineSpellID) then return end

        if NS.isUnitArena(unitTarget) then
            local spell = baselineSpells[spellID];
            if (not spell) then return end

            local guid = concatGUID(UnitGUID(unitTarget), spellID);
            return checkCooldownOptions(allstates, guid, spell, spellID, unitTarget);
        end
    end
end

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

-- Baseline icons are blocking each other
BoopUtilsWA.Triggers.BaselineIcon = function(baselineSpellID, allstates, event, ...)
    if shouldClearAllStates(event) then
        return clearAllStates(allstates);
    elseif (event == NS.UNIT_SPELLCAST_SUCCEEDED) then
        local unitTarget, _, spellID = ...;
        if (not unitTarget) then return end

        if NS.isUnitArena(unitTarget) then
            local spell = baselineSpells[baselineSpellID];
            if (not spell) then return end

            local match;
            if spell.race then
                local raceId = NS.arenaUnitRace(unitTarget);
                match = (raceId == spell.race);
            elseif spell.class then
                local classId = NS.arenaUnitClass(unitTarget);
                match = (classId == spell.class);
            end

            if match then -- class/race matches, show icon if not currently shown
                local guid = concatGUID(UnitGUID(unitTarget), baselineSpellID);
                if (not allstates[guid]) then
                    allstates[guid] = makeIconState(spell, baselineSpellID, unitTarget);
                    return true;
                end
            end
        end
    end
end

local function getOffensiveSpellDataById(spellID)
    if (spellID == NS.spellData_Combust.spellID) then
        return NS.spellData_Combust;
    elseif (spellID == NS.spellData_Vendetta.spellID) then
        return NS.spellData_Vendetta;
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
BoopUtilsWA.Triggers.PartyBurst = function(allstates, event, ...)
    if shouldClearAllStates(event) then
        return clearAllStates(allstates);
    elseif (event == NS.UNIT_SPELLCAST_SUCCEEDED) then
        local unitTarget, _, spellID = ...;
        if (not unitTarget) then return end

        if isUnitParty(unitTarget) then
            local spell = getOffensiveSpellDataById(spellID);
            if (not spell) then return end

            allstates[unitTarget] = makeTriggerState(spell, spellID, spell.duration, nil, unitTarget);
            return true;
        end
    end
end

-- This one only needs to check one event:
-- COMBAT_LOG_EVENT_UNFILTERED:SPELL_AURA_REMOVED
-- trackUnit: player/party
BoopUtilsWA.Triggers.DR = function(category, trackUnit, allstates, event, ...)
    local destGUID, _, _, _, spellID = select(8, ...);
    if (not destGUID) then return end
    if (NS.diminishingReturnSpells[spellID] == category) then
        local partyUnitId = NS.partyUnitId(destGUID);
        if NS.validateUnitForDR(partyUnitId, trackUnit) then
            local durationDR = 15;
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

-- Do not return values, otherwise WAs might block each other.
-- Same when calling this from WA, just call the function, instead of return BoopUtilsWA.AttachToArenaFrameByUnitId
BoopUtilsWA.AttachToArenaFrameByUnitId = function (frames, activeRegions)
    for _, regionData in ipairs(activeRegions) do
        local unitId = regionData.region.state and regionData.region.state.unit
        if (not unitId) then return end
        local frame = NS.findArenaFrameForUnitId(unitId);
        if frame then
            frames[frame] = frames[frame] or {}
            tinsert(frames[frame], regionData)
        end
    end
end

BoopUtilsWA.AttachToRaidFrameByUnitId = function (frames, activeRegions)
    for _, regionData in ipairs(activeRegions) do
        local unitId = regionData.region.state and regionData.region.state.unit
        if (not unitId) then return end
        local frame = NS.findRaidFrameForUnitId(unitId);
        if frame then
            frames[frame] = frames[frame] or {}
            tinsert(frames[frame], regionData) 
        end
    end
end