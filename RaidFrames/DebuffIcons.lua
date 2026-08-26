local _, addon = ...;

local auraFilter = "HARMFUL|CROWD_CONTROL";
local auraGroupKey = "CrowdControl";
local iconSpacing = 6;
local iconBaseSize = addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_BASE_SIZE;
local frameLevelOffset = 20;
local minIconCount = 1;
local maxIconCount = 5;
local psychicScream = 8122;
local kidneyShot = 408;
local testDuration = 6;
local redHighlightColor = { 1, 0, 0, 1 };

local cufPool = {};
local setupComplete = false;
local isTesting = false;
local restylePending = false;
local testTimer;

local function GetConfig()
    return SweepyBoop.db.profile.raidFrames;
end

local function Clamp(value, minValue, maxValue)
    value = tonumber(value) or minValue;
    if ( value < minValue ) then return minValue end
    if ( value > maxValue ) then return maxValue end
    return value;
end

local function GetIconCount(config)
    return Clamp(config.raidFrameDebuffIconCount, minIconCount, maxIconCount);
end

local function GetFrameHeight(frame)
    local height = frame:GetHeight();
    if ( not height ) or ( height <= 0 ) then
        local _, _, _, rectHeight = frame:GetRect();
        height = rectHeight;
    end
    return ( height and height > 0 ) and height or 36;
end

local function GetIconSize(frame, config)
    local scale = tonumber(config.raidFrameDebuffIconScale) or 0.5;
    if ( scale <= 0 ) then scale = 0.5 end
    return GetFrameHeight(frame) * scale;
end

local function GetMillisecondsThreshold(config)
    return Clamp(config.raidFrameDebuffIconMillisecondsThreshold, 1, 6);
end

local function IsEnabled()
    return GetConfig().raidFrameDebuffIconsEnabled;
end

local function CanStyleAuraButtons()
    return ( not C_Secrets )
        or ( not C_Secrets.ShouldAurasBeSecret )
        or ( not C_Secrets.ShouldAurasBeSecret() );
end

local function UpdateCooldownFontSize(cooldown)
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
                math.floor(iconBaseSize * addon.COUNTDOWN_FONT_SIZE_COEFFICIENT),
                flags
            );
        end
    end
end

local function StyleCooldown(cooldown, config)
    cooldown:SetDrawBling(false);
    cooldown:SetReverse(true);
    cooldown:SetDrawSwipe(true);
    cooldown:SetSwipeColor(0, 0, 0, 0.5);
    cooldown:SetDrawEdge(true);
    cooldown:SetEdgeTexture("Interface\\Cooldown\\UI-HUD-ActionBar-LoC", 1, 1, 1, 1);
    cooldown:SetHideCountdownNumbers(false);
    if cooldown.SetCountdownMillisecondsThreshold then
        cooldown:SetCountdownMillisecondsThreshold(GetMillisecondsThreshold(config));
    end
    UpdateCooldownFontSize(cooldown);
end

local function CreateDebuffVisual(frame)
    local backdrop = frame:CreateTexture(nil, "BACKGROUND");
    backdrop:SetAllPoints(frame);
    backdrop:SetColorTexture(0, 0, 0, 1);

    local icon = frame:CreateTexture(nil, "ARTWORK");
    local inset = addon.BIG_DEBUFFS_ICON_STYLE.DEBUFF_ICON_INSET;
    icon:SetPoint("TOPLEFT", frame, "TOPLEFT", inset, -inset);
    icon:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -inset, inset);
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92);

    local cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate");
    cooldown:SetAllPoints(icon);
    StyleCooldown(cooldown, GetConfig());
    return icon, cooldown;
end

local function CreateHighlightTexture(frame, texturePath, layer, alpha)
    local texture = frame:CreateTexture(nil, layer);
    texture:SetTexture(texturePath);
    texture:SetBlendMode("ADD");
    texture:SetPoint("TOPLEFT", frame, "TOPLEFT", -addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_PADDING, addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_PADDING);
    texture:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_PADDING, -addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_PADDING);
    texture:SetAlpha(alpha);
    return texture;
end

local function GetHighlightColorMap()
    return {
        Magic = CreateColor(1, 1, 1),
        Curse = CreateColor(1, 1, 1),
        Disease = CreateColor(1, 1, 1),
        Poison = CreateColor(1, 1, 1),
        Enrage = CreateColor(1, 1, 1),
        None = CreateColor(1, 0, 0),
    };
end

local function AddSecureHighlightTexture(button, texturePath, layer, alpha)
    local texture = CreateHighlightTexture(button, texturePath, layer, alpha);
    button:AddDispelTypeTexture(texture, {
        style = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset,
        showWhenHarmful = true,
        showWithoutDispelType = true,
        customDispelColorMap = GetHighlightColorMap(),
    });
end

local function InitializeAuraButton(button, frame)
    frame.sweepyBoopDebuffAuraButtons = frame.sweepyBoopDebuffAuraButtons or {};
    frame.sweepyBoopDebuffAuraButtons[#frame.sweepyBoopDebuffAuraButtons + 1] = button;

    button:SetSize(iconBaseSize, iconBaseSize);
    button:SetMouseMotionEnabled(false);

    local icon, cooldown = CreateDebuffVisual(button);
    button:SetIcon(icon);
    button:SetDurationCooldown(cooldown);

    AddSecureHighlightTexture(
        button,
        addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_GLOW_TEXTURE,
        "BORDER",
        0.9
    );
    AddSecureHighlightTexture(
        button,
        addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_BORDER_TEXTURE,
        "OVERLAY",
        1
    );
end

local function EnsureVisualRoot(frame)
    local root = frame.sweepyBoopDebuffRoot;
    if root then return root end

    root = CreateFrame("Frame", nil, frame);
    root:SetSize(1, 1);
    root:SetFrameLevel(frame:GetFrameLevel() + frameLevelOffset);
    frame.sweepyBoopDebuffRoot = root;
    return root;
end

local function ApplyVisualRootLayout(frame)
    local config = GetConfig();
    local root = EnsureVisualRoot(frame);

    root:ClearAllPoints();
    root:SetPoint(
        "LEFT",
        frame,
        "RIGHT",
        config.raidFrameDebuffIconOffsetX or 0,
        config.raidFrameDebuffIconOffsetY or 0
    );
    root:SetScale(GetIconSize(frame, config) / iconBaseSize);
    return root;
end

local function ApplyContainerLayout(frame, container)
    local config = GetConfig();
    local root = ApplyVisualRootLayout(frame);

    container:ClearAllPoints();
    container:SetPoint("LEFT", root, "LEFT");
    container:SetAuraGroupMaxFrameCount(auraGroupKey, GetIconCount(config));
end

local function RestyleContainer(frame, container)
    ApplyVisualRootLayout(frame);

    if ( not CanStyleAuraButtons() ) then
        restylePending = true;
        return;
    end

    restylePending = false;
    ApplyContainerLayout(frame, container);
    local config = GetConfig();
    for _, button in ipairs(frame.sweepyBoopDebuffAuraButtons or {}) do
        local cooldown = button:GetDurationCooldown();
        if cooldown then
            StyleCooldown(cooldown, config);
        end
    end
end

local function EnsureContainer(frame)
    local container = frame.sweepyBoopDebuffAuraContainer;
    if container then return container end

    local root = EnsureVisualRoot(frame);
    container = CreateFrame(
        "AuraContainer",
        nil,
        root,
        "CustomAuraContainerTemplate"
    );
    -- CustomAuraContainerTemplate starts enabled. Blizzard_AuraContainer.lua uses
    -- visibility to gate dynamic events, and OnShow requests a full aura refresh.
    container:Hide();
    container:SetFrameLevel(frame:GetFrameLevel() + frameLevelOffset);
    container:SetFlowLayoutAxis(AnchorUtil.FlowLayoutAxis.Horizontal);
    container:SetFlowLayoutAnchorPoint("LEFT");
    container:SetFlowLayoutGrowthDirection(
        AnchorUtil.FlowDirection.Right,
        AnchorUtil.FlowDirection.Down
    );
    container:SetAuraProcessingPolicy(
        CustomAuraContainerAuraProcessingPolicy.ProcessAura,
        {
            displayOnlyDispellableDebuffs = false,
            ignoreBuffs = true,
            ignoreDebuffs = false,
            ignoreDispelDebuffs = false,
        }
    );
    container:AddAuraGroup(auraGroupKey, auraFilter, {
        maxFrameCount = GetIconCount(GetConfig()),
        -- TODO: Restore UnitFrameDebuff when Blizzard's comparator handles nil debuffType values.
        sortMethod = AuraContainerSortMethod.Default,
        sortDirection = AuraContainerSortDirection.Normal,
        initializeFrame = function(button)
            InitializeAuraButton(button, frame);
        end,
        layout = {
            elementSpacing = iconSpacing,
            lineSpacing = iconSpacing,
            elementWidth = iconBaseSize,
            elementHeight = iconBaseSize,
        },
    });

    frame.sweepyBoopDebuffAuraContainer = container;
    ApplyContainerLayout(frame, container);
    return container;
end

local function HideContainer(frame)
    local container = frame.sweepyBoopDebuffAuraContainer;
    if container then
        container:Hide();
    end
end

local function IsGroupUnit(unit)
    if ( not unit ) then return false end
    return ( unit == "player" )
        or ( unit == "pet" )
        or ( string.match(unit, "^party%d+$") ~= nil )
        or ( string.match(unit, "^partypet%d+$") ~= nil )
        or ( string.match(unit, "^raid%d+$") ~= nil )
        or ( string.match(unit, "^raidpet%d+$") ~= nil );
end

local function IsFrameVisible(frame)
    local shown = frame:IsShown();
    return ( not addon.IsSecretValue(shown) ) and shown;
end

local function ShouldTrackFrameName(name)
    if ( not name ) then return false end
    return ( string.sub(name, 1, 17) == "CompactPartyFrame" )
        or ( string.sub(name, 1, 11) == "CompactRaid" );
end

local function ClearTestIcons(frame)
    local icons = frame.sweepyBoopDebuffTestIcons;
    if ( not icons ) then return end
    for i = 1, #icons do
        icons[i].highlightGlow:Hide();
        icons[i].highlightBorder:Hide();
        icons[i]:Hide();
    end
end

local function EnsureTestIcon(frame, index)
    frame.sweepyBoopDebuffTestIcons = frame.sweepyBoopDebuffTestIcons or {};
    local icon = frame.sweepyBoopDebuffTestIcons[index];
    if icon then return icon end

    local root = EnsureVisualRoot(frame);
    icon = CreateFrame("Frame", nil, root);
    icon:SetFrameLevel(frame:GetFrameLevel() + frameLevelOffset + index);
    icon:SetSize(iconBaseSize, iconBaseSize);
    icon.texture, icon.cooldown = CreateDebuffVisual(icon);
    icon.highlightGlow = CreateHighlightTexture(
        icon,
        addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_GLOW_TEXTURE,
        "BORDER",
        0.9
    );
    icon.highlightBorder = CreateHighlightTexture(
        icon,
        addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_BORDER_TEXTURE,
        "OVERLAY",
        1
    );
    frame.sweepyBoopDebuffTestIcons[index] = icon;
    return icon;
end

local function ShowTestFrame(frame)
    if frame:IsForbidden()
        or ( not IsFrameVisible(frame) ) then
        return;
    end

    HideContainer(frame);
    ClearTestIcons(frame);

    local config = GetConfig();
    local root = ApplyVisualRootLayout(frame);
    local count = math.min(GetIconCount(config), 2);
    local previous;
    for i = 1, count do
        local icon = EnsureTestIcon(frame, i);
        icon:ClearAllPoints();
        if previous then
            icon:SetPoint("LEFT", previous, "RIGHT", iconSpacing, 0);
        else
            icon:SetPoint("LEFT", root, "LEFT");
        end
        StyleCooldown(icon.cooldown, config);
        icon.texture:SetTexture(addon.GetSpellTexture(i == 1 and psychicScream or kidneyShot));
        icon.cooldown:SetCooldown(GetTime(), testDuration);
        icon.cooldown:Show();
        local color = i == 1 and nil or redHighlightColor;
        local red = color and color[1] or 1;
        local green = color and color[2] or 1;
        local blue = color and color[3] or 1;
        icon.highlightGlow:SetVertexColor(red, green, blue, 1);
        icon.highlightBorder:SetVertexColor(red, green, blue, 1);
        icon.highlightGlow:Show();
        icon.highlightBorder:Show();
        icon:Show();
        previous = icon;
    end
end

local function ActivateContainer(container, unit, forceRefresh)
    if container:GetUnit() ~= unit then
        -- Blizzard_AuraContainer.lua: AuraContainerSharedMixin:SetUnit refreshes on token changes.
        container:SetUnit(unit);
    elseif forceRefresh then
        -- The same mixin exposes UpdateAllAuras for external same-token occupant changes.
        container:UpdateAllAuras();
    end
    container:Show();
end

local function UpdateFrame(frame, forceRefresh)
    if ( not frame ) or frame:IsForbidden() then return end

    if isTesting then
        ShowTestFrame(frame);
        return;
    end

    ClearTestIcons(frame);
    local unit = frame.displayedUnit or frame.unit;
    -- Blizzard's fake AuraContainer provider is Edit Mode preview data, not live unit state.
    if ( not addon.IsUsingRealAuraData() )
        or ( not IsEnabled() )
        or ( not IsFrameVisible(frame) )
        or ( not unit )
        or ( not UnitExists(unit) )
        or ( not IsGroupUnit(unit) ) then
        HideContainer(frame);
        return;
    end

    local container = EnsureContainer(frame);
    RestyleContainer(frame, container);
    ActivateContainer(container, unit, forceRefresh);
end

local function RefreshAllFrames(forceRefresh)
    for frame in pairs(cufPool) do
        UpdateFrame(frame, forceRefresh);
    end
end

local function ReconcilePendingRestyle()
    -- Normal refreshes style immediately when access is permitted. A restricted
    -- attempt leaves this dirty flag set until the shared Blizzard restriction
    -- transition callback wakes one event-driven retry; no polling is required.
    if ( not restylePending ) or ( not CanStyleAuraButtons() ) then return end
    RefreshAllFrames();
end

local function TrackFrame(frame)
    if ( not frame ) or frame:IsForbidden() then return end
    local name = frame:GetName();
    if ShouldTrackFrameName(name) then
        cufPool[frame] = true;
        UpdateFrame(frame);
    elseif cufPool[frame] then
        cufPool[frame] = nil;
        HideContainer(frame);
        ClearTestIcons(frame);
    end
end

function SweepyBoop:SetupRaidFrameDebuffIcons()
    if ( not addon.PROJECT_MAINLINE ) or setupComplete then return end
    setupComplete = true;

    hooksecurefunc("CompactUnitFrame_UpdateAll", TrackFrame);
    hooksecurefunc("CompactUnitFrame_SetUnit", TrackFrame);
    hooksecurefunc("CompactUnitFrame_UpdateVisible", TrackFrame);

    local eventFrame = CreateFrame("Frame");
    eventFrame:RegisterEvent(addon.GROUP_ROSTER_UPDATE);
    eventFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
    eventFrame:RegisterEvent(addon.PLAYER_REGEN_ENABLED);
    eventFrame:SetScript("OnEvent", function(_, event)
        if event == addon.PLAYER_REGEN_ENABLED
            or event == addon.PLAYER_ENTERING_WORLD then

            ReconcilePendingRestyle();
        end

        local forceRefresh = event == addon.GROUP_ROSTER_UPDATE;
        if forceRefresh then
            C_Timer.After(0, function()
                RefreshAllFrames(true);
            end);
        else
            RefreshAllFrames();
        end
    end);

    addon.RegisterAuraDataProviderListener("RaidFrameDebuffIcons", function()
        RefreshAllFrames();
    end);
    addon.RegisterAuraRestrictionListener("RaidFrameDebuffIcons", ReconcilePendingRestyle);
end

function SweepyBoop:RefreshRaidFrameDebuffIcons()
    RefreshAllFrames();
    ReconcilePendingRestyle();
end

function SweepyBoop:TestRaidFrameDebuffIcons()
    isTesting = true;
    RefreshAllFrames();
    if testTimer then
        testTimer:Cancel();
    end
    testTimer = C_Timer.NewTimer(testDuration, function()
        testTimer = nil;
        if isTesting then
            SweepyBoop:HideTestRaidFrameDebuffIcons();
        end
    end);
end

function SweepyBoop:HideTestRaidFrameDebuffIcons()
    if testTimer then
        testTimer:Cancel();
        testTimer = nil;
    end
    isTesting = false;
    RefreshAllFrames();
end
