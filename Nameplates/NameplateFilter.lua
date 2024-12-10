local _, addon = ...;

local function SetupAnimation(frameWithAnimations)
    local animationGroup = frameWithAnimations:CreateAnimationGroup();

    local grow = animationGroup:CreateAnimation("Scale");
    grow:SetOrder(1);
    grow:SetScale(1.07, 1.07);
    grow:SetDuration(0.5);

    local shrink = animationGroup:CreateAnimation("Scale");
    shrink:SetOrder(2);
    shrink:SetScale(1 / 1.07, 1 / 1.07);
    shrink:SetDuration(0.5);

    animationGroup:SetLooping("REPEAT");

    return animationGroup;
end

local function EnsureNpcHighlight(frame, scale)
    if ( not frame.npcHighlight ) then
        local size = 30;

        frame.npcHighlight = CreateFrame("Frame", nil, frame);
        frame.npcHighlight:SetSize(size, size);
        frame.npcHighlight:SetScale(1);
        frame.npcHighlight:SetFrameStrata("HIGH");
        frame.npcHighlight:SetPoint("BOTTOM", frame, "TOP");

        frame.npcHighlight.customIcon = frame.npcHighlight:CreateTexture(nil, "OVERLAY");
        frame.npcHighlight.customIcon:SetAllPoints(frame.npcHighlight);

        local offsetMultiplier = 0.41;
        local widthOffset = size * offsetMultiplier;
        local heightOffset = size * offsetMultiplier;
        frame.npcHighlight.glowTexture = frame.npcHighlight:CreateTexture(nil, "OVERLAY");
        frame.npcHighlight.glowTexture:SetBlendMode("ADD");
        frame.npcHighlight.glowTexture:SetAtlas("clickcast-highlight-spellbook");
        frame.npcHighlight.glowTexture:SetDesaturated(true);
        frame.npcHighlight.glowTexture:SetPoint('TOPLEFT', frame.npcHighlight, 'TOPLEFT', -widthOffset, heightOffset);
        frame.npcHighlight.glowTexture:SetPoint('BOTTOMRIGHT', frame.npcHighlight, 'BOTTOMRIGHT', widthOffset, -heightOffset);
        frame.npcHighlight.glowTexture:SetVertexColor(128, 0, 128); -- Purple

        frame.npcHighlight.animationGroup = SetupAnimation(frame.npcHighlight);
    end

    frame.npcHighlight:SetScale(scale);

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
    local highlight = EnsureNpcHighlight(frame, SweepyBoop.db.profile.nameplatesEnemy.highlightScale / 100);
    local guid = UnitGUID(frame.unit);
    local npcID = select(6, strsplit("-", guid));
    highlight.customIcon:SetTexture(addon.iconTexture[npcID]);
    highlight:Show();
    highlight.customIcon:Show();
    highlight.glowTexture:Show();
    highlight.animationGroup:Play();
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
