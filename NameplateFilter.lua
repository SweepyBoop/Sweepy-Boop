local _, NS = ...

BoopNameplateFilter = {};
local testMode = false;

-- Whitelist for non-player units, show nameplate if unit name or NpcID matches
-- Have to use NpcID for unit names with no spaces, since hunters can name their pet Psyfiend, etc.
-- To find the NpcID of a unit, target it and type:
-- /run npcID = select(6, strsplit("-", UnitGUID("target"))); print(npcID);
-- unitFrame.namePlateNpcId is numeric type, so NPC ID index here should be numeric as well
local whiteList = {
    -- DK
    --["Zombie"] = true, -- Reanimation PVP talent, 10% HP, very deadly

    -- Priest
    [101398] = true, -- Psyfiend

    -- Shaman: totems to kill instantly
    ["Grounding Totem"] = true,
    ["Spirit Link Totem"] = true,
    ["Skyfury Totem"] = true,
    ["Ancestral Protection Totem"] = true, -- LOL
    ["Capacitor Totem"] = true,
    ["Earthgrab Totem"] = true, -- Gets you out of stealth
    -- ["Windfury Totem"] = true,
    ["Healing Tide Totem"] = true,
    ["Vesper Totem"] = true, -- One shot

    -- Warrior
    ["War Banner"] = true,

    -- Seed
    ["Regenerating Wildseed"] = true,
};

local function isInWhiteList(unitId, npcID)
    whiteList["Tremor Totem"] = NS.partyWithFearSpell();
    if ( npcID and whiteList[npcID] ) then
        return true;
    else
        local name = UnitName(unitId);
        return whiteList[name];
    end
end

local function isArenaPrimaryPet(unitId)
    local isArenaPet = UnitIsUnit(unitId, "arenapet1") or UnitIsUnit(unitId, "arenapet2") or UnitIsUnit(unitId, "arenapet3");
    if ( not isArenaPet ) then return end
    -- Warlock pet
    if UnitPowerMax(unitId, Enum.PowerType.Energy) == 200 then
        return true;
    end
    -- Hunter pet
    local maxFocus = UnitPowerMax(unitId, Enum.PowerType.Focus);
    if ( maxFocus == 120 ) then -- If a pet has 120 max focus, it's always a primary pet
        return true;
    elseif maxFocus == 100 then -- If a pet has 100 max focus, check if it belongs to a BM hunter
        for i = 1, NS.MAX_ARENA_SIZE do
            if UnitIsUnit(unitId, "arenapet"..i) and ( GetArenaOpponentSpec(i) == NS.specID.BM ) then
                return false;
            end
        end
        
        return true;
    end
end

local function isParty(unitId)
    if testMode then
        return UnitIsFriend(unitId, "player")
    end

    return UnitIsUnit(unitId, "party1") or UnitIsUnit(unitId, "party2");
end

local function shouldShowNameplate(unitId, npcID)
    if UnitIsPlayer(unitId) then
        return true;
    else
        if isArenaPrimaryPet(unitId) or isInWhiteList(unitId, npcID) then
            return true;
        end
    end

    return false;
end

-- Hide names for party members and non-players that are not whitelisted
local function updateName(unitFrame, unitId)
    -- If already hidden, avoid additional checks
    if ( not unitFrame.unitName:IsShown() ) then return end

    if ( not UnitIsPlayer(unitId) ) and ( not isInWhiteList(unitId, unitFrame.namePlateNpcId) ) then
        unitFrame.unitName:Hide();
    end
end

-- Hide buff frame for party members
local function updateBuffFrame(unitFrame, unitId)
    if unitFrame.BuffFrame:IsShown() and isParty(unitId) then
        unitFrame.BuffFrame:Hide();
    end
end

local showCastNpc = {
    [1863] = true, -- Succubus
    [61245] = true, -- Capacitor Totem
};

local function updateCastBar(unitFrame, unitId)
    if ( not unitFrame.castBar:IsShown() ) then return end

    local hideCast = false;
    if isParty(unitId) then
        hideCast = true;
    elseif ( not UnitIsPlayer(unitId) ) then
        local npcID = unitFrame.namePlateNpcId; -- select(6, strsplit("-", UnitGUID(unitId)));
        if ( not npcID ) or ( not showCastNpc[npcID] ) then
            hideCast = true;
        end
    end

    if hideCast then
        unitFrame.castBar:UnregisterAllEvents();
        unitFrame.castBar:Hide();
    end
end

local function updateFrame(unitFrame, unitId)
    if isParty(unitId) then
        -- No health bar, castBar & BuffFrame
        -- (raid marker still shows, and is not scaled with distance like Blizzard default raid markers)
        unitFrame.healthBar:Hide();
        unitFrame.castBar:UnregisterAllEvents();
        unitFrame.castBar:Hide();
        unitFrame.BuffFrame:Hide();
    elseif ( not UnitIsPlayer(unitId) ) then
        local npcID = unitFrame.namePlateNpcId; -- select(6, strsplit("-", UnitGUID(unitId)));
        if ( not npcID ) or ( not showCastNpc[npcID] ) then
            unitFrame.castBar:UnregisterAllEvents();
            unitFrame.castBar:Hide();
        end
    end
end

BoopNameplateFilter.Initialization = function (modTable)
    --insert code here
end

BoopNameplateFilter.NameplateAdded = function (self, unitId, unitFrame, envTable, modTable)
    --insert code here

    -- A hack to not show any buffs on nameplate (in case mage steals buff from me)
    unitFrame.BuffFrame2:Hide();

    if ( not unitId ) then return end
    if ( not IsActiveBattlefieldArena() ) and ( not testMode )  then return end

    -- Check if visible nameplate should be hidden
    -- Each nameplate needs to be hidden once only, to avoid repeated checks
    if unitFrame:IsShown() and ( not shouldShowNameplate(unitId, unitFrame.namePlateNpcId) ) then
        unitFrame:Hide();
        return;
    end

    updateFrame(unitFrame, unitId);
    updateName(unitFrame, unitId);
end

BoopNameplateFilter.NameplateUpdated = function (self, unitId, unitFrame, envTable, modTable)
    --insert code here

    -- A hack to not show any buffs on nameplate (in case mage steals buff from me)
    if unitFrame.BuffFrame2:IsShown() then
        unitFrame.BuffFrame2:Hide();
    end

    if ( not unitId ) then return end
    if ( not IsActiveBattlefieldArena() ) and ( not testMode )  then return end

    updateBuffFrame(unitFrame, unitId);
    updateCastBar(unitFrame, unitId);
    updateName(unitFrame, unitId);
end
