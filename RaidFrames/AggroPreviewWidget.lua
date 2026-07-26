local _, addon = ...;

local Type, Version = "RaidFrameAggroPreview-SweepyBoop", 1;
local AceGUI = LibStub and LibStub("AceGUI-3.0", true);
if not AceGUI or ( AceGUI:GetWidgetVersion(Type) or 0 ) >= Version then return end

local TEXTURE_WHITE = "Interface\\BUTTONS\\WHITE8X8";
local TEXTURE_RAID_ICONS = "Interface\\TargetingFrame\\UI-RaidTargetingIcons";
local PREVIEW_FRAME_WIDTH = 170;
local PREVIEW_FRAME_HEIGHT = 56;
local PREVIEW_HEIGHT = 104;
local MARKER_BORDER_SIZE = 1;

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

local function EnsureMarker(widget, index)
    if widget.markers[index] then
        return widget.markers[index];
    end

    local marker = CreateFrame("Frame", nil, widget.previewFrame);
    marker.outline = marker:CreateTexture(nil, "BACKGROUND");
    marker.fill = marker:CreateTexture(nil, "ARTWORK");
    marker.outline:SetBlendMode("BLEND");
    marker.fill:SetBlendMode("BLEND");
    widget.markers[index] = marker;
    return marker;
end

local function SetMarkerPoint(widget, marker, previousMarker, index, keyPrefix)
    marker:ClearAllPoints();

    local growDirection = ConfigValue(keyPrefix, "GrowDirection");
    local spacing = ConfigValue(keyPrefix, "Spacing");
    if index == 1 then
        if growDirection == "CENTER_HORIZONTAL" then
            marker:SetPoint("LEFT", widget.previewContainer, "LEFT", 0, 0);
        elseif growDirection == "CENTER_VERTICAL" then
            marker:SetPoint("TOP", widget.previewContainer, "TOP", 0, 0);
        else
            marker:SetPoint(
                ConfigValue(keyPrefix, "Anchor"),
                widget.previewFrame,
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

local function LayoutPreviewContainer(widget, markerCount)
    local keyPrefix = widget.keyPrefix;
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

    widget.previewContainer:ClearAllPoints();
    if ( growDirection == "CENTER_HORIZONTAL" ) or ( growDirection == "CENTER_VERTICAL" ) then
        widget.previewContainer:SetPoint(
            "CENTER",
            widget.previewFrame,
            ConfigValue(keyPrefix, "RelativePoint"),
            ConfigValue(keyPrefix, "OffsetX"),
            ConfigValue(keyPrefix, "OffsetY")
        );
    else
        widget.previewContainer:SetPoint(
            ConfigValue(keyPrefix, "Anchor"),
            widget.previewFrame,
            ConfigValue(keyPrefix, "RelativePoint"),
            ConfigValue(keyPrefix, "OffsetX"),
            ConfigValue(keyPrefix, "OffsetY")
        );
    end
    widget.previewContainer:SetSize(width, height);
end

local sampleColors = {
    { r = 0.25, g = 0.78, b = 0.92 },
    { r = 1.00, g = 0.96, b = 0.41 },
    { r = 1.00, g = 0.49, b = 0.04 },
};

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
        self.markerCount = data and data.markerCount or 3;
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
        self.previewFrame:SetAlpha(enabled and 1 or 0.35);
        self.disabledText:SetShown(not enabled);

        LayoutPreviewContainer(self, self.markerCount or 3);
        local shape = NormalizeShape(GetConfig().raidFrameAggroHighlightShape);
        local markerSize = ConfigValue(self.keyPrefix, "Size");
        local alpha = ConfigValue(self.keyPrefix, "Alpha");
        local previousMarker;
        local markerCount = self.markerCount or 3;
        for i = 1, markerCount do
            local marker = EnsureMarker(self, i);
            DrawPreviewMarker(marker, shape, sampleColors[i], alpha, markerSize);
            SetMarkerPoint(self, marker, previousMarker, i, self.keyPrefix);
            previousMarker = marker;
        end

        for i = markerCount + 1, #self.markers do
            self.markers[i]:Hide();
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

    local previewFrame = CreateFrame("Frame", nil, frame);
    previewFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -28);
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

    local previewContainer = CreateFrame("Frame", nil, previewFrame);

    local disabledText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall");
    disabledText:SetPoint("LEFT", previewFrame, "RIGHT", 12, 0);
    disabledText:SetText("Disabled");

    frame:SetScript("OnShow", function()
        addon.RefreshRaidFrameAggroPreviewWidgets();
    end);

    local widget = {
        frame = frame,
        label = label,
        previewFrame = previewFrame,
        previewContainer = previewContainer,
        disabledText = disabledText,
        markers = {},
        type = Type,
    };

    for method, func in pairs(methods) do
        widget[method] = func;
    end

    return AceGUI:RegisterAsWidget(widget);
end

AceGUI:RegisterWidgetType(Type, Constructor, Version);
