local _, addon = ...;

local function SetupOverlayGlow(button)
    -- If we already have a SpellActivationAlert then just early return. We should already be setup
	if button.SpellActivationAlert then
		return;
	end

	button.SpellActivationAlert = CreateFrame("Frame", nil, button, "ActionBarButtonSpellActivationAlert");

	--Make the height/width available before the next frame:
	local frameWidth, frameHeight = button:GetSize();
	button.SpellActivationAlert:SetSize(frameWidth * 1.4, frameHeight * 1.4);
	button.SpellActivationAlert:SetPoint("CENTER", button, "CENTER", 0, 0);
	button.SpellActivationAlert:Hide();
end

addon.ShowOverlayGlow = function (button)
    SetupOverlayGlow(button);

	if not button.SpellActivationAlert:IsShown() then
		button.SpellActivationAlert:Show();
		button.SpellActivationAlert.ProcStartAnim:Play();

	end
end

addon.HideOverlayGlow = function (button)
    if not button.SpellActivationAlert then
		return;
	end

	if button.SpellActivationAlert.ProcStartAnim:IsPlaying() then
		button.SpellActivationAlert.ProcStartAnim:Stop();
	end

	if button:IsVisible() then
 		button.SpellActivationAlert:Hide();
	end
end

-- Call this after modifying timers
addon.RefreshCooldownTimer = function (self, finish)
    local icon = self:GetParent();
    local timers = icon.timers;
    if ( not timers ) then return end

    -- Simplify logic for single timer
    if #(timers) < 2 then
        if finish then
            icon.cooldown:SetCooldown(0, 0); -- This triggers a cooldown finish effect
            if icon.group then
                local showUnusedIcons = addon.GetIconSetConfig(icon.iconSetID).showUnusedIcons;
                addon.IconGroup_Remove(icon:GetParent(), icon, showUnusedIcons);
            end
        else
            icon.cooldown:SetCooldown(timers[1].start, timers[1].duration);
        end

        return;
    end

    local now = GetTime();
    if finish then
        -- We previously set the finish of this timer to infinity so it will start over when the other timer comes off cooldown
        -- now restart the timer's cooldown progress
        if ( timers[2].finish == math.huge ) then
            timers[2].start = now;
            timers[2].duration = icon.info.cooldown;
            timers[2].finish = now + icon.info.cooldown;
        end

        -- Reset whichever timer is closer to finish
        -- It's possible this has been done prior to calling this function, but check here to make sure
        local index = (timers[1].finish <= timers[2].finish) and 1 or 2;
        timers[index].finish = 0;
    end

    local stack = ( now >= timers[1].finish ) + ( now >= timers[2].finish );
    -- Show the timer on cooldown; if both on cooldown, show the one closer to finish
    -- Exclude paused timers (finish == math.huge)
    local start, duration = math.huge, math.huge;
    for i = 1, #(timers) do
        if ( timers[i].finish ~= 0 ) and ( timers[i].start + timers[i].duration < start + duration ) and ( now < timers[i].start + timers[i].duration ) then
            start, duration = timers[i].start, timers[i].duration;
        end
    end

    if ( start ~= math.huge ) and ( duration ~= math.huge ) then
        icon.cooldown:SetCooldown(start, duration);
        if ( #(icon.timers) > 1 ) and icon.Count then -- Only do this if we've actually detected charges in case of opt_charges
            icon.Count:SetText(stack);
            if stack then -- There is a charge available, treat as unused (off cooldown) icon
                icon.Count:Show();
                addon.SetUnusedIconAlpha(icon);
                addon.SetHideCountdownNumbers(icon, true);
            else
                icon.Count:Hide();
                addon.SetHideCountdownNumbers(icon, false);
            end
        end
    else
        icon.cooldown:SetCooldown(0, 0); -- This triggers a cooldown finish effect
        if icon.group then
            local showUnusedIcons = addon.GetIconSetConfig(icon.iconSetID).showUnusedIcons;
            addon.IconGroup_Remove(icon:GetParent(), icon, showUnusedIcons);
        end
    end
end

addon.FinishCooldownTimer = function (self)
    addon.RefreshCooldownTimer(self, true);
end

addon.SetUnusedIconAlpha = function (icon)
    local unusedIconAlpha;
    local config = addon.GetIconSetConfig(icon.iconSetID);
    if config.showUnusedIcons then
        unusedIconAlpha = config.unusedIconAlpha;
    else
        unusedIconAlpha = 1;
    end
    icon:SetAlpha(unusedIconAlpha);
end

addon.SetUsedIconAlpha = function (icon)
    if icon.Count and icon.Count:IsShown() then
        -- There is still a charge available, keep unused alpha
        addon.SetUnusedIconAlpha(icon);
        return;
    end

    local usedIconAlpha;
    local config = addon.GetIconSetConfig(icon.iconSetID);
    if config.showUnusedIcons then
        usedIconAlpha = config.usedIconAlpha;
    else
        usedIconAlpha = 1;
    end
    icon:SetAlpha(usedIconAlpha);
end

addon.OnDurationTimerFinished = function(self)
    local icon = self:GetParent();
    addon.HideOverlayGlow(icon);
    if icon.cooldown then
        addon.SetUsedIconAlpha(icon);
        icon.cooldown:Show();
    else
        if icon.group then
            local showUnusedIcons = addon.GetIconSetConfig(icon.iconSetID).showUnusedIcons;
            addon.IconGroup_Remove(icon:GetParent(), icon, showUnusedIcons);
        end
    end
end

addon.CheckTimerToStart = function (timers)
    local index;

    if #(timers) < 2 then
        index = 1;
    else
        local now = GetTime();
        -- Check whatever is off cooldown or closest to
        if ( now >= timers[1].finish ) then
            index = 1;
        elseif ( now >= timers[2].finish ) then
            index = 2;
        else
            index = ( timers[1].finish <= timers[2].finish ) and 1 or 2;
        end
    end

    return index;
end

addon.ResetIconCooldown = function (icon, amount, resetTo)
    if ( not icon.cooldown ) then return end

    local timers = icon.timers;
    -- Find the first thing that's on cooldown
    local now = GetTime();
    local index;
    if ( not amount ) and ( #(timers) > 1 ) then
        -- if extra charge is paused (both charges are currently on cd), reset it
        if ( timers[2].finish == math.huge ) then
            index = 2;
        else
            -- Only default charge is on cooldown, reset it
            index = 1;
        end
    else
        for i = 1, #(timers) do
            -- Timer set to inf hasn't started cooldown progress yet, so we ignore it
            if ( timers[i].finish ~= math.huge ) and ( now < timers[i].finish ) then
                index = i;
                break;
            end
        end
    end

    if ( not index ) then return end

    -- Reduce the timer
    if ( not amount ) then
        -- Fully reset if no amount specified
        --print("full reset timers", index);
        timers[index] = { start = 0, duration = 0, finish = 0 };
    else
        --print("Before reduce, timers", index, timers[index].start, timers[index].duration, timers[index].finish);
        if resetTo then
            timers[index].start, timers[index].duration, timers[index].finish = now, amount, ( now + amount );
        else
            local actualReducedAmount = math.min(amount, timers[index].finish - now);
            timers[index].duration, timers[index].finish = (timers[index].duration - actualReducedAmount), (timers[index].finish - actualReducedAmount);
            amount = amount - actualReducedAmount;
        end
        if ( timers[index].finish <= now ) then
            timers[index] = { start = 0, duration = 0, finish = 0 };
        end
        --print("After reduce, timers", index, timers[index].start, timers[index].duration, timers[index].finish);

        -- If there are 2 charges and we just reset charge one, and charge 2 is on cooldown
        -- Need to unpause charge 2, and reduce charge 2 if there is amount remaining
        if ( #(timers) > 1 ) and ( index == 1 ) and ( timers[1].finish == 0 ) and ( timers[2].finish == math.huge ) then
            timers[2].start, timers[2].duration, timers[2].finish = now, icon.info.cooldown - amount, now + icon.info.cooldown - amount;
            --print("timers[2] reduced by", amount);
            -- It's unlikely second charge is completely reset with the remaining cooldown, so let's skip checking for "finish"
        end
    end

    addon.RefreshCooldownTimer(icon.cooldown);
end

addon.SetHideCountdownNumbers = function (frame, hide)
    if frame.cooldown then
        frame.cooldown:SetDrawEdge(hide); -- Since we're hiding numbers, draw edge to make it more visible
        frame.cooldown:SetHideCountdownNumbers(hide);
        frame.cooldown.noCooldownCount = hide; -- hide OmniCC timers
    end
end
