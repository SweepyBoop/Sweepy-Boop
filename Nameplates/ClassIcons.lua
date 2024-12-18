local _, addon = ...;

-- https://www.wowinterface.com/downloads/info14110-BLPConverter.html
local selectionBorderPrefix = "interface\\unitpowerbaralt\\";
local selectionBorderSuffix = "_circular_frame";
local selectionBorder = {
    [addon.SELECTIONBORDERSTYLE.ARCANE] = selectionBorderPrefix .. "arcane" .. selectionBorderSuffix,
    [addon.SELECTIONBORDERSTYLE.FIRE] = selectionBorderPrefix .. "fire" .. selectionBorderSuffix,
    [addon.SELECTIONBORDERSTYLE.AIR] = selectionBorderPrefix .. "air" .. selectionBorderSuffix,
    [addon.SELECTIONBORDERSTYLE.MECHANICAL] = selectionBorderPrefix .. "mechanical" .. selectionBorderSuffix,
    [addon.SELECTIONBORDERSTYLE.PLAIN] = "Interface\\AddOns\\SweepyBoop\\ClassIcons\\common\\PlainBorder",
};

local PvPUnitClassification = Enum.PvPUnitClassification;
local flagCarrierClassNames = {
    [PvPUnitClassification.FlagCarrierHorde] = "FlagCarrierHorde",
    [PvPUnitClassification.FlagCarrierAlliance] = "FlagCarrierAlliance",
};

local petIconCount = 4;

local function ShouldShowIcon(unitId)
    -- Do not show class icon above the personal resource display
    if UnitIsUnit(unitId, "player") then
        return false;
    end

    local isArena = IsActiveBattlefieldArena();

    if UnitIsPlayer(unitId) then
        if isArena then
            return UnitIsUnit(unitId, "party1") or UnitIsUnit(unitId, "party2");
        else
            return ( not addon.UnitIsHostile(unitId) );
        end
    else
        return addon.IsPartyPrimaryPet(unitId, (isArena and 2) or 4);
    end
end

local function EnsureClassIcon(frame)
    local nameplate = frame:GetParent();
    if ( not nameplate ) then return end
    if ( not nameplate.FriendlyClassIcon ) then
        nameplate.FriendlyClassIcon = nameplate:CreateTexture(nil, 'overlay', nil, 6);
        -- Can be updated if lastModified falls behind db.profile
        nameplate.FriendlyClassIcon:SetPoint("CENTER", nameplate, "CENTER", 0, SweepyBoop.db.profile.nameplatesFriendly.classIconOffset);
        nameplate.FriendlyClassIcon:SetAlpha(1);
        nameplate.FriendlyClassIcon:SetIgnoreParentAlpha(true);

        -- Can we leverage SetTexCoord to get round icons without making them

        nameplate.FriendlyClassIcon.border = nameplate:CreateTexture(nil, "overlay", nil, 7); -- higher subLevel to appear on top of the icon
        nameplate.FriendlyClassIcon.border:SetPoint("CENTER", nameplate.FriendlyClassIcon);
        nameplate.FriendlyClassIcon.border:SetTexture(selectionBorder[SweepyBoop.db.profile.nameplatesFriendly.classIconSelectionBorderStyle]);

        -- Can be updated if lastModified falls behind db.profile
        local scale = SweepyBoop.db.profile.nameplatesFriendly.classIconScale / 100;
        nameplate.FriendlyClassIcon:SetScale(scale);
        nameplate.FriendlyClassIcon.border:SetScale(scale);

        nameplate.FriendlyClassIcon.lastModified = SweepyBoop.db.profile.nameplatesFriendly.lastModified;
    end

    -- Compare the timestamp to see if any settings have changed
    if (nameplate.FriendlyClassIcon.lastModified ~= SweepyBoop.db.profile.nameplatesFriendly.lastModified) then
        nameplate.FriendlyClassIcon:SetPoint("CENTER", nameplate, "CENTER", 0, SweepyBoop.db.profile.nameplatesFriendly.classIconOffset);
        local scale = SweepyBoop.db.profile.nameplatesFriendly.classIconScale / 100;
        nameplate.FriendlyClassIcon:SetScale(scale);
        nameplate.FriendlyClassIcon.border:SetScale(scale);
        nameplate.FriendlyClassIcon.border:SetTexture(selectionBorder[SweepyBoop.db.profile.nameplatesFriendly.classIconSelectionBorderStyle]);

        -- Invalidate class as well, since icon style might has changed
        nameplate.FriendlyClassIcon.class = nil;
        nameplate.FriendlyClassIcon.iconSize = nil;

        nameplate.FriendlyClassIcon.lastModified = SweepyBoop.db.profile.nameplatesFriendly.lastModified;
    end

    return nameplate.FriendlyClassIcon;
end

-- Make sure icons have about the same padding between border and actual content, otherwise the border texture might look strange (too big or too small)
local ClassIconSize = {
    Player = 64,
    Pet = 48,
};

local function GetIconOptions(class, useCommonIconPath)
    local path, iconSize;

    if ( useCommonIconPath ) then
        path = "Interface\\AddOns\\SweepyBoop\\ClassIcons\\common";
    else
        path = "Interface\\AddOns\\SweepyBoop\\ClassIcons\\";
        if SweepyBoop.db.profile.nameplatesFriendly.classIconStyle == addon.CLASSICONSTYLE.FLAT then
            path = path .. "flat";
        else
            path = path .. "round";
        end
    end

    iconSize = (class == "PET" and ClassIconSize.Pet) or ClassIconSize.Player;

    return path .. "\\", iconSize;
end

local function ShowClassIcon(frame)
    local icon = EnsureClassIcon(frame);
    if ( not icon ) then return end;

    local isPlayer = UnitIsPlayer(frame.unit);
    local class = ( isPlayer and addon.GetUnitClass(frame.unit) ) or "PET";
    local useCommonIconPath = ( class == "PET" ); -- use common icon path if not a regular class, e.g., HEALER, PET, FlagCarrierXXX

    -- Show dedicated healer icon
    if SweepyBoop.db.profile.nameplatesFriendly.useHealerIcon then
        -- For player nameplates, check if it's a healer
        if isPlayer and ( UnitGroupRolesAssigned(frame.unit) == "HEALER" ) then
            class = "HEALER";
            useCommonIconPath = true;
        end
    end

    -- Show dedicated flag carrier icon (this overwrites the healer icon)
    if SweepyBoop.db.profile.nameplatesFriendly.useFlagCarrierIcon and isPlayer then
        local classification = UnitPvpClassification(frame.unit);
        if classification and flagCarrierClassNames[classification] then
            class = flagCarrierClassNames[classification];
            useCommonIconPath = true;
        end
    end

    if ( icon.class == nil ) or ( class ~= icon.class ) then
        local iconPath, iconSize = GetIconOptions(class, useCommonIconPath);
        local iconFile = iconPath .. class;
        if ( not isPlayer ) then -- Pick a pet icon based on NpcID
            if ( SweepyBoop.db.profile.nameplatesFriendly.petIconStyle == addon.PETICONSTYLE.CATS ) then -- Append a random index for cat pictures...
                local npcID = select(6, strsplit("-", UnitGUID(frame.unit)));
                local petNumber = math.fmod(tonumber(npcID), petIconCount);
                iconFile = iconFile .. petNumber;
            else
                iconFile = iconPath .. "MendPet"; -- Mend Pet
            end
        end
        icon:SetTexture(iconFile);

        if ( icon.iconSize == nil ) or ( iconSize ~= icon.iconSize ) then
            icon:SetSize(iconSize, iconSize);
            icon.border:SetSize(iconSize, iconSize);
        end

        icon.class = class;
        icon.iconSize = iconSize;
    end

    if UnitIsUnit("target", frame.unit) then
        icon.border:Show();
    else
        icon.border:Hide();
    end

    icon:Show();
end

addon.HideClassIcon = function(frame)
    local nameplate = frame:GetParent();
    if ( not nameplate ) then return end
    if nameplate.FriendlyClassIcon then
        nameplate.FriendlyClassIcon:Hide();
        if nameplate.FriendlyClassIcon.border then
            nameplate.FriendlyClassIcon.border:Hide();
        end
    end
end

addon.UpdateClassIcon = function(frame)
    if ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled ) then
        addon.HideClassIcon(frame);
        return;
    end

    if SweepyBoop.db.profile.nameplatesFriendly.hideOutsidePvP and ( UnitInBattleground("player") == nil ) and ( not IsActiveBattlefieldArena() )  then
        -- Hide outside arenas and battlegrounds
        addon.HideClassIcon(frame);
        frame:Hide();
        return;
    end

    if ShouldShowIcon(frame.unit) then
        frame:Hide();
        ShowClassIcon(frame);
    else
        addon.HideClassIcon(frame);
        frame:Show();
    end
end
