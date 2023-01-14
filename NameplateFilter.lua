local _, NS = ...

BoopNameplateFilter = {}

local function GetUnitClass(unitId)
    return select(3, UnitClass(unitId))
end

-- Whitelist for non-player units, show nameplate if unit name or NpcID matches
-- Have to use NpcID for unit names with no spaces, since hunters can name their pet Psyfiend, etc.
-- To find the NpcID of a unit, target it and type:
-- /run npcID = select(6, strsplit("-", UnitGUID("target"))); print(npcID)
-- unitFrame.namePlateNpcId is numeric type, so NPC ID index here should be numeric as well
local NameplateWhiteList = {
    -- Priest
    [101398] = true, -- Psyfiend

    -- Shaman: totems to kill instantly
    ["Grounding Totem"] = true,
    ["Spirit Link Totem"] = true,
    ["Skyfury Totem"] = true,
    ["Ancestral Protection Totem"] = true, -- LOL
    ["Capacitor Totem"] = true,
    ["Earthgrab Totem"] = true, -- Roots you out of stealth
    ["Windfury Totem"] = true,
    ["Healing Tide Totem"] = true,
    -- Fire Elemental is guardian type

    -- Warlock
    -- Pit Lord is guardian type

    -- Warrior
    ["War Banner"] = true,
}

local function IsInWhiteList(unitId, npcID)
    NameplateWhiteList["Tremor Totem"] = NS.partyWithFearSpell()
    if ( npcID and NameplateWhiteList[npcID] ) then
        return true
    else
        local name = UnitName(unitId)
        return NameplateWhiteList[name]
    end
end

local function IsPrimaryPetClass(unitId)
    local class = GetUnitClass(unitId)
    return ( class == NS.classId.Hunter ) or ( class == NS.classId.Warlock ) or ( class == NS.classId.Shaman )
end

local function IsArenaPrimaryPet(unitId)
    for i = 1, NS.MAX_ARENA_SIZE do
        if UnitIsUnit(unitId, "arenapet" .. i) then
            return IsPrimaryPetClass("arena" .. i)
        end
    end
end

local function IsPartyPrimaryPet(unitId, partySize)
    -- We're only checking hunter/warlock pets, which excludes mind controlled units (which are considered as "pets")
    if UnitIsUnit(unitId, "pet") then
        return IsPrimaryPetClass("player")
    else
        for i = 1, partySize do
            if UnitIsUnit(unitId, "partypet" .. i) then
                return IsPrimaryPetClass("party" .. i)
            end
        end
    end
end

local function ShouldHideHealthBar(unitId)
    local isArena = IsActiveBattlefieldArena()

    if UnitIsPlayer(unitId) then
        if isArena then
            return UnitIsUnit(unitId, "party1") or UnitIsUnit(unitId, "party2")
        else
            return UnitIsFriend("player", unitId) ~= UnitIsPossessed(unitId)
        end
    else
        if isArena then
            return IsPartyPrimaryPet(unitId, (isArena and 2) or 4)
        else
            return UnitIsFriend("player", unitId) ~= UnitIsPossessed(unitId)
        end
    end
end

local function ArenaNumber(unitFrame, unitId)
    for i = 1, NS.MAX_ARENA_SIZE do
        if UnitIsUnit(unitId, "arena"..i) then
            unitFrame.unitName:SetText(i)
            unitFrame.unitName:SetTextColor(1,1,0) --Yellow
            return true
        end
    end
end

local function ShouldShowNameplate(unitId, npcID)
    -- Don't filter nameplates when outside arena
    if ( not IsActiveBattlefieldArena() ) then return true end

    if UnitIsPlayer(unitId) then
        return true
    else
        if IsPartyPrimaryPet(unitId, 2) or IsArenaPrimaryPet(unitId) or IsInWhiteList(unitId, npcID) then
            return true
        end
    end

    return false
end

-- Hide names for party members and non-players that are not whitelisted
local function UpdateName(unitFrame)
    -- Keep name unchanged when outside arena
    if ( not IsActiveBattlefieldArena() ) then return end

    -- If already hidden, avoid additional checks
    if ( not unitFrame.unitName:IsShown() ) then return end

    -- Already arena numbered, avoid additional checks
    if string.len(unitFrame.unitName:GetText()) == 1 then return end

    local unitId = unitFrame.unit
    if ArenaNumber(unitFrame, unitId) then
        return
    elseif ( not UnitIsPlayer(unitId) ) and ( not IsInWhiteList(unitId, unitFrame.namePlateNpcId) ) then
        unitFrame.unitName:Hide()
    end
end

local ShowCastNpc = {
    [1863] = true, -- Succubus
    [61245] = true, -- Capacitor Totem
}

local function UpdateCastBar(unitFrame)
    if ( not unitFrame.castBar:IsShown() ) then return end

    local hideCast = false
    if ShouldHideHealthBar(unitFrame.unit) then
        hideCast = true
    elseif ( not UnitIsPlayer(unitFrame.unit) ) then
        local npcID = unitFrame.namePlateNpcId -- select(6, strsplit("-", UnitGUID(unitId)))
        if ( not npcID ) or ( not ShowCastNpc[npcID] ) then
            hideCast = true
        end
    end

    if hideCast then
        unitFrame.castBar:UnregisterAllEvents()
        unitFrame.castBar:Hide()
    end
end

local function UpdateVisibility(unitFrame)
    -- Check if visible nameplate should be hidden
    -- Each nameplate needs to be hidden once only, to avoid repeated checks
    if unitFrame:IsShown() and ( not ShouldShowNameplate(unitFrame.unit, unitFrame.namePlateNpcId) ) then
        unitFrame:Hide()
        return true
    end

    -- Hide healthBar of party members and pets, but do not hide the entire frame.
    -- Otherwise class icons will be hidden by its parent unitFrame.
    if unitFrame.healthBar:IsShown() and ShouldHideHealthBar(unitFrame.unit) then
        unitFrame.healthBar:Hide()
        unitFrame.BuffFrame:Hide()
        unitFrame.castBar:UnregisterAllEvents()
        unitFrame.castBar:Hide()
        return true
    end
end

local function UpdateBuffFrame(unitFrame)
    if unitFrame.BuffFrame:IsShown() and ShouldHideHealthBar(unitFrame.unit) then
        unitFrame.BuffFrame:Hide()
    end
end

BoopNameplateFilter.NameplateAdded = function (self, unitId, unitFrame, envTable, modTable)
    -- A hack to not show any buffs on nameplate (in case mage steals buff from me)
    unitFrame.BuffFrame2:Hide()

    -- A hack to hide raid icons (to make room for class icons)
    unitFrame.PlaterRaidTargetFrame:Hide()

    if ( not unitId ) then return end

    if UpdateVisibility(unitFrame) then
        return
    end

    UpdateBuffFrame(unitFrame)
    UpdateCastBar(unitFrame)
    UpdateName(unitFrame)
end

BoopNameplateFilter.NameplateUpdated = function (self, unitId, unitFrame, envTable, modTable)
    -- A hack to not show any buffs on nameplate (in case mage steals buff from me)
    unitFrame.BuffFrame2:Hide()

    -- A hack to hide raid icons (to make room for class icons)
    unitFrame.PlaterRaidTargetFrame:Hide()

    if ( not unitId ) then return end

    if UpdateVisibility(unitFrame) then
        return
    end

    UpdateBuffFrame(unitFrame)
    UpdateCastBar(unitFrame)
    UpdateName(unitFrame)
end

-- Target Border
BoopNameplateBorder = {}

--border options
local borderSize = 2.5
local borderColor = "white"

BoopNameplateBorder.UpdateBorder = function (unitFrame)
    if unitFrame.unit and UnitIsUnit("target", unitFrame.unit) then
        local r, g, b, a = DetailsFramework:ParseColors(borderColor)
        unitFrame.healthBar.TargetBorder:SetVertexColor(r, g, b, a)

        unitFrame.healthBar.TargetBorder:SetBorderSizes(borderSize, borderSize, borderSize, borderSize)
        unitFrame.healthBar.TargetBorder:UpdateSizes()
        unitFrame.healthBar.TargetBorder:Show()
    else
        unitFrame.healthBar.TargetBorder:Hide()
    end
end

BoopNameplateBorder.Constructor = function (self, unitId, unitFrame, envTable)
    if ( not unitFrame.healthBar.TargetBorder ) then
        unitFrame.healthBar.TargetBorder = CreateFrame("frame", nil, unitFrame.healthBar, "NamePlateFullBorderTemplate")
    end
end

BoopNameplateBorder.Destructor = function (self, unitId, unitFrame, envTable)
    if unitFrame.healthBar.TargetBorder then
        unitFrame.healthBar.TargetBorder:Hide()
    end
end



-- Class icons for friendly players
BoopNameplateClassIcon = {}

local function ShouldCreateIcon(unitId)
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

local ClassIconOptions = {
    PlayerSize = 48,
    PetSize = 32,
    Anchor = {
        side = 8,
        x = 0,
        y = 10,
    }
}

local IconPath = "Interface\\AddOns\\aSweepyBoop\\ClassIcons\\flat\\"
local IconPathTarget = "Interface\\AddOns\\aSweepyBoop\\ClassIcons\\warcraftflat\\"

-- Locale-independant class names, e.g., "WARRIOR"
local function GetNamePlateUnitClass(nameplateUnitToken)
    return select(2, UnitClass(nameplateUnitToken))
end

local function HideClassIcon (unitFrame)
    if unitFrame.FriendlyClassIcon then
        unitFrame.FriendlyClassIcon.class = nil
        unitFrame.FriendlyClassIcon.isTarget = nil
        unitFrame.FriendlyClassIcon.isPlayer = nil

        if unitFrame.FriendlyClassIcon:IsShown() then
            unitFrame.FriendlyClassIcon:Hide()
        end
    end
end
BoopNameplateClassIcon.Hide = HideClassIcon

local function UpdateIcon(unitFrame, icon)
    local isPlayer = UnitIsPlayer(unitFrame.unit)
    -- Note that NPCs can also return a class
    local class = ( isPlayer and GetNamePlateUnitClass(unitFrame.unit) ) or "PET"

    local isTarget = UnitIsUnit("target", unitFrame.unit)

    if ( class ~= icon.class ) or ( isTarget ~= icon.isTarget ) then
        local iconPath = ( isTarget and IconPathTarget ) or IconPath
        icon:SetTexture(iconPath .. class)

        if ( isPlayer ~= icon.isPlayer ) then
            local iconSize = ( isPlayer and ClassIconOptions.PlayerSize ) or ClassIconOptions.PetSize
            icon:SetSize(iconSize, iconSize)
        end

        icon.class = class
        icon.isTarget = isTarget
        icon.isPlayer = isPlayer
    end
end

local function EnsureClassIcon(unitFrame)
    if (not unitFrame.FriendlyClassIcon) then
        if ShouldCreateIcon(unitFrame.unit) then
            unitFrame.FriendlyClassIcon = unitFrame:CreateTexture(nil, 'overlay')
            local icon = unitFrame.FriendlyClassIcon
            Plater.SetAnchor (icon, ClassIconOptions.Anchor)
        end
    end
end

BoopNameplateClassIcon.UpdateTexture = function (unitFrame)
    if ( not unitFrame.unit ) then
        HideClassIcon(unitFrame)
    end

    EnsureClassIcon(unitFrame)
    local icon = unitFrame.FriendlyClassIcon
    -- We don't have an icon for this nameplate, skip
    if ( not icon ) then return end

    if ShouldCreateIcon(unitFrame.unit) then
        UpdateIcon(unitFrame, icon)
        icon:Show()
    else
        HideClassIcon(unitFrame)
    end
end
