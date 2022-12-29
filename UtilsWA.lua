local _, NS = ...
local isTestMode = NS.isTestMode;

-- Import spell data
local OFFENSIVE = NS.spellCategory.OFFENSIVE;
local OFFENSIVE_AURA = NS.spellCategory.OFFENSIVE_AURA;
local OFFENSIVE_CD = NS.spellCategory.OFFENSIVE_CD;
local OFFENSIVE_PET = NS.OFFENSIVE_PET;
local OFFENSIVE_SPECIAL = NS.spellCategory.OFFENSIVE_SPECIAL;
local OFFENSIVE_UNITAURA = NS.spellCategory.OFFENSIVE_UNITAURA;

local TRACK_UNIT = NS.trackType.TRACK_UNIT;

local spellData = NS.spellData;

local spellResets = NS.spellResets;

local baselineSpells = NS.baselineSpells;

BoopUtilsWA = {};
BoopUtilsWA.Triggers = {};

local WA_GetUnitAura = function(unit, spell, filter)
    if filter and not filter:upper():find("FUL") then
        filter = filter.."|HELPFUL"
    end
    for i = 1, 255 do
      local name, _, _, _, _, _, _, _, _, spellId = UnitAura(unit, i, filter)
      if not name then return end
      if spell == spellId or spell == name then
        return UnitAura(unit, i, filter)
      end
    end
end

local WA_GetUnitBuff = function(unit, spell, filter)
    filter = filter and filter.."|HELPFUL" or "HELPFUL"
    return WA_GetUnitAura(unit, spell, filter)
end

local function debugSpellID(sourceGUID, event, spellID)
    if NS.isTestMode and NS.isSourceArena(sourceGUID) and (event == NS.SPELL_CAST_SUCCESS or event == NS.UNIT_SPELLCAST_SUCCEEDED) then
        print(sourceGUID, event, spellID)
    end
end

-- With the following helper functions, we can use the same set of events for almost every single trigger:
-- PLAYER_ENTERING_WORLD,ARENA_PREP_OPPONENT_SPECIALIZATIONS, UNIT_SPELLCAST_SUCCEEDED, COMBAT_LOG_EVENT_UNFILTERED

local function shouldClearAllStates(event)
    return (event == NS.PLAYER_ENTERING_WORLD) or (event == NS.ARENA_PREP_OPPONENT_SPECIALIZATIONS);
end

local function shouldCheckCombatLog(subEvent)
    return (subEvent == NS.SPELL_CAST_SUCCESS)
        or (subEvent == NS.SPELL_AURA_APPLIED)
        or (subEvent == NS.SPELL_AURA_REMOVED)
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

local function unitCanAttack(unitId)
    -- The result is reversed when player is under mind control
    return UnitCanAttack(unitId, "player") and ( not UnitIsPossessed("player") );
end

-- substring of a guid is of string type, need to convert into number so it matches a numeric index
local function getNpcIdFromGuid (guid)
    local NpcId = select ( 6, strsplit ( "-", guid ) )
    if (NpcId) then
        return tonumber ( NpcId )
    end

    return 0
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
    -- Check (event & sourceGUID) based on spell tracking type
    local track = false;
    local trackType = spell.trackType;
    if (trackType == NS.trackType.TRACK_AURA_FADE) and (subEvent == NS.SPELL_AURA_REMOVED) then
        track = NS.isSourceArena(sourceGUID);
    elseif (trackType == NS.trackType.TRACK_AURA) and (subEvent == NS.SPELL_AURA_APPLIED) then
        track = NS.isSourceArena(sourceGUID);
    elseif (spell.category == OFFENSIVE_UNITAURA) and (subEvent == NS.SPELL_AURA_APPLIED) then
        track = NS.isSourceArena(sourceGUID);
    elseif (trackType == NS.trackType.TRACK_PET) and (subEvent == NS.SPELL_CAST_SUCCESS) then
        track = NS.isSourceArenaPet(sourceGUID);
    elseif (trackType == NS.trackType.TRACK_PET_AURA) and (subEvent == NS.SPELL_AURA_APPLIED) then
        track = NS.isSourceArenaPet(sourceGUID);
    elseif (not trackType) and (subEvent == NS.SPELL_CAST_SUCCESS) then
        -- if trackType is missing, it tracks SPELL_CAST_SUCCESS by default
        track = NS.isSourceArena(sourceGUID);
    end

    if (not track) then return end

    -- Check if spell is disabled for current spec
    if spell.spec then
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

    return true;
end

-- Check whether spell is enabled for UNIT_SPELLCAST_ events
local function unitSpellEnabled(spell, unitId)
    -- Check if opponent is arena
    if (not NS.isUnitArena(unitId)) then return end

    -- Check if spell is disabled for current spec
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

    return true;
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
    local now = GetTime();
    -- Check if spell is still on cooldown
    -- Occasionally this is unexpectedly detected due to marginal error of timers (https://github.com/SweepyBoop/aSweepyBoop/issues/7)
    -- To reliably detect whether the spell is on cooldown, allow some error margin, e.g.,
    -- If a spell has 20s cooldown and we press it at time 0, we want to check if he pressed it again before 18.5s (instead of 20)
    local errorMargin = 1.5;
    if allstates[guid] and ( now < allstates[guid].expirationTime - errorMargin ) then
        local state = allstates[guid];
        -- Spell has baseline charge, put the charge on cooldown and update available stacks to 0
        if spell.opt_charges and spell.opt_lower_cooldown then
            -- e.g., Double Time
            NS.setArenaOptLowerCooldown(guid, true);
            NS.setArenaSpellChargeExpire(guid, now + spell.cooldown);
            state.stacks = 0;
            state.changed = true;
            return true;
        elseif spell.charges or spell.opt_charges then
            NS.setArenaSpellChargeExpire(guid, now + spell.cooldown);
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
        if (not spellChargeExpire) or (now >= spellChargeExpire) then
            charges = 1;
        end
    elseif spell.opt_charges then
        -- For optional charge spells, the optional charge must have been used once for us to know it exists, so it cannot be null.
        local spellChargeExpire = NS.arenaSpellChargeExpire(guid);
        if spellChargeExpire and (now >= spellChargeExpire) then
            charges = 1;
        end
    end

    local cooldown = (NS.arenaOptLowerCooldown(guid) and spell.opt_lower_cooldown) or spell.cooldown;
    allstates[guid] = makeTriggerState(spell, spellID, cooldown, charges, unitTarget);
    return true;
end

local durationTrigger = function(category, allstates, event, ...)
    if shouldClearAllStates(event) then
        return clearAllStates(allstates);
    elseif (event == NS.UNIT_SPELLCAST_SUCCEEDED) then
        local unitTarget, _, spellID = ...;
        if (not unitTarget) then return end
        local spell = spellData[spellID];
        if (not spell) or (spell.trackType ~= TRACK_UNIT) or (spell.category ~= category) or (not spell.duration) then return end

        if unitSpellEnabled(spell, unitTarget) then
            local guid = concatGUID(UnitGUID(unitTarget), spellID);
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
        if spell.dispellable and (subEvent == NS.SPELL_AURA_REMOVED) then
            local guid = concatGUID(sourceGUID, spellID);
            if allstates[guid] then
                local state = allstates[guid];
                state.show = false;
                state.changed = true;
                return true;
            end
        end

        if checkSpellEnabled(spell, subEvent, sourceGUID) then
            local guid = concatGUID(sourceGUID, spellID);
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

local function durationWithExtensionTrigger(specialSpellID, allstates, event, ...)
    if shouldClearAllStates(event) then
        return clearAllStates(allstates);
    elseif (event == NS.COMBAT_LOG_EVENT_UNFILTERED) then
        local subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellID = select(2, ...);
        if (not shouldCheckCombatLog(subEvent)) then return end
        if (not sourceGUID) then return end
        local spell = spellData[specialSpellID]

        -- Check if there is a spell to extend
        if (spellID ~= specialSpellID) and allstates[sourceGUID] and subEvent == NS.SPELL_CAST_SUCCESS then
            local cost = GetSpellPowerCost(spellID);
            if (cost and cost[1] and cost[1].type == spell.extend_power_type) then
                if spell.extend_type == "fixed" then
                    allstates[sourceGUID].expirationTime = allstates[sourceGUID].expirationTime + spell.extend_amount;
                else
                    allstates[sourceGUID].expirationTime = allstates[sourceGUID].expirationTime + cost[1].cost * spell.extend_amount;
                end

                return true
            end
        elseif (spellID == specialSpellID) then
            if checkSpellEnabled(spell, subEvent, sourceGUID) then
                allstates[sourceGUID] = makeTriggerState(spell, spellID, spell.duration)
                return true
            end
        end
    end
end

BoopUtilsWA.Triggers.StormEarthAndFire = function (allstates, event, ...)
    return durationWithExtensionTrigger(137639, allstates, event, ...)
end

BoopUtilsWA.Triggers.Serenity = function (allstates, event, ...)
    return durationWithExtensionTrigger(152173, allstates, event, ...)
end

-- Cooldown trigger for a spell category, used for anything that needs cooldown tracking
local function cooldownTrigger(category, allstates, event, ...)
    if shouldClearAllStates(event) then
        return clearAllStates(allstates);
    elseif (event == NS.UNIT_SPELLCAST_SUCCEEDED) then
        local unitTarget, _, spellID = ...;
        if (not unitTarget) then return end

        -- Return if no valid spell
        local spell = spellData[spellID];
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

BoopUtilsWA.Triggers.CooldownOffensive = function(allstates, event, ...)
    return cooldownTrigger(OFFENSIVE, allstates, event, ...);
end

BoopUtilsWA.Triggers.CooldownOffensiveCD = function (allstates, event, ...)
    return cooldownTrigger(OFFENSIVE_CD, allstates, event, ...)
end

-- Generic cooldown reduction, e.g., by spell power cost
local function cooldownWithReductionTrigger(specialSpellID, allstates, event, ...)
    if shouldClearAllStates(event) then
        return clearAllStates(allstates)
    elseif (event == NS.COMBAT_LOG_EVENT_UNFILTERED) then
        local subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellID = select(2, ...);
        if (not shouldCheckCombatLog(subEvent)) then return end
        if (not sourceGUID) then return end

        local spell = spellData[specialSpellID]

        -- Check if there is a current spell to reduce
        if (spellID ~= specialSpellID) and allstates[sourceGUID] and subEvent == NS.SPELL_CAST_SUCCESS then
            local cost = GetSpellPowerCost(spellID)
            if (cost and cost[1] and cost[1].type == spell.reduce_power_type) then
                if spell.reduce_type == "fixed" then
                    allstates[sourceGUID].expirationTime = allstates[sourceGUID].expirationTime - spell.reduce_amount
                else
                    allstates[sourceGUID].expirationTime = allstates[sourceGUID].expirationTime - cost[1].cost * spell.reduce_amount
                end

                return true
            end
        elseif (spellID == specialSpellID) then
            if checkSpellEnabled(spell, subEvent, sourceGUID) then
                local unit = NS.arenaUnitId(sourceGUID)
                return checkCooldownOptions(allstates, sourceGUID, spell, spellID, unit)
            end
        end
    end
end

BoopUtilsWA.Triggers.StormEarthAndFireCD = function (allstates, event, ...)
    return cooldownWithReductionTrigger(137639, allstates, event, ...)
end

BoopUtilsWA.Triggers.SerenityCD = function (allstates, event, ...)
    return cooldownWithReductionTrigger(152173, allstates, event, ...)
end

BoopUtilsWA.Triggers.RecklessnessCD = function (allstates, event, ...)
    return cooldownWithReductionTrigger(1719, allstates, event, ...)
end

local glowOnActivationDuration = 0.75;
-- Glow on activation (only for spells without duration to get a visual hint, especially when a player uses a 2nd charge)
local function glowOnActivationTrigger(category, allstates, event, ...)
    if shouldClearAllStates(event) then
        return clearAllStates(allstates);
    elseif (event == NS.UNIT_SPELLCAST_SUCCEEDED) then
        local unitTarget, _, spellID = ...;
        if (not unitTarget) then return end

        -- Return if no valid spell
        local spell = spellData[spellID];
        if (not spell) or (spell.trackType ~= TRACK_UNIT) or (spell.category ~= category) or (not spell.cooldown) then return end

        if unitSpellEnabled(spell, unitTarget) then
            local guid = concatGUID(UnitGUID(unitTarget), spellID);
            allstates[guid] = makeTriggerState(spell, spellID, glowOnActivationDuration, nil, unitTarget);
            return true;
        end
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

BoopUtilsWA.Triggers.GlowOnActivationOffensiveCD = function (allstates, event, ...)
    return glowOnActivationTrigger(OFFENSIVE_CD, allstates, event, ...);
end

BoopUtilsWA.Triggers.CooldownCombust = function (allstates, event, ...)
    if shouldClearAllStates(event) then
        return clearAllStates(allstates);
    else
        local subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellID, spellName = select(2, ...);
        if (not shouldCheckCombatLog(subEvent)) then return end
        -- Return if no valid target
        if (not sourceGUID) then return end

        local specialSpellID = 190319
        local spell = spellData[specialSpellID];

        if (spellID == specialSpellID and checkSpellEnabled(spell, subEvent, sourceGUID)) then
            -- Start cd timer (since this is single spell, just use sourceGUID)
            allstates[sourceGUID] = makeTriggerState(spell, specialSpellID, spell.cooldown);
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
-- pass in the special special spellID (glow duration = spell.duration or glowOnActivationDuration if that's missing)
local function GlowForSpell (specialSpellID, allstates, event, ...)
    if shouldClearAllStates(event) then
        return clearAllStates(allstates);
    elseif (event == NS.COMBAT_LOG_EVENT_UNFILTERED) then
        local subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellID = select(2, ...);
        -- We only care about this one spellID
        if (spellID ~= specialSpellID) then return end
        if (not shouldCheckCombatLog(subEvent)) then return end
        -- Return if no valid target
        if (not sourceGUID) then return end

        local spell = spellData[specialSpellID]

        -- Check if an aura ended early
        if spell.dispellable and (subEvent == NS.SPELL_AURA_REMOVED) then
            if allstates[sourceGUID] then
                local state = allstates[sourceGUID];
                state.show = false;
                state.changed = true;
                return true;
            end
        elseif checkSpellEnabled(spell, subEvent, sourceGUID) then
                allstates[sourceGUID] = makeTriggerState(spell, spellID, spell.duration or glowOnActivationDuration);
                return true;
        end
    end
end

BoopUtilsWA.Triggers.DurationCombust = function (allstates, event, ...)
    return GlowForSpell(190319, allstates, event, ...)
end

BoopUtilsWA.Triggers.DurationRecklessness = function (allstates, event, ...)
    return GlowForSpell(1719, allstates, event, ...)
end

local function getOffensiveSpellDataById(spellID)
    local spell = spellData[spellID];
    if spell and ((spell.category == OFFENSIVE) or (spell.category == OFFENSIVE_AURA) or (spell.category == OFFENSIVE_SPECIAL)) then
        return spell;
    end
end

local function isUnitParty(unitId)
    if isTestMode and unitId == "player" then
        return true;
    end

    return (unitId == "party1") or (unitId == "party2");
end

-- Really simple trigger, not checking factors such as trackType, aura being dispelled/extended, etc.
-- Just providing a hint on when party is doing burst
BoopUtilsWA.Triggers.PartyBurst = function(allstates, event, ...)
    if shouldClearAllStates(event) then
        return clearAllStates(allstates);
    elseif ( event == NS.UNIT_SPELLCAST_SUCCEEDED ) then
        local unitTarget, _, spellID = ...;
        if ( not unitTarget ) then return end

        if isUnitParty(unitTarget) then
            local spell = getOffensiveSpellDataById(spellID);
            if ( not spell ) then return end

            allstates[unitTarget] = makeTriggerState(spell, spellID, spell.duration, nil, unitTarget);
            return true;
        end
    elseif ( event == NS.COMBAT_LOG_EVENT_UNFILTERED ) then
        local subEvent, _, _, _, _, _, destGUID, _, _, _, spellID = select(2, ...)
        if ( subEvent ~= NS.SPELL_AURA_APPLIED ) or ( not destGUID ) or ( not spellData[spellID] ) then return end
        local spell = spellData[spellID]
        if ( spell.category ~= OFFENSIVE_UNITAURA ) then return end
        if ( not checkSpellEnabled(spell, subEvent, destGUID) ) then return end
        local unitId = NS.arenaUnitId(destGUID)
        if ( not unitId ) then return end
        local duration = select(5, WA_GetUnitBuff(unitId, spellID))
        if ( not duration ) then return end

        allstates[unitId] = makeTriggerState(spell, spellID, duration, nil, unitId)
        return true
    end
end

-- This one only needs to check one event:
-- COMBAT_LOG_EVENT_UNFILTERED:SPELL_AURA_REMOVED
-- trackUnit: player/party
BoopUtilsWA.Triggers.DR = function(category, trackUnit, allstates, event, ...)
    local destGUID, _, _, _, spellID = select(8, ...);
    if ( not destGUID ) then return end
    if ( NS.diminishingReturnSpells[spellID] == category ) then
        local partyUnitId = NS.partyUnitId(destGUID);
        if NS.validateUnitForDR(partyUnitId, trackUnit) then
            local durationDR = 15;
            local stacksNew = 1 + ( (allstates[destGUID] and allstates[destGUID].stacks) or 0 );
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
        if ( not unitId ) then return end
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
        if ( not unitId ) then return end
        local frame = NS.findRaidFrameForUnitId(unitId);
        if frame then
            frames[frame] = frames[frame] or {}
            tinsert(frames[frame], regionData)
        end
    end
end

-- Events: PLAYER_ENTERING_WORLD,ARENA_PREP_OPPONENT_SPECIALIZATIONS, NAME_PLATE_UNIT_ADDED, NAME_PLATE_UNIT_REMOVED
BoopUtilsWA.TotemTrigger = function (allstates, event, ...)
    if shouldClearAllStates(event) then
        return clearAllStates(allstates);
    elseif ( event == NS.NAME_PLATE_UNIT_ADDED ) then
        local unit = ...;
        if unit and ( string.sub(unit, 1, 9) == "nameplate" ) and unitCanAttack(unit) then
            local npcId = getNpcIdFromGuid(UnitGUID(unit));
            if ( not spellData[npcId] ) then return end
            local spell = spellData[npcId];
            if (spell.category ~= OFFENSIVE_PET) then return end
            -- Based on "nameplate" unitIds, which would trigger nameplate removed event later
            allstates[unit] = makeTriggerState(spell, npcId, spell.duration, nil, unit);
            return true;
        end
    elseif ( event == NS.NAME_PLATE_UNIT_REMOVED ) then
        local unit = ...;
        local updated;
        for _, state in pairs(allstates) do
            if ( state.unit == unit ) then
                state.show = false;
                state.changed = true;
                updated = true;
            end
        end
        return updated;
    end
end

-- Events: PLAYER_ENTERING_WORLD,ARENA_PREP_OPPONENT_SPECIALIZATIONS, COMBAT_LOG_EVENT_UNFILTERED
BoopUtilsWA.UnitAuraTrigger = function (allstates, event, ...)
    if shouldClearAllStates(event) then
        return clearAllStates(allstates)
    elseif ( event == NS.UNIT_AURA ) then
        local unitTarget, updateAuras = ...
        if ( not unitTarget ) or ( not NS.isUnitArena(unitTarget) ) or ( not updateAuras ) or ( not updateAuras.updatedAuraInstanceIDs) then return end

        print(unitTarget, #(updateAuras.updatedAuraInstanceIDs))

        for _, instanceID in ipairs(updateAuras.updatedAuraInstanceIDs) do
            local spellInfo = C_UnitAuras.GetAuraDataByAuraInstanceID(unitTarget, instanceID)
            if spellInfo then
                local spellID = spellInfo.spellId
                local spell = spellData[spellID]
                if ( not spell ) or ( spell.category ~= OFFENSIVE_UNITAURA ) then return end
                local guid = ( spell.combine and spellID ) or concatGUID(UnitGUID(unitTarget), spellID)
                if allstates[guid] then -- Use UNIT_AURA to extend aura only, since checking all auras on a unit is expensive
                    allstates[guid].expirationTime = select(6, WA_GetUnitBuff(unitTarget, spellID))
                    allstates[guid].changed = true
                    return true
                end
            end
        end
    elseif ( event == NS.COMBAT_LOG_EVENT_UNFILTERED ) then
        local subEvent, _, _, _, _, _, destGUID, _, _, _, spellID = select(2, ...)
        if ( not destGUID ) or ( not spellData[spellID] ) then return end
        local spell = spellData[spellID]
        if ( spell.category ~= OFFENSIVE_UNITAURA ) then return end

        if ( subEvent == NS.SPELL_AURA_APPLIED ) then
            if ( not checkSpellEnabled(spell, subEvent, destGUID) ) then return end
            local unitId = NS.arenaUnitId(destGUID)
            if ( not unitId ) then return end
            local duration = select(5, WA_GetUnitBuff(unitId, spellID))
            if ( not duration ) then return end

            local guid = ( spell.combine and spellID ) or concatGUID(destGUID, spellID)
            allstates[guid] = makeTriggerState(spell, spellID, duration)
            return true
        elseif ( subEvent == NS.SPELL_AURA_REMOVED ) then
            local guid = ( spell.combine and spellID ) or concatGUID(destGUID, spellID)
            if allstates[guid] then
                allstates[guid].show = false
                allstates[guid].changed = true
                return true
            end
        end
    end
end