local _, addon = ...;

local iconSize = addon.DEFAULT_ICON_SIZE;

local containerFrame;
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

local function HideIcon(frame)
    if ( not frame ) then return end

    frame.animation:Stop();
    addon.HideOverlayGlow(frame);
    frame.text:Hide(); -- This is parented to UIParent to not scale with the animation
    frame:Hide();
end

local function CreateContainerFrame()
    local frame = CreateFrame("Frame");
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
    -- frame.cooldown:SetIgnoreParentScale(true); -- the cooldown is still scaling with the animation
    frame.cooldown:SetScript("OnCooldownDone", function (self)
        local parent = self:GetParent();
        if parent:IsShown() then
            HideIcon(parent);
        end
    end)

    frame.text = UIParent:CreateFontString(nil, "OVERLAY", "GameTooltipText");
    frame.text:SetPoint("TOP", frame, "BOTTOM", 0, -5);
    frame.text:SetText("Healer in CC!");
    frame.text:SetTextScale(2);
    frame.text:SetTextColor(255, 0, 0);

    frame.spellActivationAlert = CreateFrame("Frame", nil, frame, "ActionBarButtonSpellActivationAlert");
    frame.spellActivationAlert:SetSize(iconSize * 1.4, iconSize * 1.4);
    frame.spellActivationAlert:SetPoint("CENTER", frame, "CENTER");
    frame.spellActivationAlert:Hide();

    frame.animation = SetupAnimation(frame);
    
    return frame;
end

local function ShowIcon(iconID, startTime, duration)
    containerFrame = containerFrame or CreateContainerFrame();

    if ( not containerFrame.lastModified ) or ( containerFrame.lastModified ~= SweepyBoop.db.profile.misc.lastModified ) then
        local config = SweepyBoop.db.profile.misc;
        local scale = config.healerInCrowdControlSize / iconSize;
        containerFrame:SetScale(scale);
        containerFrame:SetPoint("CENTER", UIParent, "CENTER", config.healerInCrowdControlOffsetX / scale, config.healerInCrowdControlOffsetY / scale);

        containerFrame.lastModified = SweepyBoop.db.profile.misc.lastModified;
    end

    containerFrame.icon:SetTexture(iconID);
    if duration then
        containerFrame.cooldown:SetCooldown(startTime, duration);
        containerFrame.cooldown:Show();
    else
        containerFrame.cooldown:SetCooldown(0, 0);
    end

    containerFrame:Show();
    containerFrame.text:Show();
    addon.ShowOverlayGlow(containerFrame);
    containerFrame.animation:Play();
end

function SweepyBoop:TestHealerInCrowdControl()
    if IsInInstance() then
        print("Cannot run textest mode inside an instance");
        return;
    end

    ShowIcon(addon.ICON_PATH("spell_nature_polymorph"), GetTime(), 15);
    isInTest = true;
end

function SweepyBoop:HideTestHealerInCrowdControl()
    HideIcon(containerFrame);
end

local updateFrame = CreateFrame("Frame"); -- When a frame is hidden it might not receive event, so we create a frame to catch events
updateFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
updateFrame:RegisterEvent(addon.UNIT_AURA);
updateFrame:SetScript("OnEvent", function (self, event, unitTarget)
    if ( not SweepyBoop.db.profile.misc.healerInCrowdControl ) then
        HideIcon();
        return;
    end

    if ( not IsActiveBattlefieldArena() ) and ( not isInTest ) and ( not addon.TEST_MODE ) then
        HideIcon();
        return;
    end

    if ( event == UNIT_AURA ) then
        local auraFound, startTime, duration;
        local isHealer = ( UnitGroupRolesAssigned(unitTarget) == "HEALER" ) or ( addon.TEST_MODE and unitTarget == "PLAYER" );
        if isHealer then
            for i = 1, 40 do
                local auraData = C_UnitAuras.GetAuraDataByIndex(i);
                if auraData and auraData.spellId and addon.DRList[auraData.spellId] then
                    local category = addon.DRList[auraData.spellId];

                end
            end
        end
    end
end)
