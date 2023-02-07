local _, NS = ...;

local CreateFrame = CreateFrame;
local UIParent = UIParent;

NS.CreateCooldownTrackingIcon = function (spellID, size)
    local frame = CreateFrame("Button", nil, UIParent, "CooldownTrackingButtonTemplate");
    frame:Hide();

    frame.spellID = spellID;
    frame.spell = NS.cooldownSpells[spellID];
    frame.priority = frame.spell.priority;

    frame.icon:SetTexture(select(3, GetSpellInfo(spellID)));
    frame.icon:SetAllPoints();

    
end