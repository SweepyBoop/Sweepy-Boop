-- Combat indicator
local targetCombatFrame = CreateFrame('Frame', nil , TargetFrame);
targetCombatFrame:SetPoint('LEFT', TargetFrame, 'RIGHT', -15, 0);
targetCombatFrame:SetSize(28, 28);
targetCombatFrame.icon = targetCombatFrame:CreateTexture(nil, 'BORDER');
targetCombatFrame.icon:SetAllPoints();
targetCombatFrame.icon:SetTexture([[Interface\Icons\ABILITY_DUALWIELD]]); -- https://www.wowhead.com/icons
targetCombatFrame:Hide();

local combatFrame = CreateFrame('Frame', nil , UIParent);
combatFrame.timeSinceLastUpdate = 0;
local combatInterval = 0.1;
local function combatUpdate(self, elapsed)
    self.timeSinceLastUpdate = self.timeSinceLastUpdate + elapsed;

    if self.timeSinceLastUpdate > combatInterval then
        targetCombatFrame:SetShown(UnitAffectingCombat('target'));
        self.timeSinceLastUpdate = 0;
    end
end

combatFrame:SetScript('OnUpdate', combatUpdate);