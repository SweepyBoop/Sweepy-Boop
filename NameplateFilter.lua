local _, NS = ...

BoopNameplateFilter = {}
local testMode = false

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
    -- Fire Elemental is guardian which does not show nameplates

    -- Warlock
    ["Pit Lord"] = true,

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
            local class = select(3, UnitClass("arena" .. i))
            return ( class == NS.classId.Hunter ) or ( class == NS.classId.Warlock )
        end
    end
end

local function isPartyPrimaryPet(unitId)
    if UnitIsUnit(unitId, "pet") then
        local class = select(3, UnitClass("player"))
        return ( class == NS.classId.Hunter ) or ( class == NS.classId.Warlock )
    elseif UnitIsUnit(unitId, "partypet1") or UnitIsUnit(unitId, "partypet2") then
        local partyUnitId = "party" .. string.sub(unitId, -1, -1)
        local class = select(3, UnitClass(partyUnitId))
        return ( class == NS.classId.Hunter ) or ( class == NS.classId.Warlock )
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

BoopNameplateFilter.LoadScreen = function (modTable)
    local override = false
    if ( Plater.ZoneInstanceType == "arena" ) then
        override = true
    elseif ( Plater.ZoneInstanceType == "pvp" ) then
        local maxPlayer = select(5, GetInstanceInfo())
        override = ( maxPlayer == 6 )
    end

    if override then
        Plater.db.profile.indicator_anchor.side = Plater.AnchorSides.TOP
        Plater.db.profile.indicator_anchor.x = 0
        Plater.db.profile.indicator_anchor.y = 2
        Plater.db.profile.indicator_scale = 3
    else
        Plater.db.profile.indicator_anchor.side = Plater.AnchorSides.LEFT
        Plater.db.profile.indicator_anchor.x = -2
        Plater.db.profile.indicator_anchor.y = 0
        Plater.db.profile.indicator_scale = 1
    end

    Plater.RefreshDBUpvalues()
    Plater.UpdateAllPlates()
end
