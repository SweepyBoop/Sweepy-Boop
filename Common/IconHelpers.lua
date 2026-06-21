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

local function SetupOverlayGlow(button)
    if button.SpellActivationAlert then
        return;
    end

    -- Make the height/width available before the next frame.
    local frameWidth = button:GetSize();
    button.SpellActivationAlert = addon.CreateOverlayGlow(button, frameWidth, nil, not addon.PROJECT_TBC);
end

addon.ShowOverlayGlow = function (button)
    SetupOverlayGlow(button);

    if not button.SpellActivationAlert:IsShown() then
        button.SpellActivationAlert:Show();
        if addon.PROJECT_TBC then
            button.SpellActivationAlert.ProcStartAnim:Play();
        else
            button.SpellActivationAlert.ProcLoop:Play();
        end
    end
end

addon.HideOverlayGlow = function (button)
    if not button.SpellActivationAlert then
        return;
    end

    if button.SpellActivationAlert.ProcStartAnim:IsPlaying() then
        button.SpellActivationAlert.ProcStartAnim:Stop();
    end
    if button.SpellActivationAlert.ProcLoop:IsPlaying() then
        button.SpellActivationAlert.ProcLoop:Stop();
    end

    button.SpellActivationAlert:Hide();
end

local function SetFixedPixelGlowDotPosition(dot, path, progress)
    local segmentCount = #path;
    local scaled = ( progress % 1 ) * segmentCount;
    local index = math.floor(scaled) + 1;
    local nextIndex = ( index % segmentCount ) + 1;
    local segmentProgress = scaled - math.floor(scaled);
    local from = path[index];
    local to = path[nextIndex];

    dot:ClearAllPoints();
    dot:SetPoint(
        "CENTER",
        dot:GetParent(),
        "CENTER",
        from.x + ( ( to.x - from.x ) * segmentProgress ),
        from.y + ( ( to.y - from.y ) * segmentProgress )
    );
end

local function FixedPixelGlow_OnUpdate(self, elapsed)
    self.elapsed = self.elapsed + elapsed;
    if self.elapsed < self.throttle then
        return;
    end

    local step = self.elapsed;
    self.elapsed = 0;
    self.progress = ( self.progress + ( step * self.frequency ) ) % 1;

    for i = 1, #self.dots do
        SetFixedPixelGlowDotPosition(self.dots[i], self.path, self.progress + self.dots[i].offset);
    end
end

addon.CreateFixedPixelGlow = function (button, width, height, color, dotCount, dotSize, frequency, padding)
    width = width or 16;
    height = height or width;
    dotCount = dotCount or 8;
    dotSize = dotSize or 2;
    frequency = frequency or 0.25;
    padding = padding or 2;

    local halfWidth = ( width / 2 ) + padding;
    local halfHeight = ( height / 2 ) + padding;
    local glow = CreateFrame("Frame", nil, button);
    glow:SetSize(1, 1); -- non-zero anchor frame; animation uses stored fixed dimensions only
    glow:SetPoint("CENTER", button, "CENTER", 0, 0);
    glow.elapsed = 0;
    glow.progress = 0;
    glow.frequency = frequency;
    glow.throttle = 0.02;
    glow.path = {
        { x = -halfWidth, y = halfHeight },
        { x = halfWidth, y = halfHeight },
        { x = halfWidth, y = -halfHeight },
        { x = -halfWidth, y = -halfHeight },
    };
    glow.dots = {};

    for i = 1, dotCount do
        local dot = glow:CreateTexture(nil, "OVERLAY");
        dot:SetColorTexture(color[1], color[2], color[3], color[4]);
        dot:SetSize(dotSize, dotSize);
        dot.offset = ( i - 1 ) / dotCount;
        glow.dots[i] = dot;
        SetFixedPixelGlowDotPosition(dot, glow.path, dot.offset);
    end

    glow:Hide();
    return glow;
end

addon.ShowFixedPixelGlow = function (glow)
    if glow:IsShown() then
        return;
    end

    glow.elapsed = 0;
    glow.progress = 0;
    for i = 1, #glow.dots do
        SetFixedPixelGlowDotPosition(glow.dots[i], glow.path, glow.dots[i].offset);
    end
    glow:SetScript("OnUpdate", FixedPixelGlow_OnUpdate);
    glow:Show();
end

addon.HideFixedPixelGlow = function (glow)
    if not glow then
        return;
    end

    glow:SetScript("OnUpdate", nil);
    glow:Hide();
end
