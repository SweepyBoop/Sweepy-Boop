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
    if IsActiveBattlefieldArena() or C_PvP.IsBattleground() then
        local specInfo = addon.GetBattlefieldSpecByPlayerGuid(UnitGUID(unitId));
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

local function EnsureSpecIcon(frame)
    if ( not frame.SpecIconContainer ) then
        frame.SpecIconContainer = {};
        frame.SpecIconContainer.frames = {};
        -- Subsequent calls to SetPoint with different anchor family will not work, we have to create one frame for each alignment option
        for alignment, options in pairs(setPointOptions) do
            frame.SpecIconContainer.frames[alignment] = addon.CreateClassOrSpecIcon(frame, options.point, options.relativePoint);
            frame.SpecIconContainer.frames[alignment]:Hide();
        end
    end

    return frame.SpecIconContainer;
end

addon.UpdateSpecIcon = function (frame)
    -- Parented to UnitFrame to inherit the visibility
    -- Only update if visible
    local specIconContainer = frame.SpecIconContainer;
    if ( not specIconContainer ) then return end

    -- Still seeing an empty icon with a red border between solo shuffle rounds
    -- Repro if play some rounds with "show healer only", then switch to "show all"?
    local iconID, isHealer = GetSpecIconInfo(frame.unit);

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

addon.ShowSpecIcon = function (frame)
    EnsureSpecIcon(frame);
    addon.UpdateSpecIcon(frame);
    if frame.SpecIconContainer then
        for alignment, iconFrame in pairs(frame.SpecIconContainer.frames) do
            iconFrame:SetShown(alignment == SweepyBoop.db.profile.nameplatesEnemy.arenaSpecIconAlignment);
        end
        frame.SpecIconContainer.isShown = true;
    end
end

addon.HideSpecIcon = function (frame)
    if frame.SpecIconContainer then
        for _, iconFrame in pairs(frame.SpecIconContainer.frames) do
            iconFrame:Hide();
        end
        frame.SpecIconContainer.isShown = false;
    end
end
