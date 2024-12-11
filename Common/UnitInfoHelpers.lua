local _, addon = ...;

addon.MAX_ARENA_SIZE = 3;

local UnitAura = C_UnitAuras.GetAuraDataByIndex;
local maxAuras = 255;

addon.Util_GetUnitAura = function(unit, spell, filter)
    if filter and not filter:upper():find("FUL") then
        filter = filter.."|HELPFUL";
    end

    for i = 1, maxAuras do
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

    for i = 1, maxAuras do
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
    return select(2, UnitClass(unitId)); -- Locale-independent name, e.g. "WARRIOR"
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
        return ( class == addon.HUNTER ) or ( class == addon.WARLOCK ) or ( class == addon.SHAMAN and addon.IsShamanPrimaryPet(unitId) );
    else
        local partySize = partySize or 2;
        for i = 1, partySize do
            if UnitIsUnit(unitId, "partypet" .. i) then
                local partyUnitId = "party" .. i;
                local class = addon.GetUnitClass(partyUnitId);
                return ( class == addon.HUNTER ) or ( class == addon.WARLOCK ) or ( class == addon.SHAMAN and addon.IsShamanPrimaryPet(unitId) );
            end
        end
    end
end

addon.UnitIsHostile = function(unitId)
    local possessedFactor = ( UnitIsPossessed("player") ~= UnitIsPossessed(unitId) );
    -- UnitIsEnemy / UnitIsFriend will not work here, since it excludes neutral units
    return UnitCanAttack("player", unitId) ~= possessedFactor;
end

addon.UnitIsHunterSecondaryPet = function(unitId) -- Only call this check on hostile targets!
    if SweepyBoop.db.profile.nameplatesEnemy.hideHunterSecondaryPet and ( addon.GetNpcIdFromGuid(UnitGUID(unitId)) == addon.HUNTERPET ) then
        for i = 1, addon.MAX_ARENA_SIZE do
            if UnitIsUnit(unitId, "arenapet" .. i) then
                return false;
            end
        end

        return true; -- Option enabled and unitId is a hunter pet, but failed to match with an arena opponent
    end

    return false; -- Option disabled or not a hunter pet
end
