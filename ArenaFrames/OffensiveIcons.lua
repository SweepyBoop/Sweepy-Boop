local _, addon = ...;

if not addon.PROJECT_MAINLINE then return end

local baseIconSize = addon.DEFAULT_ICON_SIZE;
local blizzardArenaFramePrefix = "CompactArenaFrameMember";
local offensiveAuraFilter = "HELPFUL|IMPORTANT";
local offensiveAuraSlotKey = "Offensive";
local testSpells = { 190319, 31884, 185313 }; -- Combustion, Avenging Wrath, Shadow Dance
local testDuration = 12;
local procGlowColor = { 1, 0.82, 0, 1 };
local liveOverlays = {};
local previewOverlays = {};
local eventFrame;
local previewTimer;
local setupComplete = false;
local isInTest = false;
local reconcilePending = false;
local previewCleanupPending = false;

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
        cooldown:SetSwipeColor(0, 0, 0, 0.55);
    end
    if cooldown.SetEdgeTexture then
        cooldown:SetEdgeTexture("Interface\\Cooldown\\UI-HUD-ActionBar-LoC");
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

local function CreateAlertTexture(button, texturePath, layer, alpha)
    local texture = button:CreateTexture(nil, layer);
    texture:SetTexture(texturePath);
    texture:SetBlendMode("ADD");
    texture:SetPoint("TOPLEFT", button, "TOPLEFT", -7, 7);
    texture:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 7, -7);
    texture:SetVertexColor(
        procGlowColor[1],
        procGlowColor[2],
        procGlowColor[3],
        alpha
    );
    return texture;
end

local function InitializeLiveAuraButton(button, container)
    button:SetSize(baseIconSize, baseIconSize);
    button:SetMouseMotionEnabled(false);
    button:ClearAllPoints();
    button:SetPoint("LEFT", container, "LEFT");

    local backdrop = button:CreateTexture(nil, "BACKGROUND");
    backdrop:SetAllPoints(button);
    backdrop:SetColorTexture(0, 0, 0, 1);

    local icon = button:CreateTexture(nil, "ARTWORK");
    icon:SetAllPoints(button);
    button:SetIcon(icon);

    local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate");
    cooldown:SetAllPoints(icon);
    ConfigureCooldownSwipe(cooldown);
    UpdateCountdownFontSize(cooldown);
    button:SetDurationCooldown(cooldown);

    -- Static children inherit the secure aura button's visibility without requiring
    -- addon code to touch restricted descendants after initialization.
    CreateAlertTexture(
        button,
        addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_GLOW_TEXTURE,
        "BORDER",
        0.9
    );
    CreateAlertTexture(
        button,
        addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_BORDER_TEXTURE,
        "OVERLAY",
        1
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
    local size = config.arenaOffensiveIconSize or 32;
    local offsetX = config.arenaOffensiveIconOffsetX or 0;
    local offsetY = config.arenaOffensiveIconOffsetY or 0;
    local frameStrata = arenaFrame:GetFrameStrata();
    local frameLevel = arenaFrame:GetFrameLevel() + 20;
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
    if isInTest
        or ( not config.arenaOffensiveIconsEnabled )
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

local function ResetPreviewCooldown(cooldown)
    if cooldown.Clear then
        cooldown:Clear();
    else
        cooldown:SetCooldown(0, 0);
    end
end

local function ClearPreviewIcon(icon)
    if not icon then return end

    ResetPreviewCooldown(icon.cooldown);
    addon.HideProcGlow(icon);
    icon:Hide();
end

local function EnsurePreviewOverlay(index)
    local preview = previewOverlays[index];
    if preview then return preview end

    local group = CreateFrame("Frame", nil, UIParent);
    group:SetMouseClickEnabled(false);
    group:SetSize(baseIconSize, baseIconSize);
    group.index = index;
    group:Hide();

    local icon = CreateFrame("Frame", nil, group);
    icon:SetMouseClickEnabled(false);
    icon:SetSize(baseIconSize, baseIconSize);
    icon:SetPoint("LEFT", group, "LEFT");
    icon.texture = icon:CreateTexture(nil, "BORDER");
    icon.texture:SetAllPoints(icon);
    icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate");
    icon.cooldown:SetAllPoints(icon);
    ConfigureCooldownSwipe(icon.cooldown);
    UpdateCountdownFontSize(icon.cooldown);
    icon:Hide();

    preview = {
        group = group,
        icon = icon,
        index = index,
    };
    previewOverlays[index] = preview;
    return preview;
end

local function ClearPreviewOverlay(preview)
    if not preview then return end

    ClearPreviewIcon(preview.icon);
    preview.group:Hide();
end

local function ClearAllPreviewOverlays()
    if not isInTest then return true end
    if InCombatLockdown() then
        previewCleanupPending = true;
        reconcilePending = true;
        return false;
    end

    previewCleanupPending = false;
    if previewTimer then
        previewTimer:Cancel();
        previewTimer = nil;
    end
    for _, preview in pairs(previewOverlays) do
        ClearPreviewOverlay(preview);
    end
    isInTest = false;
    return true;
end

local function ApplyPreviewLayout(preview)
    local arenaFrame = _G[blizzardArenaFramePrefix .. preview.index];
    if not arenaFrame then
        ClearPreviewOverlay(preview);
        return false;
    end

    local shown = arenaFrame:IsShown();
    local visible = arenaFrame:IsVisible();
    if addon.IsSecretValue(shown) or addon.IsSecretValue(visible) or ( not shown ) or ( not visible ) then
        ClearPreviewOverlay(preview);
        return false;
    end

    local config = GetConfig();
    local scale = ( config.arenaOffensiveIconSize or 32 ) / baseIconSize;
    preview.group:SetParent(arenaFrame);
    preview.group:SetFrameStrata(arenaFrame:GetFrameStrata());
    preview.group:SetFrameLevel(arenaFrame:GetFrameLevel() + 20);
    preview.group:SetScale(scale);
    preview.group:ClearAllPoints();
    preview.group:SetPoint(
        "LEFT",
        arenaFrame,
        "LEFT",
        ( config.arenaOffensiveIconOffsetX or 0 ) / scale,
        ( config.arenaOffensiveIconOffsetY or 0 ) / scale
    );
    return true;
end

local function PreviewArenaOverlays(showWarning)
    if IsInInstance() then
        ClearAllPreviewOverlays();
        UpdateLiveOverlays();
        if showWarning then
            addon.PRINT("Test mode can only be used outside instances");
        end
        return;
    end

    isInTest = true;
    UpdateLiveOverlays();
    for i = 1, addon.MAX_ARENA_SIZE do
        local preview = EnsurePreviewOverlay(i);
        if ApplyPreviewLayout(preview) then
            local icon = preview.icon;
            icon.texture:SetTexture(addon.GetSpellTexture(testSpells[i] or testSpells[1]));
            icon.cooldown:SetCooldown(GetTime() - i, testDuration + i);
            icon.cooldown:Show();
            addon.ShowProcGlow(icon, procGlowColor);
            icon:Show();
            preview.group:Show();
        end
    end

    if previewTimer then
        previewTimer:Cancel();
    end
    previewTimer = C_Timer.NewTimer(testDuration, function()
        previewTimer = nil;
        if isInTest then
            SweepyBoop:HideTestArenaOffensiveIcons();
        end
    end);
end

local function ShowBlizzardArenaFramesForPreview()
    if not CompactArenaFrame then return end

    CompactArenaFrame:Show();
    for i = 1, addon.MAX_ARENA_SIZE do
        local frame = _G[blizzardArenaFramePrefix .. i];
        if frame then
            frame:Show();
        end
    end
end

function SweepyBoop:TestArenaOffensiveIcons()
    if IsInInstance() then
        PreviewArenaOverlays(true);
        return;
    end
    if InCombatLockdown() then
        addon.PRINT("Test mode cannot be started during combat");
        return;
    end

    ShowBlizzardArenaFramesForPreview();
    PreviewArenaOverlays(false);
end

function SweepyBoop:HideTestArenaOffensiveIcons()
    if ClearAllPreviewOverlays() then
        UpdateLiveOverlays();
    end
end

function SweepyBoop:UpdateArenaOffensiveIcons()
    if isInTest then
        if InCombatLockdown() then
            reconcilePending = true;
            return;
        end
        PreviewArenaOverlays(false);
        return;
    end

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
        if event == addon.PLAYER_ENTERING_WORLD or event == "PVP_MATCH_COMPLETE" then
            ClearAllPreviewOverlays();
        end
        if event == addon.PLAYER_REGEN_ENABLED then
            if ( not reconcilePending ) and ( not previewCleanupPending ) then return end
            reconcilePending = false;
            if previewCleanupPending then
                ClearAllPreviewOverlays();
            end
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
