local _, addon = ...;

local unitToFrame = {
    player = PlayerFrame,
    target = TargetFrame,
    focus = FocusFrame
};

local function UpdateCombatIndicator(frame, unit)
end

local function UpdateAllIndicators(frame, unit)
end

local frame = CreateFrame("Frame");
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
            UpdateAllIndicators(frame, unit);
        end
    end
end);
frame:Hide(); -- When hidden it won't process events
