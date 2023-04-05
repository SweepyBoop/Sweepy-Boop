local _, NS = ...;

local CreateFrame = CreateFrame;
local UIParent = UIParent;
local UIWidgetTopCenterContainerFrame = UIWidgetTopCenterContainerFrame;
local GameFontNormalSmall = GameFontNormalSmall;
local GetSpellInfo = GetSpellInfo;
local C_Commentator = C_Commentator;
local IsInInstance = IsInInstance;

-- Show dampen %
local frame = CreateFrame('Frame', nil , UIParent);
frame:SetSize(200, 12);
frame:SetPoint('TOP', UIWidgetTopCenterContainerFrame, 'BOTTOM', 0, -5);
frame.text = frame:CreateFontString(nil, 'BACKGROUND');
frame.text:SetFontObject(GameFontNormalSmall);
frame.text:SetAllPoints();
frame.timeSinceLastUpdate = 0;
local updateInterval = 5;
local dampeningText = GetSpellInfo(110310);
frame:SetScript('OnUpdate', function(self, elapsed)
    self.timeSinceLastUpdate = self.timeSinceLastUpdate + elapsed;

    if self.timeSinceLastUpdate > updateInterval then
        self.text:SetText(dampeningText..': ' .. C_Commentator.GetDampeningPercent() .. '%');
        self.timeSinceLastUpdate = 0;
    end
end)

local function ShowDampening(self, event)
    local _, instanceType = IsInInstance();
    if instanceType == "arena" then
        frame:Show();
    else
        frame:Hide();
    end
end
local container = CreateFrame('Frame', 'showDampening');
container:RegisterEvent("PLAYER_ENTERING_WORLD");
container:SetScript('OnEvent', ShowDampening);
