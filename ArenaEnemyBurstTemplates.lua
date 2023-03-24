local _, NS = ...;
local CreateFrame = CreateFrame;
local UIParent = UIParent;
local GetSpellInfo = GetSpellInfo;
local GetTime = GetTime;

NS.CreateSweepyIcon = function (unit, spellID, size, group)
    local frame = CreateFrame("Frame", nil, UIParent);
    frame:Hide();

    frame.unit = unit;
    frame.spellID = spellID;
    frame.spellInfo = NS.spellData[spellID];
    frame.priority = frame.spellInfo.priority;
    frame.group = group;

    frame:SetSize(size, size);

    frame.tex = frame:CreateTexture();
    frame.tex:SetTexture(select(3, GetSpellInfo(spellID)));
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
    frame.duration = CreateFrame("Cooldown", NS.HIDETIMEROMNICC .. "AuraDuration" .. unit .. spellID, frame, "CooldownFrameTemplate");
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

    frame.duration:SetScript("OnCooldownDone", NS.OnDurationTimerFinished);

    return frame;
end

-- Early dismissal of icon glow due to aura being dispelled, right clicking the buff, etc.
NS.ResetSweepyDuration = function (icon)
    if ( not icon.duration ) then return end

    icon.duration:SetCooldown(0, 0);
    NS.OnDurationTimerFinished(icon.duration);
end

NS.RefreshSweepyDuration = function (icon)
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
