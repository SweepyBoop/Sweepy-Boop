local _, addon = ...;

local unitToFrame = {
    player = PlayerFrame,
    target = TargetFrame,
    focus = FocusFrame
};

local unitToPortrait;
if addon.PROJECT_MAINLINE then
    unitToPortrait = {
        player = PlayerFrame.PlayerFrameContainer.PlayerPortrait,
        target = TargetFrame.TargetFrameContainer.Portrait,
        focus = FocusFrame.TargetFrameContainer.Portrait,
    };
else
    unitToPortrait = {
        player = PlayerFrame.portraitOverlay,
        target = TargetFrame.portraitOverlay,
        focus = FocusFrame.portraitOverlay
    };
end

local anchorPoint = {
    player = "BOTTOMLEFT",
    target = "BOTTOMRIGHT",
    focus = "BOTTOMRIGHT",
};

local function UpdateCombatIndicator(frame, unit)
    if ( not frame.combatIndicator ) then
        frame.combatIndicator = CreateFrame("Frame", nil, frame);
        frame.combatIndicator:SetMouseClickEnabled(false);
        frame.combatIndicator:SetFrameStrata("HIGH");
        frame.combatIndicator:SetPoint(anchorPoint[unit], unitToPortrait[unit]);

        frame.combatIndicator.icon = frame.combatIndicator:CreateTexture(nil, "OVERLAY");
        frame.combatIndicator.icon:SetSize(32, 32);
        frame.combatIndicator.icon:SetAtlas("countdown-swords");
        frame.combatIndicator.icon:SetAllPoints();
    end

    frame.combatIndicator:Show();
end

local frame = CreateFrame("Frame");
--frame:Hide(); -- When hidden it won't process events
frame:RegisterUnitEvent(addon.UNIT_FLAGS, "player", "target", "focus");
frame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
frame:RegisterEvent(addon.PLAYER_TARGET_CHANGED);
frame:RegisterEvent(addon.PLAYER_FOCUS_CHANGED);
frame:SetScript("OnEvent", function(self, event, unit)
    if ( event == addon.UNIT_FLAGS ) then
        local frame = unitToFrame[unit];
        if ( frame ) then
            UpdateCombatIndicator(frame, unit);
        end
    else
        for unit, frame in pairs(unitToFrame) do
            UpdateCombatIndicator(frame, unit);
        end
    end
end);

