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
    end

    if ( frame.npcHighlight.lastModified ~= SweepyBoop.db.profile.nameplatesEnemy.lastModified ) then
        frame.npcHighlight:SetScale(SweepyBoop.db.profile.nameplatesEnemy.highlightScale / 100);
        frame.npcHighlight.lastModified = SweepyBoop.db.profile.nameplatesEnemy.lastModified;
    end

    return frame.npcHighlight;
end

local function ShouldShowNpcHighlight(unitId)
    if ( not UnitIsPlayer(unitId) ) then
        local guid = UnitGUID(unitId);
        local npcID = select(6, strsplit("-", guid));
        local option = SweepyBoop.db.profile.nameplatesEnemy.filterList[tostring(npcID)];
        if ( option == addon.NpcOption.Highlight ) then
            return addon.UnitIsHostile(unitId);
        end
    end
end

local function ShowNpcHighlight(frame)
    local highlight = EnsureNpcHighlight(frame);

    local guid = UnitGUID(frame.unit);
    if ( highlight.currentGuid ~= guid ) then
        local npcID = select(6, strsplit("-", guid));
        highlight.customIcon:SetTexture(addon.iconTexture[npcID]);
        highlight.currentGuid = guid;
    end

    if ( not highlight:IsShown() ) then
        -- Seems animation is not playing
        highlight:Show();
        highlight.customIcon:Show();
        highlight.glowTexture:Show();
    end

    if ( not highlight.animationGroup:IsPlaying() ) then
        highlight.animationGroup:Play();
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

addon.UpdateNpcHighlight = function(frame)
    if ( not SweepyBoop.db.profile.nameplatesEnemy.filterEnabled ) then
        addon.HideNpcHighlight(frame);
        return;
    end

    if ShouldShowNpcHighlight(frame.unit) then
        ShowNpcHighlight(frame);
    else
        addon.HideNpcHighlight(frame);
    end
end
