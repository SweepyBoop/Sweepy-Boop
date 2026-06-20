local _, addon = ...;

local function TintOverlayGlowTexture(texture, color)
    if texture and color then
        texture:SetVertexColor(color[1], color[2], color[3], color[4]);
    end
end

addon.CreateOverlayGlow = function (button, size, color)
    local glowSize = size * 1.4;
    local glow = CreateFrame("Frame", nil, button, "ActionButtonSpellAlertTemplate");
    glow:SetSize(glowSize, glowSize);
    glow:SetPoint("CENTER", button, "CENTER", 0, 0);
    if glow.ProcStartFlipbook then
        -- Blizzard's skipBirth path plays ProcLoop directly; hide the birth flipbook to avoid its size flash.
        glow.ProcStartFlipbook:Hide();
    end
    TintOverlayGlowTexture(glow.ProcStartFlipbook, color);
    TintOverlayGlowTexture(glow.ProcLoopFlipbook, color);
    TintOverlayGlowTexture(glow.ProcAltGlow, color);
    glow:Hide();
    return glow;
end

local function SetupOverlayGlow(button)
    if button.SpellActivationAlert then
        return;
    end

    -- Make the height/width available before the next frame.
    local frameWidth = button:GetSize();
    button.SpellActivationAlert = addon.CreateOverlayGlow(button, frameWidth);
end

addon.ShowOverlayGlow = function (button)
    SetupOverlayGlow(button);

    if not button.SpellActivationAlert:IsShown() then
        button.SpellActivationAlert:Show();
        button.SpellActivationAlert.ProcLoop:Play(); -- matches Blizzard's skipBirth path
    end
end

addon.HideOverlayGlow = function (button)
    if not button.SpellActivationAlert then
        return;
    end

    button.SpellActivationAlert:Hide();

    if button.SpellActivationAlert.ProcStartAnim:IsPlaying() then
        button.SpellActivationAlert.ProcStartAnim:Stop();
    end
    if button.SpellActivationAlert.ProcLoop:IsPlaying() then
        button.SpellActivationAlert.ProcLoop:Stop();
    end
end
