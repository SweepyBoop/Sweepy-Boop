local _, addon = ...;

-- Sizes are fixed, players can customize by scale
local iconSize = 40;
local arrowSize = 64;
local highlightSize = 55;

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
    classIconFrame.border:SetAtlas("ui-frame-genericplayerchoice-portrait-border");
    classIconFrame.border:SetAllPoints(classIconFrame);

    if isFriendly then
        classIconFrame.targetHighlight = classIconFrame:CreateTexture(nil, "OVERLAY");
        classIconFrame.targetHighlight:Hide();
        classIconFrame.targetHighlight:SetDesaturated(false);
        classIconFrame.targetHighlight:SetAtlas("charactercreate-ring-select");
        classIconFrame.targetHighlight:SetSize(highlightSize, highlightSize);
        classIconFrame.targetHighlight:SetPoint("CENTER", classIconFrame); -- SetAllPoints will not work
        classIconFrame.targetHighlight:SetDrawLayer("OVERLAY", 1);
        classIconFrame.targetHighlight:SetVertexColor(1,0.88,0);
    else
        classIconFrame.border:SetVertexColor(255, 0, 0); -- Red border for hostile
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
    classIconFrame:SetPoint("CENTER", nameplate, "TOP");

    classIconFrame.icon = classIconFrame:CreateTexture(nil, "BORDER");
    classIconFrame.icon:SetSize(arrowSize, arrowSize);
    classIconFrame.icon:SetDesaturated(false);
    classIconFrame.icon:SetAtlas("covenantsanctum-renown-doublearrow-disabled");
    classIconFrame.icon:SetAllPoints(classIconFrame);
    classIconFrame.icon:SetRotation(math.pi / 2); -- Counter-clockwise by 90 degrees

    return classIconFrame;
end
