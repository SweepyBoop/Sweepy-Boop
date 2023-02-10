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

    local now = GetTime();
    local start, duration, stack = math.huge, math.huge, nil;
    for i = 1, #(timers) do
        if ( now >= timers[i].finish ) then
            stack = true;
        else
            -- We previously set the finish of this timer to infinity so it only starts recovering after the other timer comes off cooldown
            -- now resume the timer's cooldown progress
            if finish and ( timers[i].finish == math.huge ) then
                timers[i].start = now;
                timers[i].duration = icon.info.cooldown;
                timers[i].finish = now + icon.info.cooldown;
                -- We just restored a charge, always show this one in cooldown frame, and show stack text
                start, duration, stack = timers[i].start, timers[i].duration, true;
            else
                if ( timers[i].start + timers[i].duration < start + duration ) then
                    start, duration = timers[i].start, timers[i].duration;
                end
            end
        end
    end

    if ( start ~= math.huge ) and ( duration ~= math.huge ) then
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

NS.FinishCooldownTimer = function (self)
    NS.RefreshCooldownTimer(self, true);
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
    frame.info = NS.spellData[spellID];
    frame.priority = frame.info.priority;
    frame.group = group;

    frame:SetSize(size, size);

    frame.tex = frame:CreateTexture();
    frame.tex:SetTexture(select(3, GetSpellInfo(spellID)));
    frame.tex:SetAllPoints();

    -- Create duration/cooldown timers as needed
    local spell = frame.info;
    if spell.cooldown then
        frame.cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate");
        frame.cooldown:SetAllPoints();
        frame.cooldown:SetDrawEdge(false);
        frame.cooldown:SetDrawBling(false);
        frame.cooldown:SetDrawSwipe(true);
        frame.cooldown:SetReverse(true);
        frame.cooldown:SetScript("OnCooldownDone", NS.FinishCooldownTimer);

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

    return index;
end

NS.StartWeakAuraIcon = function (icon)
    local spell = icon.info;
    local timers = icon.timers;

    if #(timers) == 0 then
        table.insert(timers, {start = 0, duration = 0, finish = 0});
    end

    if spell.charges and #(timers) < 2 then
        table.insert(timers, {start = 0, duration = 0, finish = 0});
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
        -- If we use timers[1] while timers[2] is already on cooldown, it will suspend timers[2]'s cooldown progress until timers[1] recovers
        -- So here we set it to a positive infinity, and while default comes back, we'll resume its cooldown progress
        if ( index == 1 ) and timers[2] and ( now < timers[2].finish ) then
            timers[2].finish = math.huge;
        elseif ( index == 2 ) then
            -- If we use 2nd charge, also set it to infinity, since it will only start recovering when default charge comes back
            timers[2].finish = math.huge;
        end

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
    if ( expirationTime - GetTime() > 1 ) then -- Don't bother extending if less than 1 sec left
        icon.duration:SetCooldown(expirationTime - duration, duration);
        if icon.cooldown then
            icon.cooldown:Hide(); -- Duration OnCooldownDone callback will show the cooldown timer
        end
    end
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

-- Early dismissal of icon glow due to aura being dispelled, right clicking the buff, etc.
NS.ResetWeakAuraDuration = function (icon)
    if ( not icon.duration ) then return end

    icon.duration:SetCooldown(0, 0);
    OnDurationTimerFinished(icon.duration);
end
