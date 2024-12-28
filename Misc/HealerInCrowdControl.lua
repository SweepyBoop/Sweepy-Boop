local _, addon = ...;

local iconSize = addon.DEFAULT_ICON_SIZE;

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

        frame.cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate");
        frame.cooldown:SetAllPoints();
        frame.cooldown:SetDrawEdge(false);
        frame.cooldown:SetDrawBling(false);
        frame.cooldown:SetReverse(true);
        frame.cooldown:SetHideCountdownNumbers(true);

        -- frame.mask = frame:CreateMaskTexture();
        -- frame.mask:SetTexture("Interface/Masks/CircleMaskScalable");
        -- frame.mask:SetSize(iconSize, iconSize);
        -- frame.mask:SetAllPoints(frame.icon);
        -- frame.icon:AddMaskTexture(frame.mask);

        -- frame.border = frame:CreateTexture(nil, "OVERLAY");
        -- frame.border:SetAtlas("Azerite-Trait-RingGlow");
        -- frame.border:SetBlendMode("ADD");
        -- frame.border:SetDesaturated(true);
        -- frame.border:SetSize(iconSize * 1.25, iconSize * 1.25);
        -- frame.border:SetPoint("CENTER", frame, "CENTER");
        -- frame.border:SetVertexColor(128, 0, 128); -- Purple

        frame.spellActivationAlert = CreateFrame("Frame", nil, frame, "ActionBarButtonSpellActivationAlert");
        frame.spellActivationAlert:SetSize(iconSize * 1.4, iconSize * 1.4);
        frame.spellActivationAlert:SetPoint("CENTER", frame, "CENTER");
        frame.spellActivationAlert:Hide();

        frame.animation = SetupAnimation(frame);
    end

    if ( not frame.lastModified ) or ( frame.lastModified ~= SweepyBoop.db.profile.misc.lastModified ) then
        local config = SweepyBoop.db.profile.misc;
        local scale = config.healerInCrowdControlSize / iconSize;
        frame:SetScale(scale);
        frame:SetPoint("CENTER", UIParent, "CENTER", config.healerInCrowdControlOffsetX / scale, config.healerInCrowdControlOffsetY / scale);

        frame.lastModified = SweepyBoop.db.profile.misc.lastModified;
    end
end

local function ShowIcon(iconID, startTime, duration)
    EnsureIconFrame();

    frame.icon:SetTexture(iconID);
    if duration then
        frame.cooldown:SetCooldown(startTime, duration);
        frame.cooldown:Show();
    else
        frame.cooldown:SetCooldown(0, 0);
    end

    frame:Show();
    addon.ShowOverlayGlow(frame);
    frame.animation:Play();
end

local function HideIcon()
    frame.animation:Stop();
    addon.HideOverlayGlow(frame);
    frame:Hide();
    isInTest = false;
end

function SweepyBoop:TestHealerInCrowdControl()
    ShowIcon(addon.ICON_PATH("spell_nature_polymorph"), GetTime(), 60);
    isInTest = true;
end

function SweepyBoop:HideTestHealerInCrowdControl()
    HideIcon();
end
