local _, addon = ...;

local function TintOverlayGlowTexture(texture, color)
    if texture and color then
        texture:SetVertexColor(color[1], color[2], color[3], color[4]);
    end
end

local function StopOverlayGlow(glow)
    if glow.ProcLoop:IsPlaying() then
        glow.ProcLoop:Stop();
    end
end

addon.CreateOverlayGlow = function (button, size, color, skipBirth)
    local glowSize = size * 1.4;
    local glow = CreateFrame("Frame", nil, button, "ActionButtonSpellAlertTemplate");
    -- TBC's Blizzard spell alert code has no skip-birth path; always play the start flipbook.
    glow.skipBirth = skipBirth and ( not addon.PROJECT_TBC );
    glow:SetSize(glowSize, glowSize);
    glow:SetPoint("CENTER", button, "CENTER", 0, 0);
    TintOverlayGlowTexture(glow.ProcStartFlipbook, color);
    TintOverlayGlowTexture(glow.ProcLoopFlipbook, color);
    TintOverlayGlowTexture(glow.ProcAltGlow, color);
    glow:SetScript("OnHide", StopOverlayGlow);
    glow:Hide();
    return glow;
end

addon.ShowOverlayGlow = function (button)
    if not button.SpellActivationAlert then
        return;
    end

    if not button.SpellActivationAlert:IsShown() then
        button.SpellActivationAlert:Show();
        if button.SpellActivationAlert.skipBirth then
            button.SpellActivationAlert.ProcLoop:Play();
        else
            button.SpellActivationAlert.ProcStartAnim:Play();
        end
    end
end

addon.HideOverlayGlow = function (button)
    if not button.SpellActivationAlert then
        return;
    end

    button.SpellActivationAlert:Hide();
    button.SpellActivationAlert.ProcStartAnim:Stop();
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

local function EnsureProcGlow(frame)
    if frame.procGlow then return frame.procGlow end

    local glow = CreateFrame("Frame", nil, frame);
    glow:SetFrameLevel(frame:GetFrameLevel() + 8);
    glow.texture = glow:CreateTexture(nil, "ARTWORK");
    glow.texture:SetAllPoints(glow);
    glow.texture:SetAtlas("UI-HUD-ActionBar-Proc-Loop-Flipbook");
    glow.texture:SetBlendMode("ADD");

    glow.animation = glow:CreateAnimationGroup();
    glow.animation:SetLooping("REPEAT");
    glow.animation:SetToFinalAlpha(true);

    local alpha = glow.animation:CreateAnimation("Alpha");
    alpha:SetChildKey("texture");
    alpha:SetFromAlpha(1);
    alpha:SetToAlpha(1);
    alpha:SetDuration(0.001);
    alpha:SetOrder(0);

    local flipbook = glow.animation:CreateAnimation("FlipBook");
    flipbook:SetChildKey("texture");
    flipbook:SetDuration(1);
    flipbook:SetOrder(0);
    flipbook:SetFlipBookRows(6);
    flipbook:SetFlipBookColumns(5);
    flipbook:SetFlipBookFrames(30);
    flipbook:SetFlipBookFrameWidth(0);
    flipbook:SetFlipBookFrameHeight(0);

    glow:SetScript("OnHide", function (self)
        self.animation:Stop();
    end);
    glow:Hide();
    frame.procGlow = glow;
    return glow;
end

addon.HideProcGlow = function (frame)
    if frame.procGlow then
        frame.procGlow.animation:Stop();
        frame.procGlow:Hide();
    end
end

addon.ShowProcGlow = function (frame, color)
    local glow = EnsureProcGlow(frame);
    addon.HideProcGlow(frame);

    glow:SetFrameLevel(frame:GetFrameLevel() + 8);
    glow:ClearAllPoints();
    glow:SetPoint("TOPLEFT", frame, "TOPLEFT", -frame:GetWidth() * 0.2, frame:GetHeight() * 0.2);
    glow:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", frame:GetWidth() * 0.2, -frame:GetHeight() * 0.2);

    if color then
        glow.texture:SetDesaturated(true);
        glow.texture:SetVertexColor(color[1], color[2], color[3], color[4]);
    else
        glow.texture:SetDesaturated(false);
        glow.texture:SetVertexColor(1, 1, 1, 1);
    end

    glow:Show();
    glow.texture:Show();
    glow.animation:Play();
end
