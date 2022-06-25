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

local MAX_ARENAOPPONENT_SIZE = 3;
local MAX_PARTY_SIZE = 10;
NS.MAX_ARENAOPPONENT_SIZE = MAX_ARENAOPPONENT_SIZE;
NS.MAX_PARTY_SIZE = MAX_PARTY_SIZE;

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

-- Make sure you only check "arena"..i unitIds in the following helper functions
-- For testing, unitId = "player", index = 0
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

-- This is used for testing only
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

-- Only pass in "arena"..i unitIds
local function arenaUnitGUID(unitId, index)
    if (not arenaInfo.unitGUID[unitId]) and UnitExists(unitId) then
        local guid = UnitGUID(unitId);
        updateArenaInfo(guid, unitId, index);
    end

    return arenaInfo.unitGUID[unitId];
end

-- Only pass in "arena"..i unitIds, or "player" for testing
local function unitClass(unitId)
    updateArenaInfo(nil, unitId);
    return arenaInfo.unitClass[unitId];
end

-- Only pass in "arena"..i unitIds, or "player" for testing
local function unitRace(unitId)
    updateArenaInfo(nil, unitId);
    return arenaInfo.unitRace[unitId];
end

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