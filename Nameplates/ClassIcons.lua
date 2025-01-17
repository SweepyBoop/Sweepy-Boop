local _, addon = ...;

local PvPUnitClassification = Enum.PvPUnitClassification;
local specialIconScaleFactor = 1.25;

local flagCarrierIcons = {
    [PvPUnitClassification.FlagCarrierHorde] = addon.ICON_ID_FLAG_CARRIER_HORDE,
    [PvPUnitClassification.FlagCarrierAlliance] = addon.ICON_ID_FLAG_CARRIER_ALLIANCE,
    [PvPUnitClassification.FlagCarrierNeutral] = addon.ICON_ID_FLAG_CARRIER_NEUTRAL,
};

local function EnsureIcon(nameplate)
    if ( not nameplate.classIconContainer.FriendlyClassIcon ) then
        nameplate.classIconContainer.FriendlyClassIcon = addon.CreateClassOrSpecIcon(nameplate, "CENTER", "CENTER", true);
        nameplate.classIconContainer.FriendlyClassIcon:Hide();
    end

    return nameplate.classIconContainer.FriendlyClassIcon;
end

local function EnsureArrow(nameplate)
    if ( not nameplate.classIconContainer.FriendlyClassArrow ) then
        nameplate.classIconContainer.FriendlyClassArrow = addon.CreateClassColorArrowFrame(nameplate);
        nameplate.classIconContainer.FriendlyClassArrow:Hide();
    end

    return nameplate.classIconContainer.FriendlyClassArrow;
end

local function GetIconOptions(class, pvpClassification, roleAssigned)
    local iconID;
    local iconCoords = {0, 1, 0, 1};
    local scaleFactor = 1; -- 1.25 for healers and flag carriers

    local config = SweepyBoop.db.profile.nameplatesFriendly;
    -- Check regular class, then healer, then flag carrier; latter overwrites the former
    iconID = addon.ICON_ID_CLASSES;
    iconCoords = CLASS_ICON_TCOORDS[class];

    if ( roleAssigned == "HEALER" ) and config.useHealerIcon then
        if config.showHealerOnly then -- can be overwritten by flag carrier
            iconID = nil;
        else
            iconID = addon.ICON_ID_HEALER;
            iconCoords = addon.ICON_COORDS_HEALER;
            scaleFactor = specialIconScaleFactor;
        end
    end

    if ( flagCarrierIcons[pvpClassification] ) and config.useFlagCarrierIcon then
        iconID = flagCarrierIcons[pvpClassification];
        iconCoords = {0, 1, 0, 1};
        scaleFactor = specialIconScaleFactor;
    end

    return iconID, iconCoords, scaleFactor;
end

addon.ShowClassIcon = function (nameplate)
    if ( not nameplate.classIconContainer ) then return end
    local classIconContainer = nameplate.classIconContainer;

    local style = SweepyBoop.db.profile.nameplatesFriendly.classIconStyle;
    if classIconContainer.FriendlyClassIcon then
        classIconContainer.FriendlyClassIcon:SetShown(style == addon.CLASS_ICON_STYLE.ICON or classIconContainer.isSpecialIcon);
    end
    if classIconContainer.FriendlyClassArrow then
        classIconContainer.FriendlyClassArrow:SetShown(style == addon.CLASS_ICON_STYLE.ARROW and ( not classIconContainer.isSpecialIcon ));
    end
end

addon.HideClassIcon = function(nameplate)
    if ( not nameplate.classIconContainer ) then return end

    if nameplate.classIconContainer.FriendlyClassIcon then
        nameplate.classIconContainer.FriendlyClassIcon:Hide();
    end
    if nameplate.classIconContainer.FriendlyClassArrow then
        nameplate.classIconContainer.FriendlyClassArrow:Hide();
    end
end

addon.UpdateClassIconTargetHighlight = function (nameplate, frame)
    local isTarget = UnitIsUnit(frame.unit, "target");
    if nameplate.classIconContainer then
        if nameplate.classIconContainer.FriendlyClassIcon then
            nameplate.classIconContainer.FriendlyClassIcon.targetHighlight:SetShown(isTarget);
        end
        if nameplate.classIconContainer.FriendlyClassArrow then
            nameplate.classIconContainer.FriendlyClassArrow.targetHighlight:SetShown(isTarget);
        end
    end
end

-- For FC icon, listen to whatever triggers CompactUnitFrame_UpdatePvPClassificationIndicator
addon.UpdateClassIcon = function(nameplate, frame)
    -- Full update if class, PvPClassification, roleAssigned or configurations have changed
    -- (healer icons work between solo shuffle rounds because UnitGroupRolesAssigned works on opponent healer as well)
    -- Always update visibility and target highlight, since CompactUnitFrame_UpdateName is called on every target change
    local class = addon.GetUnitClass(frame.unit);
    local pvpClassification = UnitPvpClassification(frame.unit);
    local roleAssigned = UnitGroupRolesAssigned(frame.unit);
    local lastModifiedFriendly = SweepyBoop.db.profile.nameplatesFriendly.lastModified;
    nameplate.classIconContainer = nameplate.classIconContainer or {};
    local iconFrame = EnsureIcon(nameplate);
    local arrowFrame = EnsureArrow(nameplate);
    if ( not iconFrame ) or ( not arrowFrame ) then return end
    local classIconContainer = nameplate.classIconContainer;
    if ( classIconContainer.class ~= class ) or ( classIconContainer.pvpClassification ~= pvpClassification ) or ( classIconContainer.roleAssigned ~= roleAssigned ) or ( classIconContainer.lastModifiedFriendly ~= lastModifiedFriendly ) then
        local iconID, iconCoords, scaleFactor = GetIconOptions(class, pvpClassification, roleAssigned);

        if ( not iconID ) then
            iconFrame.icon:SetAlpha(0);
            iconFrame.border:SetAlpha(0);
            iconFrame.targetHighlight:SetAlpha(0);
            arrowFrame.icon:SetAlpha(0);
            arrowFrame.targetHighlight:SetAlpha(0);
        else
            iconFrame.icon:SetAlpha(1);
            iconFrame.border:SetAlpha(1);
            iconFrame.targetHighlight:SetAlpha(1);
            iconFrame.icon:SetTexture(iconID);
            iconFrame.icon:SetTexCoord(unpack(iconCoords));
            iconFrame:SetScale(SweepyBoop.db.profile.nameplatesFriendly.classIconScale / 100 * scaleFactor);
            iconFrame:SetPoint("CENTER", iconFrame:GetParent(), "CENTER", 0, SweepyBoop.db.profile.nameplatesFriendly.classIconOffset);

            local classColor = RAID_CLASS_COLORS[class];
            arrowFrame.icon:SetAlpha(1);
            arrowFrame.targetHighlight:SetAlpha(1);
            arrowFrame.icon:SetVertexColor(classColor.r, classColor.g, classColor.b);
            arrowFrame:SetScale(SweepyBoop.db.profile.nameplatesFriendly.classIconScale / 100);
            arrowFrame:SetPoint("CENTER", arrowFrame:GetParent(), "CENTER", 0, SweepyBoop.db.profile.nameplatesFriendly.classIconOffset);
        end

        classIconContainer.isSpecialIcon = ( scaleFactor == specialIconScaleFactor );

        classIconContainer.class = class;
        classIconContainer.pvpClassification = pvpClassification;
        classIconContainer.roleAssigned = roleAssigned;
        classIconContainer.lastModifiedFriendly = lastModifiedFriendly;
    end

    addon.UpdateClassIconTargetHighlight(nameplate, frame);
end
