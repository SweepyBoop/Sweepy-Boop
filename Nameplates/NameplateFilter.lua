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

local function EnsureNpcHighlight(frame)
    if ( not frame.npcHighlight ) then
        frame.npcHighlight = CreateFrame("Frame", nil, frame);
        frame.npcHighlight:SetMouseClickEnabled(false);
        frame.npcHighlight:SetSize(iconSize, iconSize);
        frame.npcHighlight:SetFrameStrata("HIGH");
        frame.npcHighlight:SetPoint("BOTTOM", frame, "TOP");

        frame.npcHighlight.customIcon = frame.npcHighlight:CreateTexture(nil, "OVERLAY");
        frame.npcHighlight.customIcon:SetAllPoints(frame.npcHighlight);

        local widthOffset = iconSize * offsetMultiplier;
        local heightOffset = iconSize * offsetMultiplier;
        frame.npcHighlight.glowTexture = frame.npcHighlight:CreateTexture(nil, "OVERLAY");
        frame.npcHighlight.glowTexture:SetBlendMode("ADD");
        frame.npcHighlight.glowTexture:SetAtlas("clickcast-highlight-spellbook");
        frame.npcHighlight.glowTexture:SetDesaturated(true);
        frame.npcHighlight.glowTexture:SetPoint('TOPLEFT', frame.npcHighlight, 'TOPLEFT', -widthOffset, heightOffset);
        frame.npcHighlight.glowTexture:SetPoint('BOTTOMRIGHT', frame.npcHighlight, 'BOTTOMRIGHT', widthOffset, -heightOffset);
        frame.npcHighlight.glowTexture:SetVertexColor(128, 0, 128); -- Purple

        frame.npcHighlight.animationGroup = SetupAnimation(frame.npcHighlight);

        frame.npcHighlight:Hide();
    end

    local config = SweepyBoop.db.profile.nameplatesEnemy;
    if ( frame.npcHighlight.lastModified ~= config.lastModified ) then
        frame.npcHighlight:SetScale(config.highlightScale / 100);
        frame.npcHighlight.lastModified = config.lastModified;
    end

    return frame.npcHighlight;
end

addon.UpdateNpcHighlight = function(frame)
    -- Parented to UnitFrame to inherit the visibility
    local highlight = EnsureNpcHighlight(frame);
    local unitGUID = UnitGUID(frame.unit);
    if ( highlight.currentGuid ~= unitGUID ) then
        local npcID = select(6, strsplit("-", unitGUID));
        highlight.customIcon:SetTexture(addon.iconTexture[npcID]); -- nil if no texture found
        highlight.currentGuid = unitGUID;
    end
end

addon.ShowNpcHighlight = function(frame)
    addon.UpdateNpcHighlight(frame);
    local highlight = frame.npcHighlight;

    if highlight then
        highlight.animationGroup:Play();
        highlight.glowTexture:Show();
        highlight.customIcon:Show();
        highlight:Show();
    end
end

addon.HideNpcHighlight = function(frame)
    local highlight = frame.npcHighlight;
    if highlight then
        highlight.animationGroup:Stop();
        highlight.glowTexture:Hide();
        highlight.customIcon:Hide();
        highlight:Hide();
    end
end
