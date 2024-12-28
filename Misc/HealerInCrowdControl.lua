local _, addon = ...;

local iconSize = 40;

local frame;
local isInTest = false;

local animationScale = 1.07;
local animationDuration = 0.5;

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

local function EnsureIconFrame()
    if ( not frame ) then
        frame = CreateFrame("Frame");
        frame:SetMouseClickEnabled(false);
        frame:SetFrameStrata("HIGH");
        frame:SetSize(iconSize, iconSize);
        
        frame.icon = frame:CreateTexture(nil, "BORDER");
        frame.icon:SetSize(iconSize, iconSize);
        frame.icon:SetAllPoints(frame);

        frame.mask = frame:CreateMaskTexture();
        frame.mask:SetTexture("Interface/Masks/CircleMaskScalable");
        frame.mask:SetSize(iconSize, iconSize);
        frame.mask:SetAllPoints(frame.icon);
        frame.icon:AddMaskTexture(frame.mask);

        frame.border = frame:CreateTexture(nil, "OVERLAY");
        frame.border:SetAtlas("Azerite-Trait-RingGlow");
        frame.border:SetBlendMode("ADD");
        frame.border:SetDesaturated(true);
        frame.border:SetSize(iconSize * 1.25, iconSize * 1.25);
        frame.border:SetPoint("CENTER", frame, "CENTER");
        frame.border:SetVertexColor(128, 0, 128); -- Purple

        frame.animation = SetupAnimation(frame);
    end

    if ( not frame.lastModified ) or ( frame.lastModified ~= SweepyBoop.db.profile.misc.lastModified ) then
        local config = SweepyBoop.db.profile.misc;
        frame:SetScale(config.healerInCrowdControlSize / iconSize);
        frame:SetPoint("CENTER", UIParent, "CENTER", config.healerInCrowdControlOffsetX, config.healerInCrowdControlOffsetY);

        frame.lastModified = SweepyBoop.db.profile.misc.lastModified;
    end
end

local function ShowIcon(iconID, duration)
    EnsureIconFrame();
    frame.icon:SetTexture(iconID);
    frame:Show();
    frame.animation:Play();
end

local function HideIcon()
    frame.animation:Stop();
    frame:Hide();
    isInTest = false;
end

function SweepyBoop:TestHealerInCrowdControl()
    ShowIcon(addon.ICON_PATH("spell_nature_polymorph"), 60);
    isInTest = true;
end

function SweepyBoop:HideTestHealerInCrowdControl()
    HideIcon();
end
