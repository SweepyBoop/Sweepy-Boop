local _, addon = ...;

local UnitAura = C_UnitAuras.GetAuraDataByIndex;
local strsplit = strsplit;

local CreateFrame = CreateFrame;
local UnitExists = UnitExists;
local UnitGUID = UnitGUID;
local UnitClass = UnitClass;

addon.Util_GetUnitAura = function(unit, spell, filter)
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

addon.Util_GetFirstUnitAura = function (unit, spells, filter, sourceUnit)
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

addon.Util_GetUnitBuff = function(unit, spell, filter)
    filter = filter and filter.."|HELPFUL" or "HELPFUL";
    return addon.Util_GetUnitAura(unit, spell, filter);
end

addon.Util_GetFirstUnitBuff = function (unit, spells, filter, sourceUnit)
    filter = filter and filter.."|HELPFUL" or "HELPFUL";
    return addon.Util_GetFirstUnitAura(unit, spells, filter, sourceUnit);
end

addon.GetUnitClass = function(unitId)
    return select(2, UnitClass(unitId));
end

addon.GetUnitClassName = function(unitId)
    return select(2, UnitClass(unitId));
end

addon.IsArenaPrimaryPet = function(unitId)
    for i = 1, addon.MAX_ARENA_SIZE do
        if UnitIsUnit(unitId, "arenapet" .. i) then
            return true;
        end
    end
end

addon.IsShamanPrimaryPet = function (unitId)
    local unitGUID = UnitGUID(unitId);
    local npcID = addon.GetNpcIdFromGuid(unitGUID);
    -- Greater / Primal Fire Elemental
    return ( npcID == 95061 ) or ( npcID == 61029 );
end

addon.IsPartyPrimaryPet = function(unitId, partySize)
    -- We're only checking hunter/warlock pets, which includes mind controlled units (which are considered as "pets")
    if UnitIsUnit(unitId, "pet") then
        local class = addon.GetUnitClass("player");
        return ( class == "HUNTER" ) or ( class == "WARLOCK" ) or ( class == "SHAMAN" and addon.IsShamanPrimaryPet(unitId) );
    else
        local partySize = partySize or 2;
        for i = 1, partySize do
            if UnitIsUnit(unitId, "partypet" .. i) then
                local partyUnitId = "party" .. i;
                local class = addon.GetUnitClass(partyUnitId);
                return ( class == "HUNTER" ) or ( class == "WARLOCK" ) or ( class == "SHAMAN" and addon.IsShamanPrimaryPet(unitId) );
            end
        end
    end
end

addon.UnitIsHostile = function(unitId)
    local possessedFactor = ( UnitIsPossessed("player") ~= UnitIsPossessed(unitId) );
    -- UnitIsEnemy will not work here, since it excludes neutral units
    return UnitCanAttack("player", unitId) ~= possessedFactor;
end

addon.MAX_ARENA_SIZE = 3
addon.MAX_PARTY_SIZE = 6 -- 3 for players and 3 for pets

local partyInfo = {
    -- Convert between unitGUID and unitID
    unitGUID = {},
    unitId = {},
    unitClass = {},
    partyWithFearSpell = nil,
}

local partyInfoFrame = CreateFrame("Frame")
partyInfoFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD)
partyInfoFrame:RegisterEvent(addon.GROUP_ROSTER_UPDATE)
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

local ClassWithFearSpell = addon.ClassWithFearSpell

addon.PartyWithFearSpell = function ()
    if ( partyInfo.partyWithFearSpell == nil ) then
        partyInfo.partyWithFearSpell =
            ClassWithFearSpell(PartyUnitClass("player"))
            or ClassWithFearSpell(PartyUnitClass("party1"))
            or ClassWithFearSpell(PartyUnitClass("party2"))
    end

    return partyInfo.partyWithFearSpell
end
