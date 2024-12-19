local _, addon = ...;

-- IMPORTANT!!!
-- Make sure you disable Interface -> Raid Profiles -> "Display Aggro Highlight", and do a /reload
-- If that option is enabled, the following code will not run so we don't mess with the Blizzard PVE aggro

-- Test mode: target a raid frame and check if the aggro highlight is showing up
local isTestMode = addon.isTestMode;

local orange = GetThreatStatusColor(2);
local red = GetThreatStatusColor(3);

local function ShouldShowAggro(unit)
    if ( not unit ) then
        return nil;
    end

    local arena = IsActiveBattlefieldArena();
    if ( not arena ) and ( not isTestMode ) then
        return nil;
    end

    if isTestMode then
        return ( UnitIsUnit(unit, "target") and orange );
    else
        local count = 0;
        for i = 1, addon.MAX_ARENA_SIZE do
            if UnitIsUnit(unit, "arena" .. i .. "target") then
                count = count + 1;
            end
        end
        if ( count > 1 ) then
            return red;
        elseif ( count == 1 ) then
            return orange;
        end
    end
end

function SweepyBoop:SetupRaidFrameAggroHighlight()
    if self.db.profile.raidFrameAggroHighlightEnabled then
        hooksecurefunc("CompactUnitFrame_UpdateName", function (frame)
            if ( not frame ) or frame:IsForbidden() then
                return;
            end

            if ( frame:GetParent() ~= CompactPartyFrame ) then
                return;
            end

            if frame.optionTable.displayAggroHighlight then
                return;
            end

            local shouldShow = ShouldShowAggro(frame.unit);
            if shouldShow then
                frame.aggroHighlight:SetVertexColor(shouldShow);
                frame.aggroHighlight:Show();
            else
                frame.aggroHighlight:Hide();
            end
        end)
    end
end
