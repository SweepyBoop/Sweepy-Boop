local _, addon = ...;

local builtInScaleFactor = 0.5; -- We don't want to show spec icon too large
local setPointOptions = {
    [addon.SPEC_ICON_HORIZONTAL_ALIGNMENT.TOP] = { point = "BOTTOM", relativePoint = "TOP" },
    [addon.SPEC_ICON_HORIZONTAL_ALIGNMENT.LEFT] = { point = "LEFT", relativePoint = "LEFT" },
    [addon.SPEC_ICON_HORIZONTAL_ALIGNMENT.RIGHT] = { point = "RIGHT", relativePoint = "RIGHT" },
};

local function ShouldShowSpecIcon(unitId) -- Return icon ID if should show, otherwise nil
    if addon.isTestMode then
        return ( UnitIsUnit(unitId, "focus") and addon.healerIconID ) or ( UnitIsUnit(unitId, "target") and 136041 ); -- Restoration Druid icon
    end

    local config = SweepyBoop.db.profile.nameplatesEnemy;
    for i = 1, addon.MAX_ARENA_SIZE do
        if UnitIsUnit(unitId, "arena" .. i) then
            -- i is the opponent index
            local specID = GetArenaOpponentSpec(i);
            if ( not specID ) then return end
            local iconID, role = select(4, GetSpecializationInfoByID(specID));

            if ( role == "HEALER" ) then
                if config.arenaSpecIconHealer then
                    if config.arenaSpecIconHealerIcon then
                        return addon.healerIconID;
                    else
                        return iconID;
                    end
                end
            elseif config.arenaSpecIconOthers then
                return iconID;
            end
        end
    end
end

local function EnsureSpecIcon(frame)
    local nameplate = frame:GetParent();
    if ( not nameplate ) then return end

    if ( not nameplate.SpecIconFrame ) then
        nameplate.SpecIconFrame = {};
        nameplate.SpecIconFrame.frames = {};
        -- Subsequent calls to SetPoint with different anchor family will not work, we have to create one frame for each alignment option
        for alignment, options in pairs(setPointOptions) do
            -- Parent to nameplate.frame, not nameplate, since when the nameplate health bar is hidden we don't want to show the spec icon
            nameplate.SpecIconFrame.frames[alignment] = addon.CreateClassOrSpecIcon(frame, options.point, options.relativePoint);
        end
    end

    return nameplate.SpecIconFrame;
end

local function ShowSpecIcon(frame, iconID)
    local specIconFrame = EnsureSpecIcon(frame);
    if ( not specIconFrame ) then return end;

    local isHealerIcon = ( iconID == addon.healerIconID );
    if ( specIconFrame.iconID ~= iconID) then
        for _, iconFrame in pairs(specIconFrame.frames) do
            iconFrame.icon:SetTexture(iconID);
            if isHealerIcon then
                iconFrame.icon:SetTexCoord(unpack(addon.healerIconCoords));
            else
                iconFrame.icon:SetTexCoord(0, 1, 0, 1);
            end
            iconFrame.iconID = iconID;
        end
    end

    if ( specIconFrame.lastModified ~= SweepyBoop.db.profile.nameplatesEnemy.lastModified ) or ( specIconFrame.isHealerIcon ~= isHealerIcon ) then
        local scale = SweepyBoop.db.profile.nameplatesEnemy.arenaSpecIconScale / 100;
        if isHealerIcon then
            scale = scale * 1.25;
        end

        for alignment, iconFrame in pairs(specIconFrame.frames) do
            iconFrame:SetScale(scale * builtInScaleFactor);
            local options = setPointOptions[alignment];
            iconFrame:SetPoint(options.point, iconFrame:GetParent(), options.relativePoint, 0, SweepyBoop.db.profile.nameplatesEnemy.arenaSpecIconVerticalOffset);
        end

        specIconFrame.lastModified = SweepyBoop.db.profile.nameplatesEnemy.lastModified;
        specIconFrame.isHealerIcon = isHealerIcon;
    end

    for alignment, iconFrame in pairs(specIconFrame.frames) do
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
    if nameplate.SpecIconFrame then
        for _, iconFrame in pairs(nameplate.SpecIconFrame.frames) do
            iconFrame:Hide();
        end
    end
end

addon.UpdateSpecIcon = function (frame)
    local iconID = ShouldShowSpecIcon(frame.unit);
    if iconID then
        ShowSpecIcon(frame, iconID);
    else
        addon.HideSpecIcon(frame);
    end
end
