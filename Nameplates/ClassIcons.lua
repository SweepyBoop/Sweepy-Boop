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
        return addon.IsPartyPrimaryPet(unitId);
    end
end

local function EnsureIcon(frame)
    local nameplate = frame:GetParent();
    if ( not nameplate ) then return end
    if ( not nameplate.FriendlyClassIcon ) then
        nameplate.FriendlyClassIcon = addon.CreateClassOrSpecIcon(nameplate, "CENTER", "CENTER", true);
    end

    return nameplate.FriendlyClassIcon;
end

local function EnsureArrow(frame)
    local nameplate = frame:GetParent();
    if ( not nameplate ) then return end
    if ( not nameplate.FriendlyClassArrow ) then
        nameplate.FriendlyClassArrow = addon.CreateClassColorArrowFrame(nameplate);
    end

    return nameplate.FriendlyClassArrow;
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

addon.HideClassIcon = function(frame)
    local nameplate = frame:GetParent();
    if ( not nameplate ) then return end
    if nameplate.FriendlyClassIcon then
        nameplate.FriendlyClassIcon:Hide();
    end
    if nameplate.FriendlyClassArrow then
        nameplate.FriendlyClassArrow:Hide();
    end
end

local specialClasses = { -- For these special classes, there is no arrow style
    ["HEALER"] = true,
    ["PET"] = true,
    ["FlagCarrierHorde"] = true,
    ["FlagCarrierAlliance"] = true,
    ['FlagCarrierNeutral'] = true,
};

local function ShowClassIcon(frame)
    -- Full update if UnitGUID, PvPClassification, or configurations have changed
    -- Always update visibility and target highlight, since CompactUnitFrame_UpdateName is called on every target change
    local unitGUID = UnitGUID(frame.unit);
    local pvpClassification = UnitPvpClassification(frame.unit);
    local lastModifiedFriendly = SweepyBoop.db.profile.nameplatesFriendly.lastModified;
    frame.classIconContainer = frame.classIconContainer or {};
    frame.classIconContainer.FriendlyClassIcon = EnsureIcon(frame);
    frame.classIconContainer.FriendlyClassArrow = EnsureArrow(frame);
    local classIconContainer = frame.classIconContainer;
    local iconFrame = classIconContainer.FriendlyClassIcon;
    local arrowFrame = classIconContainer.FriendlyClassArrow;
    if ( not iconFrame ) or ( not arrowFrame ) then return end
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
        if SweepyBoop.db.profile.nameplatesFriendly.useFlagCarrierIcon and isPlayer then
            local classification = UnitPvpClassification(frame.unit);
            if classification and flagCarrierClassNames[classification] then
                class = flagCarrierClassNames[classification];
            end
        end

        -- If the player enabled "Show healers only", hide the icon except for flag carrier
        if SweepyBoop.db.profile.nameplatesFriendly.showHealerOnly then
            if ( class ~= "HEALER" and ( not flagCarrierIcons[class] ) ) then
                class = "NONE"; -- To set an empty icon
            end
        end

        if ( class == "NONE" ) then
            iconFrame.icon:SetTexture();
            iconFrame.mask:SetTexture();
            iconFrame.targetHighlight:SetTexture();
            arrowFrame.icon:SetTexture();
            arrowFrame.targetHighlight:SetTexture();
        else
            local iconID, iconCoords = GetIconOptions(class);
            iconFrame.icon:SetTexture(iconID);
            iconFrame.icon:SetTexCoord(unpack(iconCoords));
            iconFrame.mask:SetTexture("Interface/Masks/CircleMaskScalable");
            iconFrame.targetHighlight:SetAtlas("ui-frame-genericplayerchoice-portrait-border");
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
                arrowFrame.icon:SetAtlas("covenantsanctum-renown-doublearrow-disabled");
                arrowFrame.targetHighlight:SetAtlas("Capacitance-General-WorkOrderBorder");
                arrowFrame.icon:SetVertexColor(classColor.r, classColor.g, classColor.b);
            else
                arrowFrame.icon:SetTexture();
                arrowFrame.targetHighlight:SetTexture();
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

    if ( classIconContainer.style == addon.CLASS_ICON_STYLE.ICON ) then
        if arrowFrame then arrowFrame:Hide() end
        if iconFrame.targetHighlight then
            if UnitIsUnit("target", frame.unit) then
                iconFrame.targetHighlight:Show();
            else
                iconFrame.targetHighlight:Hide();
            end
        end
        iconFrame:Show();
    elseif ( classIconContainer.style == addon.CLASS_ICON_STYLE.ARROW ) then
        if iconFrame then iconFrame:Hide() end
        if arrowFrame.targetHighlight then
            if UnitIsUnit("target", frame.unit) then
                arrowFrame.targetHighlight:Show();
            else
                arrowFrame.targetHighlight:Hide();
            end
        end
        arrowFrame:Show();
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
