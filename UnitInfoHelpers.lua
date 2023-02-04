local _, NS = ...

local isTestMode = NS.isTestMode;

NS.MAX_ARENA_SIZE = 3
NS.MAX_PARTY_SIZE = 6 -- 3 for players and 3 for pets

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

