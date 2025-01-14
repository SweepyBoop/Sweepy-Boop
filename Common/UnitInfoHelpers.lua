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

local playerClass; -- This won't chnage for a login session so cache it

addon.IsPartyPrimaryPet = function(unitId)
    -- We're only checking hunter/warlock pets, which includes mind controlled units (which are considered as "pets")
    if UnitIsUnit(unitId, "pet") then
        playerClass = playerClass or addon.GetUnitClass("player");
        return ( playerClass == addon.HUNTER ) or ( playerClass == addon.WARLOCK ) or ( playerClass == addon.SHAMAN and addon.IsShamanPrimaryPet(unitId) );
    else
        for i = 1, 2 do
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

addon.GetSpecForPlayerOrArena = function(unit)
    if ( unit == "player" ) then
        local currentSpec = GetSpecialization();
        if currentSpec then
            return GetSpecializationInfo(currentSpec);
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
        -- UnitClass returns nil unless unit is in range, but arena spec is available in prep phase.
        local index = string.sub(unitId, -1, -1);
        local specID = GetArenaOpponentSpec(index);
        if specID and ( specID > 0 ) then
            return select(6, GetSpecializationInfoByID(specID));
        end
    end
end

-- C_PvP.GetScoreInfoByPlayerGuid returns localized spec name
local specInfoByName = {};
for _, classID in pairs(addon.CLASSID) do
    for specIndex = 1, 4 do
        local _, name, _, icon, role = GetSpecializationInfoForClassID(classID, specIndex);
        if name then
            specInfoByName[name] = { icon = icon, role = role };
            --print(name, specInfoByName[name].icon, specInfoByName[name].role);
        end
    end
end

local requestFrame = CreateFrame("Frame");
requestFrame:Hide(); -- OnUpdate is not called when frame is hidden, only show this frame in battlegrounds
requestFrame.timer = 0;
requestFrame:SetScript("OnUpdate", function (self, elapsed)
    self.timer = self.timer + elapsed;
    if self.timer > 2 then -- update every 2 sec
        RequestBattlefieldScoreData();
        self.timer = 0;
    end
end)

-- Battleground enemy info parser
local cachedBattlefieldSpec = {};
local refreshFrame = CreateFrame("Frame");
refreshFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD); -- Are there other events we need to register?
refreshFrame:SetScript("OnEvent", function ()
    cachedBattlefieldSpec = {}; -- reset after every loading screen

    if ( UnitInBattleground("player") ~= nil ) then
        requestFrame:Show();
    else
        requestFrame:Hide();
    end
end)

addon.GetBattlefieldSpecByPlayerGuid = function (guid)
    if ( not cachedBattlefieldSpec[guid] ) then
        if IsActiveBattlefieldArena() then
            for i = 1, addon.MAX_ARENA_SIZE do
                if UnitIsUnit(guid, "arena" .. i) then
                    local specID = GetArenaOpponentSpec(i);
                    if ( not specID ) then return end
                    local iconID, role = select(4, GetSpecializationInfoByID(specID));
                    cachedBattlefieldSpec[guid] = { icon = iconID, role = role };
                end
            end
        elseif ( UnitInBattleground("player") == nil ) then
            local scoreInfo = C_PvP.GetScoreInfoByPlayerGuid(guid);
            if scoreInfo and scoreInfo.talentSpec then
                cachedBattlefieldSpec[guid] = specInfoByName[scoreInfo.talentSpec];
            end
        end
    end

    return cachedBattlefieldSpec[guid];
end
