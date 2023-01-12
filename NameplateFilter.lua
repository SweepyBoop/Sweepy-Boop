local _, NS = ...

BoopNameplateFilter = {}
local testMode = false

local cachedClassIds = {}

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
frame:SetScript("OnEvent", function ()
    cachedClassIds = {}
end)

local function getUnitClass(unitId)
    if ( not cachedClassIds[unitId] ) then
        cachedClassIds[unitId] = select(3, UnitClass(unitId))
    end

    return cachedClassIds[unitId]
end

-- Whitelist for non-player units, show nameplate if unit name or NpcID matches
-- Have to use NpcID for unit names with no spaces, since hunters can name their pet Psyfiend, etc.
-- To find the NpcID of a unit, target it and type:
-- /run npcID = select(6, strsplit("-", UnitGUID("target"))); print(npcID)
-- unitFrame.namePlateNpcId is numeric type, so NPC ID index here should be numeric as well
local whiteList = {
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

local function isInWhiteList(unitId, npcID)
    whiteList["Tremor Totem"] = NS.partyWithFearSpell()
    if ( npcID and whiteList[npcID] ) then
        return true
    else
        local name = UnitName(unitId)
        return whiteList[name]
    end
end

local function isArenaPrimaryPet(unitId)
    for i = 1, NS.MAX_ARENA_SIZE do
        if UnitIsUnit(unitId, "arenapet" .. i) then
            local class = getUnitClass("arena" .. i)
            return ( class == NS.classId.Hunter ) or ( class == NS.classId.Warlock )
        end
    end
end

local partyPetSize = 2

local function isPartyPrimaryPet(unitId)
    -- We're only checking hunter/warlock pets, which includes mind controlled units (which are considered as "pets")
    if UnitIsUnit(unitId, "pet") then
        local class = getUnitClass("player")
        return ( class == NS.classId.Hunter ) or ( class == NS.classId.Warlock )
    else
        for i = 1, partyPetSize do
            if UnitIsUnit(unitId, "partypet" .. i) then
                local partyUnitId = "party" .. i
                local class = getUnitClass(partyUnitId)
                return ( class == NS.classId.Hunter ) or ( class == NS.classId.Warlock )
            end
        end
    end
end

local function isPartyOrPartyPet(unitId)
    if testMode then
        return UnitIsFriend(unitId, "player")
    end

    if UnitIsUnit(unitId, "party1") or UnitIsUnit(unitId, "party2") then
        return true
    else
        return isPartyPrimaryPet(unitId)
    end
end

local function arenaNumber(unitFrame, unitId)
    for i = 1, NS.MAX_ARENA_SIZE do
        if UnitIsUnit(unitId, "arena"..i) then
            unitFrame.unitName:SetText(i)
            unitFrame.unitName:SetTextColor(1,1,0) --Yellow
            return true
        end
    end
end

local function shouldShowNameplate(unitId, npcID)
    if UnitIsPlayer(unitId) then
        return true
    else
        if isPartyPrimaryPet(unitId) or isArenaPrimaryPet(unitId) or isInWhiteList(unitId, npcID) then
            return true
        end
    end

    return false
end

-- Hide names for party members and non-players that are not whitelisted
local function updateName(unitFrame, unitId)
    -- If already hidden, avoid additional checks
    if ( not unitFrame.unitName:IsShown() ) then return end

    -- Already arena numbered
    if string.len(unitFrame.unitName:GetText()) == 1 then return end

    if arenaNumber(unitFrame, unitId) then
        return true
    elseif isPartyOrPartyPet(unitId) then
        unitFrame.unitName:Hide()
    elseif ( not UnitIsPlayer(unitId) ) and ( not isInWhiteList(unitId, unitFrame.namePlateNpcId) ) then
        unitFrame.unitName:Hide()
    end
end

-- Hide buff frame for party members
local function updateBuffFrame(unitFrame, unitId)
    if unitFrame.BuffFrame:IsShown() and isPartyOrPartyPet(unitId) then
        unitFrame.BuffFrame:Hide()
    end
end

local showCastNpc = {
    [1863] = true, -- Succubus
    [61245] = true, -- Capacitor Totem
}

local function updateCastBar(unitFrame, unitId)
    if ( not unitFrame.castBar:IsShown() ) then return end

    local hideCast = false
    if isPartyOrPartyPet(unitId) then
        hideCast = true
    elseif ( not UnitIsPlayer(unitId) ) then
        local npcID = unitFrame.namePlateNpcId -- select(6, strsplit("-", UnitGUID(unitId)))
        if ( not npcID ) or ( not showCastNpc[npcID] ) then
            hideCast = true
        end
    end

    if hideCast then
        unitFrame.castBar:UnregisterAllEvents()
        unitFrame.castBar:Hide()
    end
end

local function updateFrame(unitFrame, unitId)
    if isPartyOrPartyPet(unitId) then
        -- Smaller party nameplates with no cast bar & buff frame
        Plater.SetNameplateSize(unitFrame, 35, 13)
        unitFrame.castBar:UnregisterAllEvents()
        unitFrame.castBar:Hide()
        unitFrame.BuffFrame:Hide()
    elseif ( not UnitIsPlayer(unitId) ) then
        local npcID = unitFrame.namePlateNpcId -- select(6, strsplit("-", UnitGUID(unitId)))
        if ( not npcID ) or ( not showCastNpc[npcID] ) then
            unitFrame.castBar:UnregisterAllEvents()
            unitFrame.castBar:Hide()
        end
    end
end

local function updateWidth(unitFrame, unitId)
    local width = unitFrame:GetSize()
    if ( width < 50 ) then
        return
    end

    if isPartyOrPartyPet(unitId) then
        Plater.SetNameplateSize(unitFrame, 35, 13)
    end
end

BoopNameplateFilter.NameplateAdded = function (self, unitId, unitFrame, envTable, modTable)
    --insert code here

    -- A hack to not show any buffs on nameplate (in case mage steals buff from me)
    unitFrame.BuffFrame2:Hide()

    if ( not unitId ) then return end
    if ( not IsActiveBattlefieldArena() ) and ( not testMode )  then return end

    -- Check if visible nameplate should be hidden
    -- Each nameplate needs to be hidden once only, to avoid repeated checks
    if unitFrame:IsShown() and ( not shouldShowNameplate(unitId, unitFrame.namePlateNpcId) ) then
        unitFrame:Hide()
        return
    end

    updateFrame(unitFrame, unitId)
    updateName(unitFrame, unitId)
end

BoopNameplateFilter.NameplateUpdated = function (self, unitId, unitFrame, envTable, modTable)
    --insert code here

    -- A hack to not show any buffs on nameplate (in case mage steals buff from me)
    if unitFrame.BuffFrame2:IsShown() then
        unitFrame.BuffFrame2:Hide()
    end

    if ( not unitId ) then return end
    if ( not IsActiveBattlefieldArena() ) and ( not testMode )  then return end

    -- A hack to hide raid icons (to make room for class icons)
    if unitFrame.PlaterRaidTargetFrame:IsShown() then
        unitFrame.PlaterRaidTargetFrame:Hide()
    end

    updateWidth(unitFrame, unitId)
    updateBuffFrame(unitFrame, unitId)
    updateCastBar(unitFrame, unitId)
    updateName(unitFrame, unitId)
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

local ClassIconOptions = {
    PlayerSize = 48,
    PetSize = 28,
    Anchor = {
        side = 8,
        x = 0,
        y = 10,
    }
}

local function EnsureClassIcon(unitFrame)
    if (not unitFrame.FriendlyClassIcon) then
        if isPartyOrPartyPet(unitFrame.unit) then
            unitFrame.FriendlyClassIcon = unitFrame:CreateTexture(nil, 'overlay')
            local icon = unitFrame.FriendlyClassIcon

            if UnitIsPlayer(unitFrame.unit) then
                local class =  select(2, UnitClass(unitFrame.unit))
                icon:SetTexture ([[Interface\TargetingFrame\UI-CLASSES-CIRCLES]])
                icon:SetTexCoord (unpack (CLASS_ICON_TCOORDS [class]))
                icon:SetSize (ClassIconOptions.PlayerSize, ClassIconOptions.PlayerSize)
            else
                icon:SetTexture ([[Interface\Icons\inv_stbernarddogpet]])
                icon:SetTexCoord (0, 1, 0, 1)
                icon:SetSize (ClassIconOptions.PetSize, ClassIconOptions.PetSize)
            end

            Plater.SetAnchor (icon, ClassIconOptions.Anchor)
        end
    end
end

BoopNameplateClassIcon.UpdateTexture = function (unitFrame)
    EnsureClassIcon(unitFrame)
    local icon = unitFrame.FriendlyClassIcon

    if isPartyOrPartyPet(unitFrame.unit) then
        if UnitIsPlayer(unitFrame.unit) then
            local class = select(2, UnitClass(unitFrame.unit))
            icon:SetTexture ([[Interface\TargetingFrame\UI-CLASSES-CIRCLES]])
            icon:SetTexCoord (unpack (CLASS_ICON_TCOORDS [class]))
            icon:SetSize (ClassIconOptions.PlayerSize, ClassIconOptions.PlayerSize)
        else
            icon:SetTexture ([[Interface\Icons\inv_stbernarddogpet]])
            icon:SetTexCoord (0, 1, 0, 1)
            icon:SetSize (ClassIconOptions.PetSize, ClassIconOptions.PetSize)
        end

        icon:Show()
    else
        icon:Hide()
    end
end

BoopNameplateClassIcon.Hide = function (unitFrame)
    if unitFrame.FriendlyClassIcon then
        unitFrame.FriendlyClassIcon:Hide()
    end
end

BoopNameplateClassIcon.Constructor = function (self, unitId, unitFrame, envTable)
    EnsureClassIcon(unitFrame)
end

