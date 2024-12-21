local _, addon = ...;

-- https://www.wowinterface.com/downloads/info14110-BLPConverter.html
local selectionBorderPrefix = "interface\\unitpowerbaralt\\";
local selectionBorderSuffix = "_circular_frame";
local selectionBorder = {
    [addon.SELECTIONBORDERSTYLE.ARCANE] = selectionBorderPrefix .. "arcane" .. selectionBorderSuffix,
    [addon.SELECTIONBORDERSTYLE.FIRE] = selectionBorderPrefix .. "fire" .. selectionBorderSuffix,
    [addon.SELECTIONBORDERSTYLE.AIR] = selectionBorderPrefix .. "air" .. selectionBorderSuffix,
    [addon.SELECTIONBORDERSTYLE.PLAIN] = "Interface\\AddOns\\SweepyBoop\\ClassIcons\\common\\PlainBorder",
};

local PvPUnitClassification = Enum.PvPUnitClassification;
local flagCarrierIcons = {
    [PvPUnitClassification.FlagCarrierHorde] = addon.flagCarrierHordeIcon,
    [PvPUnitClassification.FlagCarrierAlliance] = addon.flagCarrierAllianceIcon,
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
        nameplate.FriendlyClassIcon = addon.CreateClassOrSpecIcon(nameplate, "CENTER", "CENTER");
    end

    return nameplate.FriendlyClassIcon;
end

-- Make sure icons have about the same padding between border and actual content, otherwise the border texture might look strange (too big or too small)
local ClassIconSize = {
    Player = 64,
    Pet = 48,
};

local function GetIconOptions(class)
    local iconID;
    local iconCoords = {0, 1, 0, 1};

    if ( flagCarrierIcons[class] ) then
        iconID = flagCarrierIcons[class];
    elseif ( class == "HELAER" ) then
        iconID = addon.healerIconID;
        iconCoords = addon.healerIconCoords;
    elseif ( class == "PET" ) then
        iconID = addon.petIconID;
    else -- For regular classes
        iconID = addon.classIconID;
        iconCoords = CLASS_ICON_TCOORDS[class];
    end

    return iconID, iconCoords;
end

local function ShowClassIcon(frame)
    local icon = EnsureClassIcon(frame);
    if ( not icon ) then return end;

    local isPlayer = UnitIsPlayer(frame.unit);
    local class = ( isPlayer and addon.GetUnitClass(frame.unit) ) or "PET";

    -- Show dedicated healer icon
    if SweepyBoop.db.profile.nameplatesFriendly.useHealerIcon then
        -- For player nameplates, check if it's a healer
        if isPlayer and ( UnitGroupRolesAssigned(frame.unit) == "HEALER" ) then
            class = "HEALER";
        end
    end

    -- Show dedicated flag carrier icon (this overwrites the healer icon)
    if SweepyBoop.db.profile.nameplatesFriendly.useFlagCarrierIcon and isPlayer then
        local classification = UnitPvpClassification(frame.unit);
        if classification and flagCarrierIcons[classification] then
            class = flagCarrierIcons[classification];
        end
    end

    if ( icon.class == nil ) or ( class ~= icon.class ) then
        local iconID, iconCoords = GetIconOptions(class);

        icon.icon:SetTexture(iconID);
        icon.icon:SetTexCoord(unpack(iconCoords));

        icon.class = class;
    end

    if UnitIsUnit("target", frame.unit) then
        icon.targetHighlight:Show();
    else
        icon.targetHighlight:Hide();
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
