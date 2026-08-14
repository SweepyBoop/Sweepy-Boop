local _, addon = ...;

-- Blizzard publishes one texture per raid-target marker.
local markerTextureByShape = {
    Star = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1",
    Circle = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_2",
    Diamond = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_3",
    Triangle = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_4",
    Moon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_5",
    Square = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_6",
    Cross = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_7",
    Skull = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8",
};

local renderer = {};
addon.RaidFrameAggroMarkerRenderer = renderer;

function renderer.NormalizeShape(shape)
    return markerTextureByShape[shape] and shape or "Circle";
end

function renderer.CreateMarker(parent)
    local marker = CreateFrame("Frame", nil, parent);
    marker.outline = marker:CreateTexture(nil, "BACKGROUND");
    marker.fill = marker:CreateTexture(nil, "ARTWORK");
    marker.fillMask = marker:CreateMaskTexture();
    marker.fill:AddMaskTexture(marker.fillMask);
    marker.outline:SetBlendMode("BLEND");
    marker.fill:SetBlendMode("BLEND");
    marker:EnableMouse(false);
    return marker;
end

function renderer.ConfigureMarker(marker, shape, color, alpha, width, height, borderThickness)
    local texture = markerTextureByShape[renderer.NormalizeShape(shape)];
    local fillWidth = math.max(0, width - ( 2 * borderThickness ));
    local fillHeight = math.max(0, height - ( 2 * borderThickness ));

    marker:SetSize(width, height);

    marker.outline:SetTexture(texture);
    marker.outline:SetVertexColor(0, 0, 0, alpha);
    marker.outline:ClearAllPoints();
    marker.outline:SetAllPoints(marker);
    marker.outline:Show();

    marker.fill:SetColorTexture(color.r, color.g, color.b, alpha);
    marker.fill:ClearAllPoints();
    marker.fill:SetPoint("CENTER", marker, "CENTER", 0, 0);
    marker.fill:SetSize(fillWidth, fillHeight);
    marker.fill:Show();

    marker.fillMask:SetTexture(texture, "CLAMP", "CLAMP");
    marker.fillMask:ClearAllPoints();
    marker.fillMask:SetAllPoints(marker.fill);
    marker.fillMask:Show();

    marker:SetAlpha(1);
    marker:Show();
end
