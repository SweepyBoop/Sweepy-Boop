local _, addon = ...;

local OriginalParent; -- Only need to set once, I don't think Blizzard changes the parent of CompactArenaFrame
local HiddenFrame = CreateFrame("Frame");
HiddenFrame:Hide(); -- Frame is hidden but still listens to events (different from OnUpdate)

local function UpdateBlizzArenaFrames(hide)
    if hide then
        OriginalParent = OriginalParent or CompactArenaFrame:GetParent();
        CompactArenaFrame:SetParent(HiddenFrame);
    elseif OriginalParent then
        CompactArenaFrame:SetParent(OriginalParent);
    end
end

-- We hide Blizzard arena frames by parenting it to a hidden frame
HiddenFrame:SetScript("OnEvent", function(self, event, ...)
    UpdateBlizzArenaFrames(true);
end);

function SweepyBoop:SetupHideBlizzArenaFrames()
    if SweepyBoop.db.profile.misc.hideBlizzArenaFrames and ( Gladius or GladiusEx or sArena ) then
        HiddenFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD); -- Don't need ZONE_CHANGED_NEW_AREA

        -- According to Blizzard interface code, these are the events that are likely to reshow CompactArenaFrame
        HiddenFrame:RegisterEvent(addon.ARENA_OPPONENT_UPDATE);
        HiddenFrame:RegisterEvent(addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS);
        HiddenFrame:RegisterEvent(addon.PVP_MATCH_STATE_CHANGED);

        UpdateBlizzArenaFrames(true); -- Do one-off hide initially
    else
        HiddenFrame:UnregisterAllEvents();
        UpdateBlizzArenaFrames(false); -- Restore Blizzard arena frames
    end
end
