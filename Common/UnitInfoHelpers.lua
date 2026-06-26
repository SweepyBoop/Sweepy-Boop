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

-- Arena-safe unit resolver ----------------------------------------------------
-- On mainline, arena units are PvP-restricted: UnitGUID / UnitIsUnit can return
-- secret values. Use non-secret identity attributes instead when exact identity
-- APIs are unsafe or unavailable.
local function GetUnitArenaFingerprint(unit)
    if ( not UnitExists(unit) ) then return end
    local class = UnitClassBase(unit);
    if ( not class ) then return end
    return class, select(2, UnitRace(unit)), UnitSex(unit), UnitHonorLevel(unit); -- race file is locale-independent
end

local partySlotPrintCache = {};

local function IsPartySlotUnit(unit)
    if unit == "player" then
        return true;
    end

    for i = 1, addon.MAX_ARENA_SIZE do
        if unit == "party" .. i then
            return true;
        end
    end

    return false;
end

local function GetCachedPartySlotPrint(unit)
    if not IsPartySlotUnit(unit) then
        return nil;
    end

    local cached = partySlotPrintCache[unit];
    if cached then return cached end

    local class, race, sex, honor = GetUnitArenaFingerprint(unit);
    if ( not class ) then return nil end

    local fp = { class = class, race = race, sex = sex, honor = honor };
    if race and sex and honor then
        partySlotPrintCache[unit] = fp;
    end
    return fp;
end

local function GetUnitArenaFingerprintCached(unit)
    local cached = GetCachedPartySlotPrint(unit);
    if cached then
        return cached.class, cached.race, cached.sex, cached.honor;
    end

    return GetUnitArenaFingerprint(unit);
end

addon.UnitIsUnitSecretValueSafe = function(unitA, unitB)
    if ( not addon.PROJECT_MAINLINE ) then
        return UnitIsUnit(unitA, unitB);
    end

    local classA, raceA, sexA, honorA = GetUnitArenaFingerprintCached(unitA);
    if ( not classA ) then return false end

    local classB, raceB, sexB, honorB = GetUnitArenaFingerprintCached(unitB);
    if ( not classB ) then return false end

    return classA == classB
        and raceA == raceB
        and sexA == sexB
        and honorA == honorB;
end

-- Per-slot fingerprint cache. The arena1/2/3 -> player identity is fixed for a
-- round, so complete slot fingerprints can be cached until the comp changes.
local arenaSlotPrintCache = {};

addon.ResetUnitIdentityPrintCaches = function()
    wipe(arenaSlotPrintCache);
    wipe(partySlotPrintCache);
end

addon.ResetArenaSlotPrintCache = addon.ResetUnitIdentityPrintCaches;

local function GetArenaSlotPrint(i)
    local cached = arenaSlotPrintCache[i];
    if cached then return cached end

    local class, race, sex, honor = GetUnitArenaFingerprint("arena" .. i);
    if ( not class ) then
        -- Out of range / prep phase: UnitClassBase is nil, but arena spec gives the class.
        local specID = GetArenaOpponentSpec(i);
        if specID and ( specID > 0 ) then
            class = select(6, GetSpecializationInfoByID(specID)); -- classFilename
        end
        if ( not class ) then return end
    end

    local fp = { class = class, race = race, sex = sex, honor = honor };
    -- Cache only complete in-range fingerprints; class-only prints are too coarse.
    if race and sex and honor then
        arenaSlotPrintCache[i] = fp;
    end
    return fp;
end

local function SlotMatches(slot, class, race, sex, honor)
    return class == slot.class
        and ( slot.race == nil or race == slot.race )
        and ( slot.sex == nil or sex == slot.sex )
        and ( slot.honor == nil or honor == slot.honor );
end

addon.GetArenaNumber = function(unit)
    local class, race, sex, honor = GetUnitArenaFingerprint(unit);
    if ( not class ) then return end

    local match;
    for i = 1, addon.MAX_ARENA_SIZE do
        local slot = GetArenaSlotPrint(i);
        if slot and SlotMatches(slot, class, race, sex, honor) then
            if match then return end -- a second match => ambiguous, leave blank
            match = i;
        end
    end
    return match;
end

if addon.PROJECT_MAINLINE then
    local unitIdentityPrintCacheResetFrame = CreateFrame("Frame");
    unitIdentityPrintCacheResetFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
    unitIdentityPrintCacheResetFrame:RegisterEvent(addon.GROUP_ROSTER_UPDATE);
    unitIdentityPrintCacheResetFrame:RegisterEvent(addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS);
    unitIdentityPrintCacheResetFrame:SetScript("OnEvent", addon.ResetUnitIdentityPrintCaches);
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
    local playerPossessed = UnitIsPossessed("player");
    local unitPossessed = UnitIsPossessed(unitId);
    local reaction = UnitReaction("player", unitId); -- This can return nil/secret; default to hostile to avoid friendly icons on NPCs.

    if addon.IsSecretValue(playerPossessed) or addon.IsSecretValue(unitPossessed) or addon.IsSecretValue(reaction) then
        return true;
    end

    local possessedFactor = ( playerPossessed ~= unitPossessed );
    -- UnitIsEnemy / UnitIsFriend will not work here, since it excludes neutral units
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

-- TBC heuristic spec detection ---------------------------------------------------------
-- TBC has no spec API, so we infer an enemy's spec from spells they cast and buffs they
-- carry (addon.SpecDetection, defined in SpellData_TBC.lua). Stored per GUID so it
-- survives unit-token churn; reset on PLAYER_ENTERING_WORLD (see refreshFrame below).
addon.detectedSpec = {};

-- Record a detected spec for a unit. Validates the spec belongs to the unit's class to
-- guard against misattribution. Returns true only on the first successful record.
addon.RecordDetectedSpec = function (unit, spec)
    if ( not unit ) or ( not spec ) then return end
    local guid = UnitGUID(unit);
    if ( not guid ) or addon.detectedSpec[guid] then return end

    local class = addon.GetUnitClass(unit);
    if class and ( addon.SPECID_TO_CLASS[spec] ~= class ) then return end

    addon.detectedSpec[guid] = spec;
    return true;
end

addon.GetDetectedSpec = function (unit)
    local guid = unit and UnitGUID(unit);
    return guid and addon.detectedSpec[guid];
end

-- Scan a unit's auras for a spec indicator (self-cast buffs only, e.g. Shadowform, Ice
-- Barrier). Caster-applied debuffs are caught via the combat log instead. Returns true if
-- a spec was newly detected.
addon.ScanUnitForSpec = function (unit)
    if ( not addon.SpecDetection ) then return end
    if addon.GetDetectedSpec(unit) then return end

    for _, filter in ipairs({ "HELPFUL", "HARMFUL" }) do
        for i = 1, maxAuras do
            local auraData = UnitAura(unit, i, filter);
            if ( not auraData ) then break end
            local spec = addon.SpecDetection[auraData.spellId];
            if spec and auraData.sourceUnit and UnitIsUnit(auraData.sourceUnit, unit) then
                if addon.RecordDetectedSpec(unit, spec) then
                    return true;
                end
            end
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
    addon.detectedSpec = {};
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
