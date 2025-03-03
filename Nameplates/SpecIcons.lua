local _, addon = ...;

local builtInScaleFactor = 0.5; -- We don't want to show spec icon too large
local setPointOptions = {
    [addon.SPEC_ICON_ALIGNMENT.TOP] = { point = "BOTTOM", relativePoint = "TOP" },
    [addon.SPEC_ICON_ALIGNMENT.LEFT] = { point = "LEFT", relativePoint = "LEFT" },
    [addon.SPEC_ICON_ALIGNMENT.RIGHT] = { point = "RIGHT", relativePoint = "RIGHT" },
};

local function GetSpecIconInfo(unitId) -- Return icon ID if should show, otherwise nil; check cache (for perf) and config
    local iconID, isHealer;

    if ( not UnitIsPlayer(unitId) ) then return end -- No spec icon on non-player units

    local config = SweepyBoop.db.profile.nameplatesEnemy;
    if IsActiveBattlefieldArena() or ( UnitInBattleground("player") ~= nil ) then
        local specInfo = addon.GetPlayerSpec(unitId);
        if ( not specInfo ) then return end
        if ( specInfo.role == "HEALER" ) then
            if config.arenaSpecIconHealer then
                if config.arenaSpecIconHealerIcon then
                    iconID = addon.ICON_ID_HEALER_ENEMY;
                    isHealer = true;
                else
                    iconID = specInfo.icon;
                end
            end
        elseif config.arenaSpecIconOthers then
            iconID = specInfo.icon;
        end

        return iconID, isHealer;
    end
end

local function EnsureSpecIcon(nameplate)
    if ( not nameplate.SpecIconContainer ) then
        nameplate.SpecIconContainer = {};
        nameplate.SpecIconContainer.frames = {};
        -- Subsequent calls to SetPoint with different anchor family will not work, we have to create one nameplate for each alignment option
        for alignment, options in pairs(setPointOptions) do
            nameplate.SpecIconContainer.frames[alignment] = addon.CreateClassOrSpecIcon(nameplate, options.point, options.relativePoint);
            nameplate.SpecIconContainer.frames[alignment]:Hide();
        end
    end

    return nameplate.SpecIconContainer;
end

addon.UpdateSpecIcon = function (nameplate)
    -- Parented to UnitFrame to inherit the visibility
    local specIconContainer = nameplate.SpecIconContainer;
    if ( not specIconContainer ) then return end

    -- Still seeing an empty icon with a red border between solo shuffle rounds
    -- Repro if play some rounds with "show healer only", then switch to "show all"?
    local iconID, isHealer = GetSpecIconInfo(nameplate.UnitFrame.unit);

    if ( specIconContainer.iconID ~= iconID ) then
        for _, iconFrame in pairs(specIconContainer.frames) do
            if ( not iconID ) then
                iconFrame.icon:SetTexture();
                iconFrame.border:Hide();
            elseif isHealer then
                iconFrame.icon:SetAtlas(iconID);
                iconFrame.border:Show();
            else
                iconFrame.icon:SetTexture(iconID);
                iconFrame.border:Show();
            end
        end

        specIconContainer.iconID = iconID;
    end

    if ( specIconContainer.lastModified ~= SweepyBoop.db.profile.nameplatesEnemy.lastModified ) or ( specIconContainer.isHealer ~= isHealer ) then
        local scale = SweepyBoop.db.profile.nameplatesEnemy.arenaSpecIconScale / 100 * builtInScaleFactor;
        if isHealer then
            scale = scale * 1.25;
        end

        for alignment, iconFrame in pairs(specIconContainer.frames) do
            iconFrame:SetScale(scale);
            local options = setPointOptions[alignment];
            local offsetY = ( alignment == addon.SPEC_ICON_ALIGNMENT.TOP and SweepyBoop.db.profile.nameplatesEnemy.arenaSpecIconVerticalOffset ) or 0;
            iconFrame:SetPoint(options.point, iconFrame:GetParent(), options.relativePoint, 0, offsetY);
        end

        specIconContainer.lastModified = SweepyBoop.db.profile.nameplatesEnemy.lastModified;
        specIconContainer.isHealer = isHealer;
    end
end

addon.ShowSpecIcon = function (nameplate)
    EnsureSpecIcon(nameplate);
    addon.UpdateSpecIcon(nameplate);
    if nameplate.SpecIconContainer then
        for alignment, iconFrame in pairs(nameplate.SpecIconContainer.frames) do
            iconFrame:SetShown(alignment == SweepyBoop.db.profile.nameplatesEnemy.arenaSpecIconAlignment);
        end
    end
end

addon.HideSpecIcon = function (nameplate)
    if nameplate.SpecIconContainer then
        for _, iconFrame in pairs(nameplate.SpecIconContainer.frames) do
            iconFrame:Hide();
        end
    end
end
