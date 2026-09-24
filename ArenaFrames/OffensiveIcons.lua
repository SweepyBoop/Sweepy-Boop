local _, addon = ...;

if not addon.PROJECT_MAINLINE then return end

local style = addon.ARENA_OFFENSIVE_ICON_STYLE;
local baseIconSize = style.BASE_SIZE;
local identifierBaseSize = math.floor(baseIconSize * addon.COUNTDOWN_FONT_SIZE_COEFFICIENT);
local standaloneHolderHeight = baseIconSize + identifierBaseSize + 2;
local blizzardArenaFramePrefix = "CompactArenaFrameMember";
local offensiveAuraFilter = "HELPFUL|IMPORTANT";
local offensiveAuraSlotKey = "Offensive";
local offensiveAuraGroupKey = "Important";
local defaultArenaFrameStrata = "LOW";
local defaultArenaFrameLevel = 2;
local liveOverlays = {};
local standaloneRoot;
local standaloneTestRoot;
local eventFrame;
local setupComplete = false;
local reconcilePending = false;
local standaloneIdentityRefreshPending = false;

local minStandaloneIcons = 1;
local maxStandaloneIcons = 6;
local minStandaloneColumns = 1;
local maxStandaloneColumns = 16;
local flowLayoutTolerance = 0.01;

local testSamples = {
    { spellID = 190319, name = "Pyra", class = addon.MAGE },
    { spellID = 10060, name = "Solace", class = addon.PRIEST },
    { spellID = 107574, name = "Bulwark", class = addon.WARRIOR },
};

local function GetConfig()
    return SweepyBoop.db.profile.arenaFrames;
end

local function ConfigureCooldownSwipe(cooldown)
    cooldown:SetDrawBling(false);
    cooldown:SetDrawSwipe(true);
    cooldown:SetDrawEdge(true);
    cooldown:SetReverse(true);
    cooldown:SetHideCountdownNumbers(false);
    if cooldown.SetSwipeColor then
        cooldown:SetSwipeColor(0, 0, 0, style.COOLDOWN_SWIPE_ALPHA);
    end
    if cooldown.SetEdgeTexture then
        cooldown:SetEdgeTexture(style.COOLDOWN_EDGE_TEXTURE);
    end
    if cooldown.SetCountdownMillisecondsThreshold then
        cooldown:SetCountdownMillisecondsThreshold(0);
    end
end

local function UpdateCountdownFontSize(cooldown)
    if not cooldown then return end

    if not cooldown.sweepyBoopCountdownFontString then
        local numRegions = cooldown:GetNumRegions();
        for i = 1, numRegions do
            local region = select(i, cooldown:GetRegions());
            if region and ( region:GetObjectType() == "FontString" ) then
                cooldown.sweepyBoopCountdownFontString = region;
                break;
            end
        end
    end

    local region = cooldown.sweepyBoopCountdownFontString;
    if region then
        local font, _, flags = region:GetFont();
        if font then
            region:SetFont(
                font,
                math.floor(baseIconSize * addon.COUNTDOWN_FONT_SIZE_COEFFICIENT),
                flags
            );
        end
    end
end

local function CreateOffensiveIconShadow(frame)
    local shadow = frame:CreateTexture(nil, "OVERLAY", nil, 2);
    shadow:SetTexture(style.SHADOW_TEXTURE);
    shadow:SetTexCoord(unpack(style.SHADOW_TEX_COORDS));
    shadow:SetHorizTile(false);
    shadow:SetVertTile(false);
    shadow:SetAlpha(style.SHADOW_ALPHA);
    shadow:SetSize(style.SHADOW_SIZE, style.SHADOW_SIZE);
    shadow:SetPoint(
        "CENTER",
        frame,
        "CENTER",
        style.SHADOW_OFFSET_X,
        style.SHADOW_OFFSET_Y
    );
    return shadow;
end

local function CreateHighlightTexture(frame, texturePath, layer, alpha)
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
    texture:SetAlpha(alpha);
    return texture;
end

local function GetHighlightColorMap()
    local red, green, blue = unpack(style.HIGHLIGHT_COLOR);
    return {
        Magic = CreateColor(red, green, blue),
        Curse = CreateColor(red, green, blue),
        Disease = CreateColor(red, green, blue),
        Poison = CreateColor(red, green, blue),
        Enrage = CreateColor(red, green, blue),
        None = CreateColor(red, green, blue),
    };
end

local function AddSecureHighlightTexture(button, texturePath, layer, alpha)
    local texture = CreateHighlightTexture(button, texturePath, layer, alpha);
    button:AddDispelTypeTexture(texture, {
        style = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset,
        showWhenHelpful = true,
        showWithoutDispelType = true,
        customDispelColorMap = GetHighlightColorMap(),
    });
end

local function InitializeOffensiveIcon(frame, secureAuraButton)
    frame:SetSize(baseIconSize, baseIconSize);
    frame:SetMouseClickEnabled(false);
    frame:SetMouseMotionEnabled(false);

    CreateOffensiveIconShadow(frame);

    local backdrop = frame:CreateTexture(nil, "BACKGROUND");
    backdrop:SetAllPoints(frame);
    backdrop:SetColorTexture(unpack(style.BACKDROP_COLOR));

    local icon = frame:CreateTexture(nil, "ARTWORK");
    icon:SetPoint("TOPLEFT", frame, "TOPLEFT", style.ICON_INSET, -style.ICON_INSET);
    icon:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -style.ICON_INSET, style.ICON_INSET);
    icon:SetTexCoord(unpack(style.ICON_TEX_COORDS));

    local cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate");
    cooldown:SetAllPoints(icon);
    ConfigureCooldownSwipe(cooldown);
    UpdateCountdownFontSize(cooldown);

    if secureAuraButton then
        frame:SetIcon(icon);
        frame:SetDurationCooldown(cooldown);
        AddSecureHighlightTexture(
            frame,
            addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_GLOW_TEXTURE,
            "BORDER",
            style.HIGHLIGHT_GLOW_ALPHA
        );
        AddSecureHighlightTexture(
            frame,
            addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_BORDER_TEXTURE,
            "OVERLAY",
            style.HIGHLIGHT_BORDER_ALPHA
        );
    else
        local glow = CreateHighlightTexture(
            frame,
            addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_GLOW_TEXTURE,
            "BORDER",
            style.HIGHLIGHT_GLOW_ALPHA
        );
        local border = CreateHighlightTexture(
            frame,
            addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_BORDER_TEXTURE,
            "OVERLAY",
            style.HIGHLIGHT_BORDER_ALPHA
        );
        glow:SetVertexColor(unpack(style.HIGHLIGHT_COLOR));
        border:SetVertexColor(unpack(style.HIGHLIGHT_COLOR));
        frame.icon = icon;
        frame.cooldown = cooldown;
    end
end

local function InitializeLiveAuraButton(button, container)
    InitializeOffensiveIcon(button, true);
    button:ClearAllPoints();
    button:SetPoint("LEFT", container, "LEFT");
end

local function EnsureLiveOverlay(index)
    local overlay = liveOverlays[index];
    if overlay then return overlay end

    local arenaFrame = _G[blizzardArenaFramePrefix .. index];
    if ( not arenaFrame ) or InCombatLockdown() then
        reconcilePending = true;
        return;
    end

    local root = CreateFrame("Frame", nil, arenaFrame);
    root:SetMouseClickEnabled(false);
    root:SetSize(baseIconSize, baseIconSize);
    root:Hide();

    local container = CreateFrame(
        "AuraContainer",
        nil,
        root,
        "CustomAuraContainerTemplate"
    );
    container:Hide();
    container:SetAllPoints(root);
    container:SetAuraProcessingPolicy(
        CustomAuraContainerAuraProcessingPolicy.ProcessAura,
        {
            displayOnlyDispellableDebuffs = false,
            ignoreBuffs = false,
            ignoreDebuffs = true,
            ignoreDispelDebuffs = true,
        }
    );
    container:AddAuraSlot(offensiveAuraSlotKey, offensiveAuraFilter, {
        sortMethod = AuraContainerSortMethod.ImportantOnly,
        sortDirection = AuraContainerSortDirection.Normal,
        initializeFrame = function(button)
            InitializeLiveAuraButton(button, container);
        end,
    });
    container:SetUnit("arena" .. index);

    overlay = {
        root = root,
        container = container,
        index = index,
        unit = "arena" .. index,
    };
    liveOverlays[index] = overlay;
    return overlay;
end

local function ApplyLiveOverlayLayout(overlay)
    local arenaFrame = _G[blizzardArenaFramePrefix .. overlay.index];
    if ( not arenaFrame ) or overlay.root:GetParent() ~= arenaFrame then
        return false;
    end

    local config = GetConfig();
    local size = config.arenaOffensiveIconSize or style.DEFAULT_DISPLAY_SIZE;
    local offsetX = config.arenaOffensiveIconOffsetX or 0;
    local offsetY = config.arenaOffensiveIconOffsetY or 0;
    local frameStrata = arenaFrame:GetFrameStrata();
    if addon.IsSecretValue(frameStrata) then
        frameStrata = defaultArenaFrameStrata;
    end

    local arenaFrameLevel = arenaFrame:GetFrameLevel();
    if addon.IsSecretValue(arenaFrameLevel) then
        arenaFrameLevel = defaultArenaFrameLevel;
    end
    local frameLevel = arenaFrameLevel + 20;
    if overlay.size == size
        and overlay.offsetX == offsetX
        and overlay.offsetY == offsetY
        and overlay.frameStrata == frameStrata
        and overlay.frameLevel == frameLevel then

        return true;
    end

    if InCombatLockdown() then
        reconcilePending = true;
        return overlay.layoutApplied == true;
    end

    local scale = size / baseIconSize;
    overlay.root:SetFrameStrata(frameStrata);
    overlay.root:SetFrameLevel(frameLevel);
    overlay.root:SetScale(scale);
    overlay.root:ClearAllPoints();
    overlay.root:SetPoint(
        "LEFT",
        arenaFrame,
        "LEFT",
        offsetX / scale,
        offsetY / scale
    );
    overlay.size = size;
    overlay.offsetX = offsetX;
    overlay.offsetY = offsetY;
    overlay.frameStrata = frameStrata;
    overlay.frameLevel = frameLevel;
    overlay.layoutApplied = true;
    return true;
end

local function SetLiveOverlayShown(overlay, shown)
    if overlay.shown == shown then return true end
    if InCombatLockdown() then
        reconcilePending = true;
        return false;
    end

    overlay.shown = shown;
    if shown then
        overlay.root:Show();
        overlay.container:Show();
    else
        overlay.container:Hide();
        overlay.root:Hide();
    end
    return true;
end

local function UpdateLiveOverlay(index, forceRefresh)
    local overlay = EnsureLiveOverlay(index);
    if not overlay then return end

    local config = GetConfig();
    if ( not config.arenaOffensiveIconsEnabled )
        or ( not addon.IsUsingRealAuraData() )
        or ( not ApplyLiveOverlayLayout(overlay) ) then

        SetLiveOverlayShown(overlay, false);
        return;
    end

    if overlay.container:GetUnit() ~= overlay.unit then
        if InCombatLockdown() then
            reconcilePending = true;
            return;
        end
        overlay.container:SetUnit(overlay.unit);
    elseif forceRefresh then
        overlay.container:UpdateAllAuras();
    end
    SetLiveOverlayShown(overlay, true);
end

local function UpdateLiveOverlays(forceRefresh)
    if not SweepyBoop.db then return end

    for i = 1, addon.MAX_ARENA_SIZE do
        UpdateLiveOverlay(i, forceRefresh);
    end
end

local function Clamp(value, minValue, maxValue)
    value = math.floor(tonumber(value) or minValue);
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value;
end

local function CanAccessStandaloneDecorations()
    return ( not C_Secrets )
        or ( not C_Secrets.ShouldAurasBeSecret )
        or ( not C_Secrets.ShouldAurasBeSecret() );
end

local function GetStandaloneBorderStyle(config)
    local borderStyle = config.arenaStandaloneOffensiveIconBorderStyle;
    if borderStyle == addon.BIG_DEBUFFS_ICON_STYLE_ID.DEBUFF_BORDER
        or borderStyle == addon.BIG_DEBUFFS_ICON_STYLE_ID.HIGHLIGHT then

        return borderStyle;
    end

    return addon.BIG_DEBUFFS_DEFAULTS.ICON_STYLE;
end

local function GetStandaloneLayout()
    local config = GetConfig();
    local size = tonumber(config.arenaStandaloneOffensiveIconSize)
        or style.DEFAULT_DISPLAY_SIZE;
    if size <= 0 then
        size = style.DEFAULT_DISPLAY_SIZE;
    end

    local scale = size / baseIconSize;
    local spacing = math.max(
        0,
        tonumber(config.arenaStandaloneOffensiveIconPadding) or 0
    ) / scale;
    local maxIcons = Clamp(
        config.arenaStandaloneOffensiveIconMaxIcons,
        minStandaloneIcons,
        maxStandaloneIcons
    );
    local columns = Clamp(
        config.arenaStandaloneOffensiveIconColumns,
        minStandaloneColumns,
        maxStandaloneColumns
    );
    local effectiveColumns = math.min(columns, maxIcons);
    local rows = math.ceil(maxIcons / effectiveColumns);
    local holderWidth = effectiveColumns * baseIconSize
        + ( effectiveColumns - 1 ) * spacing;
    local holderHeight = rows * standaloneHolderHeight
        + ( rows - 1 ) * spacing;
    local growDirection = config.arenaStandaloneOffensiveIconGrowDirection;
    if growDirection ~= addon.STANDALONE_GROW_DIRECTION.LEFT
        and growDirection ~= addon.STANDALONE_GROW_DIRECTION.RIGHT then

        growDirection = addon.STANDALONE_GROW_DIRECTION.CENTER;
    end

    local growUpward = config.arenaStandaloneOffensiveIconGrowUpward ~= false;
    local horizontalFlowDirection = growDirection == addon.STANDALONE_GROW_DIRECTION.LEFT
        and AnchorUtil.FlowDirection.Left
        or AnchorUtil.FlowDirection.Right;
    local verticalFlowDirection = growUpward
        and AnchorUtil.FlowDirection.Up
        or AnchorUtil.FlowDirection.Down;
    local verticalAnchor = growUpward and "BOTTOM" or "TOP";
    local horizontalAnchor;
    if growDirection == addon.STANDALONE_GROW_DIRECTION.LEFT then
        horizontalAnchor = "RIGHT";
    elseif growDirection == addon.STANDALONE_GROW_DIRECTION.RIGHT then
        horizontalAnchor = "LEFT";
    else
        horizontalAnchor = "";
    end

    local containerPoint = verticalAnchor .. horizontalAnchor;
    if horizontalAnchor == "" then
        containerPoint = verticalAnchor;
    end
    local flowAnchorPoint = verticalAnchor
        .. ( horizontalFlowDirection == AnchorUtil.FlowDirection.Left and "RIGHT" or "LEFT" );

    return {
        scale = scale,
        spacing = spacing,
        maxIcons = maxIcons,
        effectiveColumns = effectiveColumns,
        rows = rows,
        holderWidth = holderWidth,
        holderHeight = holderHeight,
        rootWidth = addon.MAX_ARENA_SIZE * holderWidth
            + ( addon.MAX_ARENA_SIZE - 1 ) * spacing,
        rootHeight = holderHeight,
        rowWidth = holderWidth,
        growDirection = growDirection,
        growUpward = growUpward,
        horizontalFlowDirection = horizontalFlowDirection,
        verticalFlowDirection = verticalFlowDirection,
        containerPoint = containerPoint,
        flowAnchorPoint = flowAnchorPoint,
        offsetX = ( tonumber(config.arenaStandaloneOffensiveIconOffsetX) or 0 ) / scale,
        offsetY = ( tonumber(config.arenaStandaloneOffensiveIconOffsetY) or 0 ) / scale,
    };
end

local function GetStandaloneLayoutSignature(layout)
    return table.concat({
        layout.scale,
        layout.spacing,
        layout.maxIcons,
        layout.effectiveColumns,
        layout.growDirection,
        tostring(layout.growUpward),
        layout.offsetX,
        layout.offsetY,
    }, ":");
end

local function CreateStandaloneIdentifier(button)
    local identifier = button:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    local font, _, flags = identifier:GetFont();
    if font then
        identifier:SetFont(font, identifierBaseSize, flags);
    end
    identifier:SetPoint("TOP", button, "TOP", 0, -baseIconSize - 2);
    identifier:SetWidth(baseIconSize);
    identifier:SetJustifyH("CENTER");
    identifier:SetWordWrap(false);
    return identifier;
end

local function CreatePlainBorder(frame)
    local border = frame:CreateTexture(nil, "OVERLAY");
    local padding = addon.BIG_DEBUFFS_ICON_STYLE.DEBUFF_BORDER_PADDING;
    border:SetPoint("TOPLEFT", frame, "TOPLEFT", -padding, padding);
    border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", padding, -padding);
    border:SetTexture(addon.BIG_DEBUFFS_ICON_STYLE.DEBUFF_BORDER_TEXTURE);
    border:SetTexCoord(unpack(addon.BIG_DEBUFFS_ICON_STYLE.DEBUFF_BORDER_TEX_COORDS));
    return border;
end

local function CreateStandaloneBaseVisual(button, secureAuraButton)
    button:SetSize(baseIconSize, standaloneHolderHeight);
    button:SetMouseClickEnabled(false);
    button:SetMouseMotionEnabled(false);

    local visual = CreateFrame("Frame", nil, button);
    visual:SetSize(baseIconSize, baseIconSize);
    visual:SetPoint("TOP", button, "TOP");
    CreateOffensiveIconShadow(visual);

    local backdrop = visual:CreateTexture(nil, "BACKGROUND");
    backdrop:SetAllPoints(visual);
    backdrop:SetColorTexture(unpack(style.BACKDROP_COLOR));

    local icon = visual:CreateTexture(nil, "ARTWORK");
    icon:SetPoint("TOPLEFT", visual, "TOPLEFT", style.ICON_INSET, -style.ICON_INSET);
    icon:SetPoint("BOTTOMRIGHT", visual, "BOTTOMRIGHT", -style.ICON_INSET, style.ICON_INSET);
    icon:SetTexCoord(unpack(style.ICON_TEX_COORDS));

    local cooldown = CreateFrame("Cooldown", nil, visual, "CooldownFrameTemplate");
    cooldown:SetAllPoints(icon);
    ConfigureCooldownSwipe(cooldown);
    UpdateCountdownFontSize(cooldown);

    if secureAuraButton then
        button:SetIcon(icon);
        button:SetDurationCooldown(cooldown);
    else
        button.icon = icon;
        button.cooldown = cooldown;
    end

    return visual, icon, cooldown;
end

local function CreateStandaloneDecoration(button, secureAuraButton)
    local visual = CreateStandaloneBaseVisual(button, secureAuraButton);
    local decoration = {
        identifier = CreateStandaloneIdentifier(button),
        plainBorder = CreatePlainBorder(visual),
        tintTextures = {},
    };
    decoration.highlightGlow = CreateHighlightTexture(
        visual,
        addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_GLOW_TEXTURE,
        "BORDER",
        style.HIGHLIGHT_GLOW_ALPHA
    );
    decoration.highlightBorder = CreateHighlightTexture(
        visual,
        addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_BORDER_TEXTURE,
        "OVERLAY",
        style.HIGHLIGHT_BORDER_ALPHA
    );
    decoration.plainBorder:Hide();
    decoration.highlightGlow:Hide();
    decoration.highlightBorder:Hide();
    decoration.tintTextures[1] = decoration.plainBorder;
    decoration.tintTextures[2] = decoration.highlightGlow;
    decoration.tintTextures[3] = decoration.highlightBorder;
    return decoration;
end

local function GetStandaloneIdentity(index, sample)
    local name = sample and sample.name or UnitName("arena" .. index);
    local class = sample and sample.class or addon.GetClassForPlayerOrArena("arena" .. index);
    if addon.IsSecretValue(name) then
        name = nil;
    end
    if addon.IsSecretValue(class) then
        class = nil;
    end
    return name, class;
end

local function ApplyStandaloneDecorationIdentity(decoration, index, sample)
    if ( not sample ) and ( not CanAccessStandaloneDecorations() ) then
        standaloneIdentityRefreshPending = true;
        return false;
    end

    local config = GetConfig();
    local name, class = GetStandaloneIdentity(index, sample);
    local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class];
    local red = color and color.r or 1;
    local green = color and color.g or 1;
    local blue = color and color.b or 1;

    for _, texture in ipairs(decoration.tintTextures) do
        texture:SetVertexColor(red, green, blue, 1);
    end

    local useHighlight = GetStandaloneBorderStyle(config)
        == addon.BIG_DEBUFFS_ICON_STYLE_ID.HIGHLIGHT;
    decoration.plainBorder:SetShown(not useHighlight);
    decoration.highlightGlow:SetShown(useHighlight);
    decoration.highlightBorder:SetShown(useHighlight);

    local identifier = decoration.identifier;
    local identifierMode = config.arenaStandaloneOffensiveIconIdentifier;
    if identifierMode == addon.ARENA_OFFENSIVE_ICON_IDENTIFIER.NONE then
        identifier:Hide();
        return true;
    end

    local identifierText;
    if identifierMode == addon.ARENA_OFFENSIVE_ICON_IDENTIFIER.NAME then
        identifierText = name;
    else
        identifierText = tostring(index);
    end

    if addon.IsSecretValue(identifierText) or identifierText == nil then
        identifier:Hide();
        return true;
    end

    identifier:SetText(identifierText);
    identifier:SetTextColor(red, green, blue);
    identifier:Show();
    return true;
end

local function RefreshStandaloneIdentities(root, samples)
    if not root then return false end
    if ( not samples ) and ( not CanAccessStandaloneDecorations() ) then
        standaloneIdentityRefreshPending = true;
        return false;
    end

    local refreshed = true;
    for index, holder in ipairs(root.holders) do
        local sample = samples and samples[index];
        if samples then
            for _, decoration in ipairs(holder.testDecorations) do
                ApplyStandaloneDecorationIdentity(decoration, index, sample);
            end
        else
            for _, decoration in ipairs(holder.container.sweepyBoopIdentityDecorations) do
                if not ApplyStandaloneDecorationIdentity(decoration, index) then
                    refreshed = false;
                end
            end
        end
    end

    if not samples then
        standaloneIdentityRefreshPending = not refreshed;
    end
    return refreshed;
end

local function InitializeStandaloneAuraButton(button, container, index)
    local decoration = CreateStandaloneDecoration(button, true);
    container.sweepyBoopIdentityDecorations[
        #container.sweepyBoopIdentityDecorations + 1
    ] = decoration;

    ApplyStandaloneDecorationIdentity(decoration, index);
end

local function CreateStandaloneContainer(holder, index)
    local container = CreateFrame(
        "AuraContainer",
        nil,
        holder,
        "CustomAuraContainerTemplate"
    );
    container:Hide();
    container:SetAuraProcessingPolicy(
        CustomAuraContainerAuraProcessingPolicy.ProcessAura,
        {
            displayOnlyDispellableDebuffs = false,
            ignoreBuffs = false,
            ignoreDebuffs = true,
            ignoreDispelDebuffs = true,
        }
    );
    container.sweepyBoopIdentityDecorations = {};
    container:AddAuraGroup(offensiveAuraGroupKey, offensiveAuraFilter, {
        maxFrameCount = Clamp(
            GetConfig().arenaStandaloneOffensiveIconMaxIcons,
            minStandaloneIcons,
            maxStandaloneIcons
        ),
        sortMethod = AuraContainerSortMethod.Default,
        sortDirection = AuraContainerSortDirection.Normal,
        initializeFrame = function(button)
            InitializeStandaloneAuraButton(button, container, index);
        end,
        layout = {
            elementSpacing = 0,
            lineSpacing = 0,
            elementWidth = baseIconSize,
            elementHeight = standaloneHolderHeight,
        },
    });
    container:SetUnit("arena" .. index);
    return container;
end

local function ApplyStandaloneContainerLayout(holder, container, layout)
    container:ClearAllPoints();
    container:SetPoint(layout.containerPoint, holder, layout.containerPoint);
    container:SetFlowLayoutAxis(AnchorUtil.FlowLayoutAxis.Horizontal);
    container:SetFlowLayoutAnchorPoint(layout.flowAnchorPoint);
    container:SetFlowLayoutGrowthDirection(
        layout.horizontalFlowDirection,
        layout.verticalFlowDirection
    );
    container:SetFlowLayoutMaximumLineSize(layout.rowWidth + flowLayoutTolerance);
    container:SetAuraGroupMaxFrameCount(offensiveAuraGroupKey, layout.maxIcons);
    container:SetAuraGroupLayout(offensiveAuraGroupKey, {
        elementSpacing = layout.spacing,
        lineSpacing = layout.spacing,
        elementWidth = baseIconSize,
        elementHeight = standaloneHolderHeight,
    });
end

local function ApplyStandaloneRootLayout(root, layout, isTest)
    local signature = GetStandaloneLayoutSignature(layout);
    if root.sweepyBoopLayoutSignature == signature then
        return true;
    end
    if ( not isTest ) and InCombatLockdown() then
        reconcilePending = true;
        return false;
    end

    root:SetScale(layout.scale);
    root:SetSize(layout.rootWidth, layout.rootHeight);
    root:ClearAllPoints();
    root:SetPoint(
        "CENTER",
        UIParent,
        "CENTER",
        layout.offsetX,
        layout.offsetY
    );

    for index, holder in ipairs(root.holders) do
        holder:SetSize(layout.holderWidth, layout.holderHeight);
        holder:ClearAllPoints();
        holder:SetPoint(
            "TOPLEFT",
            root,
            "TOPLEFT",
            ( index - 1 ) * ( layout.holderWidth + layout.spacing ),
            0
        );
        if not isTest then
            ApplyStandaloneContainerLayout(holder, holder.container, layout);
        end
    end

    root.sweepyBoopLayoutSignature = signature;
    return true;
end

local function EnsureStandaloneRoot()
    if standaloneRoot then return standaloneRoot end
    if InCombatLockdown() or ( not CanAccessStandaloneDecorations() ) then
        reconcilePending = true;
        return;
    end

    local root = CreateFrame("Frame", nil, UIParent);
    root:SetMouseClickEnabled(false);
    root:SetSize(1, 1);
    root:Hide();
    root.holders = {};

    for index = 1, addon.MAX_ARENA_SIZE do
        local holder = CreateFrame("Frame", nil, root);
        holder.index = index;
        holder.container = CreateStandaloneContainer(holder, index);
        root.holders[index] = holder;
    end

    standaloneRoot = root;
    ApplyStandaloneRootLayout(root, GetStandaloneLayout(), false);
    RefreshStandaloneIdentities(root);
    return root;
end

local function SetStandaloneRootShown(root, shown)
    if root.sweepyBoopShown == shown then return true end
    if InCombatLockdown() then
        reconcilePending = true;
        return false;
    end

    if shown then
        root:Show();
        for _, holder in ipairs(root.holders) do
            holder.container:Show();
        end
    else
        for _, holder in ipairs(root.holders) do
            holder.container:Hide();
        end
        root:Hide();
    end
    root.sweepyBoopShown = shown;
    return true;
end

local function UpdateStandaloneRoot(forceRefresh)
    if not SweepyBoop.db then return end

    local root = EnsureStandaloneRoot();
    if not root then return end

    local config = GetConfig();
    if ( not config.arenaStandaloneOffensiveIconsEnabled )
        or ( not addon.IsUsingRealAuraData() ) then

        SetStandaloneRootShown(root, false);
        return;
    end

    local layout = GetStandaloneLayout();
    if not ApplyStandaloneRootLayout(root, layout, false) then
        return;
    end

    RefreshStandaloneIdentities(root);
    for index, holder in ipairs(root.holders) do
        local container = holder.container;
        local unit = "arena" .. index;
        if container:GetUnit() ~= unit then
            if InCombatLockdown() then
                reconcilePending = true;
                return;
            end
            container:SetUnit(unit);
        elseif forceRefresh then
            container:UpdateAllAuras();
        end
    end
    SetStandaloneRootShown(root, true);
end

local function RestartTestCooldown(button, elapsed)
    if not standaloneTestRoot
        or not standaloneTestRoot:IsShown()
        or not button:IsShown() then

        return;
    end
    button.cooldown:SetCooldown(GetTime() - ( elapsed or 0 ), 18);
end

local function CreateStandaloneTestButton(holder, holderIndex, buttonIndex)
    local button = CreateFrame("Frame", nil, holder);
    local decoration = CreateStandaloneDecoration(button, false);
    local textureSample = testSamples[( buttonIndex + holderIndex - 2 ) % #testSamples + 1];
    button.icon:SetTexture(addon.GetSpellTexture(textureSample.spellID));
    button.cooldown:SetScript("OnCooldownDone", function()
        RestartTestCooldown(button);
    end);
    holder.testDecorations[buttonIndex] = decoration;
    holder.testButtons[buttonIndex] = button;
end

local function EnsureStandaloneTestRoot()
    if standaloneTestRoot then return standaloneTestRoot end

    local root = CreateFrame("Frame", nil, UIParent);
    root:SetMouseClickEnabled(false);
    root:SetSize(1, 1);
    root:Hide();
    root.holders = {};

    for index = 1, addon.MAX_ARENA_SIZE do
        local holder = CreateFrame("Frame", nil, root);
        holder.index = index;
        holder.testButtons = {};
        holder.testDecorations = {};
        for buttonIndex = 1, maxStandaloneIcons do
            CreateStandaloneTestButton(holder, index, buttonIndex);
        end
        root.holders[index] = holder;
    end

    standaloneTestRoot = root;
    return root;
end

local function ApplyStandaloneTestLayout(root, layout)
    ApplyStandaloneRootLayout(root, layout, true);

    for _, holder in ipairs(root.holders) do
        for buttonIndex, button in ipairs(holder.testButtons) do
            button:ClearAllPoints();
            if buttonIndex <= layout.maxIcons then
                local column = ( buttonIndex - 1 ) % layout.effectiveColumns;
                local row = math.floor(( buttonIndex - 1 ) / layout.effectiveColumns);
                local x = column * ( baseIconSize + layout.spacing );
                local y = row * ( standaloneHolderHeight + layout.spacing );
                local point;
                if layout.growDirection == addon.STANDALONE_GROW_DIRECTION.LEFT then
                    point = layout.growUpward and "BOTTOMRIGHT" or "TOPRIGHT";
                    x = -x;
                else
                    point = layout.growUpward and "BOTTOMLEFT" or "TOPLEFT";
                end
                if not layout.growUpward then
                    y = -y;
                end
                button:SetPoint(point, holder, point, x, y);
                button:Show();
            else
                button:Hide();
            end
        end
    end
end

local function RefreshStandaloneTestRoot()
    if not standaloneTestRoot or not standaloneTestRoot:IsShown() then return end
    if not GetConfig().arenaStandaloneOffensiveIconsEnabled then
        standaloneTestRoot:Hide();
        return;
    end

    local layout = GetStandaloneLayout();
    ApplyStandaloneTestLayout(standaloneTestRoot, layout);
    RefreshStandaloneIdentities(standaloneTestRoot, testSamples);
    for _, holder in ipairs(standaloneTestRoot.holders) do
        for buttonIndex = 1, layout.maxIcons do
            RestartTestCooldown(holder.testButtons[buttonIndex], buttonIndex * 2);
        end
    end
end

local function ReconcileStandaloneAuraRestrictions()
    if not CanAccessStandaloneDecorations() then
        standaloneIdentityRefreshPending = true;
        return;
    end

    if standaloneIdentityRefreshPending then
        RefreshStandaloneIdentities(standaloneRoot);
    end
    if reconcilePending and ( not InCombatLockdown() ) then
        reconcilePending = false;
        UpdateLiveOverlays(true);
        UpdateStandaloneRoot(true);
    end
end

function SweepyBoop:TestArenaStandaloneOffensiveIcons()
    if IsInInstance() then
        addon.PRINT(addon.L["Test mode can only be used outside instances"]);
        return;
    end
    if not GetConfig().arenaStandaloneOffensiveIconsEnabled then return end

    local root = EnsureStandaloneTestRoot();
    root:Show();
    RefreshStandaloneTestRoot();
end

function SweepyBoop:HideTestArenaStandaloneOffensiveIcons()
    if standaloneTestRoot then
        standaloneTestRoot:Hide();
    end
end

function SweepyBoop:UpdateArenaOffensiveIcons()
    UpdateLiveOverlays();
    UpdateStandaloneRoot();
    RefreshStandaloneTestRoot();
end

function SweepyBoop:SetupArenaOffensiveIcons()
    if setupComplete then
        UpdateLiveOverlays();
        UpdateStandaloneRoot();
        return;
    end
    setupComplete = true;

    for i = 1, addon.MAX_ARENA_SIZE do
        EnsureLiveOverlay(i);
    end
    EnsureStandaloneRoot();

    eventFrame = CreateFrame("Frame");
    eventFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
    eventFrame:RegisterEvent(addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS);
    eventFrame:RegisterEvent(addon.ARENA_OPPONENT_UPDATE);
    eventFrame:RegisterEvent(addon.PVP_MATCH_STATE_CHANGED);
    eventFrame:RegisterEvent(addon.PLAYER_REGEN_ENABLED);
    eventFrame:RegisterEvent("PVP_MATCH_ACTIVE");
    eventFrame:RegisterEvent("PVP_MATCH_COMPLETE");
    eventFrame:RegisterEvent("UNIT_NAME_UPDATE");
    eventFrame:SetScript("OnEvent", function(_, event, unit)
        if event == addon.PLAYER_ENTERING_WORLD and standaloneTestRoot then
            standaloneTestRoot:Hide();
        end
        if event == addon.PLAYER_REGEN_ENABLED then
            if ( not reconcilePending ) and ( not standaloneIdentityRefreshPending ) then
                return;
            end
            reconcilePending = false;
            UpdateLiveOverlays(true);
            UpdateStandaloneRoot(true);
            RefreshStandaloneIdentities(standaloneRoot);
            return;
        end
        if event == "UNIT_NAME_UPDATE" then
            if unit ~= "arena1" and unit ~= "arena2" and unit ~= "arena3" then return end
            RefreshStandaloneIdentities(standaloneRoot);
            return;
        end

        UpdateLiveOverlays(true);
        UpdateStandaloneRoot(true);
    end);

    addon.RegisterAuraDataProviderListener("ArenaOffensiveIcons", function()
        UpdateLiveOverlays(true);
        UpdateStandaloneRoot(true);
    end);
    addon.RegisterAuraRestrictionListener(
        "ArenaOffensiveIcons",
        ReconcileStandaloneAuraRestrictions
    );

    UpdateLiveOverlays();
    UpdateStandaloneRoot();
end
