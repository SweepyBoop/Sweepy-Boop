local _, NS = ...;

local CreateFrame = CreateFrame;
local UIParent = UIParent;
local GetTime = GetTime;
local GetSpellInfo = GetSpellInfo;
local UnitIsUnit = UnitIsUnit;

local function StartAnimation(icon)
    icon.flashAnim:Play();
	icon.newitemglowAnim:Play();
end

local function StopAnimation(icon)
    if icon.flashAnim:IsPlaying() then icon.flashAnim:Stop() end
	if icon.newitemglowAnim:IsPlaying() then icon.newitemglowAnim:Stop() end
end

local function OnCooldownTimerFinished(self)
    local icon = self:GetParent();
    local group = icon:GetParent();
    StopAnimation(icon);
    NS.IconGroup_Remove(group, icon);
end

function CooldownTracking_UpdateBorder(icon)
    if UnitIsUnit(icon.unit, "focus") then
        icon.FocusTexture:SetAlpha(1);
    else
        icon.FocusTexture:SetAlpha(0);
    end

    -- Target highlight overwrites focus highlight
    if UnitIsUnit(icon.unit, "target") then
        icon.FocusTexture:SetAlpha(0);
        icon.TargetTexture:SetAlpha(1);
    else
        icon.TargetTexture:SetAlpha(0);
    end
end

NS.CreateCooldownTrackingIcon = function (unit, spellID, size)
    local frame = CreateFrame("Button", nil, UIParent, "CooldownTrackingButtonTemplate");
    frame:Hide();

    frame.unit = unit;
    frame.spellID = spellID;
    local spell = NS.cooldownSpells[spellID];
    frame.spellInfo = {
        cooldown = spell.cooldown,
        opt_lower_cooldown = spell.opt_lower_cooldown,
        charges = spell.charges,
        opt_charges = spell.charges,
    };
    frame.priority = frame.spell.priority;

    frame.icon:SetTexture(select(3, GetSpellInfo(spellID)));
    frame.icon:SetAllPoints();

    -- Set default cooldown
    frame.cooldown.cooldown = spell.cooldown;
    -- If baseline charge, set chargeExpire now
    frame.cooldown.chargeExpire = frame.spellInfo.charges and 0 or nil;
    frame.cooldown:SetScript("OnCooldownDone", OnCooldownTimerFinished);

    return frame;
end

NS.StartCooldownTrackingIcon = function (icon)
    local spell = icon.spellInfo;
    local now = GetTime();

    -- Icon is visible now, update opt_charges / opt_lower_cooldown
    -- Check if using second baseline charge
    if icon:IsShown() then
        -- Spell has opt_lower_cooldown, adjust icon cooldown
        if spell.opt_lower_cooldown then
            icon.cooldown.cooldown = spell.opt_lower_cooldown;
        end

        -- Spell has opt_charges, activate that charge and set expirationTime to now (so it can be used in the following logic)
        if spell.opt_charges and ( not icon.cooldown.chargeExpire ) then
            icon.cooldown.chargeExpire = 0;
        end
    end

    -- Check if should use charge
    if icon:IsShown() and icon.cooldown.chargeExpire and ( now >= icon.cooldown.chargeExpire ) then
        icon.Count:SetText("");
        icon.cooldown.chargeExpire = now + spell.cooldown;
    else
        -- Use default charge
        icon.cooldown.start = now;
        icon.cooldown.duration = spell.cooldown;
        icon.cooldown:SetCooldown(icon.cooldown.start, icon.cooldown.duration);
        if icon.cooldown.chargeExpire then
            icon.Count:SetText("#");
        end
    end

    StartAnimation(icon);

    NS.IconGroup_Insert(icon:GetParent(), icon);
end

NS.ResetCooldownTrackingCooldown = function (icon, amount)
    if ( not icon.cooldown ) then return end

    -- Fully set if amount is not specified
    if ( not amount ) then
        icon.cooldown:SetCooldown(0, 0);
        OnCooldownTimerFinished(icon.cooldown);
    else
        icon.cooldown.duration = icon.cooldown.duration - amount;
        -- Check if new duration hides the timer
        if icon.cooldown.duration <= 0 then
            icon.cooldown:SetCooldown(0, 0);
            OnCooldownTimerFinished(icon.cooldown);
        else
            icon.cooldown:SetCooldown(icon.cooldown.start, icon.cooldown.duration);
        end
    end
end
