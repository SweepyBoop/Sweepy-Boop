local _, addon = ...;

if not addon.PROJECT_MAINLINE then return end

local style = addon.ARENA_OFFENSIVE_ICON_STYLE;
local standaloneBorderStyle = addon.ARENA_STANDALONE_OFFENSIVE_BORDER_STYLE;
local baseIconSize = style.BASE_SIZE;
local standaloneLabelLineSpacing = 2;
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
local standaloneDecorationRefreshPending = false;

local minStandaloneIcons = 1;
local maxStandaloneIcons = 6;
local minStandaloneColumns = 1;
local maxStandaloneColumns = 16;
local flowLayoutTolerance = 0.01;

local testSamples = {
    { spellID = 190319, name = "Pyra", class = addon.MAGE, specID = addon.SPECID.FIRE },
    { spellID = 10060, name = "Solace", class = addon.PRIEST, specID = addon.SPECID.DISCIPLINE },
    { spellID = 107574, name = "Bulwark", class = addon.WARRIOR, specID = addon.SPECID.ARMS },
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
    local iconSpacing = math.max(
        0,
        tonumber(config.arenaStandaloneOffensiveIconPadding) or 0
    ) / scale;
    local groupSpacing = math.max(
        0,
        tonumber(config.arenaStandaloneOffensiveIconGroupSpacing) or 0
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
    local maxLineWidth = effectiveColumns * baseIconSize
        + ( effectiveColumns - 1 ) * iconSpacing;
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
    local flowAnchorPoint = verticalAnchor
        .. ( horizontalFlowDirection == AnchorUtil.FlowDirection.Left and "RIGHT" or "LEFT" );

    return {
        scale = scale,
        iconSpacing = iconSpacing,
        groupSpacing = groupSpacing,
        maxIcons = maxIcons,
        effectiveColumns = effectiveColumns,
        maxLineWidth = maxLineWidth,
        growDirection = growDirection,
        growUpward = growUpward,
        horizontalFlowDirection = horizontalFlowDirection,
        verticalFlowDirection = verticalFlowDirection,
        verticalAnchor = verticalAnchor,
        flowAnchorPoint = flowAnchorPoint,
        offsetX = ( tonumber(config.arenaStandaloneOffensiveIconOffsetX) or 0 ) / scale,
        offsetY = ( tonumber(config.arenaStandaloneOffensiveIconOffsetY) or 0 ) / scale,
    };
end

local function GetStandaloneLayoutSignature(layout)
    return table.concat({
        layout.scale,
        layout.iconSpacing,
        layout.groupSpacing,
        layout.maxIcons,
        layout.effectiveColumns,
        layout.growDirection,
        tostring(layout.growUpward),
        layout.offsetX,
        layout.offsetY,
    }, ":");
end

local function CreateStandaloneBorderTexture(
    frame,
    texturePath,
    padding,
    layer,
    sublevel,
    blendMode,
    alpha
)
    local texture = frame:CreateTexture(nil, layer, nil, sublevel);
    texture:SetTexture(texturePath, "CLAMP", "CLAMP");
    texture:SetPoint("TOPLEFT", frame, "TOPLEFT", -padding, padding);
    texture:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", padding, -padding);
    texture:SetTexCoord(0, 1, 0, 1);
    texture:SetBlendMode(blendMode);
    texture:SetAlpha(alpha);
    return texture;
end

local function CreateStandaloneBaseVisual(button, secureAuraButton)
    button:SetSize(baseIconSize, baseIconSize);
    button:SetMouseClickEnabled(false);
    button:SetMouseMotionEnabled(false);

    local visual = CreateFrame("Frame", nil, button);
    visual:SetSize(baseIconSize, baseIconSize);
    visual:SetPoint("TOP", button, "TOP");

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
        plainBorder = CreateStandaloneBorderTexture(
            visual,
            standaloneBorderStyle.PLAIN_BORDER_TEXTURE,
            standaloneBorderStyle.PLAIN_BORDER_PADDING,
            "OVERLAY",
            1,
            "BLEND",
            1
        ),
        tintTextures = {},
    };
    decoration.highlightGlow = CreateStandaloneBorderTexture(
        visual,
        standaloneBorderStyle.HIGHLIGHT_GLOW_TEXTURE,
        standaloneBorderStyle.HIGHLIGHT_GLOW_PADDING,
        "BORDER",
        0,
        "ADD",
        standaloneBorderStyle.HIGHLIGHT_GLOW_ALPHA
    );
    decoration.highlightBorder = CreateStandaloneBorderTexture(
        visual,
        standaloneBorderStyle.HIGHLIGHT_BORDER_TEXTURE,
        standaloneBorderStyle.HIGHLIGHT_BORDER_PADDING,
        "OVERLAY",
        2,
        "BLEND",
        1
    );
    decoration.plainBorder:Hide();
    decoration.highlightGlow:Hide();
    decoration.highlightBorder:Hide();
    decoration.tintTextures[1] = decoration.plainBorder;
    decoration.tintTextures[2] = decoration.highlightGlow;
    decoration.tintTextures[3] = decoration.highlightBorder;
    return decoration;
end

local function CreateStandaloneLabelLine(host, fontObject)
    local line = host:CreateFontString(nil, "OVERLAY", fontObject);
    line:SetJustifyH("CENTER");
    line:SetJustifyV("MIDDLE");
    line:SetWordWrap(false);
    if line.SetMaxLines then
        line:SetMaxLines(1);
    end
    local _, fontSize = line:GetFont();
    line:SetHeight(fontSize or 12);
    return line, fontSize or 12;
end

local function CreateStandaloneLabelHost(parent, relativeFrame)
    local host = CreateFrame(
        "Frame",
        nil,
        parent,
        "DisableUntrustedLayoutScriptsTemplate"
    );
    host:SetMouseClickEnabled(false);
    host:SetMouseMotionEnabled(false);
    host:SetSize(1, 1);
    host:SetPoint("TOP", relativeFrame, "BOTTOM", 0, -2);
    host:Hide();

    local number, numberHeight =
        CreateStandaloneLabelLine(host, "GameFontNormalLarge");
    local spec, standardHeight =
        CreateStandaloneLabelLine(host, "GameFontNormal");
    local name = CreateStandaloneLabelLine(host, "GameFontNormal");

    return {
        host = host,
        number = number,
        spec = spec,
        name = name,
        numberHeight = numberHeight,
        standardHeight = standardHeight,
    };
end

local function ClearStandaloneLabelLine(line)
    if line.ClearText then
        line:ClearText();
    else
        line:SetText("");
    end
    line:Hide();
end

local function ClearStandaloneLabel(label)
    ClearStandaloneLabelLine(label.number);
    ClearStandaloneLabelLine(label.spec);
    ClearStandaloneLabelLine(label.name);
    label.host:Hide();
end

local function ApplyStandaloneLabel(label, numberText, specText, nameText, color)
    ClearStandaloneLabel(label);
    local lines = {};
    if numberText then
        lines[#lines + 1] = {
            fontString = label.number,
            height = label.numberHeight,
            text = numberText,
        };
    end
    if specText then
        lines[#lines + 1] = {
            fontString = label.spec,
            height = label.standardHeight,
            text = specText,
        };
    end
    if nameText then
        lines[#lines + 1] = {
            fontString = label.name,
            height = label.standardHeight,
            text = nameText,
        };
    end
    if #lines == 0 then return end

    local height = standaloneLabelLineSpacing * ( #lines - 1 );
    for _, lineInfo in ipairs(lines) do
        height = height + lineInfo.height;
    end
    label.host:SetHeight(height);

    local offsetY = 0;
    local red, green, blue = color[1], color[2], color[3];
    for _, lineInfo in ipairs(lines) do
        local line = lineInfo.fontString;
        line:ClearAllPoints();
        line:SetPoint("TOP", label.host, "TOP", 0, -offsetY);
        line:SetText(lineInfo.text);
        line:SetTextColor(red, green, blue);
        line:Show();
        offsetY = offsetY + lineInfo.height + standaloneLabelLineSpacing;
    end
    label.host:Show();
end

local function GetSafeStandaloneIdentity(index, sample)
    local config = GetConfig();
    local unit = "arena" .. index;
    local class;
    if sample then
        class = sample.class;
    else
        class = addon.GetClassForPlayerOrArena(unit);
    end
    if addon.IsSecretValue(class) then return end
    if type(class) ~= "string" then return end

    local colorMap = RAID_CLASS_COLORS;
    if not colorMap then return end
    local classColor = colorMap[class];
    if addon.IsSecretValue(classColor) then return end
    if classColor == nil then return end

    local red = classColor.r;
    if addon.IsSecretValue(red) then return end
    local green = classColor.g;
    if addon.IsSecretValue(green) then return end
    local blue = classColor.b;
    if addon.IsSecretValue(blue) then return end
    if red == nil or green == nil or blue == nil then return end

    local name;
    if config.arenaStandaloneOffensiveIconShowName then
        local candidateName;
        if sample then
            candidateName = sample.name;
        else
            candidateName = UnitName(unit);
        end
        if not addon.IsSecretValue(candidateName)
            and type(candidateName) == "string"
            and candidateName ~= "" then

            name = candidateName;
        end
    end

    local specName;
    if config.arenaStandaloneOffensiveIconShowSpec then
        local specID;
        if sample then
            specID = sample.specID;
        else
            specID = addon.GetSpecForPlayerOrArena(unit);
        end
        if not addon.IsSecretValue(specID) and type(specID) == "number" and specID > 0 then
            local candidateSpecName = select(2, GetSpecializationInfoByID(specID));
            if not addon.IsSecretValue(candidateSpecName)
                and type(candidateSpecName) == "string"
                and candidateSpecName ~= "" then

                specName = candidateSpecName;
            end
        end
    end

    local arenaNumber = config.arenaStandaloneOffensiveIconShowArenaNumber
        and tostring(index)
        or nil;

    return arenaNumber, specName, name, { red, green, blue };
end

local function ApplyStandaloneDecorationStyle(decoration, color)
    decoration.plainBorder:Hide();
    decoration.highlightGlow:Hide();
    decoration.highlightBorder:Hide();
    if not color then return end

    for _, texture in ipairs(decoration.tintTextures) do
        texture:SetVertexColor(color[1], color[2], color[3], 1);
    end

    local useHighlight = GetStandaloneBorderStyle(GetConfig())
        == addon.BIG_DEBUFFS_ICON_STYLE_ID.HIGHLIGHT;
    decoration.plainBorder:SetShown(not useHighlight);
    decoration.highlightGlow:SetShown(useHighlight);
    decoration.highlightBorder:SetShown(useHighlight);
end

local function RefreshStandaloneGroupLabels(root, samples)
    if not root then return false end

    local config = GetConfig();
    local showAnyLabel = config.arenaStandaloneOffensiveIconShowArenaNumber
        or config.arenaStandaloneOffensiveIconShowName
        or config.arenaStandaloneOffensiveIconShowSpec;
    for index, entry in ipairs(root.entries) do
        local sample = samples and samples[index];
        local numberText, specText, nameText, color =
            GetSafeStandaloneIdentity(index, sample);
        entry.classColor = color;
        if entry.container then
            entry.container.sweepyBoopClassColor = color;
        end
        if showAnyLabel and color then
            ApplyStandaloneLabel(
                entry.label,
                numberText,
                specText,
                nameText,
                color
            );
        else
            ClearStandaloneLabel(entry.label);
        end
    end
    return true;
end

local function RefreshStandaloneDecorationStyles(root, unrestricted)
    if not root then return false end
    if ( not unrestricted ) and ( not CanAccessStandaloneDecorations() ) then
        standaloneDecorationRefreshPending = true;
        return false;
    end

    for _, entry in ipairs(root.entries) do
        for _, decoration in ipairs(entry.decorations) do
            ApplyStandaloneDecorationStyle(decoration, entry.classColor);
        end
    end

    if not unrestricted then
        standaloneDecorationRefreshPending = false;
    end
    return true;
end

local function RefreshStandalonePresentation(root, samples)
    RefreshStandaloneGroupLabels(root, samples);
    return RefreshStandaloneDecorationStyles(root, samples ~= nil);
end

local function InitializeStandaloneAuraButton(button, container)
    local decoration = CreateStandaloneDecoration(button, true);
    container.sweepyBoopDecorations[#container.sweepyBoopDecorations + 1] = decoration;
    if CanAccessStandaloneDecorations() then
        ApplyStandaloneDecorationStyle(decoration, container.sweepyBoopClassColor);
    else
        standaloneDecorationRefreshPending = true;
    end
end

local function CreateStandaloneContainer(parent)
    local container = CreateFrame(
        "AuraContainer",
        nil,
        parent,
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
    container.sweepyBoopDecorations = {};
    container:AddAuraGroup(offensiveAuraGroupKey, offensiveAuraFilter, {
        maxFrameCount = Clamp(
            GetConfig().arenaStandaloneOffensiveIconMaxIcons,
            minStandaloneIcons,
            maxStandaloneIcons
        ),
        sortMethod = AuraContainerSortMethod.Default,
        sortDirection = AuraContainerSortDirection.Normal,
        initializeFrame = function(button)
            InitializeStandaloneAuraButton(button, container);
        end,
        layout = {
            elementSpacing = 0,
            lineSpacing = 0,
            elementWidth = baseIconSize,
            elementHeight = baseIconSize,
        },
    });
    return container;
end

local function ApplyStandaloneContainerLayout(container, layout)
    container:SetFlowLayoutAxis(AnchorUtil.FlowLayoutAxis.Horizontal);
    container:SetFlowLayoutAnchorPoint(layout.flowAnchorPoint);
    container:SetFlowLayoutGrowthDirection(
        layout.horizontalFlowDirection,
        layout.verticalFlowDirection
    );
    container:SetFlowLayoutMaximumLineSize(layout.maxLineWidth + flowLayoutTolerance);
    container:SetAuraGroupMaxFrameCount(offensiveAuraGroupKey, layout.maxIcons);
    container:SetAuraGroupLayout(offensiveAuraGroupKey, {
        elementSpacing = layout.iconSpacing,
        lineSpacing = layout.iconSpacing,
        elementWidth = baseIconSize,
        elementHeight = baseIconSize,
    });
end

local function AnchorStandaloneGroups(root, entries, layout)
    for _, entry in ipairs(entries) do
        entry.frame:ClearAllPoints();
    end

    local verticalAnchor = layout.verticalAnchor;
    if layout.growDirection == addon.STANDALONE_GROW_DIRECTION.RIGHT then
        entries[1].frame:SetPoint(verticalAnchor .. "LEFT", root, verticalAnchor);
        for index = 2, #entries do
            entries[index].frame:SetPoint(
                verticalAnchor .. "LEFT",
                entries[index - 1].frame,
                verticalAnchor .. "RIGHT",
                layout.groupSpacing,
                0
            );
        end
    elseif layout.growDirection == addon.STANDALONE_GROW_DIRECTION.LEFT then
        entries[1].frame:SetPoint(verticalAnchor .. "RIGHT", root, verticalAnchor);
        for index = 2, #entries do
            entries[index].frame:SetPoint(
                verticalAnchor .. "RIGHT",
                entries[index - 1].frame,
                verticalAnchor .. "LEFT",
                -layout.groupSpacing,
                0
            );
        end
    else
        entries[2].frame:SetPoint(verticalAnchor, root, verticalAnchor);
        entries[1].frame:SetPoint(
            verticalAnchor .. "RIGHT",
            entries[2].frame,
            verticalAnchor .. "LEFT",
            -layout.groupSpacing,
            0
        );
        entries[3].frame:SetPoint(
            verticalAnchor .. "LEFT",
            entries[2].frame,
            verticalAnchor .. "RIGHT",
            layout.groupSpacing,
            0
        );
    end
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
    root:ClearAllPoints();
    root:SetPoint(
        "CENTER",
        UIParent,
        "CENTER",
        layout.offsetX,
        layout.offsetY
    );

    if not isTest then
        for _, entry in ipairs(root.entries) do
            ApplyStandaloneContainerLayout(entry.container, layout);
        end
        AnchorStandaloneGroups(root, root.entries, layout);
    end

    root.sweepyBoopLayoutSignature = signature;
    return true;
end

local function EnsureStandaloneRoot()
    if standaloneRoot then return standaloneRoot end
    if InCombatLockdown() then
        reconcilePending = true;
        return;
    end

    local root = CreateFrame("Frame", nil, UIParent);
    root:SetMouseClickEnabled(false);
    root:SetSize(1, 1);
    root:Hide();
    root.entries = {};

    for index = 1, addon.MAX_ARENA_SIZE do
        local container = CreateStandaloneContainer(root);
        local label = CreateStandaloneLabelHost(root, container);
        container:SetUnit("arena" .. index);
        root.entries[index] = {
            container = container,
            frame = container,
            index = index,
            decorations = container.sweepyBoopDecorations,
            label = label,
        };
    end

    standaloneRoot = root;
    ApplyStandaloneRootLayout(root, GetStandaloneLayout(), false);
    RefreshStandalonePresentation(root);
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
        for _, entry in ipairs(root.entries) do
            entry.container:Show();
        end
    else
        for _, entry in ipairs(root.entries) do
            entry.container:Hide();
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

    RefreshStandalonePresentation(root);
    for index, entry in ipairs(root.entries) do
        local container = entry.container;
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
    root.entries = {};

    for index = 1, addon.MAX_ARENA_SIZE do
        local holder = CreateFrame("Frame", nil, root);
        holder.index = index;
        holder.testButtons = {};
        holder.testDecorations = {};
        for buttonIndex = 1, maxStandaloneIcons do
            CreateStandaloneTestButton(holder, index, buttonIndex);
        end
        local label = CreateStandaloneLabelHost(root, holder);
        root.entries[index] = {
            frame = holder,
            index = index,
            testButtons = holder.testButtons,
            decorations = holder.testDecorations,
            label = label,
        };
    end

    standaloneTestRoot = root;
    return root;
end

local function GetStandaloneTestSampleCount(layout, index)
    if index == 1 then return layout.maxIcons end
    if index == 2 then return 1 end
    return math.max(1, layout.maxIcons - 2);
end

local function ApplyStandaloneTestLayout(root, layout)
    ApplyStandaloneRootLayout(root, layout, true);

    for index, entry in ipairs(root.entries) do
        local holder = entry.frame;
        local sampleCount = GetStandaloneTestSampleCount(layout, index);
        local sampleColumns = math.min(layout.effectiveColumns, sampleCount);
        local sampleRows = math.ceil(sampleCount / sampleColumns);
        holder:SetSize(
            sampleColumns * baseIconSize + ( sampleColumns - 1 ) * layout.iconSpacing,
            sampleRows * baseIconSize + ( sampleRows - 1 ) * layout.iconSpacing
        );

        for buttonIndex, button in ipairs(entry.testButtons) do
            button:ClearAllPoints();
            if buttonIndex <= sampleCount then
                local column = ( buttonIndex - 1 ) % sampleColumns;
                local row = math.floor(( buttonIndex - 1 ) / sampleColumns);
                local x = column * ( baseIconSize + layout.iconSpacing );
                local y = row * ( baseIconSize + layout.iconSpacing );
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

    AnchorStandaloneGroups(root, root.entries, layout);
end

local function RefreshStandaloneTestRoot()
    if not standaloneTestRoot or not standaloneTestRoot:IsShown() then return end
    if not GetConfig().arenaStandaloneOffensiveIconsEnabled then
        standaloneTestRoot:Hide();
        return;
    end

    local layout = GetStandaloneLayout();
    ApplyStandaloneTestLayout(standaloneTestRoot, layout);
    RefreshStandalonePresentation(standaloneTestRoot, testSamples);
    for index, entry in ipairs(standaloneTestRoot.entries) do
        local sampleCount = GetStandaloneTestSampleCount(layout, index);
        for buttonIndex = 1, sampleCount do
            RestartTestCooldown(entry.testButtons[buttonIndex], buttonIndex * 2);
        end
    end
end

local function ReconcileStandaloneAuraRestrictions()
    if not CanAccessStandaloneDecorations() then
        standaloneDecorationRefreshPending = true;
        return;
    end

    if standaloneDecorationRefreshPending then
        RefreshStandaloneGroupLabels(standaloneRoot);
        RefreshStandaloneDecorationStyles(standaloneRoot, false);
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
            if ( not reconcilePending ) and ( not standaloneDecorationRefreshPending ) then
                return;
            end
            reconcilePending = false;
            UpdateLiveOverlays(true);
            UpdateStandaloneRoot(true);
            return;
        end
        if event == "UNIT_NAME_UPDATE" then
            if unit ~= "arena1" and unit ~= "arena2" and unit ~= "arena3" then return end
            RefreshStandaloneGroupLabels(standaloneRoot);
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
