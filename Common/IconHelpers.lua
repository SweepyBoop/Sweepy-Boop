local _, addon = ...;

local function TintOverlayGlowTexture(texture, color)
    if texture and color then
        texture:SetVertexColor(color[1], color[2], color[3], color[4]);
    end
end

addon.CreateOverlayGlow = function (button, size, color, skipStartFlipbook)
    local glowSize = size * 1.4;
    local glow = CreateFrame("Frame", nil, button, "ActionButtonSpellAlertTemplate");
    glow:SetSize(glowSize, glowSize);
    glow:SetPoint("CENTER", button, "CENTER", 0, 0);
    if glow.ProcStartFlipbook then
        glow.ProcStartFlipbook:SetSize(glowSize, glowSize); -- template defaults this birth burst to 150px
        if skipStartFlipbook then
            glow.ProcStartFlipbook:Hide(); -- skip the birth flipbook; first frame can flash the raw atlas grid
        end
    end
    TintOverlayGlowTexture(glow.ProcStartFlipbook, color);
    TintOverlayGlowTexture(glow.ProcLoopFlipbook, color);
    TintOverlayGlowTexture(glow.ProcAltGlow, color);
    glow:Hide();
    return glow;
end
