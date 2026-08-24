local _, addon = ...;

local Type, Version = "ArenaOffensiveIconPreview-SweepyBoop", 1;
local AceGUI = LibStub and LibStub("AceGUI-3.0", true);
if not AceGUI or ( AceGUI:GetWidgetVersion(Type) or 0 ) >= Version then return end

local previewWidgets = setmetatable({}, { __mode = "k" });
local style = addon.ARENA_OFFENSIVE_ICON_STYLE;
local TEXTURE_WHITE = "Interface\\BUTTONS\\WHITE8X8";
local sampleSpellID = 12472; -- Icy Veins
local previewFrameWidth = 144;
local previewFrameHeight = 72;
local previewHeight = 116;
local baseIconSize = style.BASE_SIZE;
local sampleCooldownDuration = 18;
local sampleCooldownInitialElapsed = 4;

local function GetConfig()
    return SweepyBoop.db.profile.arenaFrames;
end

local function ConfigureCooldownSwipe(cooldown)
    cooldown:SetDrawBling(false);
    cooldown:SetDrawSwipe(true);
    cooldown:SetDrawEdge(true);
    cooldown:SetReverse(true);
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

local function RestartIconCooldown(icon, elapsed)
    if not icon.previewActive then
        return;
    end
    icon.cooldown:SetCooldown(GetTime() - ( elapsed or 0 ), sampleCooldownDuration);
end

local function ClearIconCooldown(icon)
    icon.previewActive = false;
    if icon.cooldown.Clear then
        icon.cooldown:Clear();
    else
        icon.cooldown:SetCooldown(0, 0);
    end
    icon.cooldown:Hide();
end

local function CleanupPreview(widget)
    if not widget or not widget.sample then
        return;
    end

    ClearIconCooldown(widget.sample.icon);
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
    texture:SetVertexColor(unpack(style.HIGHLIGHT_COLOR));
    texture:SetAlpha(alpha);
    return texture;
end

local function BuildSample(parent)
    local previewFrame = CreateFrame("Frame", nil, parent);
    previewFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -28);
    previewFrame:SetSize(previewFrameWidth, previewFrameHeight);

    local background = previewFrame:CreateTexture(nil, "BACKGROUND");
    background:SetAllPoints(previewFrame);
    background:SetTexture(TEXTURE_WHITE);
    local mageColor = RAID_CLASS_COLORS and RAID_CLASS_COLORS.MAGE;
    background:SetVertexColor(
        ( mageColor and mageColor.r ) or 0.25,
        ( mageColor and mageColor.g ) or 0.78,
        ( mageColor and mageColor.b ) or 0.92,
        1
    );

    local function CreateBorderEdge(point, relativePoint, width, height)
        local edge = previewFrame:CreateTexture(nil, "OVERLAY");
        edge:SetColorTexture(0, 0, 0, 1);
        edge:SetPoint(point, previewFrame, relativePoint);
        edge:SetSize(width, height);
    end

    CreateBorderEdge("TOPLEFT", "TOPLEFT", previewFrameWidth, 1);
    CreateBorderEdge("BOTTOMLEFT", "BOTTOMLEFT", previewFrameWidth, 1);
    CreateBorderEdge("TOPLEFT", "TOPLEFT", 1, previewFrameHeight);
    CreateBorderEdge("TOPRIGHT", "TOPRIGHT", 1, previewFrameHeight);

    local icon = CreateFrame("Frame", nil, previewFrame);
    local shadow = icon:CreateTexture(nil, "OVERLAY", nil, 2);
    shadow:SetTexture(style.SHADOW_TEXTURE);
    shadow:SetTexCoord(unpack(style.SHADOW_TEX_COORDS));
    shadow:SetHorizTile(false);
    shadow:SetVertTile(false);
    shadow:SetAlpha(style.SHADOW_ALPHA);
    shadow:SetSize(style.SHADOW_SIZE, style.SHADOW_SIZE);
    shadow:SetPoint(
        "CENTER",
        icon,
        "CENTER",
        style.SHADOW_OFFSET_X,
        style.SHADOW_OFFSET_Y
    );

    local iconBackdrop = icon:CreateTexture(nil, "BACKGROUND");
    iconBackdrop:SetAllPoints(icon);
    iconBackdrop:SetColorTexture(unpack(style.BACKDROP_COLOR));

    icon.texture = icon:CreateTexture(nil, "ARTWORK");
    icon.texture:SetPoint("TOPLEFT", icon, "TOPLEFT", style.ICON_INSET, -style.ICON_INSET);
    icon.texture:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -style.ICON_INSET, style.ICON_INSET);
    icon.texture:SetTexCoord(unpack(style.ICON_TEX_COORDS));
    CreateHighlightTexture(
        icon,
        addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_GLOW_TEXTURE,
        "BORDER",
        style.HIGHLIGHT_GLOW_ALPHA
    );
    CreateHighlightTexture(
        icon,
        addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_BORDER_TEXTURE,
        "OVERLAY",
        style.HIGHLIGHT_BORDER_ALPHA
    );

    icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate");
    icon.cooldown:SetAllPoints(icon);
    ConfigureCooldownSwipe(icon.cooldown);
    icon.cooldown:SetScript("OnCooldownDone", function()
        RestartIconCooldown(icon);
    end);

    return {
        frame = previewFrame,
        icon = icon,
    };
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

        local config = GetConfig();
        local enabled = config.arenaOffensiveIconsEnabled;
        local scale = ( config.arenaOffensiveIconSize or style.DEFAULT_DISPLAY_SIZE ) / baseIconSize;
        local icon = self.sample.icon;

        icon.previewActive = self.frame:IsShown();
        icon:SetSize(baseIconSize, baseIconSize);
        icon:SetScale(scale);
        icon:ClearAllPoints();
        icon:SetPoint(
            "LEFT",
            self.sample.frame,
            "LEFT",
            ( config.arenaOffensiveIconOffsetX or 0 ) / scale,
            ( config.arenaOffensiveIconOffsetY or 0 ) / scale
        );
        icon.texture:SetTexture(addon.GetSpellTexture(sampleSpellID));
        RestartIconCooldown(icon, sampleCooldownInitialElapsed);
        icon:SetAlpha(enabled and 1 or 0.35);
        icon:SetShown(true);

        self.sample.frame:SetAlpha(enabled and 1 or 0.45);
        self.disabledText:SetShown(not enabled);
    end,
};

function addon.RefreshArenaOffensiveIconPreviewWidgets()
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
    disabledText:SetPoint("LEFT", sample.frame, "RIGHT", 12, 0);
    disabledText:SetText(addon.L["Disabled"]);

    local widget = {
        frame = frame,
        label = label,
        sample = sample,
        disabledText = disabledText,
        type = Type,
    };

    frame:SetScript("OnShow", function()
        addon.RefreshArenaOffensiveIconPreviewWidgets();
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
