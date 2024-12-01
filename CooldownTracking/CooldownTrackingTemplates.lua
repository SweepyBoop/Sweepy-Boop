local _, NS = ...;

local CreateFrame = CreateFrame;
local UIParent = UIParent;
local GetTime = GetTime;
local GetSpellInfo = C_Spell.GetSpellInfo;
local GetSpellTexture = C_Spell.GetSpellTexture;
local UnitIsUnit = UnitIsUnit;

local function StartAnimation(icon)
    icon.FlashAnimation:Play();
	icon.ActivationAnimation:Play();
end

local function StopAnimation(icon)
    if icon.FlashAnimation:IsPlaying() then icon.FlashAnimation:Stop() end
	if icon.ActivationAnimation:IsPlaying() then icon.ActivationAnimation:Stop() end
end

local function OnCooldownTimerFinished(self)
    StopAnimation(self:GetParent());
    NS.FinishCooldownTimer(self);
end

function CooldownTracking_UpdateBorder(icon)
    if UnitIsUnit(icon.unit, "target") then
        icon.TargetHighlight:SetAlpha(1);
    else
        icon.TargetHighlight:SetAlpha(0);
    end
end

-- Only put static info in this function
-- An icon for a unit + spellID is only created once per session
NS.CreateCooldownTrackingIcon = function (unit, spellID, size, hideHighlight)
    local frame = CreateFrame("Button", nil, UIParent, "CooldownTrackingButtonTemplate");
    frame.group = true; -- To add itself to parent group
    frame:Hide();

    frame.unit = unit;
    frame.spellID = spellID;
    local spell = NS.cooldownSpells[spellID];
    frame.category = spell.category;

    if size then
        local scale = size / NS.DEFAULT_ICON_SIZE;
        frame:SetScale(scale);
    end

    if hideHighlight then
        frame.TargetHighlight:Hide();
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

    frame.Icon:SetTexture(GetSpellTexture(spellID));
    frame.Icon:SetAllPoints();
    frame.Count:SetText(""); -- Call this before setting color
    frame.Count:SetTextColor(1, 1, 0); -- Yellow
    frame.cooldown:SetScript("OnCooldownDone", OnCooldownTimerFinished);

    return frame;
end

NS.StartCooldownTrackingIcon = function (icon)
    local spell = icon.spellInfo; -- static spell info
    local info = icon.info; -- dynamic info for current icon
    local timers = icon.timers;

    -- Init default charge
    if #(timers) == 0 then
        table.insert(timers, {start = 0, duration = 0, finish = 0});
    end

    -- Initialize charge expire if baseline charge
    if info.charges and #(timers) < 2 then
        table.insert(timers, {start = 0, duration = 0, finish = 0});
    end

    if icon:IsShown() then
        if spell.opt_lower_cooldown then
            info.cooldown = math.min(info.cooldown, spell.opt_lower_cooldown);
        end

        if spell.opt_charges and #(timers) < 2 then
            table.insert(timers, {start = 0, duration = 0, finish = 0});
        end
    end

    -- Always use timers[1] since it will be either off cooldown, or closet to come off cooldown
    -- Always use timers[1] since it will be either off cooldown, or closet to come off cooldown
    local now = GetTime();

    -- Check which one should be used
    local index = NS.CheckTimerToStart(timers);
    timers[index].start = now;
    timers[index].duration = info.cooldown;
    timers[index].finish = timers[index].start + timers[index].duration;

    if ( index == 1 ) and timers[2] and ( now < timers[2].finish ) then
        -- If we use timers[1] while timers[2] is already on cooldown, it will suspend timers[2]'s cooldown progress until timers[1] recovers
        -- So here we set it to a positive infinity, and while default comes back, we'll resume its cooldown progress
        timers[2].finish = math.huge;
    elseif ( index == 2 ) then
        -- If we use 2nd charge, also set it to infinity, since it will only start recovering when default charge comes back
        timers[2].finish = math.huge;
    end

    NS.RefreshCooldownTimer(icon.cooldown);

    StartAnimation(icon);

    NS.IconGroup_Insert(icon:GetParent(), icon, icon.unit .. "-" .. icon.spellID);
end

-- For spells with reduce_on_interrupt, set an internal cooldown so it doesn't reset cd multiple times
-- This is basically only for solar beam
NS.ResetCooldownTrackingCooldown = function (icon, amount, internalCooldown)
    if internalCooldown then
        local now = GetTime();
        if icon.info.lasteReset and ( now < icon.info.lasteReset + internalCooldown ) then
            return;
        end

        icon.info.lasteReset = now;
    end

    NS.ResetIconCooldown(icon, amount);
end
