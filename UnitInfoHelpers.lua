local _, NS = ...

local isTestMode = NS.isTestMode;

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

NS.MAX_ARENA_SIZE = 3;
NS.MAX_PARTY_SIZE = 6; -- 3 for players and 3 for pets

local arenaInfoFrame = CreateFrame('Frame');
arenaInfoFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
arenaInfoFrame:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS");
arenaInfoFrame:SetScript("OnEvent", function ()
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

-- For the following helpers, make sure unitId is "arena".i, or "player" for testing
-- index = 1/2/3 for "arena"..index, or 0 for "player"

local function getSpecForArenaIndex(index)
    if (index == 0) then
        local currentSpec = GetSpecialization();
        return GetSpecializationInfo(currentSpec);
    else
        return GetArenaOpponentSpec(index);
    end
end

-- Make sure unitId is valid (player if test is on, arena..i) and exists
local function updateArenaInfo(unitId, ...)
    local index = ...;

    if (not arenaInfo.unitGUID[unitId]) then
        arenaInfo.unitGUID[unitId] = UnitGUID(unitId);
    end

    local unitGUID = arenaInfo.unitGUID[unitId];
    if (not arenaInfo.unitId[unitGUID]) then
        arenaInfo.unitId[unitGUID] = unitId;
    end

    if index and (not arenaInfo.spec[unitId]) then
        arenaInfo.spec[unitGUID] = getSpecForArenaIndex(index);
    end

    if index and unitId and (not arenaInfo.unitSpec[unitId]) then
        arenaInfo.unitSpec[unitId] = getSpecForArenaIndex(index);
    end

    if (not arenaInfo.unitClass[unitId]) then
        arenaInfo.unitClass[unitId] = select(3, UnitClass(unitId));
    end

    if (not arenaInfo.unitRace[unitId]) then
        arenaInfo.unitRace[unitId] = select(3, UnitRace(unitId));
    end
end

local function arenaUnitGUID(unitId, index)
    if UnitExists(unitId) then
        updateArenaInfo(unitId, index);
    end

    return arenaInfo.unitGUID[unitId];
end

-- Caller ensures sourceGUID is not nil
-- Call this before getting any info based on sourceGUID
NS.isSourceArena = function(sourceGUID)
    if isTestMode and (sourceGUID == arenaUnitGUID("player", 0)) then
        -- updateArenaInfo called by arenaUnitGUID
        return true;
    end

    for i = 1, NS.MAX_ARENA_SIZE do
        if (sourceGUID == arenaUnitGUID("arena"..i, i)) then
            -- updateArenaInfo called by arenaUnitGUID
            return true;
        end
    end
end

NS.arenaUnitId = function (sourceGUID)
    return arenaInfo.unitId[sourceGUID];
end

NS.arenaSpec = function (sourceGUID)
    return arenaInfo.spec[sourceGUID];
end

-- For arena pets we cannot reliably cache the GUIDs, since pets can die and players can summon a different pet.
-- This is only checked for TRACK_PET spells which is rare.
NS.isSourceArenaPet = function(sourceGUID)
    if isTestMode then return sourceGUID == UnitGUID("pet") end

    for i = 1, NS.MAX_ARENA_SIZE do
        if (sourceGUID == UnitGUID("arenapet"..i)) then
            return true;
        end
    end
end

-- Caller ensures unitId is not nil
-- Call this before getting any info based on unitId
NS.isUnitArena = function(unitId)
    if isTestMode and unitId == "player" then
        updateArenaInfo(unitId, 0);
        return true;
    end

    for i = 1, NS.MAX_ARENA_SIZE do
        if (unitId == "arena"..i) then
            updateArenaInfo(unitId, i);
            return true;
        end
    end
end

NS.arenaUnitSpec = function (unitId)
    return arenaInfo.unitSpec[unitId];
end

NS.arenaUnitClass = function(unitId)
    return arenaInfo.unitClass[unitId];
end

NS.arenaUnitRace = function(unitId)
    return arenaInfo.unitRace[unitId];
end

NS.arenaSpellChargeExpire = function (guid)
    return arenaInfo.spellChargeExpire[guid];
end
NS.setArenaSpellChargeExpire = function (guid, value)
    arenaInfo.spellChargeExpire[guid] = value;
end

NS.arenaOptLowerCooldown = function (guid)
    return arenaInfo.optLowerCooldown[guid];
end
NS.setArenaOptLowerCooldown = function (guid, value)
    arenaInfo.optLowerCooldown[guid] = value;
end

NS.arenaDefaultHoJCooldown = function (guid)
    return arenaInfo.defaultHoJCooldown[guid];
end
NS.setArenaDefaultHoJCooldown = function (guid, value)
    arenaInfo.defaultHoJCooldown[guid] = value;
end



local partyInfo = {
    -- Convert between unitGUID and unitID
    unitGUID = {},
    unitId = {},
    unitClass = {},
    partyWithFearSpell = nil;
}

local partyInfoFrame = CreateFrame("Frame");
partyInfoFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
partyInfoFrame:RegisterEvent("GROUP_ROSTER_UPDATE");
partyInfoFrame:SetScript("OnEvent", function ()
    partyInfo.unitGUID = {};
    partyInfo.unitId = {};
    partyInfo.unitClass = {};
    partyInfo.partyWithFearSpell = nil;
end);

-- Update info for this unitId whenever being queried
local function updatePartyInfo(unitId)
    if ( not UnitExists(unitId) ) then return end

    if ( not partyInfo.unitGUID[unitId] ) then
        partyInfo.unitGUID[unitId] = UnitGUID(unitId);
    end

    if ( not partyInfo.unitClass[unitId] ) then
        partyInfo.unitClass[unitId] = select(3, UnitClass(unitId));
    end

    local guid = partyInfo.unitGUID[unitId];
    if ( not partyInfo.unitId[guid] ) then
        partyInfo.unitId[guid] = unitId;
    end
end

-- unitId must be player/party1/party2
local function partyUnitGUID(unitId)
    updatePartyInfo(unitId);
    return partyInfo.unitGUID[unitId];
end

-- unitId must be player/party1/party2
local function partyUnitClass(unitId)
    updatePartyInfo(unitId);
    return partyInfo.unitClass[unitId];
end

local classWithFearSpell = NS.classWithFearSpell;

NS.partyWithFearSpell = function ()
    if ( partyInfo.partyWithFearSpell == nil ) then
        partyInfo.partyWithFearSpell = classWithFearSpell(partyUnitClass("player"))
            or classWithFearSpell(partyUnitClass("party1"))
            or classWithFearSpell(partyUnitClass("party2"));
    end

    return partyInfo.partyWithFearSpell;
end

-- If unitGUID matches player/party1/party2, cache and return the corresponding unitId; otherwise return nil
-- The cached unitId can later be used as "unit" in the TSU
-- Call ensures unitGUID is not nil
NS.partyUnitId = function(unitGUID)
    if ( unitGUID == partyUnitGUID("player") ) or ( unitGUID == partyUnitGUID("party1") ) or ( unitGUID == partyUnitGUID("party2") ) then
        return partyInfo.unitId[unitGUID];
    end

    -- If unitGUID does not match the above units, no value should be cached and nil will be returned
end

NS.validateUnitForDR = function(partyUnitId, trackUnit)
    if (not partyUnitId) then return end
    if (trackUnit == "player") then
        return (partyUnitId == "player")
    elseif (trackUnit == "party") then
        return (partyUnitId ~= "player");
    end
end

NS.findArenaFrameForUnitId = function (unitId)
    if NS.isTestMode and (unitId == "player") then
        local frame = _G["sArenaEnemyFrame1"];
        if ( not frame ) then
            frame = _G["GladiusButtonFramearena1"];
        end

        return frame;
    else
        for i = 1, NS.MAX_ARENA_SIZE do
            if ( unitId == "arena"..i ) then
                local frame = _G["sArenaEnemyFrame"..i];
                if ( not frame ) then
                    frame = _G["GladiusButtonFramearena"..i];
                end

                return frame;
            end
        end
    end
end

NS.findRaidFrameForUnitId = function (unitId)
    for i = 1, NS.MAX_PARTY_SIZE do
        local frame = _G["CompactRaidFrame"..i];
        if ( not frame ) then return end
        if frame.unit and UnitIsUnit(frame.unit, unitId) then
            return frame;
        end
    end
end

