local _, addon = ...;

local Type, Version = "RaidFrameAggroPreview-SweepyBoop", 1;
local AceGUI = LibStub and LibStub("AceGUI-3.0", true);
if not AceGUI or ( AceGUI:GetWidgetVersion(Type) or 0 ) >= Version then return end

local TEXTURE_WHITE = "Interface\\BUTTONS\\WHITE8X8";
local TEXTURE_RAID_ICONS = "Interface\\TargetingFrame\\UI-RaidTargetingIcons";
local PREVIEW_FRAME_WIDTH = 170;
local PREVIEW_FRAME_HEIGHT = 56;
local PREVIEW_HEIGHT = 168;
local MARKER_BORDER_SIZE = 1;
local FLASH_SECONDS = 0.85;
local FLASH_MIN_ALPHA = 0.35;

local RAID_ICON_INDICES = {
    Star = 1,
    Circle = 2,
    Diamond = 3,
    Triangle = 4,
    Moon = 5,
    Square = 6,
    Cross = 7,
    Skull = 8,
    Flag = 15,
    Murloc = 16,
};

local previewWidgets = setmetatable({}, { __mode = "k" });

local sampleColors = {
    { r = 0.25, g = 0.78, b = 0.92 },
    { r = 1.00, g = 0.96, b = 0.41 },
    { r = 1.00, g = 0.49, b = 0.04 },
};

local function GetConfig()
    return SweepyBoop.db.profile.raidFrames;
end

local function NormalizeShape(shape)
    return RAID_ICON_INDICES[shape] and shape or "Circle";
end

local function ConfigValue(keyPrefix, key)
    return GetConfig()[keyPrefix .. key];
end

local function RemoveMask(texture, mask)
    if mask then
        mask:Hide();
        texture:RemoveMaskTexture(mask);
    end
end

local function PrepareLayer(texture, r, g, b, a)
    texture:SetTexture(TEXTURE_WHITE);
    texture:SetTexCoord(0, 1, 0, 1);
    texture:SetVertexColor(r, g, b, a);
    texture:Show();
end

local function MoveMask(mask, owner, iconIndex, width, height)
    local column = ( iconIndex - 1 ) % 4;
    local row = math.floor(( iconIndex - 1 ) / 4);

    mask:SetTexture(TEXTURE_RAID_ICONS, "CLAMP", "CLAMP");
    mask:SetSize(width * 4, height * 4);
    mask:ClearAllPoints();
    mask:SetPoint("TOPLEFT", owner, "TOPLEFT", -column * width, row * height);
    mask:Show();
end

local function DrawPreviewMarker(marker, shape, color, alpha, size)
    local iconIndex = RAID_ICON_INDICES[NormalizeShape(shape)];
    local fillSize = math.max(0, size - ( 2 * MARKER_BORDER_SIZE ));

    RemoveMask(marker.outline, marker.outlineMask);
    RemoveMask(marker.fill, marker.fillMask);

    marker:SetSize(size, size);
    marker.outline:ClearAllPoints();
    marker.outline:SetAllPoints(marker);
    marker.fill:ClearAllPoints();
    marker.fill:SetPoint("CENTER", marker, "CENTER", 0, 0);
    marker.fill:SetSize(fillSize, fillSize);

    PrepareLayer(marker.outline, 0, 0, 0, alpha);
    PrepareLayer(marker.fill, color.r, color.g, color.b, alpha);

    if not marker.outlineMask then marker.outlineMask = marker:CreateMaskTexture() end
    if not marker.fillMask then marker.fillMask = marker:CreateMaskTexture() end

    MoveMask(marker.outlineMask, marker, iconIndex, size, size);
    MoveMask(marker.fillMask, marker.fill, iconIndex, fillSize, fillSize);
    marker.outline:AddMaskTexture(marker.outlineMask);
    marker.fill:AddMaskTexture(marker.fillMask);
    marker:Show();
end

local function EnsureMarker(parent, markers, index)
    if markers[index] then
        return markers[index];
    end

    local marker = CreateFrame("Frame", nil, parent);
    marker.outline = marker:CreateTexture(nil, "BACKGROUND");
    marker.fill = marker:CreateTexture(nil, "ARTWORK");
    marker.outline:SetBlendMode("BLEND");
    marker.fill:SetBlendMode("BLEND");
    markers[index] = marker;
    return marker;
end

local function PositionMarker(marker, previewFrame, previewContainer, previousMarker, index, keyPrefix)
    marker:ClearAllPoints();

    local growDirection = ConfigValue(keyPrefix, "GrowDirection");
    local spacing = ConfigValue(keyPrefix, "Spacing");
    if index == 1 then
        if growDirection == "CENTER_HORIZONTAL" then
            marker:SetPoint("LEFT", previewContainer, "LEFT", 0, 0);
        elseif growDirection == "CENTER_VERTICAL" then
            marker:SetPoint("TOP", previewContainer, "TOP", 0, 0);
        else
            marker:SetPoint(
                ConfigValue(keyPrefix, "Anchor"),
                previewFrame,
                ConfigValue(keyPrefix, "RelativePoint"),
                ConfigValue(keyPrefix, "OffsetX"),
                ConfigValue(keyPrefix, "OffsetY")
            );
        end
        return;
    end

    if ( growDirection == "RIGHT" ) or ( growDirection == "CENTER_HORIZONTAL" ) then
        marker:SetPoint("LEFT", previousMarker, "RIGHT", spacing, 0);
    elseif growDirection == "UP" then
        marker:SetPoint("BOTTOM", previousMarker, "TOP", 0, spacing);
    elseif ( growDirection == "DOWN" ) or ( growDirection == "CENTER_VERTICAL" ) then
        marker:SetPoint("TOP", previousMarker, "BOTTOM", 0, -spacing);
    else
        marker:SetPoint("RIGHT", previousMarker, "LEFT", -spacing, 0);
    end
end

local function LayoutPreviewContainer(previewFrame, previewContainer, keyPrefix, markerCount)
    local markerSize = ConfigValue(keyPrefix, "Size");
    local spacing = ConfigValue(keyPrefix, "Spacing");
    local growDirection = ConfigValue(keyPrefix, "GrowDirection");
    local totalSpacing = math.max(0, markerCount - 1) * spacing;
    local width = markerSize;
    local height = markerSize;

    if ( growDirection == "UP" ) or ( growDirection == "DOWN" ) or ( growDirection == "CENTER_VERTICAL" ) then
        height = ( markerCount * markerSize ) + totalSpacing;
    else
        width = ( markerCount * markerSize ) + totalSpacing;
    end

    previewContainer:ClearAllPoints();
    if ( growDirection == "CENTER_HORIZONTAL" ) or ( growDirection == "CENTER_VERTICAL" ) then
        previewContainer:SetPoint(
            "CENTER",
            previewFrame,
            ConfigValue(keyPrefix, "RelativePoint"),
            ConfigValue(keyPrefix, "OffsetX"),
            ConfigValue(keyPrefix, "OffsetY")
        );
    else
        previewContainer:SetPoint(
            ConfigValue(keyPrefix, "Anchor"),
            previewFrame,
            ConfigValue(keyPrefix, "RelativePoint"),
            ConfigValue(keyPrefix, "OffsetX"),
            ConfigValue(keyPrefix, "OffsetY")
        );
    end
    previewContainer:SetSize(width, height);
end

local function RenderSample(widget, sample, markerCount)
    LayoutPreviewContainer(sample.frame, sample.container, widget.keyPrefix, markerCount);

    local shape = NormalizeShape(ConfigValue(widget.keyPrefix, "Shape"));
    local markerSize = ConfigValue(widget.keyPrefix, "Size");
    local alpha = ConfigValue(widget.keyPrefix, "Alpha");
    local previousMarker;
    for i = 1, markerCount do
        local marker = EnsureMarker(sample.frame, sample.markers, i);
        DrawPreviewMarker(marker, shape, sampleColors[i], alpha, markerSize);
        PositionMarker(marker, sample.frame, sample.container, previousMarker, i, widget.keyPrefix);
        previousMarker = marker;
    end

    for i = markerCount + 1, #sample.markers do
        sample.markers[i]:Hide();
    end
end

local function SetFlashingSampleAlpha(widget, alpha)
    local sample = widget.flashingSample;
    if not sample then
        return;
    end

    for i = 1, #sample.markers do
        sample.markers[i]:SetAlpha(alpha);
    end
end

local function StartPreviewFlash(widget)
    widget.frame:SetScript("OnUpdate", function(_, elapsed)
        widget.flashElapsed = ( widget.flashElapsed or 0 ) + elapsed;
        local progress = ( widget.flashElapsed % FLASH_SECONDS ) / FLASH_SECONDS;
        local pulse = FLASH_MIN_ALPHA + ( ( 1 - FLASH_MIN_ALPHA ) * ( 0.5 + ( 0.5 * math.sin(progress * math.pi * 2) ) ) );
        SetFlashingSampleAlpha(widget, ConfigValue(widget.keyPrefix, "Alpha") * pulse);
    end);
end

local function StopPreviewFlash(widget)
    widget.frame:SetScript("OnUpdate", nil);
    widget.flashElapsed = 0;
    SetFlashingSampleAlpha(widget, 1);
end

local function BuildSample(parent, title, topOffset)
    local titleText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
    titleText:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, topOffset);
    titleText:SetText(title);
    titleText:SetTextColor(1, 1, 1, 1);

    local previewFrame = CreateFrame("Frame", nil, parent);
    previewFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, topOffset - 18);
    previewFrame:SetSize(PREVIEW_FRAME_WIDTH, PREVIEW_FRAME_HEIGHT);

    local border = previewFrame:CreateTexture(nil, "BACKGROUND");
    border:SetAllPoints(previewFrame);
    border:SetTexture(TEXTURE_WHITE);
    border:SetVertexColor(0, 0, 0, 1);

    local background = previewFrame:CreateTexture(nil, "BORDER");
    background:SetPoint("TOPLEFT", previewFrame, "TOPLEFT", 1, -1);
    background:SetPoint("BOTTOMRIGHT", previewFrame, "BOTTOMRIGHT", -1, 1);
    background:SetTexture(TEXTURE_WHITE);
    background:SetVertexColor(1, 0.45, 0, 1);

    return {
        frame = previewFrame,
        container = CreateFrame("Frame", nil, previewFrame),
        markers = {},
    };
end

local methods = {
    ["OnAcquire"] = function(self)
        self:SetFullWidth(true);
        self:SetHeight(PREVIEW_HEIGHT);
        self.frame:SetHeight(PREVIEW_HEIGHT);
        previewWidgets[self] = true;
        self:Refresh();
    end,

    ["OnRelease"] = function(self)
        previewWidgets[self] = nil;
        self.keyPrefix = nil;
        StopPreviewFlash(self);
    end,

    ["SetText"] = function(self, text)
        self.label:SetText(text or "Preview");
    end,

    ["SetFontObject"] = function(self, fontObject)
        self.label:SetFontObject(fontObject or GameFontNormal);
    end,

    ["SetDisabled"] = function(self, disabled)
        self.disabled = disabled;
        self:Refresh();
    end,

    ["SetCustomData"] = function(self, data)
        self.keyPrefix = data and data.keyPrefix;
        self:Refresh();
    end,

    ["OnWidthSet"] = function(self, width)
        self.frame:SetWidth(width);
        self:Refresh();
    end,

    ["Refresh"] = function(self)
        if not self.keyPrefix or not SweepyBoop or not SweepyBoop.db then
            return;
        end

        local enabled = ConfigValue(self.keyPrefix, "Enabled");
        self.normalSample.frame:SetAlpha(enabled and 1 or 0.35);
        self.flashingSample.frame:SetAlpha(enabled and 1 or 0.35);
        self.disabledText:SetShown(not enabled);

        RenderSample(self, self.normalSample, 2);
        RenderSample(self, self.flashingSample, 3);
        StopPreviewFlash(self);
        if enabled then
            StartPreviewFlash(self);
        end
    end,
};

function addon.RefreshRaidFrameAggroPreviewWidgets()
    for widget in pairs(previewWidgets) do
        widget:Refresh();
    end
end

local function Constructor()
    local frame = CreateFrame("Frame", nil, UIParent);
    frame:Hide();
    frame:SetHeight(PREVIEW_HEIGHT);

    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    label:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -4);
    label:SetTextColor(1, 0.82, 0, 1);

    local normalSample = BuildSample(frame, "2 targeters", -24);
    local flashingSample = BuildSample(frame, "3 targeters (flashing)", -94);

    local disabledText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall");
    disabledText:SetPoint("LEFT", normalSample.frame, "RIGHT", 12, 0);
    disabledText:SetText("Disabled");

    local widget = {
        frame = frame,
        label = label,
        normalSample = normalSample,
        flashingSample = flashingSample,
        disabledText = disabledText,
        type = Type,
    };

    frame:SetScript("OnShow", function()
        addon.RefreshRaidFrameAggroPreviewWidgets();
    end);
    frame:SetScript("OnHide", function()
        StopPreviewFlash(widget);
    end);

    for method, func in pairs(methods) do
        widget[method] = func;
    end

    return AceGUI:RegisterAsWidget(widget);
end

AceGUI:RegisterWidgetType(Type, Constructor, Version);
