local _, NS = ...;

local UnitAura = C_UnitAuras.GetAuraDataByIndex;
local strsplit = strsplit;

local CreateFrame = CreateFrame;
local UnitExists = UnitExists;
local UnitGUID = UnitGUID;
local UnitClass = UnitClass;

NS.Util_GetUnitAura = function(unit, spell, filter)
    if filter and not filter:upper():find("FUL") then
        filter = filter.."|HELPFUL";
    end

    for i = 1, 255 do
      local auraData = UnitAura(unit, i, filter);
      if (not auraData) or (not auraData.name) then return end
      if spell == auraData.spellId or spell == auraData.name then
        return UnitAura(unit, i, filter);
      end
    end
end

NS.Util_GetFirstUnitAura = function (unit, spells, filter, sourceUnit)
    if filter and not filter:upper():find("FUL") then
        filter = filter.."|HELPFUL";
    end

    for i = 1, 255 do
        local auraData = UnitAura(unit, i, filter);
        if auraData and auraData.name and spells[auraData.spellId] then
            if ( not sourceUnit ) or ( auraData.sourceUnit == sourceUnit ) then
                return UnitAura(unit, i, filter);
            end
        end
    end
end

NS.Util_GetUnitBuff = function(unit, spell, filter)
    filter = filter and filter.."|HELPFUL" or "HELPFUL";
    return NS.Util_GetUnitAura(unit, spell, filter);
end

NS.Util_GetFirstUnitBuff = function (unit, spells, filter, sourceUnit)
    filter = filter and filter.."|HELPFUL" or "HELPFUL";
    return NS.Util_GetFirstUnitAura(unit, spells, filter, sourceUnit);
end

NS.GetNpcIdFromGuid = function (guid)
    local NpcId = select ( 6, strsplit ( "-", guid ) )
    if (NpcId) then
        return tonumber ( NpcId )
    end

    return 0
end

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
partyInfoFrame:RegisterEvent(NS.PLAYER_ENTERING_WORLD)
partyInfoFrame:RegisterEvent(NS.GROUP_ROSTER_UPDATE)
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
    local unitGUID = UnitGUID(unitId);
    local npcID = NS.GetNpcIdFromGuid(unitGUID);
    -- Greater / Primal Fire Elemental
    return ( npcID == 95061 ) or ( npcID == 61029 );
end

