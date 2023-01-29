local _, NS = ...;

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

NS.CreateWeakAuraIcon = function (unit, spellID, size)
    local frame = CreateFrame("Frame", nil, UIParent);
    frame:Hide();

    frame.unit = unit;
    frame.spellID = spellID;
    frame.spell = NS.spellData[spellID];
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
    end
    if spell.duration then
        -- Assign a framename to hide in OmniCC
        frame.duration = CreateFrame("Cooldown", "BoopHideTimerAuraDuration" .. spellID, frame, "CooldownFrameTemplate");
        frame.duration:SetAllPoints();
        frame.duration:SetDrawEdge(false);
        frame.duration:SetDrawBling(false);
        frame.duration:SetDrawSwipe(true);
        frame.duration:SetReverse(true);
        frame.duration:Raise(); -- Raise it above cooldown timer (if exists)

        frame.spellActivationAlert = CreateFrame("Frame", nil, frame, "ActionBarButtonSpellActivationAlert");
        frame.spellActivationAlert:SetSize(size * 1.4, size * 1.4);
        frame.spellActivationAlert:SetPoint("CENTER", frame, "CENTER", 0, 0);
        frame.spellActivationAlert:Hide();
        frame.spellActivationAlert:Raise(); -- Raise to front

        frame.duration:SetScript("OnCooldownDone", function (self)
            NS.HideOverlayGlow(self);
        end)
    end

    -- If there is a cooldown timer, always let it hide the icon.
    -- Otherwise the icon is duration only, let duration timer hide the icon.
    frame.hideIconTimer = frame.cooldown or frame.duration;
    frame.hideIconTimer:SetScript("OnCooldownDone", function (self)
        NS.IconGroup_Remove(self:GetParent(), self);
    end)

    return frame;
end

NS.StartWeakAuraIcon = function (icon)
    local spell = icon.spell;

    -- If there is a duration, start the duration timer
    if icon.duration then
        -- Decide duration
        local duration;
        if spell.duration == "dynamic" then
            duration = NS.Util_GetUnitBuff(icon.unit, icon.spellID);
        else
            duration = spell.duration;
        end

        icon.duration:SetCooldown(GetTime(), duration);
        NS.ShowOverlayGlow(icon);
    end

    -- If there is a cooldown, start the cooldown timer
    if icon.cooldown then
        local cooldownDuration = spell.cooldown;
        icon.cooldown:SetCooldown(GetTime(), cooldownDuration);
    end

    NS.IconGroup_Insert(icon:GetParent(), icon);
end

NS.RefreshWeakAuraDuration = function (icon)
    if ( not icon.duration ) then return end

    -- Get new duration
    local duration, expirationTime = select(5, NS.Util_GetUnitBuff(icon.unit, icon.spellID));
    icon.duration:SetCooldown(expirationTime - duration, duration);
end

NS.ResetWeakAuraCooldown = function (icon, amount)
    if ( not icon.cooldown ) then return end

    -- Fully reset if amount is not specified
    if ( not amount ) then
        icon.cooldown:SetCooldown(0, 0);
    else
        local start, duration = icon.cooldown:GetCooldownTimes();
        duration = duration - amount;
        -- Check if new duration hides the timer
        if duration <= 0 then
            icon.cooldown:SetCooldown(0, 0);
        else
            icon.cooldown:SetCooldown(start, duration);
        end
    end
end