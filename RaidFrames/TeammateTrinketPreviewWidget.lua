local _, addon = ...;

local Type, Version = "RaidFrameTeammateTrinketPreview-SweepyBoop", 1;
local AceGUI = LibStub and LibStub("AceGUI-3.0", true);
if not AceGUI or ( AceGUI:GetWidgetVersion(Type) or 0 ) >= Version then return end

local previewWidgets = setmetatable({}, { __mode = "k" });
local textureWhite = "Interface\\BUTTONS\\WHITE8X8";
local trinketSpellID = 336126;
local iconBaseSize = addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_BASE_SIZE;
local cooldownBorderColor = { 1, 0.45, 0.1, 1 };
local cooldownIconBrightness = 0.45;
local previewFrameWidth = 144;
local previewFrameHeight = 72;
local previewHeight = 116;
local previewMargin = 16;
local previewDuration = 120;
local previewElapsed = 35;

local function GetConfig()
    return SweepyBoop.db.profile.raidFrames;
end

local function Clamp(value, minValue, maxValue)
    value = tonumber(value) or minValue;
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value;
end

local function GetIconScale(config)
    local scale = tonumber(config.raidFrameTeammateTrinketScale) or 0.5;
    return scale > 0 and scale or 0.5;
end

local function GetMillisecondsThreshold(config)
    return Clamp(config.raidFrameTeammateTrinketMillisecondsThreshold, 1, 6);
end

local function UpdateCooldownFontSize(cooldown)
    if not cooldown.sweepyBoopCountdownFontString then
        local numRegions = cooldown:GetNumRegions();
        for i = 1, numRegions do
            local region = select(i, cooldown:GetRegions());
            if region and region:GetObjectType() == "FontString" then
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
    local hideCountdown = config.raidFrameTeammateTrinketShowCountdown == false;
    cooldown:SetDrawBling(false);
    cooldown:SetReverse(true);
    cooldown:SetDrawSwipe(true);
    cooldown:SetSwipeColor(0, 0, 0, 0.5);
    cooldown:SetDrawEdge(true);
    cooldown:SetEdgeTexture("Interface\\Cooldown\\UI-HUD-ActionBar-LoC");
    cooldown:SetHideCountdownNumbers(hideCountdown);
    cooldown.noCooldownCount = hideCountdown;
    if cooldown.SetCountdownMillisecondsThreshold then
        cooldown:SetCountdownMillisecondsThreshold(GetMillisecondsThreshold(config));
    end
    UpdateCooldownFontSize(cooldown);
end

local function SetCooldownVisual(icon)
    icon.texture:SetDesaturated(true);
    icon.texture:SetVertexColor(
        cooldownIconBrightness,
        cooldownIconBrightness,
        cooldownIconBrightness,
        1
    );
    icon.border:SetVertexColor(unpack(cooldownBorderColor));
    icon.readyGlow:Hide();
end

local function StartPreviewCooldown(icon)
    if not icon.previewActive then return end

    SetCooldownVisual(icon);
    if C_DurationUtil and C_DurationUtil.CreateDuration
        and icon.cooldown.SetCooldownFromDurationObject then

        local duration = C_DurationUtil.CreateDuration();
        duration:SetTimeFromStart(GetTime() - previewElapsed, previewDuration);
        icon.cooldown:SetCooldownFromDurationObject(duration, true);
    else
        -- Preview-only fallback. Production uses Blizzard's opaque LuaDurationObject.
        icon.cooldown:SetCooldown(GetTime() - previewElapsed, previewDuration);
    end
    icon.cooldown:Show();
end

local function CreateSample(parent)
    local sampleFrame = CreateFrame("Frame", nil, parent);
    sampleFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -28);
    sampleFrame:SetSize(previewFrameWidth, previewFrameHeight);

    local border = sampleFrame:CreateTexture(nil, "BACKGROUND");
    border:SetAllPoints(sampleFrame);
    border:SetTexture(textureWhite);
    border:SetVertexColor(0, 0, 0, 1);

    local background = sampleFrame:CreateTexture(nil, "BORDER");
    background:SetPoint("TOPLEFT", sampleFrame, "TOPLEFT", 1, -1);
    background:SetPoint("BOTTOMRIGHT", sampleFrame, "BOTTOMRIGHT", -1, 1);
    background:SetTexture(textureWhite);
    background:SetVertexColor(1, 0.45, 0, 1);

    local icon = CreateFrame("Frame", nil, sampleFrame);
    icon:SetSize(iconBaseSize, iconBaseSize);

    local iconBackdrop = icon:CreateTexture(nil, "BACKGROUND");
    iconBackdrop:SetAllPoints(icon);
    iconBackdrop:SetColorTexture(0, 0, 0, 1);

    icon.texture = icon:CreateTexture(nil, "ARTWORK");
    local inset = addon.BIG_DEBUFFS_ICON_STYLE.DEBUFF_ICON_INSET;
    icon.texture:SetPoint("TOPLEFT", icon, "TOPLEFT", inset, -inset);
    icon.texture:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -inset, inset);
    icon.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92);
    icon.texture:SetTexture(addon.GetSpellTexture(trinketSpellID));

    local glowPadding = addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_PADDING;
    icon.readyGlow = icon:CreateTexture(nil, "BORDER");
    icon.readyGlow:SetTexture(addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_GLOW_TEXTURE);
    icon.readyGlow:SetBlendMode("ADD");
    icon.readyGlow:SetPoint("TOPLEFT", icon, "TOPLEFT", -glowPadding, glowPadding);
    icon.readyGlow:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", glowPadding, -glowPadding);
    icon.readyGlow:SetAlpha(0.9);

    icon.border = icon:CreateTexture(nil, "OVERLAY");
    local padding = addon.BIG_DEBUFFS_ICON_STYLE.DEBUFF_BORDER_PADDING;
    icon.border:SetPoint("TOPLEFT", icon, "TOPLEFT", -padding, padding);
    icon.border:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", padding, -padding);
    icon.border:SetTexture(addon.BIG_DEBUFFS_ICON_STYLE.DEBUFF_BORDER_TEXTURE);
    icon.border:SetTexCoord(unpack(addon.BIG_DEBUFFS_ICON_STYLE.DEBUFF_BORDER_TEX_COORDS));

    icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate");
    icon.cooldown:SetAllPoints(icon.texture);
    icon.cooldown:SetScript("OnCooldownDone", function()
        StartPreviewCooldown(icon);
    end);
    icon:Hide();

    return {
        frame = sampleFrame,
        icon = icon,
    };
end

local function RenderSample(widget)
    local config = GetConfig();
    local enabled = config.raidFrameTeammateTrinketEnabled;
    local shownIconSize = previewFrameHeight * GetIconScale(config);
    local offsetX = config.raidFrameTeammateTrinketOffsetX or 0;
    local offsetY = config.raidFrameTeammateTrinketOffsetY or 0;
    local iconScale = shownIconSize / iconBaseSize;
    local borderExtent = addon.BIG_DEBUFFS_ICON_STYLE.DEBUFF_BORDER_PADDING * iconScale;
    local leftExtent = math.max(0, shownIconSize - offsetX + borderExtent);
    local icon = widget.sample.icon;

    widget.sample.frame:ClearAllPoints();
    widget.sample.frame:SetPoint(
        "TOPLEFT",
        widget.frame,
        "TOPLEFT",
        previewMargin + leftExtent,
        -28
    );
    icon:ClearAllPoints();
    icon:SetPoint(
        "RIGHT",
        widget.sample.frame,
        "LEFT",
        offsetX,
        offsetY
    );
    icon:SetScale(shownIconSize / iconBaseSize);
    StyleCooldown(icon.cooldown, config);
    icon.previewActive = widget.frame:IsShown();
    icon:SetAlpha(enabled and 1 or 0.35);
    icon:Show();
    StartPreviewCooldown(icon);

    widget.sample.frame:SetAlpha(enabled and 1 or 0.45);
    widget.disabledText:SetShown(not enabled);
end

local function CleanupPreview(widget)
    local icon = widget and widget.sample and widget.sample.icon;
    if not icon then return end

    icon.previewActive = false;
    if icon.cooldown.Clear then
        icon.cooldown:Clear();
    else
        icon.cooldown:SetCooldown(0, 0);
    end
    icon.cooldown:Hide();
    icon:Hide();
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
        if not SweepyBoop or not SweepyBoop.db then return end
        if not self.frame:IsShown() then
            CleanupPreview(self);
            return;
        end
        RenderSample(self);
    end,
};

function addon.RefreshRaidFrameTeammateTrinketPreviewWidgets()
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

    local sample = CreateSample(frame);

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
        addon.RefreshRaidFrameTeammateTrinketPreviewWidgets();
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
