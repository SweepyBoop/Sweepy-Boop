local _, addon = ...;

-- Sizes are fixed, players can customize by scale
local iconSize = 40;
local arrowSize = 67;
local highlightSize = 55;
local classicBorderSize = 64;

addon.CreateClassOrSpecIcon = function (nameplate, point, relativePoint, isFriendly)
    local classIconFrame = CreateFrame("Frame", nil, nameplate);
    classIconFrame:SetMouseClickEnabled(false);
    -- Force alpha 1 and ignore parent alpha, so that the nameplate is always super visible
    classIconFrame:SetAlpha(1);
    classIconFrame:SetIgnoreParentAlpha(true);
    classIconFrame:SetSize(iconSize, iconSize);
    classIconFrame:SetFrameStrata("HIGH");
    classIconFrame:SetPoint(point, nameplate, relativePoint);

    classIconFrame.icon = classIconFrame:CreateTexture(nil, "BORDER");
    classIconFrame.icon:SetSize(iconSize, iconSize);
    classIconFrame.icon:SetAllPoints(classIconFrame);

    classIconFrame.mask = classIconFrame:CreateMaskTexture();
    classIconFrame.mask:SetTexture("Interface/Masks/CircleMaskScalable");
    classIconFrame.mask:SetSize(iconSize, iconSize);
    classIconFrame.mask:SetAllPoints(classIconFrame.icon);
    classIconFrame.icon:AddMaskTexture(classIconFrame.mask);

    classIconFrame.border = classIconFrame:CreateTexture(nil, "OVERLAY");
    classIconFrame.border:SetAtlas("charactercreate-ring-metallight"); -- "ui-frame-genericplayerchoice-portrait-border"
    classIconFrame.border:SetSize(classicBorderSize, classicBorderSize);
    classIconFrame.border:SetPoint("CENTER", classIconFrame); -- SetAllPoints will not work

    if isFriendly then
        classIconFrame.targetHighlight = classIconFrame:CreateTexture(nil, "OVERLAY");
        classIconFrame.targetHighlight:Hide();
        classIconFrame.targetHighlight:SetDesaturated(false);
        classIconFrame.targetHighlight:SetAtlas("charactercreate-ring-select"); -- Consider using UI-LFG-RoleIcon-Incentive for a stronger effect
        classIconFrame.targetHighlight:SetSize(highlightSize, highlightSize);
        classIconFrame.targetHighlight:SetPoint("CENTER", classIconFrame); -- SetAllPoints will not work
        classIconFrame.targetHighlight:SetDrawLayer("OVERLAY", 1);
        classIconFrame.targetHighlight:SetVertexColor(1,0.88,0);

        classIconFrame.name = classIconFrame:CreateFontString(nil, "OVERLAY");
        classIconFrame.name:SetFontObject("GameFontHighlightOutline");
        classIconFrame.name:SetText("");
        classIconFrame.name:SetPoint("TOP", classIconFrame.icon, "BOTTOM");
    else
        classIconFrame.border:SetVertexColor(255, 0, 0); -- Red border for hostile
        classIconFrame.border:Hide(); -- Hide initially until an actual icon is set
    end

    return classIconFrame;
end

addon.CreateClassColorArrowFrame = function (nameplate)
    local classIconFrame = CreateFrame("Frame", nil, nameplate);
    classIconFrame:SetMouseClickEnabled(false);
    -- Force alpha 1 and ignore parent alpha, so that the nameplate is always super visible
    classIconFrame:SetAlpha(1);
    classIconFrame:SetIgnoreParentAlpha(true);
    classIconFrame:SetSize(arrowSize, arrowSize);
    classIconFrame:SetFrameStrata("HIGH");
    classIconFrame:SetPoint("CENTER", nameplate, "CENTER");

    classIconFrame.icon = classIconFrame:CreateTexture(nil, "BORDER");
    classIconFrame.icon:SetSize(arrowSize, arrowSize);
    classIconFrame.icon:SetDesaturated(false);
    classIconFrame.icon:SetAtlas("covenantsanctum-renown-doublearrow-disabled"); -- original size is 67 * 48, distort to 67 * 67
    classIconFrame.icon:SetAllPoints(classIconFrame);
    classIconFrame.icon:SetRotation(math.pi / 2); -- Counter-clockwise by 90 degrees

    classIconFrame.targetHighlight = classIconFrame:CreateTexture(nil, "OVERLAY");
    classIconFrame.targetHighlight:SetAtlas("communities-guildbanner-border"); -- Originally Capacitance-General-WorkOrderBorder which is rectangle
    classIconFrame.targetHighlight:SetVertexColor(1, 0.88, 0);
    classIconFrame.targetHighlight:SetDesaturated(false);
    classIconFrame.targetHighlight:SetSize(arrowSize / 1.25, arrowSize);
    classIconFrame.targetHighlight:SetPoint("CENTER", classIconFrame, "CENTER", 0, -5);
    classIconFrame.targetHighlight:Hide();

    classIconFrame.name = classIconFrame:CreateFontString(nil, "OVERLAY");
    classIconFrame.name:SetFontObject("GameFontHighlightOutline");
    classIconFrame.name:SetText("");
    classIconFrame.name:SetPoint("TOP", classIconFrame.icon, "BOTTOM");

    return classIconFrame;
end
