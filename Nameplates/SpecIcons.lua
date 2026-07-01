local _, addon = ...;

local builtInScaleFactor = 0.5; -- We don't want to show spec icon too large
local setPointOptions = {
    [addon.SPEC_ICON_ALIGNMENT.TOP] = { point = "BOTTOM", relativePoint = "TOP" },
    [addon.SPEC_ICON_ALIGNMENT.LEFT] = { point = "LEFT", relativePoint = "LEFT" },
    [addon.SPEC_ICON_ALIGNMENT.RIGHT] = { point = "RIGHT", relativePoint = "RIGHT" },
};

local function GetConfiguredSpecIcon(specIconID, role, config)
    if ( not specIconID ) then return end

    if ( role == "HEALER" ) then
        if config.arenaSpecIconHealer then
            if config.arenaSpecIconHealerIcon then
                return addon.ICON_ID_HEALER_ENEMY, true;
            end
            return specIconID;
        end
    elseif config.arenaSpecIconOthers then
        return specIconID;
    end
end

local function GetMainlineArenaSpecInfo(unitId)
    local arenaNumber = addon.GetArenaNumber(unitId);
    if ( not arenaNumber ) then return end

    local specID = GetArenaOpponentSpec(arenaNumber);
    if ( not specID ) or ( specID <= 0 ) then return end

    return select(4, GetSpecializationInfoByID(specID)); -- iconID, role
end

local function GetSpecIconInfo(unitId) -- Return icon ID if should show, otherwise nil; check cache (for perf) and config
    local iconID, isHealer;

    if ( not UnitIsPlayer(unitId) ) then return end -- No spec icon on non-player units

    local config = SweepyBoop.db.profile.nameplatesEnemy;

    if addon.PROJECT_MAINLINE then
        if IsActiveBattlefieldArena() then
            local specIconID, role = GetMainlineArenaSpecInfo(unitId);
            return GetConfiguredSpecIcon(specIconID, role, config);
        end
    elseif addon.PROJECT_TBC then
        -- TBC: UnitGroupRolesAssigned doesn't work reliably for enemy arena units
        -- TBC didn't have a spec system, so we can't detect healers
        -- Feature disabled for TBC
    else
        -- On MoP Classic, we can detect spec from tooltip
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
        end
    end

    return iconID, isHealer;
end

local function EnsureSpecIcon(nameplate)
    if ( not nameplate.SpecIconFrame ) then
        nameplate.SpecIconFrame = addon.CreateClassOrSpecIcon(nameplate, "BOTTOM", "TOP");
        nameplate.SpecIconFrame:Hide();
    end
end

addon.UpdateSpecIcon = function (nameplate)
    -- Parented to UnitFrame to inherit the visibility
    local iconFrame = nameplate.SpecIconFrame;
    if ( not iconFrame ) then return end

    local iconID, isHealer = GetSpecIconInfo(nameplate.UnitFrame.unit);

    if ( iconFrame.iconID ~= iconID ) then
        if ( not iconID ) then
            iconFrame.icon:SetTexture();
            iconFrame.border:Hide();
        elseif isHealer then
            iconFrame.icon:SetAtlas(iconID);
            if addon.PROJECT_MAINLINE then
                iconFrame.border:Show();
            else
                iconFrame.border:Hide();
                iconFrame.icon:SetVertexColor(1, 0, 0);
            end
        else
            iconFrame.icon:SetTexture(iconID);
            iconFrame.border:Show();
        end

        iconFrame.iconID = iconID;
    end

    local config = SweepyBoop.db.profile.nameplatesEnemy;
    if ( iconFrame.lastModified ~= config.lastModified ) or ( iconFrame.isHealer ~= isHealer ) then
        local scale = SweepyBoop.db.profile.nameplatesEnemy.arenaSpecIconScale / 100 * builtInScaleFactor;
        if isHealer then
            scale = scale * 1.25;
        end

        iconFrame:SetScale(scale);
        local alignment = config.arenaSpecIconAlignment;
        local options = setPointOptions[alignment];
        local offsetX = config.arenaSpecIconHorizontalOffset or 0;
        local offsetY = config.arenaSpecIconVerticalOffset or 0;
        iconFrame:ClearAllPoints();
        iconFrame:SetPoint(options.point, iconFrame:GetParent(), options.relativePoint, offsetX, offsetY);

        iconFrame.lastModified = SweepyBoop.db.profile.nameplatesEnemy.lastModified;
        iconFrame.isHealer = isHealer;
    end
end

addon.ShowSpecIcon = function (nameplate)
    EnsureSpecIcon(nameplate);
    addon.UpdateSpecIcon(nameplate);
    nameplate.SpecIconFrame:Show();
end

addon.HideSpecIcon = function (nameplate)
    if nameplate.SpecIconFrame then
        nameplate.SpecIconFrame:Hide();
    end
end
