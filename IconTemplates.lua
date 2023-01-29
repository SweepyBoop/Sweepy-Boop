local _, NS = ...;

NS.CreateWeakAuraIcon = function (unit, spellID, size)
    local frame = CreateFrame("Frame", nil, UIParent);
    frame:Hide();

    frame.unit = unit;
    frame.spellID = spellID;
    frame:SetSize(size, size);

    frame.tex = frame:CreateTexture();
    frame.tex:SetTexture(select(3, GetSpellInfo(spellID)));
    frame.tex:SetAllPoints();

    -- Create duration/cooldown timers as needed
    local spell = NS.spellData[spellID];
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
    end

end