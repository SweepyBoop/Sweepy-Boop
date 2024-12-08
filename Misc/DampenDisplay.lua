local _, addon = ...;

local frame = CreateFrame('Frame', nil , UIParent, "UIWidgetTemplateIconAndText");
local widgetSetInfo = C_UIWidgetManager.GetWidgetSetInfo(C_UIWidgetManager.GetTopCenterWidgetSetID());
frame:SetPoint(UIWidgetTopCenterContainerFrame.verticalAnchorPoint, UIWidgetTopCenterContainerFrame, UIWidgetTopCenterContainerFrame.verticalRelativePoint, 0, widgetSetInfo.verticalPadding);
frame.Text:SetParent(frame);
frame:SetWidth(200);
frame.Text:SetAllPoints();
frame.Text:SetJustifyH("CENTER");

local dampeningText = C_Spell.GetSpellInfo(110310).name; -- This doesn't change so set it as constant
local updateInterval = 1; -- We don't need to update on every UNIT_AURA, just update every 1 sec via keeping track of timeSinceLastUpdate

frame.timeSinceLastUpdate = 0;
frame:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end);

function frame:OnUpdate(elapsed)
    if ( not SweepyBoop.db.profile.showDampenPercentage ) then return end

    self.timeSinceLastUpdate = self.timeSinceLastUpdate + elapsed;

    if self.timeSinceLastUpdate > updateInterval then
        self.text:SetText(dampeningText..': ' .. C_Commentator.GetDampeningPercent() .. '%');
        self.timeSinceLastUpdate = 0;
    end
end

function frame:PLAYER_ENTERING_WORLD()
    if ( not SweepyBoop.db.profile.showDampenPercentage ) then
        self:Hide();
    end

    local _, instanceType = IsInInstance();
    if instanceType == "arena" then
        self:Show();
    else
        self:Hide();
    end
end
