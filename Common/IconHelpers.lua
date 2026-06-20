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
        glow.ProcStartFlipbook:SetSize(glowSize, glowSize); -- template defaults this birth burst to 150px
        -- The birth flipbook can flash at the wrong size before settling; use the stable loop glow only.
        glow.ProcStartFlipbook:Hide();
    end
    TintOverlayGlowTexture(glow.ProcStartFlipbook, color);
    TintOverlayGlowTexture(glow.ProcLoopFlipbook, color);
    TintOverlayGlowTexture(glow.ProcAltGlow, color);
    glow:Hide();
    return glow;
end
