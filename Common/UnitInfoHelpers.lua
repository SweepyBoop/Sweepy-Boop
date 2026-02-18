local _, addon = ...;

if addon.PROJECT_MAINLINE then
    addon.MAX_ARENA_SIZE = 3;
else
    addon.MAX_ARENA_SIZE = 5; -- MoP Classic
end

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

local playerClass; -- This won't change for a login session so cache it
local classesWithPets = {
    [addon.HUNTER] = true,
    [addon.WARLOCK] = true,
    [addon.SHAMAN] = true,
};

addon.IsPartyPrimaryPet = function(unitId)
    -- We're only checking hunter/warlock pets, which includes mind controlled units (which are considered as "pets")
    if UnitIsUnit(unitId, "pet") then
        playerClass = playerClass or addon.GetUnitClass("player");
        return classesWithPets[playerClass];
    else
        for i = 1, 2 do
            if UnitIsUnit(unitId, "partypet" .. i) then
                local partyUnitId = "party" .. i;
                local class = addon.GetUnitClass(partyUnitId);
                return classesWithPets[class];
            end
        end
    end
end

addon.UnitIsHostile = function(unitId)
    local possessedFactor = ( UnitIsPossessed("player") ~= UnitIsPossessed(unitId) );
    -- UnitIsEnemy / UnitIsFriend will not work here, since it excludes neutral units
    local reaction = UnitReaction("player", unitId); -- this can sometimes return nil, treat as hostile to avoid showing friendly class icons on NPCs
    local isHostile = ( not reaction ) or ( reaction < 5 );
    return isHostile ~= possessedFactor;
end

addon.UnitIsHunterSecondaryPet = function(unitId) -- Only call this check on hostile targets!
    if ( not IsActiveBattlefieldArena() ) then return end -- We can't do this check outside arena, so just return false by default

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

addon.GetSpecForPlayerOrArena = function(unit)
    if ( unit == "player" ) then
        if addon.PROJECT_MAINLINE then
            local currentSpec = GetSpecialization();
            if currentSpec then
                return GetSpecializationInfo(currentSpec);
            end
        else
            -- Temporary solution for MoP Classic, GetSpecialization is not yet in place (as it should be)
            return addon.SPECID.DESTRUCTION; -- Hard code spec ID in test (https://warcraft.wiki.gg/wiki/SpecializationID)
        end
    else
        local arenaIndex = string.sub(unit, -1, -1);
        return GetArenaOpponentSpec(arenaIndex);
    end
end

addon.GetClassForPlayerOrArena = function (unitId)
    if ( unitId == "player" ) then
        return addon.GetUnitClass(unitId);
    else
        -- In TBC, there are no specs, so we need to use UnitClass directly
        if addon.PROJECT_TBC then
            return addon.GetUnitClass(unitId);
        end

        -- UnitClass returns nil unless unit is in range, but arena spec is available in prep phase.
        local index = string.sub(unitId, -1, -1);
        local specID = GetArenaOpponentSpec(index);
        if specID and ( specID > 0 ) then
            return select(6, GetSpecializationInfoByID(specID));
        end
    end
end

-- C_PvP.GetScoreInfoByPlayerGuid returns localized spec name
-- There are Frost Mage and Frost DK, but the spec name is "Frost" for both...
-- We need to append class info as well
local specInfoByName = {};
local specIDByTooltip = {}; -- To retrieve specID from tooltip
for _, classID in pairs(addon.CLASSID) do
    for specIndex = 1, 4 do
        local specID, specName, _, icon, role = GetSpecializationInfoForClassID(classID, specIndex);
        local classInfo = C_CreatureInfo.GetClassInfo(classID);
        if specName and classInfo and classInfo.classFile then
            local classFile = classInfo.classFile;
            specInfoByName[classFile .. "-" .. specName] = { icon = icon, role = role };

            local localizedClassMale = LOCALIZED_CLASS_NAMES_MALE[classFile];
            if localizedClassMale then
                specIDByTooltip[specName .. " " .. localizedClassMale] = specID;
                --print(specName .. " " .. localizedClassMale, specID); -- Debug
            end

            local localizedClassFemale = LOCALIZED_CLASS_NAMES_FEMALE[classFile];
            if localizedClassFemale and ( localizedClassFemale ~= localizedClassMale ) then
                specIDByTooltip[specName .. " " .. localizedClassFemale] = specID;
                --print(specName .. " " .. localizedClassFemale, specID); -- Debug
            end
        end
    end
end

-- Battleground enemy info parser
-- Use tooltip to get spec - this works even when UnitGUID/UnitName return secret values
-- Tooltip shows "Spec Class" format (e.g., "Frost Mage", "Arms Warrior")
-- Key insight: tooltipData.guid works even when UnitGUID() returns secret values

-- Cache by GUID from tooltip (more persistent than unitId token)
addon.cachedPlayerSpec = {};

local refreshFrame = CreateFrame("Frame");
refreshFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
refreshFrame:SetScript("OnEvent", function (self, event)
    addon.cachedPlayerSpec = {};
end)

addon.GetPlayerSpec = function (unitId)
    if not unitId then return nil end

    -- Check if unit is a player
    if not UnitIsPlayer(unitId) then
        return nil;
    end

    -- Use tooltip - tooltipData.guid works even when UnitGUID() is secret
    local tooltipData = C_TooltipInfo.GetUnit(unitId);
    if not tooltipData or not tooltipData.guid or not tooltipData.lines then
        return nil;
    end

    local tooltipGUID = tooltipData.guid;
    local canCache = tooltipGUID and ( not addon.IsSecretValue(tooltipGUID) );

    -- Return cached specInfo if already found
    if canCache and addon.cachedPlayerSpec[tooltipGUID] then
        return addon.cachedPlayerSpec[tooltipGUID];
    end

    -- Skip if line.leftText is secret, i.e., can't parse
    local firstLine = tooltipData.lines and tooltipData.lines[1];
    if ( not firstLine ) or ( not firstLine.leftText ) or addon.IsSecretValue(firstLine.leftText) then
        return nil;
    end

    -- Iterate through tooltip lines to find the spec name
    for _, line in ipairs(tooltipData.lines) do
        if line and line.type == Enum.TooltipDataLineType.None and line.leftText and line.leftText ~= "" then
            local specID = specIDByTooltip[line.leftText];
            if specID then
                local iconID, role = select(4, GetSpecializationInfoByID(specID));
                local specInfo = { icon = iconID, role = role };
                if canCache then
                    addon.cachedPlayerSpec[tooltipGUID] = specInfo;
                end
                return specInfo;
            end
        end
    end

    return nil;
end
