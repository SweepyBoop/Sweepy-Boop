local _, addon = ...;

local Type, Version = "RaidFrameTeammateTrinketPreview-SweepyBoop", 2;
local AceGUI = LibStub and LibStub("AceGUI-3.0", true);
if not AceGUI or ( AceGUI:GetWidgetVersion(Type) or 0 ) >= Version then return end

local previewWidgets = setmetatable({}, { __mode = "k" });
local textureWhite = "Interface\\BUTTONS\\WHITE8X8";
local trinketSpellID = 336126;
local iconBaseSize = addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_BASE_SIZE;
local readyGlowColor = { 0.1, 1, 0.45, 1 };
local cooldownBorderColor = { 1, 0.45, 0.1, 1 };
local cooldownIconBrightness = 0.45;
local previewFrameWidth = 144;
local previewFrameHeight = 72;
local previewTop = 28;
local previewMargin = 16;
local previewRowGap = 18;
local previewFooterHeight = 30;
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

local function SetReadyVisual(icon)
    icon.texture:SetDesaturated(false);
    icon.texture:SetVertexColor(1, 1, 1, 1);
    icon.border:SetVertexColor(unpack(readyGlowColor));
    icon.readyGlow:SetVertexColor(unpack(readyGlowColor));
    icon.readyGlow:Show();
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

local function CreateTrinketIcon(parent, restartCooldown)
    local icon = CreateFrame("Frame", nil, parent);
    icon:SetSize(iconBaseSize, iconBaseSize);

    local backdrop = icon:CreateTexture(nil, "BACKGROUND");
    backdrop:SetAllPoints(icon);
    backdrop:SetColorTexture(0, 0, 0, 1);

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
    if restartCooldown then
        icon.cooldown:SetScript("OnCooldownDone", function()
            StartPreviewCooldown(icon);
        end);
    end
    icon:Hide();
    return icon;
end

local function CreatePreviewRow(parent, labelText, restartCooldown)
    local row = CreateFrame("Frame", nil, parent);
    row:SetSize(previewFrameWidth, previewFrameHeight);

    local border = row:CreateTexture(nil, "BACKGROUND");
    border:SetAllPoints(row);
    border:SetTexture(textureWhite);
    border:SetVertexColor(0, 0, 0, 1);

    local background = row:CreateTexture(nil, "BORDER");
    background:SetPoint("TOPLEFT", row, "TOPLEFT", 1, -1);
    background:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -1, 1);
    background:SetTexture(textureWhite);
    background:SetVertexColor(1, 0.45, 0, 1);

    row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmallOutline");
    row.label:SetPoint("CENTER", row, "CENTER");
    row.label:SetText(labelText);

    row.icon = CreateTrinketIcon(row, restartCooldown);
    return row;
end

local function BuildSample(parent)
    return {
        ready = CreatePreviewRow(parent, addon.L["Ready"], false),
        cooldown = CreatePreviewRow(parent, addon.L["On cooldown"], true),
    };
end

local function ClearIcon(icon)
    icon.previewActive = false;
    if icon.cooldown.Clear then
        icon.cooldown:Clear();
    else
        icon.cooldown:SetCooldown(0, 0);
    end
    icon.cooldown:Hide();
    icon:Hide();
end

local function CleanupPreview(widget)
    if not widget or not widget.sample then return end
    ClearIcon(widget.sample.ready.icon);
    ClearIcon(widget.sample.cooldown.icon);
end

local function PositionRow(row, relativeFrame, relativePoint, x, y, iconScale, offsetX, offsetY)
    row:ClearAllPoints();
    row:SetPoint("TOPLEFT", relativeFrame, relativePoint, x, y);
    row.icon:ClearAllPoints();
    row.icon:SetPoint("RIGHT", row, "LEFT", offsetX, offsetY);
    row.icon:SetScale(iconScale);
end

local function RenderSample(widget)
    local config = GetConfig();
    local enabled = config.raidFrameTeammateTrinketEnabled;
    local shownIconSize = previewFrameHeight * GetIconScale(config);
    local iconScale = shownIconSize / iconBaseSize;
    local offsetX = config.raidFrameTeammateTrinketOffsetX or 0;
    local offsetY = config.raidFrameTeammateTrinketOffsetY or 0;
    local visualPadding = math.max(
        addon.BIG_DEBUFFS_ICON_STYLE.DEBUFF_BORDER_PADDING,
        addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_PADDING
    ) * iconScale;
    local leftExtent = math.max(0, shownIconSize - offsetX + visualPadding);
    local visualHalfHeight = ( shownIconSize / 2 ) + visualPadding;
    local topExtent = math.max(0, offsetY + visualHalfHeight - ( previewFrameHeight / 2 ));
    local bottomExtent = math.max(0, -offsetY + visualHalfHeight - ( previewFrameHeight / 2 ));
    local frameX = previewMargin + leftExtent;
    local firstFrameY = -( previewTop + topExtent );
    local totalHeight = previewTop
        + topExtent
        + ( previewFrameHeight * 2 )
        + previewRowGap
        + bottomExtent
        + previewFooterHeight;

    widget:SetHeight(totalHeight);
    widget.frame:SetHeight(totalHeight);
    PositionRow(
        widget.sample.ready,
        widget.frame,
        "TOPLEFT",
        frameX,
        firstFrameY,
        iconScale,
        offsetX,
        offsetY
    );
    PositionRow(
        widget.sample.cooldown,
        widget.sample.ready,
        "BOTTOMLEFT",
        0,
        -previewRowGap,
        iconScale,
        offsetX,
        offsetY
    );

    local readyIcon = widget.sample.ready.icon;
    StyleCooldown(readyIcon.cooldown, config);
    readyIcon.previewActive = widget.frame:IsShown();
    if readyIcon.cooldown.Clear then
        readyIcon.cooldown:Clear();
    end
    readyIcon.cooldown:Hide();
    SetReadyVisual(readyIcon);
    readyIcon:SetAlpha(enabled and 1 or 0.35);
    readyIcon:Show();

    local cooldownIcon = widget.sample.cooldown.icon;
    StyleCooldown(cooldownIcon.cooldown, config);
    cooldownIcon.previewActive = widget.frame:IsShown();
    cooldownIcon:SetAlpha(enabled and 1 or 0.35);
    cooldownIcon:Show();
    StartPreviewCooldown(cooldownIcon);

    widget.sample.ready:SetAlpha(enabled and 1 or 0.45);
    widget.sample.cooldown:SetAlpha(enabled and 1 or 0.45);
    widget.disabledText:ClearAllPoints();
    widget.disabledText:SetPoint(
        "TOPLEFT",
        widget.sample.cooldown,
        "BOTTOMLEFT",
        0,
        -( 6 + bottomExtent )
    );
    widget.disabledText:SetShown(not enabled);
end

local methods = {
    ["OnAcquire"] = function(self)
        self:SetFullWidth(true);
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

    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    label:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -4);
    label:SetTextColor(1, 0.82, 0, 1);

    local sample = BuildSample(frame);

    local disabledText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall");
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
