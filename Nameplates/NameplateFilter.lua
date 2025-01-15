local _, addon = ...;

local animationScale = 1.05;
local animationDuration = 0.5;
local iconSize = 30;
local offsetMultiplier = 0.41;

local function SetupAnimation(frameWithAnimations)
    local animationGroup = frameWithAnimations:CreateAnimationGroup();

    local grow = animationGroup:CreateAnimation("Scale");
    grow:SetOrder(1);
    grow:SetScale(animationScale, animationScale);
    grow:SetDuration(animationDuration);

    local shrink = animationGroup:CreateAnimation("Scale");
    shrink:SetOrder(2);
    shrink:SetScale(1 / animationScale, 1 / animationScale);
    shrink:SetDuration(animationDuration);

    animationGroup:SetLooping("REPEAT");

    return animationGroup;
end

local function EnsureNpcHighlight(nameplate)
    if ( not nameplate.npcHighlight ) then
        nameplate.npcHighlight = CreateFrame("Frame", nil, nameplate);
        nameplate.npcHighlight:SetMouseClickEnabled(false);
        nameplate.npcHighlight:SetSize(iconSize, iconSize);
        nameplate.npcHighlight:SetFrameStrata("HIGH");
        nameplate.npcHighlight:SetPoint("BOTTOM", nameplate, "TOP");

        nameplate.npcHighlight.customIcon = nameplate.npcHighlight:CreateTexture(nil, "OVERLAY");
        nameplate.npcHighlight.customIcon:SetAllPoints(nameplate.npcHighlight);

        local widthOffset = iconSize * offsetMultiplier;
        local heightOffset = iconSize * offsetMultiplier;
        nameplate.npcHighlight.glowTexture = nameplate.npcHighlight:CreateTexture(nil, "OVERLAY");
        nameplate.npcHighlight.glowTexture:SetBlendMode("ADD");
        nameplate.npcHighlight.glowTexture:SetAtlas("clickcast-highlight-spellbook");
        nameplate.npcHighlight.glowTexture:SetDesaturated(true);
        nameplate.npcHighlight.glowTexture:SetPoint('TOPLEFT', nameplate.npcHighlight, 'TOPLEFT', -widthOffset, heightOffset);
        nameplate.npcHighlight.glowTexture:SetPoint('BOTTOMRIGHT', nameplate.npcHighlight, 'BOTTOMRIGHT', widthOffset, -heightOffset);
        nameplate.npcHighlight.glowTexture:SetVertexColor(128, 0, 128); -- Purple

        nameplate.npcHighlight.animationGroup = SetupAnimation(nameplate.npcHighlight);

        nameplate.npcHighlight:Hide();
    end

    if ( nameplate.npcHighlight.lastModified ~= SweepyBoop.db.profile.nameplatesEnemy.lastModified ) then
        nameplate.npcHighlight:SetScale(SweepyBoop.db.profile.nameplatesEnemy.highlightScale / 100);
        nameplate.npcHighlight.lastModified = SweepyBoop.db.profile.nameplatesEnemy.lastModified;
    end

    return nameplate.npcHighlight;
end

addon.ShowNpcHighlight = function(nameplate)
    local highlight = nameplate.npcHighlight;

    if highlight then
        highlight.animationGroup:Play();
        highlight.glowTexture:Show();
        highlight.customIcon:Show();
        highlight:Show();
    end
end

addon.HideNpcHighlight = function(nameplate)
    local highlight = nameplate.npcHighlight;
    if highlight then
        highlight.animationGroup:Stop();
        highlight.glowTexture:Hide();
        highlight.customIcon:Hide();
        highlight:Hide();
    end
end

addon.UpdateNpcHighlight = function(nameplate, frame)
    local highlight = EnsureNpcHighlight(nameplate);

    local guid = UnitGUID(frame.unit);
    if ( highlight.currentGuid ~= guid ) then
        local npcID = select(6, strsplit("-", guid));
        highlight.customIcon:SetTexture(addon.iconTexture[npcID]); -- nil if no texture found
        highlight.currentGuid = guid;
    end
end
