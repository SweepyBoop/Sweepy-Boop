local _, addon = ...;

local function EnsureIndicator(frame)
    if not frame.rangeIndicator then
        frame.rangeIndicator = CreateFrame("Frame", nil, frame);
        frame.rangeIndicator:SetSize(32, 32);
        frame.rangeIndicator:SetPoint("CENTER", frame, "CENTER");
        frame.rangeIndicator:SetMouseClickEnabled(false);

        frame.rangeIndicator.tex = frame.rangeIndicator:CreateTexture(nil, "OVERLAY");
        frame.rangeIndicator.tex:SetAllPoints();
        frame.rangeIndicator.tex:SetAtlas("CircleMaskScalable");
        frame.rangeIndicator.tex:SetVertexColor(0, 1, 0); -- Green

        frame.rangeIndicator:Hide();
    end
end

local function ShowIndicator(frame)
    EnsureIndicator(frame);
    frame.rangeIndicator:Show();
end

local function HideIndicator(frame)
    if frame.rangeIndicator then
        frame.rangeIndicator:Hide();
    end
end

local arenaFramePrefix = ( GladiusEx and "GladiusExButtonFramearena" ) or ( Gladius and "GladiusButtonFramearena" ) or ( sArena and "sArenaEnemyFrame" ) or "CompactArenaFrameMember";
local function UpdateIndicators()
    for i = 1, addon.MAX_ARENA_SIZE do
        local frame = _G[arenaFramePrefix .. i];
        if frame and frame:IsShown() then
            EnsureIndicator(frame);
        end
    end
end