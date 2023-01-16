local _, NS = ...

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
    NameplateWhiteList["Tremor Totem"] = NS.partyWithFearSpell()

    local name = UnitName(unitId)
    if NameplateWhiteList[name] then return true end

    local guid = UnitGUID(unitId)
    local npcID = select(6, strsplit("-", guid))
    if ( npcID and NameplateWhiteList[tonumber(npcID)] ) then
        return true
    end
end

local function GetUnitClass(unitId)
    return select(3, UnitClass(unitId))
end

local function IsArenaPrimaryPet(unitId)
    for i = 1, NS.MAX_ARENA_SIZE do
        if UnitIsUnit(unitId, "arenapet" .. i) then
            local class = GetUnitClass("arena" .. i)
            return ( class == NS.classId.Hunter ) or ( class == NS.classId.Warlock ) or ( class == NS.classId.Shaman )
        end
    end
end

local function IsPartyPrimaryPet(unitId, partySize)
    -- We're only checking hunter/warlock pets, which includes mind controlled units (which are considered as "pets")
    if UnitIsUnit(unitId, "pet") then
        local class = GetUnitClass("player")
        return ( class == NS.classId.Hunter ) or ( class == NS.classId.Warlock ) or ( class == NS.classId.Shaman )
    else
        local partySize = partySize or 2
        for i = 1, partySize do
            if UnitIsUnit(unitId, "partypet" .. i) then
                local partyUnitId = "party" .. i
                local class = GetUnitClass(partyUnitId)
                return ( class == NS.classId.Hunter ) or ( class == NS.classId.Warlock ) or ( class == NS.classId.Shaman )
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
            return UnitIsFriend("player", unitId) ~= UnitIsPossessed(unitId)
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

local IconPath = "Interface\\AddOns\\aSweepyBoop\\ClassIcons\\flat\\"
local IconPathTarget = "Interface\\AddOns\\aSweepyBoop\\ClassIcons\\warcraftflat\\"

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
    if ShouldShowNameplate(frame.unit) then
        frame:Show()
    else
        frame:Hide()
    end
end

local ShowCastNpc = {
    [1863] = true, -- Succubus
    [61245] = true, -- Capacitor Totem
}

local function UpdateCastBar(frame)
    if ( not frame.unit) or ( string.sub(frame.unit, 1, 9) ~= "nameplate" ) then
        return
    end

    local showCastBarEx = false
    if UnitIsPlayer(frame.unit) then
        showCastBarEx = true
    else
        if ( not IsActiveBattlefieldArena() ) then
            showCastBarEx = true
        else
            local guid = UnitGUID(frame.unit)
            local npcID = select(6, strsplit("-", guid))
            showCastBarEx = npcID and ShowCastNpc[npcID]
        end
    end

    showCastBarEx = false

    if ( frame.showCastBarEx == nil ) or ( showCastBarEx ~= frame.showCastBarEx ) then
        if showCastBarEx then
            frame.castBar:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", unit)
            frame.castBarelf:RegisterUnitEvent("UNIT_SPELLCAST_DELAYED", unit)
            frame.castBar:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", unit)
            frame.castBar:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", unit)
            frame.castBar:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", unit)
            frame.castBar:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_START", unit)
            frame.castBar:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_UPDATE", unit)
            frame.castBar:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_STOP", unit)
            frame.castBar:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTIBLE", unit)
            frame.castBar:RegisterUnitEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", unit)
            frame.castBar:RegisterUnitEvent("UNIT_SPELLCAST_START", unit)
            frame.castBar:RegisterUnitEvent("UNIT_SPELLCAST_STOP", unit)
            frame.castBar:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", unit)
            frame.castBar:RegisterEvent("PLAYER_ENTERING_WORLD")
        else
            frame.castBar:UnregisterAllEvents()
        end

        frame.showCastBarEx = showCastBarEx
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

local function HideRaidFrameName(frame)
    -- Check if this is a compact party/raid frame
    for i = 1, 5 do
        if ( frame == _G["CompactPartyFrameMember" .. i] ) then
            frame.name:Hide()
            return true
        end
    end
end

hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
    if HideRaidFrameName(frame) then
        return
    end

    if ( not ShouldUpdateNamePlate(frame) ) then
        return
    end

    UpdateHealthBar(frame)
    UpdateClassIcon(frame)

    if IsActiveBattlefieldArena() then
        -- Put arena numbers
        for i = 1, 3 do
            if UnitIsUnit(frame.unit, "arena" .. i) then
                frame.name:SetText(i)
                frame.name:SetTextColor(1,1,0) --Yellow
                return
            end
        end

        -- Check if name should be hidden
        if ( not IsInWhiteList(frame.unit) ) then
            frame.name:SetText("")
        end

        -- Update cast bar
        UpdateCastBar(frame)
    end
end)

hooksecurefunc("CompactUnitFrame_UpdateVisible", function (frame)
    if ( not ShouldUpdateNamePlate(frame) ) then
        return
    end

    UpdateHealthBar(frame)
end)
