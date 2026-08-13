local _, addon = ...;

if not addon.PROJECT_MAINLINE then return end

local AURA_KIND = addon.BIG_DEBUFFS_AURA_KIND;
local iconBaseSize = addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_BASE_SIZE;
local frameLevelOffset = 20;

local RAIL = {
    LEFT = {
        rootKey = "sweepyBoopBigDebuffsLeftRoot",
        containersKey = "sweepyBoopBigDebuffsLeftContainers",
        anchorPoint = "RIGHT",
        anchorRelativePoint = "LEFT",
        growthDirection = AnchorUtil.FlowDirection.Left,
        direction = -1,
    },
    RIGHT = {
        rootKey = "sweepyBoopBigDebuffsRightRoot",
        containersKey = "sweepyBoopBigDebuffsRightContainers",
        anchorPoint = "LEFT",
        anchorRelativePoint = "RIGHT",
        growthDirection = AnchorUtil.FlowDirection.Right,
        direction = 1,
    },
};

local GROUP = {
    CROWD_CONTROL = {
        key = "CrowdControl",
        filter = "HARMFUL|CROWD_CONTROL",
        configKey = "bigDebuffsShowCrowdControl",
        auraKind = AURA_KIND.CROWD_CONTROL,
    },
    BIG_DEFENSIVE = {
        key = "BigDefensive",
        filter = "HELPFUL|BIG_DEFENSIVE",
        configKey = "bigDebuffsShowDefensives",
        auraKind = AURA_KIND.DEFENSIVE,
    },
    EXTERNAL_DEFENSIVE = {
        key = "ExternalDefensive",
        filter = "HELPFUL|EXTERNAL_DEFENSIVE|!BIG_DEFENSIVE",
        configKey = "bigDebuffsShowDefensives",
        auraKind = AURA_KIND.DEFENSIVE,
    },
    IMPORTANT = {
        key = "Important",
        filter = "HELPFUL|IMPORTANT|!BIG_DEFENSIVE|!EXTERNAL_DEFENSIVE",
        configKey = "bigDebuffsShowImportantBuffs",
        auraKind = AURA_KIND.IMPORTANT_BUFF,
    },
};

local leftGroups = {
    GROUP.BIG_DEFENSIVE,
    GROUP.EXTERNAL_DEFENSIVE,
    GROUP.IMPORTANT,
};
local rightGroups = {
    GROUP.CROWD_CONTROL,
};

local function GetConfig()
    return SweepyBoop.db.profile.nameplatesEnemy;
end

local function Clamp(value, minValue, maxValue)
    value = tonumber(value) or minValue;
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value;
end

local function GetIconSize(config)
    return Clamp(
        config.bigDebuffsIconSize,
        20,
        64
    );
end

local function GetIconCount(config)
    return Clamp(
        config.bigDebuffsMaxIcons,
        1,
        8
    );
end

local function GetIconSpacing(config)
    return Clamp(
        config.bigDebuffsSpacing,
        0,
        16
    );
end

local function IsHighlightStyle(iconStyle)
    return iconStyle == addon.BIG_DEBUFFS_ICON_STYLE_ID.HIGHLIGHT;
end

local function IsGlowStyle(iconStyle)
    return iconStyle == addon.BIG_DEBUFFS_ICON_STYLE_ID.GLOW;
end

local function CreateHighlightTexture(frame, texturePath, layer, color, alpha)
    local texture = frame:CreateTexture(nil, layer);
    texture:SetTexture(texturePath);
    texture:SetBlendMode("ADD");
    texture:SetPoint(
        "TOPLEFT",
        frame,
        "TOPLEFT",
        -addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_PADDING,
        addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_PADDING
    );
    texture:SetPoint(
        "BOTTOMRIGHT",
        frame,
        "BOTTOMRIGHT",
        addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_PADDING,
        -addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_PADDING
    );
    texture:SetVertexColor(color[1], color[2], color[3], alpha);
    return texture;
end

local function ConfigureCooldown(cooldown, useGlowStyle)
    cooldown:SetDrawBling(false);
    cooldown:SetDrawSwipe(true);
    cooldown:SetDrawEdge(true);
    cooldown:SetReverse(true);
    cooldown:SetHideCountdownNumbers(false);
    cooldown:SetSwipeColor(0, 0, 0, useGlowStyle and 0.5 or 0.55);
    if cooldown.SetEdgeTexture then
        cooldown:SetEdgeTexture(addon.BIG_DEBUFFS_ICON_STYLE.GLOW_COOLDOWN_EDGE_TEXTURE);
    end
end

local function InitializeAuraButton(button, auraKind, iconStyle)
    local useHighlightStyle = IsHighlightStyle(iconStyle);
    local useGlowStyle = IsGlowStyle(iconStyle);
    local color = addon.GetBigDebuffsAuraTint(auraKind, iconStyle);

    button:SetSize(iconBaseSize, iconBaseSize);
    button:SetMouseMotionEnabled(false);

    local backdrop = button:CreateTexture(nil, "BACKGROUND");
    backdrop:SetAllPoints(button);
    backdrop:SetColorTexture(0, 0, 0, 1);

    local icon = button:CreateTexture(nil, "ARTWORK");
    if useGlowStyle then
        icon:SetAllPoints(button);
        icon:SetTexCoord(0, 1, 0, 1);
    else
        local inset = addon.BIG_DEBUFFS_ICON_STYLE.DEBUFF_ICON_INSET;
        icon:SetPoint("TOPLEFT", button, "TOPLEFT", inset, -inset);
        icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -inset, inset);
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92);
    end
    button:SetIcon(icon);

    if useGlowStyle then
        CreateHighlightTexture(
            button,
            addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_GLOW_TEXTURE,
            "OVERLAY",
            color,
            1
        );
    elseif useHighlightStyle then
        CreateHighlightTexture(
            button,
            addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_GLOW_TEXTURE,
            "BORDER",
            color,
            0.9
        );
        CreateHighlightTexture(
            button,
            addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_BORDER_TEXTURE,
            "OVERLAY",
            color,
            1
        );
    else
        local border = button:CreateTexture(nil, "OVERLAY");
        local padding = addon.BIG_DEBUFFS_ICON_STYLE.DEBUFF_BORDER_PADDING;
        border:SetPoint("TOPLEFT", button, "TOPLEFT", -padding, padding);
        border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", padding, -padding);
        border:SetTexture(addon.BIG_DEBUFFS_ICON_STYLE.DEBUFF_BORDER_TEXTURE);
        border:SetTexCoord(unpack(addon.BIG_DEBUFFS_ICON_STYLE.DEBUFF_BORDER_TEX_COORDS));
        border:SetVertexColor(color[1], color[2], color[3], 1);
    end

    local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate");
    cooldown:SetAllPoints(icon);
    ConfigureCooldown(cooldown, useGlowStyle);
    button:SetDurationCooldown(cooldown);
end

local function EnsureRoot(nameplate, railInfo)
    local root = nameplate[railInfo.rootKey];
    if root then return root end

    root = CreateFrame("Frame", nil, nameplate);
    root:SetMouseClickEnabled(false);
    root:SetIgnoreParentAlpha(true);
    root:SetFrameStrata("HIGH");
    root:SetFrameLevel(nameplate:GetFrameLevel() + frameLevelOffset);
    root:SetSize(1, 1);
    nameplate[railInfo.rootKey] = root;
    return root;
end

local function ApplyRootLayout(nameplate, railInfo)
    local config = GetConfig();
    local root = EnsureRoot(nameplate, railInfo);
    local anchor = nameplate.UnitFrame and nameplate.UnitFrame.healthBar or nameplate;
    local scale = GetIconSize(config) / iconBaseSize;
    local offsetX = config.bigDebuffsOffsetX or addon.BIG_DEBUFFS_DEFAULTS.OFFSET_X;
    local offsetY = config.bigDebuffsOffsetY or addon.BIG_DEBUFFS_DEFAULTS.OFFSET_Y;

    root:ClearAllPoints();
    root:SetPoint(
        railInfo.anchorPoint,
        anchor,
        railInfo.anchorRelativePoint,
        railInfo.direction * (2 + offsetX) / scale,
        offsetY / scale
    );
    root:SetScale(scale);
    root.sweepyBoopAnchor = anchor;
    return root;
end

local function AddAuraGroup(container, group, iconStyle)
    container:AddAuraGroup(group.key, group.filter, {
        maxFrameCount = GetIconCount(GetConfig()),
        sortMethod = AuraContainerSortMethod.UnitFrameDebuff,
        sortDirection = AuraContainerSortDirection.Normal,
        initializeFrame = function(button)
            InitializeAuraButton(button, group.auraKind, iconStyle);
        end,
        layout = {
            elementSpacing = GetIconSpacing(GetConfig()) * iconBaseSize / GetIconSize(GetConfig()),
            groupSpacing = GetIconSpacing(GetConfig()) * iconBaseSize / GetIconSize(GetConfig()),
            lineSpacing = 0,
            elementWidth = iconBaseSize,
            elementHeight = iconBaseSize,
        },
    });
end

local function EnsureContainer(nameplate, railInfo, groups)
    local iconStyle = addon.GetBigDebuffsIconStyle(GetConfig());
    local containers = nameplate[railInfo.containersKey];
    if not containers then
        containers = {};
        nameplate[railInfo.containersKey] = containers;
    end

    local container = containers[iconStyle];
    if container then return container end

    local root = EnsureRoot(nameplate, railInfo);
    container = CreateFrame(
        "AuraContainer",
        nil,
        root,
        "CustomAuraContainerTemplate"
    );
    container:SetPoint(railInfo.anchorPoint, root, railInfo.anchorPoint);
    container:SetFlowLayoutAxis(AnchorUtil.FlowLayoutAxis.Horizontal);
    container:SetFlowLayoutAnchorPoint(railInfo.anchorPoint);
    container:SetFlowLayoutGrowthDirection(
        railInfo.growthDirection,
        AnchorUtil.FlowDirection.Down
    );
    container:SetUnit("none");
    container:SetEnabled(false);
    container:Hide();
    container:SetAuraProcessingPolicy(
        CustomAuraContainerAuraProcessingPolicy.ProcessAura,
        {
            displayOnlyDispellableDebuffs = false,
            ignoreBuffs = false,
            ignoreDebuffs = false,
            ignoreDispelDebuffs = false,
        }
    );

    for _, group in ipairs(groups) do
        AddAuraGroup(container, group, iconStyle);
    end

    containers[iconStyle] = container;
    return container;
end

local function ApplyContainerLayout(nameplate, railInfo, container, groups)
    local config = GetConfig();
    local root = EnsureRoot(nameplate, railInfo);
    local anchor = nameplate.UnitFrame and nameplate.UnitFrame.healthBar or nameplate;
    if container.sweepyBoopLastModified == config.lastModified
        and root.sweepyBoopAnchor == anchor then
        return;
    end

    root = ApplyRootLayout(nameplate, railInfo);
    local spacing = GetIconSpacing(config) / root:GetScale();
    local maxIcons = GetIconCount(config);

    container:ClearAllPoints();
    container:SetPoint(railInfo.anchorPoint, root, railInfo.anchorPoint);
    for _, group in ipairs(groups) do
        container:SetAuraGroupMaxFrameCount(
            group.key,
            config[group.configKey] and maxIcons or 0
        );
        container:SetAuraGroupLayout(group.key, {
            elementSpacing = spacing,
            groupSpacing = spacing,
            lineSpacing = 0,
            elementWidth = iconBaseSize,
            elementHeight = iconBaseSize,
        });
    end
    container.sweepyBoopLastModified = config.lastModified;
end

local function ActivateContainer(container, unit)
    if container:GetUnit() ~= unit then
        container:Hide();
        container:SetUnit(unit);
        container:UpdateAllAuras();
    end
    container:SetEnabled(true);
    container:Show();
end

local function HideContainers(containers, exceptContainer)
    if not containers then return end

    for _, container in pairs(containers) do
        if container ~= exceptContainer then
            container:SetEnabled(false);
            container:Hide();
        end
    end
end

addon.UpdateBigDebuffs = function(nameplate, frame)
    if not addon.PROJECT_MAINLINE then return end
    if ( not nameplate ) or ( not frame ) or ( not frame.unit ) then return end

    local config = GetConfig();
    if ( not config.bigDebuffsEnabled )
        or ( not UnitIsPlayer(frame.unit) )
        or ( not addon.UnitIsHostile(frame.unit) ) then
        addon.HideBigDebuffs(nameplate);
        return;
    end

    local leftContainer = EnsureContainer(nameplate, RAIL.LEFT, leftGroups);
    local rightContainer = EnsureContainer(nameplate, RAIL.RIGHT, rightGroups);
    HideContainers(nameplate[RAIL.LEFT.containersKey], leftContainer);
    HideContainers(nameplate[RAIL.RIGHT.containersKey], rightContainer);
    ApplyContainerLayout(nameplate, RAIL.LEFT, leftContainer, leftGroups);
    ApplyContainerLayout(nameplate, RAIL.RIGHT, rightContainer, rightGroups);
    ActivateContainer(leftContainer, frame.unit);
    ActivateContainer(rightContainer, frame.unit);
end

addon.HideBigDebuffs = function(nameplate)
    if not nameplate then return end

    HideContainers(nameplate[RAIL.LEFT.containersKey]);
    HideContainers(nameplate[RAIL.RIGHT.containersKey]);
end
