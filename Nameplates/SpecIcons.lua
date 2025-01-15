local _, addon = ...;

local builtInScaleFactor = 0.5; -- We don't want to show spec icon too large
local setPointOptions = {
    [addon.SPEC_ICON_ALIGNMENT.TOP] = { point = "BOTTOM", relativePoint = "TOP" },
    [addon.SPEC_ICON_ALIGNMENT.LEFT] = { point = "LEFT", relativePoint = "LEFT" },
    [addon.SPEC_ICON_ALIGNMENT.RIGHT] = { point = "RIGHT", relativePoint = "RIGHT" },
};

local function ShouldShowSpecIcon(unitId) -- Return icon ID if should show, otherwise nil
    local iconID, isHealer;

    if addon.TEST_MODE then
        if UnitIsUnit(unitId, "focus") then
            iconID = addon.ICON_ID_HEALER_ENEMY;
            isHealer = true;
        elseif UnitIsUnit(unitId, "target") then
            iconID = 136041;
        end
        
        return iconID, isHealer;
    end

    if ( not UnitIsPlayer(unitId) ) then return end -- No spec icon on non-player units

    local config = SweepyBoop.db.profile.nameplatesEnemy;
    if IsActiveBattlefieldArena() or ( ( UnitInBattleground("player") ~= nil ) and addon.UnitIsHostile(unitId) ) then
        local specInfo = addon.GetBattlefieldSpecByPlayerGuid(UnitGUID(unitId));
        if ( not specInfo ) then return end
        if ( specInfo.role == "HEALER" ) then
            if config.arenaSpecIconHealer then
                if config.arenaSpecIconHealerIcon then
                    iconID = addon.ICON_ID_HEALER_ENEMY;
                    isHealer = true;
                else
                    iconID = specInfo.iconID;
                end
            end
        elseif config.arenaSpecIconOthers then
            iconID = specInfo.iconID;
        end

        return iconID, isHealer;
    end
end

local function EnsureSpecIcon(frame)
    local nameplate = frame:GetParent();
    if ( not nameplate ) then return end

    if ( not nameplate.SpecIconContainer ) then
        nameplate.SpecIconContainer = {};
        nameplate.SpecIconContainer.frames = {};
        -- Subsequent calls to SetPoint with different anchor family will not work, we have to create one frame for each alignment option
        for alignment, options in pairs(setPointOptions) do
            nameplate.SpecIconContainer.frames[alignment] = addon.CreateClassOrSpecIcon(nameplate, options.point, options.relativePoint);
        end
    end

    return nameplate.SpecIconContainer;
end

local function ShowSpecIcon(frame, iconID, isHealer)
    local specIconContainer = EnsureSpecIcon(frame);
    if ( not specIconContainer ) then return end;

    if ( specIconContainer.iconID ~= iconID ) then
        for _, iconFrame in pairs(specIconContainer.frames) do
            if isHealer then
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

    for alignment, iconFrame in pairs(specIconContainer.frames) do
        if ( alignment == SweepyBoop.db.profile.nameplatesEnemy.arenaSpecIconAlignment ) then
            iconFrame:Show();
        else
            iconFrame:Hide();
        end
    end
end

addon.HideSpecIcon = function (frame)
    local nameplate = frame:GetParent();
    if ( not nameplate ) then return end
    if nameplate.SpecIconContainer then
        for _, iconFrame in pairs(nameplate.SpecIconContainer.frames) do
            iconFrame:Hide();
        end
    end
end

addon.UpdateSpecIcon = function (frame)
    local iconID, isHealer = ShouldShowSpecIcon(frame.unit);
    if iconID and ( iconID ~= 0 ) then
        ShowSpecIcon(frame, iconID, isHealer);
    else
        addon.HideSpecIcon(frame);
    end
end
