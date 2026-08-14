local _, addon = ...;

local Type, Version = "RaidFrameAggroPreview-SweepyBoop", 1;
local AceGUI = LibStub and LibStub("AceGUI-3.0", true);
if not AceGUI or ( AceGUI:GetWidgetVersion(Type) or 0 ) >= Version then return end

local aggroHighlight = addon.RAID_FRAME_AGGRO_HIGHLIGHT;
local markerRenderer = addon.RaidFrameAggroMarkerRenderer;
local TEXTURE_WHITE = aggroHighlight.TEXTURE_WHITE;

local previewWidgets = setmetatable({}, { __mode = "k" });

local sampleColors = {
    { r = 0.25, g = 0.78, b = 0.92 },
    { r = 1.00, g = 0.96, b = 0.41 },
    { r = 1.00, g = 0.49, b = 0.04 },
};

local function GetConfig()
    return SweepyBoop.db.profile.raidFrames;
end

local function ConfigValue(keyPrefix, key)
    return GetConfig()[keyPrefix .. key];
end

local function EnsureMarker(parent, markers, index)
    if markers[index] then
        return markers[index];
    end

    local marker = markerRenderer.CreateMarker(parent);
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

    local shape = markerRenderer.NormalizeShape(ConfigValue(widget.keyPrefix, "Shape"));
    local markerSize = ConfigValue(widget.keyPrefix, "Size");
    local borderThickness = ConfigValue(widget.keyPrefix, "BorderThickness");
    local previousMarker;
    for i = 1, markerCount do
        local marker = EnsureMarker(sample.frame, sample.markers, i);
        markerRenderer.ConfigureMarker(marker, shape, sampleColors[i], aggroHighlight.MARKER_ALPHA, markerSize, markerSize, borderThickness);
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
        local progress = ( widget.flashElapsed % aggroHighlight.FLASH_SECONDS ) / aggroHighlight.FLASH_SECONDS;
        local pulse = aggroHighlight.FLASH_MIN_ALPHA + ( ( 1 - aggroHighlight.FLASH_MIN_ALPHA ) * ( 0.5 + ( 0.5 * math.sin(progress * math.pi * 2) ) ) );
        SetFlashingSampleAlpha(widget, aggroHighlight.MARKER_ALPHA * pulse);
    end);
end

local function StopPreviewFlash(widget)
    widget.frame:SetScript("OnUpdate", nil);
    widget.flashElapsed = 0;
    SetFlashingSampleAlpha(widget, 1);
end

local function BuildSample(parent, anchorTo, xOffset)
    local previewFrame = CreateFrame("Frame", nil, parent);
    previewFrame:SetPoint("TOPLEFT", anchorTo, "TOPLEFT", xOffset, 0);
    previewFrame:SetSize(aggroHighlight.PREVIEW_FRAME_WIDTH, aggroHighlight.PREVIEW_FRAME_HEIGHT);

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
        self:SetHeight(aggroHighlight.PREVIEW_HEIGHT);
        self.frame:SetHeight(aggroHighlight.PREVIEW_HEIGHT);
        previewWidgets[self] = true;
        self:Refresh();
    end,

    ["OnRelease"] = function(self)
        previewWidgets[self] = nil;
        self.keyPrefix = nil;
        StopPreviewFlash(self);
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

        local enabled = ConfigValue(self.keyPrefix, "Shape") ~= "Disabled";
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
    frame:SetHeight(aggroHighlight.PREVIEW_HEIGHT);

    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    label:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -4);
    label:SetTextColor(1, 0.82, 0, 1);

    local previewRow = CreateFrame("Frame", nil, frame);
    previewRow:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -28);
    previewRow:SetSize(( aggroHighlight.PREVIEW_FRAME_WIDTH * 2 ) + aggroHighlight.PREVIEW_FRAME_SPACING, aggroHighlight.PREVIEW_FRAME_HEIGHT);

    local normalSample = BuildSample(frame, previewRow, 0);
    local flashingSample = BuildSample(frame, previewRow, aggroHighlight.PREVIEW_FRAME_WIDTH + aggroHighlight.PREVIEW_FRAME_SPACING);

    local disabledText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall");
    disabledText:SetPoint("LEFT", normalSample.frame, "RIGHT", 12, 0);
    disabledText:SetText(addon.L["Disabled"]);

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
