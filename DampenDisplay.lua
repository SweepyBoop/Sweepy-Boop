-- Show dampen %
local dampeningFrame = CreateFrame('Frame', nil , UIParent)
dampeningFrame:SetSize(200, 12)
dampeningFrame:SetPoint('TOP', UIWidgetTopCenterContainerFrame, 'BOTTOM', 0, -2)
dampeningFrame.text = dampeningFrame:CreateFontString(nil, 'BACKGROUND')
dampeningFrame.text:SetFontObject(GameFontNormalSmall)
dampeningFrame.text:SetAllPoints()
dampeningFrame.timeSinceLastUpdate = 0
local updateInterval = 5
local dampeningText = GetSpellInfo(110310)
dampeningFrame:SetScript('OnUpdate', function(self, elapsed)
    self.timeSinceLastUpdate = self.timeSinceLastUpdate + elapsed

    if self.timeSinceLastUpdate > updateInterval then
        self.text:SetText(dampeningText..': '..C_Commentator.GetDampeningPercent()..'%')
        self.timeSinceLastUpdate = 0
    end
end)

local function ShowDampening(self, event)
    local _, instanceType = IsInInstance()
    if instanceType == "arena" then
        dampeningFrame:Show()
    else
        dampeningFrame:Hide()
    end
end
local dampen = CreateFrame('Frame', 'showDampening')
dampen:RegisterEvent("PLAYER_ENTERING_WORLD")
dampen:SetScript('OnEvent', ShowDampening)