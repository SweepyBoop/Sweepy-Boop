local _, NS = ...;

local CreateFrame = CreateFrame;
local UIParent = UIParent;
local GetSpellInfo = GetSpellInfo;
local GetTime = GetTime;

NS.ShowOverlayGlow = function (button)
    if not button.spellActivationAlert then
        return;
    end

    if button.spellActivationAlert.animOut:IsPlaying() then
        button.spellActivationAlert.animOut:Stop();
    end

    if not button.spellActivationAlert:IsShown() then
        button.spellActivationAlert.animIn:Play();
    end
end

NS.HideOverlayGlow = function (button)
    if not button.spellActivationAlert then
        return;
    end

    if button.spellActivationAlert.animIn:IsPlaying() then
        button.spellActivationAlert.animIn:Stop();
    end

    if button:IsVisible() then
        button.spellActivationAlert.animOut:Play();
    else
        button.spellActivationAlert.animOut:OnFinished();	--We aren't shown anyway, so we'll instantly hide it.
    end
end

-- Call this after modifying timers
NS.RefreshCooldownTimer = function (self, finish)
    local icon = self:GetParent();
    local timers = icon.timers;
    if ( not timers ) then return end

    -- Simplify logic for single timer
    if #(timers) < 2 then
        if finish then
            icon.cooldown:SetCooldown(0, 0); -- This triggers a cooldown finish effect
            if icon.group then
                NS.IconGroup_Remove(icon:GetParent(), icon);
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

    local stack = ( now >= timers[1].finish ) or ( now >= timers[2].finish );
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
        if icon.Count then
            icon.Count:SetText(stack and "#" or "");
        end
    else
        icon.cooldown:SetCooldown(0, 0); -- This triggers a cooldown finish effect
        if icon.group then
            NS.IconGroup_Remove(icon:GetParent(), icon);
        end
    end
end

NS.FinishCooldownTimer = function (self)
    NS.RefreshCooldownTimer(self, true);
end

NS.OnDurationTimerFinished = function(self)
    local icon = self:GetParent();
    NS.HideOverlayGlow(icon);
    if icon.cooldown then
        icon.cooldown:Show();
    else
        if icon.group then
            NS.IconGroup_Remove(icon:GetParent(), icon);
        end
    end
end

NS.CheckTimerToStart = function (timers)
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

NS.ResetIconCooldown = function (icon, amount)
    if ( not icon.cooldown ) then return end

    local timers = icon.timers;
    -- Find the first thing that's on cooldown
    local now = GetTime();
    local index;
    for i = 1, #(timers) do
        -- Timer set to inf is hasn't started cooldown progress yet, so we ignore it
        if ( timers[i].finish ~= math.huge ) and ( now < timers[i].finish ) then
            index = i;
            break;
        end
    end

    if ( not index ) then return end

    -- Reduce the timer
    local finish;
    if ( not amount ) then
        -- Fully reset if no amount specified
        timers[index] = { start = 0, duration = 0, finish = 0};
        finish = true;
    else
        timers[index].duration, timers[index].finish = (timers[index].duration - amount), (timers[index].finish - amount);
        if ( timers[index].duration < 0 ) then
            timers[index] = { start = 0, duration = 0, finish = 0};
            finish = true;
        end
    end

    NS.RefreshCooldownTimer(icon.cooldown, finish);
end
