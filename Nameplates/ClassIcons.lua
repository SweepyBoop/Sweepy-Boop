local _, addon = ...;

local PvPUnitClassification = Enum.PvPUnitClassification;

local flagCarrierClassNames = {
    [PvPUnitClassification.FlagCarrierHorde] = "FlagCarrierHorde",
    [PvPUnitClassification.FlagCarrierAlliance] = "FlagCarrierAlliance",
};

local flagCarrierIcons = {
    ["FlagCarrierHorde"] = addon.ICON_ID_FLAG_CARRIER_HORDE,
    ["FlagCarrierAlliance"] = addon.ICON_ID_FLAG_CARRIER_ALLIANCE,
};

local function ShouldShowIcon(unitId) -- "Show healers only" option will be checked in function ShowClassIcon
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
        nameplate.FriendlyClassIcon = addon.CreateClassOrSpecIcon(nameplate, "CENTER", "CENTER", true);
    end

    return nameplate.FriendlyClassIcon;
end


local function GetIconOptions(class)
    local iconID;
    local iconCoords = {0, 1, 0, 1};

    if ( flagCarrierIcons[class] ) then
        iconID = flagCarrierIcons[class];
    elseif ( class == "HEALER" ) then
        iconID = addon.ICON_ID_HEALER;
        iconCoords = addon.ICON_COORDS_HEALER;
    elseif ( class == "PET" ) then
        iconID = addon.ICON_ID_PET;
    else -- For regular classes
        iconID = addon.ICON_ID_CLASSES;
        iconCoords = CLASS_ICON_TCOORDS[class];
    end

    return iconID, iconCoords;
end

local function ShowClassIcon(frame)
    local iconFrame = EnsureClassIcon(frame);
    if ( not iconFrame ) then return end;

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
        if classification and flagCarrierClassNames[classification] then
            class = flagCarrierClassNames[classification];
        end
    end

    -- If the player enabled "Show healers only", hide the icon except for flag carrier
    if SweepyBoop.db.profile.nameplatesFriendly.showHealerOnly then
        if ( class ~= "HEALER" and class ~= "FlagCarrierHorde" and class ~= "FlagCarrierAlliance" ) then
            -- iconFrame.class and iconFrame.lastModified remain unchanged
            iconFrame:Hide();
            return;
        end
    end

    -- Class changed or settings changed, update scale and offset
    if ( class ~= iconFrame.class ) or ( not iconFrame.lastModified ) or ( iconFrame.lastModified ~= SweepyBoop.db.profile.nameplatesFriendly.lastModified ) then
        local iconID, iconCoords = GetIconOptions(class);

        iconFrame.icon:SetTexture(iconID);
        iconFrame.icon:SetTexCoord(unpack(iconCoords));

        local scale = SweepyBoop.db.profile.nameplatesFriendly.classIconScale / 100;
        if ( class == "HEALER" ) then
            scale = scale * 1.25; -- Because healer uses icon coords from a collection of icons, using the same scale would make it seem smaller
        elseif ( class == "PET" ) then
            scale = scale * 0.8; -- smaller icon for pets
        end
        iconFrame:SetScale(scale);

        iconFrame:SetPoint("CENTER", iconFrame:GetParent(), "CENTER", 0, SweepyBoop.db.profile.nameplatesFriendly.classIconOffset);

        iconFrame.class = class;
        iconFrame.lastModified = SweepyBoop.db.profile.nameplatesFriendly.lastModified;
    end

    if UnitIsUnit("target", frame.unit) then
        iconFrame.targetHighlight:Show();
    else
        iconFrame.targetHighlight:Hide();
    end

    iconFrame:Show();
end

addon.HideClassIcon = function(frame)
    local nameplate = frame:GetParent();
    if ( not nameplate ) then return end
    if nameplate.FriendlyClassIcon then
        nameplate.FriendlyClassIcon:Hide();
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
