local _, addon = ...;

local builtInScaleFactor = 0.5; -- We don't want to show spec icon too large
local healerOverlaySize = 50;
local setPointOptions = {
    [addon.SPEC_ICON_ALIGNMENT.TOP] = { point = "BOTTOM", relativePoint = "TOP" },
    [addon.SPEC_ICON_ALIGNMENT.LEFT] = { point = "LEFT", relativePoint = "LEFT" },
    [addon.SPEC_ICON_ALIGNMENT.RIGHT] = { point = "RIGHT", relativePoint = "RIGHT" },
};

local function GetClassicSpecIconInfo(unitId)
    local iconID, isHealer;

    if ( not UnitIsPlayer(unitId) ) then return end -- No spec icon on non-player units

    local config = SweepyBoop.db.profile.nameplatesEnemy;

    if addon.PROJECT_TBC then
        -- TBC: UnitGroupRolesAssigned doesn't work reliably for enemy arena units
        -- TBC didn't have a spec system, so we can't detect healers
        -- Feature disabled for TBC
    elseif IsActiveBattlefieldArena() or ( UnitInBattleground("player") ~= nil ) then
        -- On MoP Classic, we can detect spec from tooltip.
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

    return iconID, isHealer;
end

local function EnsureSpecIcon(nameplate)
    if nameplate.SpecIconFrame then return end

    local iconFrame = addon.CreateClassOrSpecIcon(nameplate, "BOTTOM", "TOP");
    nameplate.SpecIconFrame = iconFrame;

    if addon.PROJECT_MAINLINE then
        -- Configure protected descendants before forwarding secret display values.
        iconFrame.healerIcon = iconFrame:CreateTexture(nil, "ARTWORK");
        iconFrame.healerIcon:SetSize(healerOverlaySize, healerOverlaySize);
        iconFrame.healerIcon:SetPoint("CENTER", iconFrame);
        iconFrame.healerIcon:SetAlpha(0);

        iconFrame.healerMask = iconFrame:CreateMaskTexture();
        iconFrame.healerMask:SetTexture("Interface/Masks/CircleMaskScalable");
        iconFrame.healerMask:SetAllPoints(iconFrame.healerIcon);
        iconFrame.healerIcon:AddMaskTexture(iconFrame.healerMask);

        iconFrame.icon:SetAlpha(0);
        iconFrame.border:SetAlpha(0);
        iconFrame.border:Show();
    end

    iconFrame:Hide();
end

local function ApplySpecIconLayout(iconFrame, config, isHealer)
    if iconFrame.specLayoutApplied
        and iconFrame.lastModified == config.lastModified
        and iconFrame.isHealer == isHealer then
        return;
    end

    local scale = config.arenaSpecIconScale / 100 * builtInScaleFactor;
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

    iconFrame.lastModified = config.lastModified;
    iconFrame.isHealer = isHealer;
    iconFrame.specLayoutApplied = true;
end

local function UpdateMainlineSpecIcon(nameplate, iconFrame, config)
    local unitId = nameplate.UnitFrame.unit;
    local isPlayer = UnitIsPlayer(unitId);
    if addon.IsSecretValue(isPlayer)
        or ( not isPlayer )
        or ( not IsActiveBattlefieldArena() ) then
        iconFrame:Hide();
        return;
    end

    local arenaNumber = addon.GetArenaNumber(unitId);
    local getDisplayInfo = UnitFrameUtil and UnitFrameUtil.GetArenaOpponentSpecDisplayInfo;
    if ( not arenaNumber ) or ( not getDisplayInfo ) then
        iconFrame.icon:SetAlpha(0);
        iconFrame.healerIcon:SetAlpha(0);
        iconFrame.border:SetAlpha(0);
        iconFrame:Hide();
        return;
    end

    local info = getDisplayInfo(arenaNumber, addon.ARENA_SPEC_ROLE_TEXTURES_NAMEPLATE);
    if ( not info ) then
        iconFrame.icon:SetAlpha(0);
        iconFrame.healerIcon:SetAlpha(0);
        iconFrame.border:SetAlpha(0);
        iconFrame:Hide();
        return;
    end

    iconFrame.icon:SetTexture(info.specIcon);
    iconFrame.healerIcon:SetTexture(info.roleIconTexture);

    if config.arenaSpecIconOthers then
        iconFrame.icon:SetAlphaFromBoolean(info.hasSpec, 1, 0);
        iconFrame.border:SetAlphaFromBoolean(info.hasSpec, 1, 0);
    else
        iconFrame.icon:SetAlpha(0);
        iconFrame.border:SetAlpha(0);
    end

    if config.arenaSpecIconHealer then
        iconFrame.healerIcon:SetAlphaFromBoolean(info.showRoleIcon, 1, 0);
    else
        iconFrame.healerIcon:SetAlpha(0);
    end

    iconFrame:Show();
end

local function UpdateClassicSpecIcon(nameplate, iconFrame, config)
    local iconID, isHealer = GetClassicSpecIconInfo(nameplate.UnitFrame.unit);

    if ( iconFrame.iconID ~= iconID ) then
        if ( not iconID ) then
            iconFrame.icon:SetTexture();
            iconFrame.border:Hide();
        elseif isHealer then
            iconFrame.icon:SetAtlas(iconID);
            iconFrame.border:Hide();
            iconFrame.icon:SetVertexColor(1, 0, 0);
        else
            iconFrame.icon:SetTexture(iconID);
            iconFrame.border:Show();
        end

        iconFrame.iconID = iconID;
    end

    ApplySpecIconLayout(iconFrame, config, isHealer);
    iconFrame:SetShown(iconID ~= nil);
end

addon.UpdateSpecIcon = function (nameplate)
    local iconFrame = nameplate.SpecIconFrame;
    if ( not iconFrame ) then return end

    local config = SweepyBoop.db.profile.nameplatesEnemy;
    if addon.PROJECT_MAINLINE then
        ApplySpecIconLayout(iconFrame, config, false);
        UpdateMainlineSpecIcon(nameplate, iconFrame, config);
    else
        UpdateClassicSpecIcon(nameplate, iconFrame, config);
    end
end

addon.ShowSpecIcon = function (nameplate)
    EnsureSpecIcon(nameplate);
    addon.UpdateSpecIcon(nameplate);
end

addon.HideSpecIcon = function (nameplate)
    if nameplate.SpecIconFrame then
        nameplate.SpecIconFrame:Hide();
    end
end
