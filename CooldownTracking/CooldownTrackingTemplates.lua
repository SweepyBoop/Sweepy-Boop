local _, NS = ...;

local CreateFrame = CreateFrame;
local UIParent = UIParent;
local GetTime = GetTime;

NS.CreateCooldownTrackingIcon = function (spellID, size)
    local frame = CreateFrame("Button", nil, UIParent, "CooldownTrackingButtonTemplate");
    frame:Hide();

    frame.spellID = spellID;
    frame.spell = NS.cooldownSpells[spellID];
    frame.priority = frame.spell.priority;

    frame.icon:SetTexture(select(3, GetSpellInfo(spellID)));
    frame.icon:SetAllPoints();

    frame.duration:SetScript("OnCooldownDone", function(self)
        local icon = self:GetParent();
        local group = icon:GetParent();
        NS.IconGroup_Remove(group, icon);
    end);

    return frame;
end

NS.StartCooldownTrackingIcon = function (icon)
    local spell = icon.spell;
    local now = GetTime();

    -- Check if using second charge
    if icon:IsShown() and spell.charges and ( now >= icon.cooldown.chargeExpire ) then
        icon.Count:SetText("");
        icon.cooldown.chargeExpire = now + spell.cooldown;
    else
        -- Use default charge
        icon.cooldown.start = now;
        icon.cooldown.duration = spell.cooldown;
        icon.cooldown:SetCooldown(icon.cooldown.start, icon.cooldown.duration);
        if spell.charges then
            icon.Count:SetText("#");
        end
    end

    NS.IconGroup_Insert(icon:GetParent(), icon);
end