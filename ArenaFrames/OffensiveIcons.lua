local _, addon = ...;

if not addon.PROJECT_MAINLINE then return end

local style = addon.ARENA_OFFENSIVE_ICON_STYLE;
local baseIconSize = style.BASE_SIZE;
local blizzardArenaFramePrefix = "CompactArenaFrameMember";
local offensiveAuraFilter = "HELPFUL|IMPORTANT";
local offensiveAuraSlotKey = "Offensive";
local defaultArenaFrameStrata = "LOW";
local defaultArenaFrameLevel = 2;
local liveOverlays = {};
local eventFrame;
local setupComplete = false;
local reconcilePending = false;

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

local function InitializeLiveAuraButton(button, container)
    button:SetSize(baseIconSize, baseIconSize);
    button:SetMouseClickEnabled(false);
    button:SetMouseMotionEnabled(false);
    button:ClearAllPoints();
    button:SetPoint("LEFT", container, "LEFT");

    CreateOffensiveIconShadow(button);

    local backdrop = button:CreateTexture(nil, "BACKGROUND");
    backdrop:SetAllPoints(button);
    backdrop:SetColorTexture(unpack(style.BACKDROP_COLOR));

    local icon = button:CreateTexture(nil, "ARTWORK");
    icon:SetPoint("TOPLEFT", button, "TOPLEFT", style.ICON_INSET, -style.ICON_INSET);
    icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -style.ICON_INSET, style.ICON_INSET);
    icon:SetTexCoord(unpack(style.ICON_TEX_COORDS));
    button:SetIcon(icon);

    local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate");
    cooldown:SetAllPoints(icon);
    ConfigureCooldownSwipe(cooldown);
    UpdateCountdownFontSize(cooldown);
    button:SetDurationCooldown(cooldown);

    AddSecureHighlightTexture(
        button,
        addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_GLOW_TEXTURE,
        "BORDER",
        style.HIGHLIGHT_GLOW_ALPHA
    );
    AddSecureHighlightTexture(
        button,
        addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_BORDER_TEXTURE,
        "OVERLAY",
        style.HIGHLIGHT_BORDER_ALPHA
    );
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

function SweepyBoop:UpdateArenaOffensiveIcons()
    UpdateLiveOverlays();
end

function SweepyBoop:SetupArenaOffensiveIcons()
    if setupComplete then
        UpdateLiveOverlays();
        return;
    end
    setupComplete = true;

    for i = 1, addon.MAX_ARENA_SIZE do
        EnsureLiveOverlay(i);
    end

    eventFrame = CreateFrame("Frame");
    eventFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
    eventFrame:RegisterEvent(addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS);
    eventFrame:RegisterEvent(addon.ARENA_OPPONENT_UPDATE);
    eventFrame:RegisterEvent(addon.PVP_MATCH_STATE_CHANGED);
    eventFrame:RegisterEvent(addon.PLAYER_REGEN_ENABLED);
    eventFrame:RegisterEvent("PVP_MATCH_ACTIVE");
    eventFrame:RegisterEvent("PVP_MATCH_COMPLETE");
    eventFrame:SetScript("OnEvent", function(_, event)
        if event == addon.PLAYER_REGEN_ENABLED then
            if not reconcilePending then return end
            reconcilePending = false;
            UpdateLiveOverlays(true);
            return;
        end
        UpdateLiveOverlays(true);
    end);

    addon.RegisterAuraDataProviderListener("ArenaOffensiveIcons", function()
        UpdateLiveOverlays(true);
    end);

    UpdateLiveOverlays();
end
