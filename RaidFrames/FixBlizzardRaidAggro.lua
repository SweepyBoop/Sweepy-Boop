local _, addon = ...;

-- IMPORTANT!!!
-- Make sure you disable Interface -> Raid Profiles -> "Display Aggro Highlight", and do a /reload
-- If that option is enabled, the following code will not run so we don't mess with the Blizzard PVE aggro

local throttle = 0.01;
local scale = 1.4 * 0.85;

local function GetThreatCount(unit)
    local count = 0;

    if ( not unit ) then return count end

    -- Comment out for retail release
    -- if addon.TEST_MODE then
    --     count = UnitIsUnit(unit, "target") and 2 or 0;
    --     return count;
    -- end

    for i = 1, addon.MAX_ARENA_SIZE do
        if UnitIsUnit(unit, "arena" .. i .. "target") then
            count = count + 1;
            if ( count > 1 ) then
                return count;
            end
        end
    end

    return count;
end

local function ShowCustomAggroHighlight(frame)
    if not frame.customAggroHighlight then
        local customAggroHighlight = CreateFrame("Frame", nil, frame);
        customAggroHighlight:SetAllPoints();

        customAggroHighlight.ants = customAggroHighlight:CreateTexture(nil, "OVERLAY");
        customAggroHighlight.ants:SetPoint("CENTER");
        customAggroHighlight.ants:SetTexture([[Interface\SpellActivationOverlay\IconAlertAnts]]);

        customAggroHighlight:SetScript("OnUpdate", function (self, elapsed)
            AnimateTexCoords(self.ants, 256, 256, 48, 48, 22, elapsed, throttle);
        end)
        customAggroHighlight:Hide();

        frame.customAggroHighlight = customAggroHighlight;
    end

    frame.customAggroHighlight.ants:SetSize(frame:GetWidth() * scale, frame:GetHeight() * scale);
    frame.customAggroHighlight:Show();
end

local function ShowCustomAggroHighlightPurple(frame)
    if not frame.customAggroHighlightPurple then
        local customAggroHighlight = CreateFrame("Frame", nil, frame);
        customAggroHighlight:SetAllPoints();

        customAggroHighlight.ants = customAggroHighlight:CreateTexture(nil, "OVERLAY");
        customAggroHighlight.ants:SetPoint("CENTER");
        customAggroHighlight.ants:SetTexture([[Interface\Transmogrify\PurpleIconAlertAnts]]);

        customAggroHighlight:SetScript("OnUpdate", function (self, elapsed)
            AnimateTexCoords(self.ants, 256, 256, 48, 48, 22, elapsed, throttle);
        end)
        customAggroHighlight:Hide();

        frame.customAggroHighlightPurple = customAggroHighlight;
    end

    frame.customAggroHighlightPurple.ants:SetSize(frame:GetWidth() * scale, frame:GetHeight() * scale);
    frame.customAggroHighlightPurple:Show();
end

local function HideCustomAggroHighlight(frame)
    if frame.customAggroHighlight then
        frame.customAggroHighlight:Hide();
    end
end

local function HideCustomAggroHighlightPurple(frame)
    if frame.customAggroHighlightPurple then
        frame.customAggroHighlightPurple:Hide();
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
            HideCustomAggroHighlightPurple(frame);

            return;
        end

        -- Comment out when testing
        if ( not IsActiveBattlefieldArena() ) then
            if frame.aggroHighlight then
                frame.aggroHighlight:SetAlpha(1);
            end
            HideCustomAggroHighlight(frame);
            HideCustomAggroHighlightPurple(frame);

            return;
        end

        local threatCount = GetThreatCount(frame.unit);

        if threatCount > 1 then
            HideCustomAggroHighlight(frame);
            ShowCustomAggroHighlightPurple(frame);
        elseif threatCount > 0 then
            HideCustomAggroHighlightPurple(frame);
            ShowCustomAggroHighlight(frame);
        else
            HideCustomAggroHighlight(frame);
            HideCustomAggroHighlightPurple(frame);
        end
    end)
end
