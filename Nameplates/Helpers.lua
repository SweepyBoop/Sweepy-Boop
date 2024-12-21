local _, addon = ...;

addon.selectedBorder = "charactercreate-ring-select";
addon.unselectedBorder = "charactercreate-ring-metallight";
addon.healerIconID = "interface/lfgframe/uilfgprompts";
addon.petIconID = "interface/icons/ability_hunter_mendpet";
addon.classIconID = "Interface/GLUES/CHARACTERCREATE/UI-CHARACTERCREATE-CLASSES";
addon.flagCarrierHordeIconID = "interface/icons/inv_bannerpvp_01";
addon.flagCarrierAllianceIconID = "interface/icons/inv_bannerpvp_02";

addon.healerIconCoords = {0.005, 0.116, 0.76, 0.87};

-- Sizes are fixed, players can customize by scale
local iconSize = 40;
local highlightSize = 60;

addon.CreateClassOrSpecIcon = function (nameplate, point, relativePoint)
    local classIconFrame = CreateFrame("Frame", nil, nameplate);
    classIconFrame:SetMouseClickEnabled(false);
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

    classIconFrame.targetHighlight = classIconFrame:CreateTexture(nil, "OVERLAY");
    classIconFrame.targetHighlight:SetDesaturated(false);
    classIconFrame.targetHighlight:SetAtlas("charactercreate-ring-select");
    classIconFrame.targetHighlight:SetSize(highlightSize, highlightSize);
    classIconFrame.targetHighlight:SetAllPoints(classIconFrame.icon);
    classIconFrame.targetHighlight:SetDrawLayer("OVERLAY", 1);
    classIconFrame.targetHighlight:SetVertexColor(1,0.88,0);

    return classIconFrame;
end