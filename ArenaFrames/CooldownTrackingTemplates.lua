local _, addon = ...;

local GetSpellTexture = C_Spell.GetSpellTexture;

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
    addon.FinishCooldownTimer(self);
end

function CooldownTracking_OnAnimationFinished(icon)
    addon.UpdateTargetHighlight(icon, UnitIsUnit(icon.unit, "target"));

    -- Wait for animation to finish to set used alpha
    -- Has another ability reset this icon's cooldown while animation was playing?
    if icon.started then
        addon.SetUsedIconAlpha(icon);
    end
end

-- Only put static info in this function
-- An icon for a unit + spellID is only created once per session
addon.CreateCooldownTrackingIcon = function (unit, spellID, size)
    local frame = CreateFrame("Button", nil, UIParent, "CooldownTrackingButtonTemplate");
    frame.template = addon.ICON_TEMPLATE.FLASH;
    frame:SetMouseClickEnabled(false);
    frame.group = true; -- To add itself to parent group
    frame:Hide();

    frame.unit = unit;
    frame.spellID = spellID;
    local spell = addon.SpellData[spellID];
    frame.category = spell.category;

    if size then
        local scale = size / addon.DEFAULT_ICON_SIZE;
        frame:SetScale(scale);
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

    if spell.charges or spell.opt_charges then
        frame.Count = CreateFrame("Frame", nil, frame);
        frame.Count:SetIgnoreParentAlpha(true);
        frame.Count:SetFrameLevel(10000);
        frame.Count:SetSize(addon.CHARGE_TEXTURE_SIZE, addon.CHARGE_TEXTURE_SIZE);
        frame.Count:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT");

        frame.Count.text = frame.Count:CreateFontString(nil, "OVERLAY", "NumberFontNormal");
        frame.Count.text:SetPoint("CENTER", frame.Count, "CENTER");
        frame.Count.text:SetText("");
        frame.Count.text:SetTextColor(1, 1, 1);

        frame.Count:Hide();
    end

    frame.cooldown:SetScript("OnCooldownDone", OnCooldownTimerFinished);

    return frame;
end

addon.StartCooldownTrackingIcon = function (icon)
    icon:SetAlpha(1); -- When starting the icon, always show it at full alpha

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

    if icon:IsShown() and icon.started then
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
    local index = addon.CheckTimerToStart(timers);
    --print("Use timers", index);
    timers[index].start = now;
    timers[index].duration = info.cooldown;
    timers[index].finish = timers[index].start + timers[index].duration;

    if ( index == 1 ) and timers[2] and ( now < timers[2].finish ) then
        -- If we use timers[1] while timers[2] is already on cooldown, it will suspend timers[2]'s cooldown progress until timers[1] recovers
        -- So here we set it to a positive infinity, and while default comes back, we'll resume its cooldown progress
        --print("Pause timers[2]");
        timers[2].finish = math.huge;
    elseif ( index == 2 ) then
        -- If we use 2nd charge, also set it to infinity, since it will only start recovering when default charge comes back
        --print("Pause timers[2]");
        timers[2].finish = math.huge;
    end

    addon.RefreshCooldownTimer(icon.cooldown);

    StartAnimation(icon);

    addon.IconGroup_Insert(icon:GetParent(), icon, icon.unit .. "-" .. icon.spellID);
end

-- For spells with reduce_on_interrupt, set an internal cooldown so it doesn't reset cd multiple times
-- This is basically only for solar beam
addon.ResetCooldownTrackingCooldown = function (icon, amount, internalCooldown, resetTo)
    if internalCooldown then
        local now = GetTime();
        if icon.info.lastReset and ( now < icon.info.lastReset + internalCooldown ) then
            return;
        end

        icon.info.lastReset = now;
    end

    addon.ResetIconCooldown(icon, amount, resetTo);
end
