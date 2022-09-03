-- Combat indicator
local targetCombatFrame = CreateFrame('Frame', nil , TargetFrame)
targetCombatFrame:SetPoint('BOTTOMLEFT', TargetFramePortrait, 'RIGHT', 0, 0)
targetCombatFrame:SetSize(28, 28)
targetCombatFrame.icon = targetCombatFrame:CreateTexture(nil, 'BORDER')
targetCombatFrame.icon:SetAllPoints()
targetCombatFrame.icon:SetTexture([[Interface\Icons\ABILITY_DUALWIELD]]) -- https://www.wowhead.com/icons
targetCombatFrame:Hide()

local focusCombatFrame = CreateFrame('Frame', nil , FocusFrame)
focusCombatFrame:SetPoint('BOTTOMLEFT', FocusFramePortrait, 'RIGHT', 0, 0)
focusCombatFrame:SetSize(28, 28)
focusCombatFrame.icon = focusCombatFrame:CreateTexture(nil, 'BORDER')
focusCombatFrame.icon:SetAllPoints()
focusCombatFrame.icon:SetTexture([[Interface\Icons\ABILITY_DUALWIELD]]) -- https://www.wowhead.com/icons
focusCombatFrame:Hide()

local combatFrame = CreateFrame('Frame', nil , UIParent)
combatFrame.timeSinceLastUpdate = 0
local combatInterval = 0.1
local function combatUpdate(self, elapsed)
    self.timeSinceLastUpdate = self.timeSinceLastUpdate + elapsed

    if self.timeSinceLastUpdate > combatInterval then
        targetCombatFrame:SetShown(UnitAffectingCombat('target'))
        focusCombatFrame:SetShown(UnitAffectingCombat('focus'))
        self.timeSinceLastUpdate = 0
    end
end

combatFrame:SetScript('OnUpdate', combatUpdate)