local _, addon = ...;

local Type, Version = "RaidFrameDebuffIconPreview-SweepyBoop", 1;
local AceGUI = LibStub and LibStub("AceGUI-3.0", true);
if not AceGUI or ( AceGUI:GetWidgetVersion(Type) or 0 ) >= Version then return end

local previewWidgets = setmetatable({}, { __mode = "k" });
local TEXTURE_WHITE = "Interface\\BUTTONS\\WHITE8X8";
local psychicScream = 8122;
local kidneyShot = 408;
local testDuration = 6;
local testInitialElapsed = 1;
local iconSpacing = 2;
local redGlowColor = { 1, 0, 0, 1 };
local previewFrameWidth = 144;
local previewFrameHeight = 72;
local previewHeight = 116;

local function GetConfig()
    return SweepyBoop.db.profile.raidFrames;
end

local function Clamp(value, minValue, maxValue)
    value = tonumber(value) or minValue;
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value;
end

local function GetIconCount(config)
    return Clamp(config.raidFrameDebuffIconCount, 1, 5);
end

local function GetIconScale(config)
    local scale = tonumber(config.raidFrameDebuffIconScale) or 0.5;
    if scale <= 0 then return 0.5 end
    return scale;
end

local function GetMillisecondsThreshold(config)
    return Clamp(config.raidFrameDebuffIconMillisecondsThreshold, 1, 6);
end

local function IsEnabled(config)
    return config.raidFrameDebuffIconsEnabled and ( not addon.IsConflictingRaidFrameDebuffAddonLoaded() );
end

local function StyleCooldown(cooldown, config)
    cooldown:SetDrawBling(false);
    cooldown:SetReverse(true);
    cooldown:SetDrawSwipe(true);
    cooldown:SetSwipeColor(0, 0, 0, 0.5);
    cooldown:SetDrawEdge(true);
    cooldown:SetEdgeTexture("Interface\\Cooldown\\UI-HUD-ActionBar-LoC");
    cooldown:SetHideCountdownNumbers(false);
    if cooldown.SetCountdownMillisecondsThreshold then
        cooldown:SetCountdownMillisecondsThreshold(GetMillisecondsThreshold(config));
    end
end

local function RestartIconCooldown(icon, elapsed)
    if not icon.previewActive then
        return;
    end
    icon.cooldown:SetCooldown(GetTime() - ( elapsed or 0 ), testDuration);
    icon.cooldown:Show();
end

local function UpdateCooldownFontSize(cooldown, iconSize)
    if ( not cooldown ) or ( not iconSize ) then return end

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
            region:SetFont(font, math.floor(iconSize * addon.COUNTDOWN_FONT_SIZE_COEFFICIENT), flags);
        end
    end
end

local function SetIconSize(icon, frameHeight, scale)
    local shownSize = frameHeight * scale;
    local visualScale = shownSize / addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_BASE_SIZE;
    local inset = addon.BIG_DEBUFFS_ICON_STYLE.DEBUFF_ICON_INSET * visualScale;
    local borderPadding = visualScale;
    local highlightPadding = addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_PADDING * visualScale;

    icon:SetSize(shownSize, shownSize);
    icon.texture:ClearAllPoints();
    icon.texture:SetPoint("TOPLEFT", icon, "TOPLEFT", inset, -inset);
    icon.texture:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -inset, inset);
    icon.border:ClearAllPoints();
    icon.border:SetPoint("TOPLEFT", icon, "TOPLEFT", -borderPadding, borderPadding);
    icon.border:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", borderPadding, -borderPadding);
    icon.highlightGlow:ClearAllPoints();
    icon.highlightGlow:SetPoint("TOPLEFT", icon, "TOPLEFT", -highlightPadding, highlightPadding);
    icon.highlightGlow:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", highlightPadding, -highlightPadding);
    icon.highlightBorder:ClearAllPoints();
    icon.highlightBorder:SetPoint("TOPLEFT", icon, "TOPLEFT", -highlightPadding, highlightPadding);
    icon.highlightBorder:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", highlightPadding, -highlightPadding);
    UpdateCooldownFontSize(icon.cooldown, shownSize);
end

local function ClearIcon(icon)
    icon.previewActive = false;
    icon.texture:SetTexture(nil);
    if icon.cooldown.Clear then
        icon.cooldown:Clear();
    else
        icon.cooldown:SetCooldown(0, 0);
    end
    icon.cooldown:Hide();
    icon.highlightGlow:Hide();
    icon.highlightBorder:Hide();
    icon:Hide();
end

local function CleanupPreview(widget)
    if not widget or not widget.sample then
        return;
    end

    for _, icon in ipairs(widget.sample.container.icons) do
        ClearIcon(icon);
    end
end

local function CreateDebuffIcon(parent)
    local icon = CreateFrame("Frame", nil, parent);

    local backdrop = icon:CreateTexture(nil, "BACKGROUND");
    backdrop:SetAllPoints(icon);
    backdrop:SetColorTexture(0, 0, 0, 1);

    icon.texture = icon:CreateTexture(nil, "ARTWORK");
    icon.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92);

    icon.border = icon:CreateTexture(nil, "OVERLAY");
    icon.border:SetTexture(addon.BIG_DEBUFFS_ICON_STYLE.DEBUFF_BORDER_TEXTURE);
    icon.border:SetTexCoord(unpack(addon.BIG_DEBUFFS_ICON_STYLE.DEBUFF_BORDER_TEX_COORDS));

    icon.highlightGlow = icon:CreateTexture(nil, "BORDER");
    icon.highlightGlow:SetTexture(addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_GLOW_TEXTURE);
    icon.highlightGlow:SetBlendMode("ADD");
    icon.highlightGlow:SetAlpha(0.9);

    icon.highlightBorder = icon:CreateTexture(nil, "OVERLAY");
    icon.highlightBorder:SetTexture(addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_BORDER_TEXTURE);
    icon.highlightBorder:SetBlendMode("ADD");

    icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate");
    icon.cooldown:SetAllPoints(icon.texture);
    icon.cooldown:SetScript("OnCooldownDone", function()
        RestartIconCooldown(icon);
    end);
    icon:Hide();
    return icon;
end

local function BuildSample(parent)
    local previewFrame = CreateFrame("Frame", nil, parent);
    previewFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -28);
    previewFrame:SetSize(previewFrameWidth, previewFrameHeight);

    local border = previewFrame:CreateTexture(nil, "BACKGROUND");
    border:SetAllPoints(previewFrame);
    border:SetTexture(TEXTURE_WHITE);
    border:SetVertexColor(0, 0, 0, 1);

    local background = previewFrame:CreateTexture(nil, "BORDER");
    background:SetPoint("TOPLEFT", previewFrame, "TOPLEFT", 1, -1);
    background:SetPoint("BOTTOMRIGHT", previewFrame, "BOTTOMRIGHT", -1, 1);
    background:SetTexture(TEXTURE_WHITE);
    background:SetVertexColor(1, 0.45, 0, 1);

    local container = CreateFrame("Frame", nil, previewFrame);
    container.icons = {};

    return {
        frame = previewFrame,
        container = container,
    };
end

local function EnsureIcon(sample, index)
    if sample.container.icons[index] then
        return sample.container.icons[index];
    end

    local icon = CreateDebuffIcon(sample.container);
    sample.container.icons[index] = icon;
    return icon;
end

local function RenderSample(widget)
    local config = GetConfig();
    local enabled = IsEnabled(config);
    local iconCount = GetIconCount(config);
    local frameHeight = previewFrameHeight;
    local iconScale = GetIconScale(config);
    local maxIconSize = frameHeight * iconScale;
    local shownIconCount = math.min(iconCount, 2);
    local previousIcon;

    widget.sample.container:SetSize(( maxIconSize * iconCount ) + ( iconSpacing * ( iconCount - 1 ) ), maxIconSize);
    widget.sample.container:ClearAllPoints();
    widget.sample.container:SetPoint(
        "LEFT",
        widget.sample.frame,
        "RIGHT",
        config.raidFrameDebuffIconOffsetX or 0,
        config.raidFrameDebuffIconOffsetY or 0
    );

    for i = 1, iconCount do
        local icon = EnsureIcon(widget.sample, i);
        StyleCooldown(icon.cooldown, config);
        icon:SetFrameLevel(widget.sample.frame:GetFrameLevel() + 20 + i);
        icon:ClearAllPoints();
        if previousIcon then
            icon:SetPoint("LEFT", previousIcon, "RIGHT", iconSpacing, 0);
        else
            icon:SetPoint("LEFT", widget.sample.container, "LEFT", 0, 0);
        end
        previousIcon = icon;

        if i <= shownIconCount then
            icon.previewActive = widget.frame:IsShown();
            if i == 1 then
                SetIconSize(icon, frameHeight, iconScale);
                icon.texture:SetTexture(addon.GetSpellTexture(psychicScream));
                icon.highlightGlow:SetVertexColor(1, 1, 1, 1);
                icon.highlightBorder:SetVertexColor(1, 1, 1, 1);
            else
                SetIconSize(icon, frameHeight, iconScale);
                icon.texture:SetTexture(addon.GetSpellTexture(kidneyShot));
                icon.highlightGlow:SetVertexColor(unpack(redGlowColor));
                icon.highlightBorder:SetVertexColor(unpack(redGlowColor));
            end
            icon.highlightGlow:Show();
            icon.highlightBorder:Show();
            RestartIconCooldown(icon, testInitialElapsed);
            icon:SetAlpha(enabled and 1 or 0.35);
            icon:Show();
        else
            ClearIcon(icon);
        end
    end

    for i = iconCount + 1, #widget.sample.container.icons do
        ClearIcon(widget.sample.container.icons[i]);
    end

    widget.sample.frame:SetAlpha(enabled and 1 or 0.45);
    widget.sample.container:SetAlpha(enabled and 1 or 0.35);
    widget.disabledText:SetShown(not enabled);
end

local methods = {
    ["OnAcquire"] = function(self)
        self:SetFullWidth(true);
        self:SetHeight(previewHeight);
        self.frame:SetHeight(previewHeight);
        previewWidgets[self] = true;
        self:Refresh();
    end,

    ["OnRelease"] = function(self)
        previewWidgets[self] = nil;
        CleanupPreview(self);
    end,

    ["SetText"] = function(self, text)
        self.label:SetText(text or addon.L["Preview"]);
    end,

    ["SetFontObject"] = function(self, fontObject)
        self.label:SetFontObject(fontObject or GameFontNormal);
    end,

    ["SetDisabled"] = function(self, disabled)
        self.disabled = disabled;
        self:Refresh();
    end,

    ["OnWidthSet"] = function(self, width)
        self.frame:SetWidth(width);
        self:Refresh();
    end,

    ["Refresh"] = function(self)
        if not SweepyBoop or not SweepyBoop.db then
            return;
        end
        if not self.frame:IsShown() then
            CleanupPreview(self);
            return;
        end

        RenderSample(self);
    end,
};

function addon.RefreshRaidFrameDebuffIconPreviewWidgets()
    for widget in pairs(previewWidgets) do
        widget:Refresh();
    end
end

local function Constructor()
    local frame = CreateFrame("Frame", nil, UIParent);
    frame:Hide();
    frame:SetHeight(previewHeight);

    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    label:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -4);
    label:SetTextColor(1, 0.82, 0, 1);

    local sample = BuildSample(frame);

    local disabledText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall");
    disabledText:SetPoint("TOPLEFT", sample.frame, "BOTTOMLEFT", 0, -6);
    disabledText:SetText(addon.L["Disabled"]);

    local widget = {
        frame = frame,
        label = label,
        sample = sample,
        disabledText = disabledText,
        type = Type,
    };

    frame:SetScript("OnShow", function()
        addon.RefreshRaidFrameDebuffIconPreviewWidgets();
    end);
    frame:SetScript("OnHide", function()
        CleanupPreview(widget);
    end);

    for method, func in pairs(methods) do
        widget[method] = func;
    end

    return AceGUI:RegisterAsWidget(widget);
end

AceGUI:RegisterWidgetType(Type, Constructor, Version);
