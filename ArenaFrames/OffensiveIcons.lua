local _, addon = ...;

if not addon.PROJECT_MAINLINE then return end

local style = addon.ARENA_OFFENSIVE_ICON_STYLE;
local baseIconSize = style.BASE_SIZE;
local identifierBaseSize = math.floor(baseIconSize * addon.COUNTDOWN_FONT_SIZE_COEFFICIENT);
local standaloneHolderHeight = baseIconSize + identifierBaseSize + 2;
local blizzardArenaFramePrefix = "CompactArenaFrameMember";
local offensiveAuraFilter = "HELPFUL|IMPORTANT";
local offensiveAuraSlotKey = "Offensive";
local defaultArenaFrameStrata = "LOW";
local defaultArenaFrameLevel = 2;
local liveOverlays = {};
local standaloneGroup;
local standaloneTestGroup;
local eventFrame;
local setupComplete = false;
local reconcilePending = false;

local standaloneGrowOptions = {
    [addon.STANDALONE_GROW_DIRECTION.CENTER] = {
        direction = "CENTER",
        anchor = "CENTER",
    },
    [addon.STANDALONE_GROW_DIRECTION.LEFT] = {
        direction = "LEFT",
        anchor = "RIGHT",
    },
    [addon.STANDALONE_GROW_DIRECTION.RIGHT] = {
        direction = "RIGHT",
        anchor = "LEFT",
    },
};

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

local function CreateIdentifier(holder)
    local identifier = holder:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    local font, _, flags = identifier:GetFont();
    if font then
        identifier:SetFont(font, identifierBaseSize, flags);
    end
    identifier:SetPoint("TOP", holder, "TOP", 0, -baseIconSize - 2);
    identifier:SetWidth(baseIconSize * 2);
    identifier:SetJustifyH("CENTER");
    identifier:SetWordWrap(false);
    holder.identifier = identifier;
    return identifier;
end

local function GetIdentifierColor(index, classOverride)
    local class = classOverride;
    if not class then
        class = addon.GetClassForPlayerOrArena("arena" .. index);
    end
    if addon.IsSecretValue(class) then
        class = nil;
    end

    local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class];
    if color then
        return color.r, color.g, color.b;
    end
    return 1, 1, 1;
end

local function UpdateIdentifier(holder, index, nameOverride, classOverride)
    local identifier = holder.identifier or CreateIdentifier(holder);
    local identifierMode = GetConfig().arenaStandaloneOffensiveIconIdentifier;
    local identifierText;

    if identifierMode == addon.ARENA_OFFENSIVE_ICON_IDENTIFIER.NONE then
        identifier:Hide();
        return;
    elseif identifierMode == addon.ARENA_OFFENSIVE_ICON_IDENTIFIER.NAME then
        if nameOverride ~= nil then
            identifierText = nameOverride;
        else
            identifierText = UnitName("arena" .. index);
        end
        if addon.IsSecretValue(identifierText) then
            identifier:Hide();
            return;
        end
    else
        identifierText = tostring(index);
    end

    identifier:SetText(identifierText);
    identifier:SetTextColor(GetIdentifierColor(index, classOverride));
    identifier:Show();
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

local function GetStandaloneLayoutOptions()
    local config = GetConfig();
    local size = config.arenaStandaloneOffensiveIconSize or style.DEFAULT_DISPLAY_SIZE;
    local scale = size / baseIconSize;
    local growDirection = config.arenaStandaloneOffensiveIconGrowDirection
        or addon.STANDALONE_GROW_DIRECTION.CENTER;
    local sourceGrowOptions = standaloneGrowOptions[growDirection]
        or standaloneGrowOptions[addon.STANDALONE_GROW_DIRECTION.CENTER];

    return scale, {
        point = "CENTER",
        relativeTo = "UIParent",
        relativePoint = "CENTER",
        offsetX = ( config.arenaStandaloneOffensiveIconOffsetX or 0 ) / scale,
        offsetY = ( config.arenaStandaloneOffensiveIconOffsetY or 0 ) / scale,
    }, {
        direction = sourceGrowOptions.direction,
        anchor = sourceGrowOptions.anchor,
        margin = ( config.arenaStandaloneOffensiveIconPadding or 0 ) / scale,
        columns = config.arenaStandaloneOffensiveIconColumns or addon.MAX_ARENA_SIZE,
        growUpward = config.arenaStandaloneOffensiveIconGrowUpward,
    };
end

local function ApplyStandaloneGroupLayout(group)
    local scale, setPointOptions, growOptions = GetStandaloneLayoutOptions();
    if InCombatLockdown() and group.isSecure then
        reconcilePending = true;
        return group.layoutApplied == true;
    end

    addon.UpdateIconGroupSetPointOptions(group, setPointOptions, growOptions);
    group:SetScale(scale);
    addon.IconGroup_Position(group);
    group.layoutApplied = true;
    return true;
end

local function RefreshStandaloneIdentifiers(group)
    if not group then return end
    if group.isSecure and InCombatLockdown() then
        reconcilePending = true;
        return;
    end

    for i = 1, addon.MAX_ARENA_SIZE do
        local holder = group.active[i];
        if holder then
            local sample = holder.testButton and testSamples[i];
            UpdateIdentifier(
                holder,
                i,
                sample and sample.name,
                sample and sample.class
            );
        end
    end
end

local function InitializeStandaloneAuraButton(button, holder)
    InitializeOffensiveIcon(button, true);
    button:ClearAllPoints();
    button:SetPoint("TOP", holder.container, "TOP");
end

local function CreateStandaloneLiveHolder(group, index)
    local holder = CreateFrame("Frame", nil, group);
    holder:SetSize(baseIconSize, standaloneHolderHeight);
    holder.index = index;
    CreateIdentifier(holder);

    local container = CreateFrame(
        "AuraContainer",
        nil,
        holder,
        "CustomAuraContainerTemplate"
    );
    holder.container = container;
    container:Hide();
    container:SetSize(baseIconSize, baseIconSize);
    container:SetPoint("TOP", holder, "TOP");
    container:SetAuraProcessingPolicy(
        CustomAuraContainerAuraProcessingPolicy.ProcessAura,
        {
            displayOnlyDispellableDebuffs = false,
            ignoreBuffs = false,
            ignoreDebuffs = true,
            ignoreDispelDebuffs = true,
        }
    );
    container:AddAuraSlot(offensiveAuraSlotKey .. index, offensiveAuraFilter, {
        sortMethod = AuraContainerSortMethod.ImportantOnly,
        sortDirection = AuraContainerSortDirection.Normal,
        initializeFrame = function(button)
            InitializeStandaloneAuraButton(button, holder);
        end,
    });
    container:SetUnit("arena" .. index);

    group.active[index] = holder;
end

local function EnsureStandaloneGroup()
    if standaloneGroup then return standaloneGroup end
    if InCombatLockdown() then
        reconcilePending = true;
        return;
    end

    local _, setPointOptions, growOptions = GetStandaloneLayoutOptions();
    standaloneGroup = addon.CreateIconGroup(setPointOptions, growOptions);
    standaloneGroup.isSecure = true;
    standaloneGroup:Hide();
    -- Keep secure aura occupancy from changing opponent order or group geometry.
    for i = 1, addon.MAX_ARENA_SIZE do
        CreateStandaloneLiveHolder(standaloneGroup, i);
    end
    ApplyStandaloneGroupLayout(standaloneGroup);
    return standaloneGroup;
end

local function SetStandaloneGroupShown(group, shown)
    if group.shown == shown then return true end
    if InCombatLockdown() then
        reconcilePending = true;
        return false;
    end

    group.shown = shown;
    for i = 1, addon.MAX_ARENA_SIZE do
        group.active[i].container:SetShown(shown);
    end
    group:SetShown(shown);
    return true;
end

local function UpdateStandaloneGroup(forceRefresh)
    if not SweepyBoop.db then return end

    local group = EnsureStandaloneGroup();
    if not group then return end

    local config = GetConfig();
    if ( not config.arenaStandaloneOffensiveIconsEnabled )
        or ( not addon.IsUsingRealAuraData() ) then

        SetStandaloneGroupShown(group, false);
        return;
    end

    if not ApplyStandaloneGroupLayout(group) then
        SetStandaloneGroupShown(group, false);
        return;
    end

    RefreshStandaloneIdentifiers(group);
    if forceRefresh then
        for i = 1, addon.MAX_ARENA_SIZE do
            group.active[i].container:UpdateAllAuras();
        end
    end
    SetStandaloneGroupShown(group, true);
end

local function RestartTestCooldown(button, elapsed)
    if not standaloneTestGroup or not standaloneTestGroup:IsShown() then return end
    button.cooldown:SetCooldown(GetTime() - ( elapsed or 0 ), 18);
end

local function CreateStandaloneTestHolder(group, index)
    local sample = testSamples[index];
    local holder = CreateFrame("Frame", nil, group);
    holder:SetSize(baseIconSize, standaloneHolderHeight);
    holder.index = index;

    local button = CreateFrame("Frame", nil, holder);
    button:SetPoint("TOP", holder, "TOP");
    InitializeOffensiveIcon(button, false);
    button.icon:SetTexture(addon.GetSpellTexture(sample.spellID));
    CreateIdentifier(holder);
    UpdateIdentifier(holder, index, sample.name, sample.class);
    button.cooldown:SetScript("OnCooldownDone", function()
        RestartTestCooldown(button);
    end);

    holder.testButton = button;
    group.active[index] = holder;
end

local function EnsureStandaloneTestGroup()
    if standaloneTestGroup then return standaloneTestGroup end

    local _, setPointOptions, growOptions = GetStandaloneLayoutOptions();
    standaloneTestGroup = addon.CreateIconGroup(setPointOptions, growOptions);
    standaloneTestGroup:Hide();
    for i = 1, addon.MAX_ARENA_SIZE do
        CreateStandaloneTestHolder(standaloneTestGroup, i);
    end
    ApplyStandaloneGroupLayout(standaloneTestGroup);
    return standaloneTestGroup;
end

local function RefreshStandaloneTestGroup()
    if not standaloneTestGroup or not standaloneTestGroup:IsShown() then return end

    if not GetConfig().arenaStandaloneOffensiveIconsEnabled then
        standaloneTestGroup:Hide();
        return;
    end

    ApplyStandaloneGroupLayout(standaloneTestGroup);
    RefreshStandaloneIdentifiers(standaloneTestGroup);
end

function SweepyBoop:TestArenaStandaloneOffensiveIcons()
    if IsInInstance() then
        addon.PRINT(addon.L["Test mode can only be used outside instances"]);
        return;
    end
    if not GetConfig().arenaStandaloneOffensiveIconsEnabled then return end

    local group = EnsureStandaloneTestGroup();
    ApplyStandaloneGroupLayout(group);
    RefreshStandaloneIdentifiers(group);
    group:Show();
    for i = 1, addon.MAX_ARENA_SIZE do
        RestartTestCooldown(group.active[i].testButton, i * 3);
    end
end

function SweepyBoop:HideTestArenaStandaloneOffensiveIcons()
    if standaloneTestGroup then
        standaloneTestGroup:Hide();
    end
end

function SweepyBoop:UpdateArenaOffensiveIcons()
    UpdateLiveOverlays();
    UpdateStandaloneGroup();
    RefreshStandaloneTestGroup();
end

function SweepyBoop:SetupArenaOffensiveIcons()
    if setupComplete then
        UpdateLiveOverlays();
        UpdateStandaloneGroup();
        return;
    end
    setupComplete = true;

    for i = 1, addon.MAX_ARENA_SIZE do
        EnsureLiveOverlay(i);
    end
    EnsureStandaloneGroup();

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
        if event == addon.PLAYER_ENTERING_WORLD and standaloneTestGroup then
            standaloneTestGroup:Hide();
        end
        if event == addon.PLAYER_REGEN_ENABLED then
            if not reconcilePending then return end
            reconcilePending = false;
            UpdateLiveOverlays(true);
            UpdateStandaloneGroup(true);
            return;
        end
        if event == "UNIT_NAME_UPDATE" then
            if unit ~= "arena1" and unit ~= "arena2" and unit ~= "arena3" then return end
            RefreshStandaloneIdentifiers(standaloneGroup);
            return;
        end

        UpdateLiveOverlays(true);
        UpdateStandaloneGroup(true);
    end);

    addon.RegisterAuraDataProviderListener("ArenaOffensiveIcons", function()
        UpdateLiveOverlays(true);
        UpdateStandaloneGroup(true);
    end);

    UpdateLiveOverlays();
    UpdateStandaloneGroup();
end
