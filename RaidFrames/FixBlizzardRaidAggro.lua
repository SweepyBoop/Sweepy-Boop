local _, addon = ...;

local LCG = LibStub("LibCustomGlow-1.0");

local threatColors = {
    [1] = {1, 1, 0, 0.5}, -- yellow
    [2] = {1, 0.5, 0, 0.5}, -- orange
    [3] = {1, 0, 0, 0.5}, -- red
};

local function GetThreatCount(unit)
    local count = 0;

    if ( not unit ) then return count end

    -- Comment out for retail release
    -- if addon.TEST_MODE then
    --     count = UnitIsUnit(unit, "focus") and 2 or 0;
    --     return count;
    -- end

    for i = 1, addon.MAX_ARENA_SIZE do
        if UnitIsUnit(unit, "arena" .. i .. "target") then
            count = count + 1;
        end
    end

    return count;
end

local function ShowCustomAggroHighlight(frame, threatCount)
    if not frame.customAggroHighlight then
        local customAggroHighlight = CreateFrame("Frame", nil, frame);
        customAggroHighlight:SetAllPoints();
        frame.customAggroHighlight = customAggroHighlight;
    end

    local thickness = SweepyBoop.db.profile.raidFrames.raidFrameAggroHighlightThickness;
    local speed = SweepyBoop.db.profile.raidFrames.raidFrameAggroHighlightAnimationSpeed;
    if speed == 0 then
        speed = 1e-10; -- Set to a very small frequency, essentially no animation
    end

    LCG.PixelGlow_Start(
        frame.customAggroHighlight, -- frame
        threatColors[threatCount], -- color
        16, -- number of frames
        0.025 * speed, -- frequency (default is 0.25)
        nil, -- actions.glow_length,
        thickness, -- actions.glow_thickness,
        nil, -- actions.glow_XOffset,
        nil, -- actions.glow_YOffset,
        false -- actions.glow_border and true or false,
        -- id
    );
end

local function HideCustomAggroHighlight(frame)
    if frame.customAggroHighlight then
        LCG.PixelGlow_Stop(frame.customAggroHighlight);
    end
end

function SweepyBoop:SetupRaidFrameAggroHighlight()
    hooksecurefunc("CompactUnitFrame_UpdateName", function (frame)
        if frame:IsForbidden() then return end
        if ( frame.isParentCompactPartyFrame == nil ) then
            frame.isParentCompactPartyFrame = ( frame:GetParent() == CompactPartyFrame );
        end
        if ( not frame.isParentCompactPartyFrame ) then return end
        if ( not self.db.profile.raidFrames.raidFrameAggroHighlightEnabled ) then -- If feature disabled
            if frame.aggroHighlight then
                frame.aggroHighlight:SetAlpha(1);
            end
            HideCustomAggroHighlight(frame);

            return;
        end

        -- Comment out when testing
        if ( not IsActiveBattlefieldArena() ) then
            if frame.aggroHighlight then
                frame.aggroHighlight:SetAlpha(1);
            end
            HideCustomAggroHighlight(frame);

            return;
        end

        if frame.aggroHighlight then
            frame.aggroHighlight:SetAlpha(0);
        end
        local threatCount = GetThreatCount(frame.unit);

        if threatCount > 0 then
            ShowCustomAggroHighlight(frame, threatCount);
        else
            HideCustomAggroHighlight(frame);
        end
    end)
end
