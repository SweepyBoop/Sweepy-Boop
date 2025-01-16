local _, addon = ...;

local builtInScaleFactor = 0.5; -- We don't want to show spec icon too large
local setPointOptions = {
    [addon.SPEC_ICON_ALIGNMENT.TOP] = { point = "BOTTOM", relativePoint = "TOP" },
    [addon.SPEC_ICON_ALIGNMENT.LEFT] = { point = "LEFT", relativePoint = "LEFT" },
    [addon.SPEC_ICON_ALIGNMENT.RIGHT] = { point = "RIGHT", relativePoint = "RIGHT" },
};

local function GetSpecIconInfo(unitId) -- Return icon ID if should show, otherwise nil
    local iconID, isHealer;

    -- if addon.TEST_MODE then
    --     iconID = addon.ICON_ID_HEALER_ENEMY;
    --     isHealer = true;
    --     return iconID, isHealer;
    -- end

    if ( not UnitIsPlayer(unitId) ) then return end -- No spec icon on non-player units

    local config = SweepyBoop.db.profile.nameplatesEnemy;
    if IsActiveBattlefieldArena() or ( C_PvP.IsBattleground() and addon.UnitIsHostile(unitId) ) then
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

addon.ShowSpecIcon = function (frame)
    if frame.SpecIconContainer then
        for alignment, iconFrame in pairs(frame.SpecIconContainer.frames) do
            iconFrame:SetShown(alignment == SweepyBoop.db.profile.nameplatesEnemy.arenaSpecIconAlignment);
        end
    end
end

addon.HideSpecIcon = function (frame)
    if frame.SpecIconContainer then
        for _, iconFrame in pairs(frame.SpecIconContainer.frames) do
            iconFrame:Hide();
        end
    end
end

addon.UpdateSpecIcon = function (frame)
    -- Parented to UnitFrame to inherit the visibility
    local specIconContainer = EnsureSpecIcon(frame);
    if ( not specIconContainer ) then return end;

    local iconID, isHealer = GetSpecIconInfo(frame.unit);

    if ( specIconContainer.iconID ~= iconID ) then
        for _, iconFrame in pairs(specIconContainer.frames) do
            if ( not iconID ) then
                iconFrame.icon:SetTexture(); -- Empty texture if no spec icon to show
            elseif isHealer then
                iconFrame.icon:SetAtlas(iconID);
            else
                iconFrame.icon:SetTexture(iconID);
            end
            iconFrame.iconID = iconID;
        end
    end

    if ( specIconContainer.lastModified ~= SweepyBoop.db.profile.nameplatesEnemy.lastModified ) or ( specIconContainer.isHealer ~= isHealer ) then
        local scale = SweepyBoop.db.profile.nameplatesEnemy.arenaSpecIconScale / 100;
        if isHealer then
            scale = scale * 1.25;
        end

        for alignment, iconFrame in pairs(specIconContainer.frames) do
            iconFrame:SetScale(scale * builtInScaleFactor);
            local options = setPointOptions[alignment];
            local offsetY = ( alignment == addon.SPEC_ICON_ALIGNMENT.TOP and SweepyBoop.db.profile.nameplatesEnemy.arenaSpecIconVerticalOffset ) or 0;
            iconFrame:SetPoint(options.point, iconFrame:GetParent(), options.relativePoint, 0, offsetY);
        end

        specIconContainer.lastModified = SweepyBoop.db.profile.nameplatesEnemy.lastModified;
        specIconContainer.isHealerIcon = isHealer;
    end
end
