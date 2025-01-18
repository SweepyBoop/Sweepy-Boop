local _, addon = ...;

-- IMPORTANT!!!
-- Make sure you disable Interface -> Raid Profiles -> "Display Aggro Highlight", and do a /reload
-- If that option is enabled, the following code will not run so we don't mess with the Blizzard PVE aggro

local R, G, B = GetThreatStatusColor(3); -- Red

local function GetThreatCount(unit)
    if ( not unit ) then return end
    if ( not IsActiveBattlefieldArena() ) and ( not addon.TEST_MODE ) then return end

    if addon.TEST_MODE then
        return UnitIsUnit(unit, "target");
    else
        local count = 0;

        for i = 1, addon.MAX_ARENA_SIZE do
            if UnitIsUnit(unit, "arena" .. i .. "target") then
                count = count + 1;
                if ( count > 1 ) then
                    return true; -- red when unit is being targeted by more than one enemy players
                end
            end
        end
    end
end

function SweepyBoop:SetupRaidFrameAggroHighlight()
    hooksecurefunc("CompactUnitFrame_UpdateName", function (frame)
        if frame:IsForbidden() then return end
        if ( frame.isParentCompactPartyFrame == nil ) then
            frame.isParentCompactPartyFrame = ( frame:GetParent() == CompactPartyFrame );
        end
        if ( not frame.isParentCompactPartyFrame ) then return end
        if ( not self.db.profile.raidFrames.raidFrameAggroHighlightEnabled ) then return end -- If feature disabled
        if frame.optionTable.displayAggroHighlight then return end -- Don't overwrite PvE threats

        if GetThreatCount(frame.unit) then
            frame.aggroHighlight:SetVertexColor(R, G, B);
            frame.aggroHighlight:Show();
        else
            frame.aggroHighlight:Hide();
        end
    end)
end
