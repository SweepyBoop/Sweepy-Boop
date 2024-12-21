local _, addon = ...;

local GetSpellTexture = C_Spell.GetSpellTexture;

local iconSize = addon.DEFAULT_ICON_SIZE;

addon.CreateBurstIcon = function (unit, spellID, size, group)
    local frame = CreateFrame("Frame", nil, UIParent);
    frame:SetMouseClickEnabled(false);
    frame:SetSize(iconSize, iconSize);
    frame:Hide();

    frame.unit = unit;
    frame.spellID = spellID;
    frame.spellInfo = addon.burstSpells[spellID];
    frame.priority = frame.spellInfo.priority;
    frame.group = group;

    frame.tex = frame:CreateTexture();
    frame.tex:SetTexture(GetSpellTexture(spellID));
    frame.tex:SetAllPoints();

    -- Create duration/cooldown timers as needed
    local spell = frame.spellInfo;
    if spell.cooldown then
        frame.cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate");
        frame.cooldown:SetAllPoints();
        frame.cooldown:SetDrawEdge(false);
        frame.cooldown:SetDrawBling(false);
        frame.cooldown:SetDrawSwipe(true);
        frame.cooldown:SetReverse(true);
        frame.cooldown:SetScript("OnCooldownDone", addon.FinishCooldownTimer);

        if addon.internal and ( not addon.isTestMode ) then
            frame.cooldown:SetHideCountdownNumbers(true);
        end

        if spell.charges then
            frame.Count = frame:CreateFontString(nil, "ARTWORK");
            frame.Count:SetFont("Fonts\\ARIALN.ttf", iconSize / 2, "OUTLINE");
            frame.Count:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2);
            frame.Count:SetText(""); -- Call this before setting font color
            frame.Count:SetTextColor(1, 1, 0);
        end
    end

    -- For now, always create a duration timer, if there is no duration, show 3s glow as reminder
    frame.duration = CreateFrame("Cooldown", addon.HIDETIMEROMNICC .. "AuraDuration" .. unit .. spellID, frame, "CooldownFrameTemplate");
    frame.duration:SetAllPoints();
    frame.duration:SetDrawEdge(false);
    frame.duration:SetDrawBling(false);
    frame.duration:SetDrawSwipe(true);
    frame.duration:SetReverse(true);
    frame.duration:SetAlpha(0);

    frame.spellActivationAlert = CreateFrame("Frame", nil, frame, "ActionBarButtonSpellActivationAlert");
    frame.spellActivationAlert:SetSize(iconSize * 1.4, iconSize * 1.4);
    frame.spellActivationAlert:SetPoint("CENTER", frame, "CENTER", 0, 0);
    frame.spellActivationAlert:Hide();

    frame.duration:SetScript("OnCooldownDone", addon.OnDurationTimerFinished);

    if size then
        local scale = size / iconSize;
        frame:SetScale(scale);
    end

    return frame;
end

local function SetBurstDuration(icon, startTime, duration)
    icon.duration:SetCooldown(startTime, duration);
    icon.duration.finish = startTime + duration;
end

addon.StartBurstIcon = function (icon)
    local spell = icon.spellInfo;
    local timers = icon.timers;
    local info = icon.info;

    if #(timers) == 0 then
        table.insert(timers, {start = 0, duration = 0, finish = 0});
    end

    if spell.charges and #(timers) < 2 then
        table.insert(timers, {start = 0, duration = 0, finish = 0});
    end

    -- If there is a cooldown, start the cooldown timer
    if icon.cooldown then
        -- Update opt_lower_cooldown
        if icon:IsShown() and spell.opt_lower_cooldown then
            info.cooldown = spell.opt_lower_cooldown;
        end

        -- Always use timers[1] since it will be either off cooldown, or closet to come off cooldown
        local now = GetTime();

        -- Check which one should be used
        local index = addon.CheckTimerToStart(timers);
        timers[index].start = now;
        timers[index].duration = info.cooldown;
        timers[index].finish = now + info.cooldown;
        -- If we use timers[1] while timers[2] is already on cooldown, it will suspend timers[2]'s cooldown progress until timers[1] recovers
        -- So here we set it to a positive infinity, and while default comes back, we'll resume its cooldown progress
        if ( index == 1 ) and timers[2] and ( now < timers[2].finish ) then
            timers[2].finish = math.huge;
        elseif ( index == 2 ) then
            -- If we use 2nd charge, also set it to infinity, since it will only start recovering when default charge comes back
            timers[2].finish = math.huge;
        end

        addon.RefreshCooldownTimer(icon.cooldown);
    end

    -- If there is a duration, start the duration timer
    if icon.duration then
        local startTime = GetTime();
        -- Decide duration
        local duration;
        if ( not spell.duration ) then
            -- Default glow duration
            duration = 3;
        elseif spell.duration == addon.DURATION_DYNAMIC then
            local expirationTime;
            duration, expirationTime = select(5, AuraUtil.UnpackAuraData(addon.Util_GetUnitBuff(icon.unit, icon.spellID)));
            startTime = expirationTime - duration;
        else
            duration = spell.duration;
        end

        SetBurstDuration(icon, startTime, duration);
        if icon.cooldown then
            icon.cooldown:Hide(); -- Hide the cooldown timer until duration is over
        end
        addon.ShowOverlayGlow(icon);
    end

    if icon.group then
        addon.IconGroup_Insert(icon:GetParent(), icon, icon.spellID);
    end
end

-- Early dismissal of icon glow due to aura being dispelled, right clicking the buff, etc.
addon.ResetBurstDuration = function (icon)
    if ( not icon.duration ) then return end

    SetBurstDuration(icon, 0, 0);
    addon.OnDurationTimerFinished(icon.duration);
end

addon.RefreshBurstDuration = function (icon)
    if ( not icon.duration ) then return end

    -- Get new duration
    local duration, expirationTime = select(5, AuraUtil.UnpackAuraData(addon.Util_GetUnitBuff(icon.unit, icon.spellID)));
    if ( expirationTime - GetTime() > 1 ) then -- Don't bother extending if less than 1 sec left
        SetBurstDuration(icon, expirationTime - duration, duration);
        if icon.cooldown then
            icon.cooldown:Hide(); -- Duration OnCooldownDone callback will show the cooldown timer
        end
    end
end
