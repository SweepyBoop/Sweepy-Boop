local _, addon = ...;

local PvPUnitClassification = Enum.PvPUnitClassification;

local flagCarrierClassNames = {
    [PvPUnitClassification.FlagCarrierHorde] = "FlagCarrierHorde",
    [PvPUnitClassification.FlagCarrierAlliance] = "FlagCarrierAlliance",
    [PvPUnitClassification.FlagCarrierNeutral] = "FlagCarrierNeutral",
};

local flagCarrierIcons = {
    ["FlagCarrierHorde"] = addon.ICON_ID_FLAG_CARRIER_HORDE,
    ["FlagCarrierAlliance"] = addon.ICON_ID_FLAG_CARRIER_ALLIANCE,
    ["FlagCarrierNeutral"] = addon.ICON_ID_FLAG_CARRIER_NEUTRAL,
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

addon.ShowClassIcon = function (nameplate)
    if ( not nameplate.classIconContainer ) then return end

    local style = SweepyBoop.db.profile.nameplatesFriendly.classIconStyle;
    if nameplate.classIconContainer.FriendlyClassIcon then
        nameplate.classIconContainer.FriendlyClassIcon:SetShown(style == addon.CLASS_ICON_STYLE.ICON);
    end
    if nameplate.classIconContainer.FriendlyClassArrow then
        nameplate.classIconContainer.FriendlyClassArrow:SetShown(style == addon.CLASS_ICON_STYLE.ARROW);
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

addon.UpdateTargetHighlight = function (nameplate, frame)
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

local specialClasses = { -- For these special classes, there is no arrow style
    ["HEALER"] = true,
    ["PET"] = true,
    ["FlagCarrierHorde"] = true,
    ["FlagCarrierAlliance"] = true,
    ['FlagCarrierNeutral'] = true,
};

-- For FC icon, listen to whatever triggers CompactUnitFrame_UpdatePvPClassificationIndicator
addon.UpdateClassIcon = function(nameplate, frame)
    -- Full update if UnitGUID, PvPClassification, or configurations have changed
    -- Always update visibility and target highlight, since CompactUnitFrame_UpdateName is called on every target change
    local unitGUID = UnitGUID(frame.unit);
    local pvpClassification = UnitPvpClassification(frame.unit);
    local lastModifiedFriendly = SweepyBoop.db.profile.nameplatesFriendly.lastModified;
    nameplate.classIconContainer = nameplate.classIconContainer or {};
    local iconFrame = EnsureIcon(nameplate);
    local arrowFrame = EnsureArrow(nameplate);
    if ( not iconFrame ) or ( not arrowFrame ) then return end
    local classIconContainer = nameplate.classIconContainer;
    if ( classIconContainer.currentGUID ~= unitGUID ) or ( classIconContainer.pvpClassification ~= pvpClassification ) or ( classIconContainer.lastModifiedFriendly ~= lastModifiedFriendly ) then
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
        -- Issue: flag carrier icons are showing up but no target highlight
        if SweepyBoop.db.profile.nameplatesFriendly.useFlagCarrierIcon and isPlayer then
            if pvpClassification and flagCarrierClassNames[pvpClassification] then
                class = flagCarrierClassNames[pvpClassification];
            end
        end

        -- If the player enabled "Show healers only", hide the icon except for flag carrier
        if SweepyBoop.db.profile.nameplatesFriendly.showHealerOnly then
            if ( class ~= "HEALER" and ( not flagCarrierIcons[class] ) ) then
                class = "NONE"; -- To set alpha to 0
            end
        end

        if ( class == "NONE" ) then
            iconFrame.icon:SetAlpha(0);
            iconFrame.border:SetAlpha(0);
            iconFrame.targetHighlight:SetAlpha(0);
            arrowFrame.icon:SetAlpha(0);
            arrowFrame.targetHighlight:SetAlpha(0);
        else
            iconFrame.icon:SetAlpha(1);
            iconFrame.border:SetAlpha(1);
            iconFrame.targetHighlight:SetAlpha(1);
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

            local classColor = RAID_CLASS_COLORS[class];
            if classColor then
                arrowFrame.icon:SetAlpha(1);
                arrowFrame.targetHighlight:SetAlpha(1);
                arrowFrame.icon:SetVertexColor(classColor.r, classColor.g, classColor.b);
            else
                arrowFrame.icon:SetAlpha(0);
                arrowFrame.targetHighlight:SetAlpha(0);
            end
            arrowFrame:SetScale(SweepyBoop.db.profile.nameplatesFriendly.classIconScale / 100);
            arrowFrame:SetPoint("CENTER", arrowFrame:GetParent(), "CENTER", 0, SweepyBoop.db.profile.nameplatesFriendly.classIconOffset);
        end

        -- If we enabled icon style, or in case of a special class such as "PET", "HEALER", use icon style
        if ( SweepyBoop.db.profile.nameplatesFriendly.classIconStyle == addon.CLASS_ICON_STYLE.ICON ) or specialClasses[class] then
            classIconContainer.style = addon.CLASS_ICON_STYLE.ICON;
        else
            classIconContainer.style = addon.CLASS_ICON_STYLE.ARROW;
        end

        classIconContainer.currentGUID = unitGUID;
        classIconContainer.pvpClassification = pvpClassification;
        classIconContainer.lastModifiedFriendly = lastModifiedFriendly;
    end

    addon.UpdateTargetHighlight(nameplate, frame);
end
