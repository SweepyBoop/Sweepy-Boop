local _, addon = ...;

local iconSize = 36;

local unitToFrame = {
    player = PlayerFrame,
    target = TargetFrame,
    focus = FocusFrame
};

local anchors;
if addon.PROJECT_MAINLINE then
    anchors = {
        player = { point = "RIGHT", relativeTo = PlayerFrame.PlayerFrameContainer.PlayerPortrait, relativePoint = "LEFT" },
        target = { point = "LEFT", relativeTo = TargetFrame.TargetFrameContainer.Portrait, relativePoint = "RIGHT" },
        focus = { point = "LEFT", relativeTo = FocusFrame.TargetFrameContainer.Portrait, relativePoint = "RIGHT" },
    };
else

end

local function UpdateCombatIndicator(frame, unit)
    if ( not frame.combatIndicator ) then
        frame.combatIndicator = CreateFrame("Frame", nil, frame);
        frame.combatIndicator:SetMouseClickEnabled(false);
        frame.combatIndicator:SetFrameStrata("HIGH");
        frame.combatIndicator:SetSize(iconSize, iconSize);
        frame.combatIndicator:SetPoint(anchors[unit].point, anchors[unit].relativeTo, anchors[unit].relativePoint);

        frame.combatIndicator.icon = frame.combatIndicator:CreateTexture(nil, "OVERLAY");
        frame.combatIndicator.icon:SetAtlas("countdown-swords");
        frame.combatIndicator.icon:SetAllPoints();
    end

    frame.combatIndicator:SetShown(UnitAffectingCombat(unit));
end

local function HideAll()
    for _, frame in pairs(unitToFrame) do
        if ( frame.combatIndicator ) then
            frame.combatIndicator:Hide();
        end
    end
end

local eventFrame = CreateFrame("Frame");
eventFrame:Hide(); -- When hidden it won't process events
eventFrame:RegisterUnitEvent(addon.UNIT_FLAGS, "player", "target", "focus");
eventFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
eventFrame:RegisterEvent(addon.PLAYER_TARGET_CHANGED);
eventFrame:RegisterEvent(addon.PLAYER_FOCUS_CHANGED);
eventFrame:SetScript("OnEvent", function(_, event, unit)
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

function SweepyBoop:SetupCombatIndicator()
    if SweepyBoop.db.profile.misc.combatIndicator then
        for unit, frame in pairs(unitToFrame) do
            UpdateCombatIndicator(frame, unit);
        end
        eventFrame:Show();
    else
        eventFrame:Hide();
        HideAll();
    end
end
