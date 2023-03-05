local _, NS = ...

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

-- Have to use NpcID because non-US locales can return different names for totems, minions, etc.
-- To find the NpcID of a unit, target it and type:
-- /run npcID = select(6, strsplit("-", UnitGUID("target"))); print(npcID)
local NameplateWhiteList = {
    -- DK
    [106041] = true, -- Reanimation

    -- Priest
    [101398] = true, -- Psyfiend

    -- Shaman: totems to kill instantly
    [5925] = true, -- Grounding Totem
    [53006] = true, -- Spirit Link Totem
    [105427] = true, -- Skyfury Totem
    [104818] = true, -- Ancestral Protection Totem
    [61245] = true, -- Capacitor Totem
    [60561] = true, -- Earthgrab Totem
    [6112] = true, -- Windfury Totem
    [59764] = true, -- Healing Tide Totem
    [95061] = true, -- Greater Fire Elemental
    [61029] = true, -- Primal Fire Elemental

    -- Warlock
    [196111] = true, -- Pit Lord (Guldan's Ambition)

    -- Warrior
    [119052] = true, -- War Banner
}

local function IsInWhiteList(unitId)
    -- Tremor Totem
    NameplateWhiteList[5913] = NS.PartyWithFearSpell();

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
    -- Do not show class icon above the personal resource display
    if UnitIsUnit(unitId, "player") then
        return false;
    end

    local isArena = IsActiveBattlefieldArena();

    if UnitIsPlayer(unitId) then
        if isArena then
            return UnitIsUnit(unitId, "party1") or UnitIsUnit(unitId, "party2");
        else
            local possessedFactor = ( UnitIsPossessed("player") ~= UnitIsPossessed(unitId) );
            -- UnitIsFriend does not consider friendly units in duel
            return UnitCanAttack("player", unitId) == possessedFactor;
        end
    else
        return IsPartyPrimaryPet(unitId, (isArena and 2) or 4);
    end
end

local function EnsureClassIcon(frame)
    local nameplate = frame:GetParent();
    if ( not nameplate ) then return end
    if ( not nameplate.FriendlyClassIcon ) then
        nameplate.FriendlyClassIcon = nameplate:CreateTexture(nil, 'overlay');
        nameplate.FriendlyClassIcon:SetPoint("CENTER", nameplate, "CENTER", 0, 40);
        nameplate.FriendlyClassIcon:SetAlpha(1);
        nameplate.FriendlyClassIcon:SetIgnoreParentAlpha(true);
    end

    return nameplate.FriendlyClassIcon
end

local function HideClassIcon(frame)
    local nameplate = frame:GetParent();
    if ( not nameplate ) then return end
    if nameplate.FriendlyClassIcon then
        nameplate.FriendlyClassIcon:Hide();
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
        frame:Hide();
        ShowClassIcon(frame);
    else
        HideClassIcon(frame);
        frame:Show();
    end
end

local function ShouldShowNameplate(unitId)
    -- Do not hide personal resource display
    if UnitIsUnit(unitId, "player") then
        return true;
    end

    -- When outside arena, show everything hostile
    if ( not IsActiveBattlefieldArena() ) then
        local possessedFactor = ( UnitIsPossessed("player") ~= UnitIsPossessed(unitId) );
        -- UnitIsEnemy will not work here, since it excludes neutral units
        return UnitCanAttack("player", unitId) ~= possessedFactor;
    end

    -- Show arena 1~3
    for i = 1, NS.MAX_ARENA_SIZE do
        if UnitIsUnit(unitId, "arena" .. i) then
            return true;
        end
    end

    -- Show arenapet 1~3 but only important ones
    if IsArenaPrimaryPet(unitId) then
        return true;
    end

    -- Show whitelisted non-player units
    if ( not UnitIsPlayer(unitId) ) and IsInWhiteList(unitId) then
        -- Reverse if one unit is possessed and the other is not
        local possessedFactor = ( UnitIsPossessed("player") ~= UnitIsPossessed(unitId) );
        return UnitIsEnemy("player", unitId) ~= possessedFactor;
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
        local instanceType = select(2, IsInInstance());
        if restricted[instanceType] then
            -- In restricted instance, should skip all the nameplate logic
            -- But if there is a class icon showing, hide it
            HideClassIcon(frame);
            return false;
        end

        return true;
    end
end

function SweepyBoop:SetupNameplateModules()
    hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
        if frame:IsForbidden() then
            return;
        end

        if ( not ShouldUpdateNamePlate(frame) ) then
            return;
        end

        -- Class icon mod will hide/show healthBar when showing/hiding class icons
        UpdateClassIcon(frame)
        -- Nameplate filter mod could overwrite the healthBar visibility afterwards (need to ensure healthBar and class icon do not show at the same time)
        UpdateHealthBar(frame)

        if IsActiveBattlefieldArena() then
            -- Put arena numbers
            if self.db.profile.arenaNumbersEnabled then
                for i = 1, 3 do
                    if UnitIsUnit(frame.unit, "arena" .. i) then
                        frame.name:SetText(i)
                        frame.name:SetTextColor(1,1,0) --Yellow
                        return
                    end
                end
            end

            -- Check if name should be hidden
            if self.db.profile.nameplateFilterEnabled then
                if ( not IsInWhiteList(frame.unit) ) then
                    frame.name:SetText("")
                end
            end
        end
    end)

    hooksecurefunc("CompactUnitFrame_UpdateVisible", function (frame)
        if ( not self.db.profile.nameplateFilterEnabled ) then return end

        if frame:IsForbidden() then
            return;
        end

        if ( not ShouldUpdateNamePlate(frame) ) then
            return
        end

        UpdateHealthBar(frame)
    end)
end
