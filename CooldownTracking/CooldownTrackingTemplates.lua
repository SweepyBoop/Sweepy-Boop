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
    --[[ if UnitIsUnit(icon.unit, "focus") then
        icon.FocusTexture:SetAlpha(1);
    else
        icon.FocusTexture:SetAlpha(0);
    end ]]

    -- Target highlight overwrites focus highlight
    if UnitIsUnit(icon.unit, "target") then
        --icon.FocusTexture:SetAlpha(0);
        icon.TargetTexture:SetAlpha(1);
    else
        icon.TargetTexture:SetAlpha(0);
    end
end

-- Only put static info in this function
-- An icon for a unit + spellID is only created once per session
NS.CreateCooldownTrackingIcon = function (unit, spellID, size, hideHighlight)
    local frame = CreateFrame("Button", nil, UIParent, "CooldownTrackingButtonTemplate");
    frame:Hide();

    frame.unit = unit;
    frame.spellID = spellID;
    local spell = NS.cooldownSpells[spellID];
    frame.category = spell.category;

    if size then
        local scale = size / 32;
        frame:SetScale(scale);
    end

    if hideHighlight then
        frame.TargetTexture:Hide();
    end
    
    -- Fill in static info here
    frame.spellInfo = {
        cooldown = spell.cooldown,
        opt_lower_cooldown = spell.opt_lower_cooldown,
        charges = spell.charges,
        opt_charges = spell.opt_charges,
        reduce_on_interrupt = spell.reduce_on_interrupt,
        trackEvent = spell.trackEvent,
        trackPet = spell.trackPet,
    };
    frame.priority = spell.priority;

    frame.icon:SetTexture(select(3, GetSpellInfo(spellID)));
    frame.icon:SetAllPoints();
    frame.Count:SetText(""); -- Call this before setting color
    frame.Count:SetTextColor(1, 1, 0); -- Yellow

    frame.dynamic = {};
    frame.cooldown:SetScript("OnCooldownDone", OnCooldownTimerFinished);

    return frame;
end

NS.StartCooldownTrackingIcon = function (icon)
    local spell = icon.spellInfo; -- static spell info
    local overrides = icon.overrides; -- spec overrides
    local dynamic = icon.dynamic; -- dynamic info for current icon

    -- Apply overrides if haven't
    if ( not dynamic.charges ) then
        dynamic.charges = overrides.charges;
    end
    if ( not dynamic.cooldown ) then
        dynamic.cooldown = overrides.cooldown;
    end
    
    -- If spell has baseline charge and charge not set
    if dynamic.charges and ( not dynamic.chargeExpire ) then
        dynamic.chargeExpire = 0;
    end

    local now = GetTime();

    -- Icon is visible now, update opt_charges / opt_lower_cooldown
    -- Check if using second baseline charge
    if icon:IsShown() then
        -- Spell has opt_lower_cooldown, adjust icon cooldown
        if spell.opt_lower_cooldown then
            dynamic.cooldown = math.min(spell.opt_lower_cooldown, dynamic.cooldown);
        end

        -- Spell has opt_charges, activate that charge and set expirationTime to now (so it can be used in the following logic)
        if spell.opt_charges and ( not dynamic.chargeExpire ) then
            dynamic.chargeExpire = 0;
        end
    end

    -- Check if using second charge
    if icon:IsShown() and dynamic.chargeExpire and ( now >= dynamic.chargeExpire ) then
        icon.Count:SetText("");
        dynamic.chargeExpire = now + dynamic.cooldown;
    else
        -- Use default (or only) charge
        dynamic.start = now;
        dynamic.duration = dynamic.cooldown; -- This is used for cooldown reduction, as Cooldown:GetCooldownDuration is not reliable
        icon.cooldown:SetCooldown(dynamic.start, dynamic.duration);
        if dynamic.chargeExpire and ( now >= dynamic.chargeExpire ) then
            icon.Count:SetText("#");
        elseif icon.text then
            icon.Count:SetText("");
        end
    end

    --[[ -- Spell has no charge, just use default
    if ( not dynamic.charge ) then
        dynamic.start = now;
        dynamic.duration = dynamic.cooldown;
        icon.cooldown:SetCooldown(dynamic.start, dynamic.duration);
    else
        local start, duration;
        -- Check if default is available
        if ( not dynamic.start ) or ( now >= dynamic.start + dynamic.duration ) then
            dynamic.start = now;
            dynamic.duration = dynamic.cooldown;
            start, duration = dynamic.start, dynamic.duration;
        else
            -- Use extra charge
            dynamic.charge.start = now;
            dynamic.charge.duration = dynamic.cooldown;
            start, duration = dynamic.charge.start, dynamic.charge.duration;
        end

        if icon:IsShown() then
            icon.Count:SetText("");
        else
            icon.cooldown:SetCooldown(start, duration);
            -- Do we have a charge available after pressing this icon?
            local charges = ( not dynamic.start ) or ( now >= dynamic.start + dynamic.duration )
                or ( not dynamic.charge.start ) or ( now >= dynamic.charge.start + dynamic.charge.duration );
            if charges then
                icon.Count:SetText("#");
            else
                icon.Count:SetText("");
            end
        end
    end ]]

    StartAnimation(icon);

    NS.IconGroup_Insert(icon:GetParent(), icon, icon.unit .. "-" .. icon.spellID);
end

-- For spells with reduce_on_interrupt, set an internal cooldown so it doesn't reset cd multiple times
-- This is basically only for solar beam
NS.ResetCooldownTrackingCooldown = function (icon, amount, internalCooldown)
    if ( not icon.cooldown ) then return end

    local dynamic = icon.dynamic;
    local now = GetTime();

    if internalCooldown then
        if dynamic.lastRest and ( now < dynamic.lastRest + internalCooldown ) then
            return;
        end

        dynamic.lastRest = now;
    end

    -- Fully set if amount is not specified
    if ( not amount ) then
        icon.cooldown:SetCooldown(0, 0);
        OnCooldownTimerFinished(icon.cooldown);
    else
        dynamic.duration = dynamic.duration - amount;
        -- Check if new duration hides the timer
        if dynamic.duration <= 0 then
            icon.cooldown:SetCooldown(0, 0);
            OnCooldownTimerFinished(icon.cooldown);
        else
            icon.cooldown:SetCooldown(dynamic.start, dynamic.duration);
        end
    end
end
