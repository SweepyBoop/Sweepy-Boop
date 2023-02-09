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

local function OnCooldownTimerFinished(self)
    local icon = self:GetParent();
    if icon.group then
        NS.IconGroup_Remove(icon:GetParent(), icon);
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
        frame.cooldown:SetScript("OnCooldownDone", OnCooldownTimerFinished);

        if spell.charges then
            frame.text = frame:CreateFontString(nil, "ARTWORK");
            frame.text:SetFont("Fonts\\ARIALN.ttf", size / 2, "OUTLINE");
            frame.text:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2);
            frame.text:SetText(""); -- Call this before setting font color
            frame.text:SetTextColor(1, 1, 0);
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

NS.StartWeakAuraIcon = function (icon)
    local spell = icon.spell;
    local timers = icon.timers;

    -- Init default charge
    if #(timers) == 0 then
        table.insert(timers, {start = 0, duration = 0, finish = 0});
    end

    -- Initialize charge expire if baseline charge
    if spell.charges and #(timers) < 2 then
        table.insert(timers, {start = 0, duration = 0, finish = 0});
    end

    -- Sort by finish time after changing timers
    table.sort(timers, NS.TimerCompare);

    -- If there is a cooldown, start the cooldown timer
    if icon.cooldown then
        local now = GetTime();
        -- Always use timers[1] since it will be either off cooldown, or closet to come off cooldown
        timers[1].start = now;
        timers[1].duration = spell.cooldown;
        timers[1].finish = now + spell.cooldown;

        -- Sort again after updating timers
        table.sort(timers, NS.TimerCompare);

        local start, duration, charge;
        -- Show the first timer that is on cooldown, and while iterating through timers, check if there is one off cooldown (to set the charge text)
        for i = 1, #(timers) do
            if now >= timers[i].finish then
                charge = true;
            else
                -- Found the first timer that is on cooldown, use it to update cooldown frame
                start, duration = timers[i].start, timers[i].duration;
            end
        end

        if start and duration then
            icon.cooldown:SetCooldown(start, duration);
        end

        if icon.text then
            icon.text:SetText(charge and "#" or "");
        end
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

NS.ResetWeakAuraCooldown = function (icon, amount)
    if ( not icon.cooldown ) then return end

    -- Timers are sorted by finish time
    local timers = icon.timers;
    -- Find the first thing that's on cooldown
    local now = GetTime();
    local timer;
    for i = 1, #(timers) do
        if ( now < timers[i].finish ) then
            timer = timers[i];
            break;
        end
    end

    if ( not timer ) then return end

    -- Reduce the timer
    if ( not amount ) then
        -- Fully reset if no amount specified
        timer = { start = 0, duration = 0, finish = 0};
    else
        timer.duration, timer.finish = (timer.duration - amount), (timer.finish - amount);
    end

    -- Sort after updating timers
    table.sort(timers, NS.TimerCompare);

    -- Update the cooldown frame, display the first things found on cooldown
    local start, duration, found;
    for i = 1, #(timers) do
        if ( now < timers[i].finish ) then
            start, duration, found = timers[i].start, timers[i].duration, true;
            break;
        end
    end

    if start and duration then
        icon.cooldown:SetCooldown(start, duration);
    elseif ( not found ) then
        icon.cooldown:SetCooldown(0, 0);
        OnCooldownTimerFinished(icon.cooldown);
    end
end

-- Early dismissal of icon glow due to aura being dispelled, right clicking the buff, etc.
NS.ResetWeakAuraDuration = function (icon)
    if ( not icon.duration ) then return end

    icon.duration:SetCooldown(0, 0);
    OnDurationTimerFinished(icon.duration);
end
