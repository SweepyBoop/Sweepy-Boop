local _, addon = ...;

local function EnsureIcon(nameplate)
    if ( not nameplate.FriendlyPetIcon ) then
        nameplate.FriendlyPetIcon = addon.CreateClassOrSpecIcon(nameplate, "BOTTOM", "BOTTOM", true);
        nameplate.FriendlyPetIcon.icon:SetTexture(addon.ICON_ID_PET);
        nameplate.FriendlyPetIcon:Hide();
    end

    return nameplate.FriendlyPetIcon;
end

addon.UpdatePetIconTargetHighlight = function (nameplate, frame)
    local iconFrame = nameplate.FriendlyPetIcon;
    if ( not iconFrame ) then return end

    local config = SweepyBoop.db.profile.nameplatesFriendly;
    local featureEnabled = config.targetHighlight and ( not C_AddOns.IsAddOnLoaded("NeatPlates") );
    local iconVisible = iconFrame:IsShown() and ( iconFrame.icon:GetAlpha() > 0 );
    local shouldShow = UnitIsUnit(frame.unit, "target") and featureEnabled and iconVisible;
    if addon.SetTargetHighlightShown then
        addon.SetTargetHighlightShown(iconFrame, shouldShow, config.animatedTargetHighlight);
    else
        iconFrame.targetHighlight:SetShown(shouldShow);
    end
end

addon.UpdatePetIcon = function(nameplate, frame)
    -- Only update if config changes (we have separated out pet icon from class / healer / flag carrier icons, and pet icon has fixed texture)
    local iconFrame = EnsureIcon(nameplate);
    local config = SweepyBoop.db.profile.nameplatesFriendly;
    local lastModifiedFriendly = config.lastModified;
    if ( iconFrame.lastModifiedFriendly ~= lastModifiedFriendly ) then
        iconFrame:SetScale(config.petIconSize);
        iconFrame:SetPoint("BOTTOM", nameplate, "BOTTOM", config.classIconHorizontalOffset or 0, config.classIconOffset or 0);
        iconFrame.lastModifiedFriendly = lastModifiedFriendly;
    end
end

addon.ShowPetIcon = function (nameplate, frame)
    addon.UpdatePetIcon(nameplate, frame);
    if nameplate.FriendlyPetIcon then
        nameplate.FriendlyPetIcon:Show();
    end
    addon.UpdatePetIconTargetHighlight(nameplate, frame);
end

addon.HidePetIcon = function(nameplate)
    if nameplate.FriendlyPetIcon then
        if addon.SetTargetHighlightShown then
            addon.SetTargetHighlightShown(nameplate.FriendlyPetIcon, false, false);
        else
            nameplate.FriendlyPetIcon.targetHighlight:Hide();
        end
        nameplate.FriendlyPetIcon:Hide();
    end
end
