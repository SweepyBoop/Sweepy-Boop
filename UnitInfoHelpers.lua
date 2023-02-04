local _, NS = ...

local isTestMode = NS.isTestMode

local arenaInfo = {
    -- Key: unitId (arena1, arena2, arena3), value: sourceGUID
    unitGUID = {},
    -- Key: sourceGUID, value: unitId
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
}

NS.MAX_ARENA_SIZE = 3
NS.MAX_PARTY_SIZE = 6 -- 3 for players and 3 for pets

local arenaInfoFrame = CreateFrame('Frame')
arenaInfoFrame:RegisterEvent(NS.PLAYER_ENTERING_WORLD)
arenaInfoFrame:RegisterEvent(NS.ARENA_PREP_OPPONENT_SPECIALIZATIONS)
arenaInfoFrame:RegisterEvent(NS.PLAYER_SPECIALIZATION_CHANGED)
arenaInfoFrame:SetScript("OnEvent", function (self, event, ...)
    local reset = false
    if ( event == NS.PLAYER_ENTERING_WORLD ) or ( event == NS.ARENA_PREP_OPPONENT_SPECIALIZATIONS ) then
        reset = true
    elseif ( event == NS.PLAYER_SPECIALIZATION_CHANGED ) then
        local unitTarget = ...
        reset = ( unitTarget == "player" )
    end

    if reset then
        arenaInfo.unitGUID = {}
        arenaInfo.unitId = {}
        arenaInfo.spec = {}
        arenaInfo.unitSpec = {}
        arenaInfo.unitClass = {}
        arenaInfo.unitRace = {}
        arenaInfo.spellChargeExpire = {}
        arenaInfo.optLowerCooldown = {}
    end
end)

-- For the following helpers, make sure unitId is "arena".i, or "player" for testing
-- index = 1/2/3 for "arena"..index, or 0 for "player"

local function getSpecForArenaIndex(index)
    if (index == 0) then
        local currentSpec = GetSpecialization()
        return GetSpecializationInfo(currentSpec)
    else
        return GetArenaOpponentSpec(index)
    end
end

-- Make sure unitId is valid (player if test is on, arena..i) and exists
local function updateArenaInfo(unitId, ...)
    local index = ...

    if (not arenaInfo.unitGUID[unitId]) then
        arenaInfo.unitGUID[unitId] = UnitGUID(unitId)
    end

    local unitGUID = arenaInfo.unitGUID[unitId]
    if (not arenaInfo.unitId[unitGUID]) then
        arenaInfo.unitId[unitGUID] = unitId
    end

    if index and (not arenaInfo.spec[unitGUID]) then
        arenaInfo.spec[unitGUID] = getSpecForArenaIndex(index)
    end

    if index and unitId and (not arenaInfo.unitSpec[unitId]) then
        arenaInfo.unitSpec[unitId] = getSpecForArenaIndex(index)
    end

    if (not arenaInfo.unitClass[unitId]) then
        arenaInfo.unitClass[unitId] = select(3, UnitClass(unitId))
    end

    if (not arenaInfo.unitRace[unitId]) then
        arenaInfo.unitRace[unitId] = select(3, UnitRace(unitId))
    end
end

local function arenaUnitGUID(unitId, index)
    if UnitExists(unitId) then
        updateArenaInfo(unitId, index)
    end

    return arenaInfo.unitGUID[unitId]
end

-- Caller ensures unitGUID is not nil
NS.isGUIDArena = function(unitGUID)
    if isTestMode then
        -- updateArenaInfo called by arenaUnitGUID
        return (unitGUID == arenaUnitGUID("player", 0))
    end

    for i = 1, NS.MAX_ARENA_SIZE do
        if (unitGUID == arenaUnitGUID("arena"..i, i)) then
            -- updateArenaInfo called by arenaUnitGUID
            return true
        end
    end
end

NS.arenaUnitId = function (unitGUID)
    if ( not arenaInfo.unitId[unitGUID] ) then
        NS.isGUIDArena(unitGUID)
    end

    return arenaInfo.unitId[unitGUID]
end

NS.arenaSpec = function (unitGUID)
    if ( not arenaInfo.spec[unitGUID] ) then
        NS.isGUIDArena(unitGUID)
    end

    return arenaInfo.spec[unitGUID]
end

-- Caller ensures unitId is not nil
-- Call this before getting any info based on unitId
NS.isUnitArena = function(unitId)
    if isTestMode then
        if ( unitId == "player" ) then
            updateArenaInfo(unitId, 0)
            return true
        else
            return false
        end
    end

    for i = 1, NS.MAX_ARENA_SIZE do
        if (unitId == "arena"..i) then
            updateArenaInfo(unitId, i)
            return true
        end
    end
end

NS.arenaUnitSpec = function (unitId)
    return arenaInfo.unitSpec[unitId]
end

NS.arenaUnitClass = function(unitId)
    return arenaInfo.unitClass[unitId]
end

NS.arenaUnitRace = function(unitId)
    return arenaInfo.unitRace[unitId]
end

NS.arenaSpellChargeExpire = function (guid)
    return arenaInfo.spellChargeExpire[guid]
end
NS.setArenaSpellChargeExpire = function (guid, value)
    arenaInfo.spellChargeExpire[guid] = value
end

NS.arenaOptLowerCooldown = function (guid)
    return arenaInfo.optLowerCooldown[guid]
end
NS.setArenaOptLowerCooldown = function (guid, value)
    arenaInfo.optLowerCooldown[guid] = value
end



local partyInfo = {
    -- Convert between unitGUID and unitID
    unitGUID = {},
    unitId = {},
    unitClass = {},
    partyWithFearSpell = nil,
}

local partyInfoFrame = CreateFrame("Frame")
partyInfoFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
partyInfoFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
partyInfoFrame:SetScript("OnEvent", function ()
    partyInfo.unitGUID = {}
    partyInfo.unitId = {}
    partyInfo.unitClass = {}
    partyInfo.partyWithFearSpell = nil
end)

-- Update info for this unitId whenever being queried
local function UpdatePartyInfo(unitId)
    if ( not UnitExists(unitId) ) then return end

    if ( not partyInfo.unitGUID[unitId] ) then
        partyInfo.unitGUID[unitId] = UnitGUID(unitId)
    end

    if ( not partyInfo.unitClass[unitId] ) then
        partyInfo.unitClass[unitId] = select(2, UnitClass(unitId))
    end

    local guid = partyInfo.unitGUID[unitId]
    if ( not partyInfo.unitId[guid] ) then
        partyInfo.unitId[guid] = unitId
    end
end

-- unitId must be player/party1/party2
local function PartyUnitClass(unitId)
    UpdatePartyInfo(unitId)
    return partyInfo.unitClass[unitId]
end

local ClassWithFearSpell = NS.ClassWithFearSpell

NS.PartyWithFearSpell = function ()
    if ( partyInfo.partyWithFearSpell == nil ) then
        partyInfo.partyWithFearSpell =
            ClassWithFearSpell(PartyUnitClass("player"))
            or ClassWithFearSpell(PartyUnitClass("party1"))
            or ClassWithFearSpell(PartyUnitClass("party2"))
    end

    return partyInfo.partyWithFearSpell
end

NS.IsShamanPrimaryPet = function (unitId)
    local unitName = UnitName(unitId);
    local suffix = string.sub(unitName, -14, -1);
    return ( suffix == "Fire Elemental" );
end

