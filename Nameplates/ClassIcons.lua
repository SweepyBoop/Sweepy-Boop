local _, addon = ...;

local specialIconScaleFactor = 1.25;

local PvPUnitClassification;
local flagCarrierIcons;
if addon.PROJECT_MAINLINE then
    PvPUnitClassification = Enum.PvPUnitClassification;
    flagCarrierIcons = {
        [PvPUnitClassification.FlagCarrierHorde] = addon.ICON_ID_FLAG_CARRIER_HORDE,
        [PvPUnitClassification.FlagCarrierAlliance] = addon.ICON_ID_FLAG_CARRIER_ALLIANCE,
        [PvPUnitClassification.FlagCarrierNeutral] = addon.ICON_ID_FLAG_CARRIER_NEUTRAL,
    };
end

-- Suppress friendly FC icon and target highlight, as NeatPlates unregisters all UnitFrame events, causing problems for those 2 features
local hasConflict = C_AddOns.IsAddOnLoaded("NeatPlates");

local function EnsureClassIcon(nameplate)
    nameplate.classIconContainer = nameplate.classIconContainer or {};

    if ( not nameplate.classIconContainer.FriendlyClassIcon ) then
        nameplate.classIconContainer.FriendlyClassIcon = addon.CreateClassOrSpecIcon(nameplate, "CENTER", "CENTER", true);
        nameplate.classIconContainer.FriendlyClassIcon:Hide();
    end

    if ( not nameplate.classIconContainer.FriendlyClassArrow ) then
        nameplate.classIconContainer.FriendlyClassArrow = addon.CreateClassColorArrowFrame(nameplate);
        nameplate.classIconContainer.FriendlyClassArrow:Hide();
    end
end

local function GetIconOptions(class, pvpClassification, specIconID, roleAssigned)
    local iconID;
    local iconCoords = {0, 1, 0, 1};
    local isSpecialIcon;

    local config = SweepyBoop.db.profile.nameplatesFriendly;

    if config.hideOutsidePvP and ( not IsActiveBattlefieldArena() ) and ( UnitInBattleground("player") == nil ) then
        -- Hide icons but still show name
        return iconID, iconCoords, isSpecialIcon;
    end

    -- Check regular class, then healer, then flag carrier; latter overwrites the former
    iconID = addon.ICON_ID_CLASSES;
    iconCoords = CLASS_ICON_TCOORDS[class];

    if config.showSpecIcons and specIconID then -- Show spec icon in PvP instances, overwritten by healer / flag carrier icons
        iconID = specIconID;
        iconCoords = {0, 1, 0, 1};
    end

    local isHealer = ( roleAssigned == "HEALER" );
    if isHealer and config.useHealerIcon then
        iconID = addon.ICON_ID_HEALER;
        iconCoords = addon.ICON_COORDS_HEALER;
        isSpecialIcon = true;
    elseif ( not isHealer ) and config.showHealerOnly then
        iconID = nil;
    end

    if addon.PROJECT_MAINLINE and ( not hasConflict ) then
        if ( pvpClassification ~= nil ) and ( flagCarrierIcons[pvpClassification] ) and config.useFlagCarrierIcon then
            iconID = flagCarrierIcons[pvpClassification];
            iconCoords = {0, 1, 0, 1};
            isSpecialIcon = true;
        end
    end

    return iconID, iconCoords, isSpecialIcon;
end

addon.UpdateClassIconTargetHighlight = function (nameplate, frame)
    local isTarget = UnitIsUnit(frame.unit, "target");
    local featureEnabled = SweepyBoop.db.profile.nameplatesFriendly.targetHighlight and ( not hasConflict );
    if nameplate.classIconContainer then
        if nameplate.classIconContainer.FriendlyClassIcon then
            nameplate.classIconContainer.FriendlyClassIcon.targetHighlight:SetShown(isTarget and featureEnabled);
        end
        if nameplate.classIconContainer.FriendlyClassArrow then
            nameplate.classIconContainer.FriendlyClassArrow.targetHighlight:SetShown(isTarget and featureEnabled);
        end
    end
end

addon.UpdatePlayerName = function (nameplate, frame)
    if ( not nameplate.classIconContainer ) then return end

    local container = nameplate.classIconContainer;
    local guid = UnitGUID(frame.unit);

    if ( container.currentGUID ~= guid ) then
        local name = UnitName(frame.unit) or "";
        local class = addon.GetUnitClass(frame.unit);
        local classColor = class and RAID_CLASS_COLORS[class];

        if nameplate.classIconContainer.FriendlyClassIcon then
            nameplate.classIconContainer.FriendlyClassIcon.name:SetText(name);
            if classColor then
                nameplate.classIconContainer.FriendlyClassIcon.name:SetTextColor(classColor.r, classColor.g, classColor.b);
            else
                nameplate.classIconContainer.FriendlyClassIcon.name:SetTextColor(1, 1, 1);
            end
        end

        if nameplate.classIconContainer.FriendlyClassArrow then
            nameplate.classIconContainer.FriendlyClassArrow.name:SetText(name);
            if classColor then
                nameplate.classIconContainer.FriendlyClassArrow.name:SetTextColor(classColor.r, classColor.g, classColor.b);
            else
                nameplate.classIconContainer.FriendlyClassArrow.name:SetTextColor(1, 1, 1);
            end
        end

        container.currentGUID = guid;
    end
end

addon.UpdateClassIcon = function(nameplate, frame)
    if ( not nameplate.classIconContainer ) then return end
    local classIconContainer = nameplate.classIconContainer;
    if ( not classIconContainer.FriendlyClassIcon ) or ( not classIconContainer.FriendlyClassArrow ) then return end

    -- Full update if class, PvPClassification, roleAssigned or configurations have changed
    -- (healer icons work between solo shuffle rounds because UnitGroupRolesAssigned works on opponent healer as well)
    -- Always update visibility and target highlight, since CompactUnitFrame_UpdateName is called on every target change
    local class = addon.GetUnitClass(frame.unit);
    local pvpClassification, specIconID;
    if addon.PROJECT_MAINLINE then
        pvpClassification = UnitPvpClassification(frame.unit);
        if IsActiveBattlefieldArena() or ( UnitInBattleground("player") ~= nil ) then
            local specInfo = addon.GetPlayerSpec(frame.unit);
            if specInfo then
                specIconID = specInfo.icon;
            end
        end
    end
    local roleAssigned = UnitGroupRolesAssigned(frame.unit);
    local config = SweepyBoop.db.profile.nameplatesFriendly;
    if ( classIconContainer.class ~= class )
        or ( classIconContainer.pvpClassification ~= pvpClassification )
        or ( classIconContainer.specIconID ~= specIconID )
        or ( classIconContainer.roleAssigned ~= roleAssigned )
        or ( classIconContainer.lastModified ~= config.lastModified ) then
        local iconID, iconCoords, isSpecialIcon = GetIconOptions(class, pvpClassification, specIconID, roleAssigned);
        local iconFrame = classIconContainer.FriendlyClassIcon;
        local arrowFrame = classIconContainer.FriendlyClassArrow;

        if ( not iconID ) or ( not iconCoords ) then -- nil icon ID due to "Show Healer Only" option, or classFileName is not valid
            iconFrame.icon:SetAlpha(0);
            iconFrame.border:SetAlpha(0);
            iconFrame.targetHighlight:SetAlpha(0);
            arrowFrame.icon:SetAlpha(0);
            arrowFrame.targetHighlight:SetAlpha(0);
        else
            iconFrame.icon:SetAlpha(1);
            iconFrame.border:SetAlpha(1);
            iconFrame.targetHighlight:SetAlpha(1);

            local classColor = RAID_CLASS_COLORS[class];
            if config.classColorBorder then
                iconFrame.border:SetDesaturated(true);
                iconFrame.border:SetVertexColor(classColor.r, classColor.g, classColor.b);
            else
                iconFrame.border:SetDesaturated(false);
                iconFrame.border:SetVertexColor(1, 1, 1);
            end

            local showPlayerName = config.showPlayerName;

            iconFrame.icon:SetTexture(iconID);
            iconFrame.icon:SetTexCoord(unpack(iconCoords));
            local scaleFactor = ( isSpecialIcon and specialIconScaleFactor ) or 1;
            iconFrame:SetScale(config.classIconScale / 100 * scaleFactor);
            iconFrame.name:SetShown(showPlayerName);
            local offset = config.classIconOffset;
            if showPlayerName then
                offset = offset + iconFrame.name:GetStringHeight();
            end
            iconFrame:SetPoint("CENTER", nameplate, "CENTER", 0, offset);

            arrowFrame.icon:SetAlpha(1);
            arrowFrame.targetHighlight:SetAlpha(1);
            arrowFrame.icon:SetVertexColor(classColor.r, classColor.g, classColor.b);
            arrowFrame:SetScale(config.classIconScale / 100);
            arrowFrame.name:SetShown(showPlayerName);
            local offset = config.classIconOffset;
            if showPlayerName then
                offset = offset + arrowFrame.name:GetStringHeight();
            end
            arrowFrame:SetPoint("CENTER", nameplate, "CENTER", 0, offset);
        end

        classIconContainer.isSpecialIcon = isSpecialIcon;

        classIconContainer.class = class;
        classIconContainer.pvpClassification = pvpClassification;
        classIconContainer.specIconID = specIconID;
        classIconContainer.roleAssigned = roleAssigned;
        classIconContainer.lastModified = config.lastModified;
    end

    addon.UpdateClassIconTargetHighlight(nameplate, frame);
end

addon.ShowClassIcon = function (nameplate, frame)
    EnsureClassIcon(nameplate);
    addon.UpdatePlayerName(nameplate, frame);
    addon.UpdateClassIcon(nameplate, frame);
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
    local classIconContainer = nameplate.classIconContainer;

    if classIconContainer.FriendlyClassIcon then
        classIconContainer.FriendlyClassIcon:Hide();
    end
    if classIconContainer.FriendlyClassArrow then
        classIconContainer.FriendlyClassArrow:Hide();
    end
end
