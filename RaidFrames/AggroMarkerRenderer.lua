local _, addon = ...;

-- Blizzard exposes each raid marker as an individual texture, so marker geometry
-- can use ordinary texture regions without depending on sprite-sheet layout.
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
    marker.outline:SetBlendMode("BLEND");
    marker.fill:SetBlendMode("BLEND");
    marker.outline:SetDesaturated(true);
    marker.fill:SetDesaturated(true);
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

    marker.fill:SetTexture(texture);
    marker.fill:SetVertexColor(color.r, color.g, color.b, alpha);
    marker.fill:ClearAllPoints();
    marker.fill:SetPoint("CENTER", marker, "CENTER", 0, 0);
    marker.fill:SetSize(fillWidth, fillHeight);
    marker.fill:Show();

    marker:SetAlpha(1);
    marker:Show();
end
