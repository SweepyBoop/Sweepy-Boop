local _, NS = ...

local UnitName = UnitName;
local UnitGUID = UnitGUID;
local UnitIsUnit = UnitIsUnit;
local IsActiveBattlefieldArena = IsActiveBattlefieldArena;
local UnitIsPlayer = UnitIsPlayer;
local UnitIsPossessed = UnitIsPossessed;
local UnitIsFriend = UnitIsFriend;
local UnitClass = UnitClass;
local UnitCanAttack = UnitCanAttack;
local UnitIsEnemy = UnitIsEnemy;
local IsInInstance = IsInInstance;
local strsplit = strsplit;
local CompactPartyFrame = CompactPartyFrame;
local hooksecurefunc = hooksecurefunc;

-- Have to use NpcID for unit names with no spaces, since hunters can name their pet Psyfiend, etc.
-- To find the NpcID of a unit, target it and type:
-- /run npcID = select(6, strsplit("-", UnitGUID("target"))); print(npcID)
local NameplateWhiteList = {
    -- Priest
    [101398] = true, -- Psyfiend (have to use NpcID since player pets can have this name)

    -- Shaman: totems to kill instantly
    ["Grounding Totem"] = true,
    ["Spirit Link Totem"] = true,
    ["Skyfury Totem"] = true,
    ["Ancestral Protection Totem"] = true, -- LOL
    ["Capacitor Totem"] = true,
    ["Earthgrab Totem"] = true, -- Roots you out of stealth
    ["Windfury Totem"] = true,
    ["Healing Tide Totem"] = true,
    ["Greater Fire Elemental"] = true, -- Guardian

    -- Warlock
    ["Pit Lord"] = true, -- Guardian

    -- Warrior
    ["War Banner"] = true,
}

local function IsInWhiteList(unitId)
    NameplateWhiteList["Tremor Totem"] = NS.PartyWithFearSpell();

    local name = UnitName(unitId)
    if NameplateWhiteList[name] then return true end

    local guid = UnitGUID(unitId)
    local npcID = select(6, strsplit("-", guid))
    if ( npcID and NameplateWhiteList[tonumber(npcID)] ) then
        return true
    end
end

local function GetUnitClass(unitId)
    return select(2, UnitClass(unitId))
end

local function IsArenaPrimaryPet(unitId)
    for i = 1, NS.MAX_ARENA_SIZE do
        if UnitIsUnit(unitId, "arenapet" .. i) then
            local class = GetUnitClass("arena" .. i)
            return ( class == "HUNTER" ) or ( class == "WARLOCK" ) or ( class == "SHAMAN" and NS.IsShamanPrimaryPet(unitId) );
        end
    end
end

local function IsPartyPrimaryPet(unitId, partySize)
    -- We're only checking hunter/warlock pets, which includes mind controlled units (which are considered as "pets")
    if UnitIsUnit(unitId, "pet") then
        local class = GetUnitClass("player")
        return ( class == "HUNTER" ) or ( class == "WARLOCK" ) or ( class == "SHAMAN" and NS.IsShamanPrimaryPet(unitId) );
    else
        local partySize = partySize or 2
        for i = 1, partySize do
            if UnitIsUnit(unitId, "partypet" .. i) then
                local partyUnitId = "party" .. i
                local class = GetUnitClass(partyUnitId)
                return ( class == "HUNTER" ) or ( class == "WARLOCK" ) or ( class == "SHAMAN" and NS.IsShamanPrimaryPet(unitId) );
            end
        end
    end
end

local function ShouldMakeIcon(unitId)
    local isArena = IsActiveBattlefieldArena()

    if UnitIsPlayer(unitId) then
        if isArena then
            return UnitIsUnit(unitId, "party1") or UnitIsUnit(unitId, "party2")
        else
            local possessedFactor = ( UnitIsPossessed("player") ~= UnitIsPossessed(unitId) )
            return UnitIsFriend("player", unitId) ~= possessedFactor
        end
    else
        return IsPartyPrimaryPet(unitId, (isArena and 2) or 4)
    end
end

local function EnsureClassIcon(frame)
    local nameplate = frame:GetParent()
    if ( not nameplate ) then return end
    if ( not nameplate.FriendlyClassIcon ) then
        nameplate.FriendlyClassIcon = nameplate:CreateTexture(nil, 'overlay')
        nameplate.FriendlyClassIcon:SetPoint("CENTER", nameplate, "CENTER", 0, 40)
    end

    return nameplate.FriendlyClassIcon
end

local function HideClassIcon(frame)
    local nameplate = frame:GetParent()
    if ( not nameplate ) then return end
    if nameplate.FriendlyClassIcon then
        nameplate.FriendlyClassIcon:Hide()
    end
end

local IconPath = "Interface\\AddOns\\SweepyBoop\\ClassIcons\\flat\\"
local IconPathTarget = "Interface\\AddOns\\SweepyBoop\\ClassIcons\\warcraftflat\\"

local ClassIconOptions = {
    PlayerSize = 48,
    PetSize = 32,
}

local function GetUnitClassName(unitId)
    return select(2, UnitClass(unitId))
end

local iconCount = 4

local function ShowClassIcon(frame)
    local icon = EnsureClassIcon(frame)
    if ( not icon ) then return end

    local isPlayer = UnitIsPlayer(frame.unit)
    local class = ( isPlayer and GetUnitClassName(frame.unit) ) or "PET"
    local isTarget = UnitIsUnit("target", frame.unit)

    if ( icon.class == nil ) or ( class ~= icon.class ) or ( icon.isTarget == nil ) or ( isTarget ~= icon.isTarget ) then
        local iconPath = ( isTarget and IconPathTarget ) or IconPath
        local iconFile = iconPath .. class
        if ( not isPlayer ) then -- Pick a pet icon based on NpcID
            local npcID = select(6, strsplit("-", UnitGUID(frame.unit)))
            local petNumber = math.fmod(tonumber(npcID), iconCount)
            iconFile = iconFile .. petNumber
        end
        icon:SetTexture(iconFile)

        if ( icon.isPlayer == nil ) or ( isPlayer ~= icon.isPlayer ) then
            local iconSize = ( isPlayer and ClassIconOptions.PlayerSize ) or ClassIconOptions.PetSize
            icon:SetSize(iconSize, iconSize)
        end

        icon.class = class
        icon.isTarget = isTarget
        icon.isPlayer = isPlayer
    end

    icon:Show()
end

local function UpdateClassIcon(frame)
    if ( not SweepyBoop.db.profile.classIconsEnabled ) then return end

    if ShouldMakeIcon(frame.unit) then
        ShowClassIcon(frame)
    else
        HideClassIcon(frame)
    end
end

local function ShouldShowNameplate(unitId)
    -- When outside arena, show everything hostile
    if ( not IsActiveBattlefieldArena() ) then
        local possessedFactor = ( UnitIsPossessed("player") ~= UnitIsPossessed(unitId) )
        -- UnitIsEnemy will not work here, since it excludes neutral units
        return UnitCanAttack("player", unitId) ~= possessedFactor
    end

    -- Show arena 1~3
    for i = 1, NS.MAX_ARENA_SIZE do
        if UnitIsUnit(unitId, "arena" .. i) then
            return true
        end
    end

    -- Show arenapet 1~3 but only important ones
    if IsArenaPrimaryPet(unitId) then
        return true
    end

    -- Show whitelisted non-player units
    if ( not UnitIsPlayer(unitId) ) and IsInWhiteList(unitId) then
        -- Reverse if one unit is possessed and the other is not
        local possessedFactor = ( UnitIsPossessed("player") ~= UnitIsPossessed(unitId) )
        return UnitIsEnemy("player", unitId) ~= possessedFactor
    end
end

local function UpdateHealthBar(frame)
    if ( not SweepyBoop.db.profile.nameplateFilterEnabled ) then return end

    if ShouldShowNameplate(frame.unit) then
        frame:Show()
    else
        frame:Hide()
    end
end

-- Protected nameplates in dungeons and raids
local restricted = {
	party = true,
	raid = true,
}

local function ShouldUpdateNamePlate(frame)
    if frame.unit and ( string.sub(frame.unit, 1, 9) == "nameplate" ) then
        -- Check if in restricted areas
        local instanceType = select(2, IsInInstance())
        return ( not restricted[instanceType] )
    end
end

hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
    if frame:IsForbidden() then
        return;
    end

    if ( not ShouldUpdateNamePlate(frame) ) then
        return
    end

    UpdateHealthBar(frame)
    UpdateClassIcon(frame)

    if IsActiveBattlefieldArena() then
        -- Put arena numbers
        if SweepyBoop.db.profile.arenaNumbersEnabled then
            for i = 1, 3 do
                if UnitIsUnit(frame.unit, "arena" .. i) then
                    frame.name:SetText(i)
                    frame.name:SetTextColor(1,1,0) --Yellow
                    return
                end
            end
        end

        -- Check if name should be hidden
        if SweepyBoop.db.profile.nameplateFilterEnabled then
            if ( not IsInWhiteList(frame.unit) ) then
                frame.name:SetText("")
            end
        end
    end
end)

hooksecurefunc("CompactUnitFrame_UpdateVisible", function (frame)
    if ( not SweepyBoop.db.profile.classIconsEnabled ) then return end

    if frame:IsForbidden() then
        return;
    end

    if ( not ShouldUpdateNamePlate(frame) ) then
        return
    end

    UpdateHealthBar(frame)
end)
