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
NS.RefreshCooldownTimer = function (self)
    local icon = self:GetParent();
    -- Timers are sorted by finish time, the first one is either off cooldown, or closest to
    local timers = icon.timers;
    if ( not timers ) then return end

    local now = GetTime();
    local start, duration, stack = math.huge, math.huge, nil;
    for i = 1, #(timers) do
        if ( now >= timers[i].finish ) then
            stack = true;
        else
            -- We previously set the finish of this timer to infinity so it only starts recovering after the other timer comes off cooldown, so now reset the timer to start from now
            if timers[i].finish == math.huge then
                timers[i].start = now;
                timers[i].duration = icon.info.cooldown;
                timers[i].finish = now + icon.info.cooldown;
            end

            start, duration = math.min(start, timers[i].start), math.min(duration, timers[i].duration);
        end
    end

    if ( start ~= math.huge) and ( duration ~= math.huge) then
        icon.cooldown:SetCooldown(start, duration);
        if icon.Count then
            icon.Count:SetText(stack and "#" or "");
        end
    else
        -- Nothing is on cooldown, hide the icon
        icon.cooldown:SetCooldown(0, 0); -- This triggers a cooldown finish effect
        if icon.group then
            NS.IconGroup_Remove(icon:GetParent(), icon);
        end
    end
end

local function OnDurationTimerFinished(self)
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

NS.CreateWeakAuraIcon = function (unit, spellID, size, group)
    local frame = CreateFrame("Frame", nil, UIParent);
    frame:Hide();

    frame.unit = unit;
    frame.spellID = spellID;
    frame.spell = NS.spellData[spellID];
    frame.priority = frame.spell.priority;
    frame.group = group;

    frame:SetSize(size, size);

    frame.tex = frame:CreateTexture();
    frame.tex:SetTexture(select(3, GetSpellInfo(spellID)));
    frame.tex:SetAllPoints();

    -- Create duration/cooldown timers as needed
    local spell = frame.spell;
    if spell.cooldown then
        frame.cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate");
        frame.cooldown:SetAllPoints();
        frame.cooldown:SetDrawEdge(false);
        frame.cooldown:SetDrawBling(false);
        frame.cooldown:SetDrawSwipe(true);
        frame.cooldown:SetReverse(true);
        frame.cooldown:SetScript("OnCooldownDone", NS.RefreshCooldownTimer);

        if spell.charges then
            frame.Count = frame:CreateFontString(nil, "ARTWORK");
            frame.Count:SetFont("Fonts\\ARIALN.ttf", size / 2, "OUTLINE");
            frame.Count:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2);
            frame.Count:SetText(""); -- Call this before setting font color
            frame.Count:SetTextColor(1, 1, 0);
        end
    end
    
    -- For now, always create a duration timer, if there is no duration, show 3s glow as reminder
    frame.duration = CreateFrame("Cooldown", "BoopHideTimerAuraDuration" .. unit .. spellID, frame, "CooldownFrameTemplate");
    frame.duration:SetAllPoints();
    frame.duration:SetDrawEdge(false);
    frame.duration:SetDrawBling(false);
    frame.duration:SetDrawSwipe(true);
    frame.duration:SetReverse(true);
    frame.duration:SetAlpha(0);

    frame.spellActivationAlert = CreateFrame("Frame", nil, frame, "ActionBarButtonSpellActivationAlert");
    frame.spellActivationAlert:SetSize(size * 1.4, size * 1.4);
    frame.spellActivationAlert:SetPoint("CENTER", frame, "CENTER", 0, 0);
    frame.spellActivationAlert:Hide();

    frame.duration:SetScript("OnCooldownDone", OnDurationTimerFinished);

    return frame;
end

NS.TimerCompare = function (left, right)
    return left.finish < right.finish;
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
            index = ( timers[1].finish < timers[2].finish ) and 1 or 2;
        end
    end

    -- Set active state for timer
    for i = 1, #(timers) do
        timers[i].active = ( i == index );
    end

    return index;
end

NS.StartWeakAuraIcon = function (icon)
    local spell = icon.spell;
    local timers = icon.timers;

    if spell.charges and #(timers) < 2 then
        timers.insert({start = 0, duration = 0, finish = 0});
    end

    -- If there is a cooldown, start the cooldown timer
    if icon.cooldown then
        -- Always use timers[1] since it will be either off cooldown, or closet to come off cooldown
        local now = GetTime();
        
        -- Check which one should be used
        local index = NS.CheckTimerToStart(timers);
        timers[index].start = now;
        timers[index].duration = spell.cooldown;
        timers[index].finish = now + spell.cooldown;
        -- If I use timers[1] while timers[2] is already on cooldown, it will make timers[2]'s cooldown progress start after timers[1] finish
        -- So here we set it to a positive infinity, and while one charge comes back, we'll reset its values
        if ( index == 1 ) and timers[2] and ( now < timers[2].finish ) then
            timers[2].finish = math.huge;
        end

        -- Sort after changing timers
        --table.sort(timers, NS.TimerCompare);

        NS.RefreshCooldownTimer(icon.cooldown);
    end

    -- If there is a duration, start the duration timer
    if icon.duration then
        -- Decide duration
        local duration;
        if ( not spell.duration ) then
            -- Default glow duration
            duration = 3;
        elseif spell.duration == "dynamic" then
            duration = NS.Util_GetUnitBuff(icon.unit, icon.spellID);
        else
            duration = spell.duration;
        end

        icon.duration:SetCooldown(GetTime(), duration);
        if icon.cooldown then
            icon.cooldown:Hide(); -- Hide the cooldown timer until duration is over
        end
        NS.ShowOverlayGlow(icon);
    end

    -- Play sound for spells with highest priority
    if ( icon.priority == 1 ) then
        -- https://wowpedia.fandom.com/wiki/API_PlaySound
        --PlaySoundFile(567721); -- MachineGun
    end

    if icon.group then
        NS.IconGroup_Insert(icon:GetParent(), icon, icon.spellID);
    end
end

NS.RefreshWeakAuraDuration = function (icon)
    if ( not icon.duration ) then return end

    -- Get new duration
    local duration, expirationTime = select(5, NS.Util_GetUnitBuff(icon.unit, icon.spellID));
    icon.duration:SetCooldown(expirationTime - duration, duration);
end

NS.ResetIconCooldown = function (icon, amount)
    if ( not icon.cooldown ) then return end

    -- Timers are sorted by finish time
    local timers = icon.timers;
    -- Find the first thing that's on cooldown
    local now = GetTime();
    local index;
    for i = 1, #(timers) do
        if ( timers[i].finish ~= math.huge ) and ( now < timers[i].finish ) then
            index = i;
            break;
        end
    end

    if ( not index ) then return end

    -- Reduce the timer
    if ( not amount ) then
        -- Fully reset if no amount specified
        timers[index] = { start = 0, duration = 0, finish = 0};
    else
        timers[index].duration, timers[index].finish = (timers[index].duration - amount), (timers[index].finish - amount);
        if ( timers[index].duration < 0 ) then
            timers[index] = { start = 0, duration = 0, finish = 0};
        end
    end

    -- Sort after updating timers
    --table.sort(timers, NS.TimerCompare);
    NS.RefreshCooldownTimer(icon.cooldown);
end

-- Early dismissal of icon glow due to aura being dispelled, right clicking the buff, etc.
NS.ResetWeakAuraDuration = function (icon)
    if ( not icon.duration ) then return end

    icon.duration:SetCooldown(0, 0);
    OnDurationTimerFinished(icon.duration);
end
