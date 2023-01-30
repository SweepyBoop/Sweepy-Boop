-- https://www.curseforge.com/wow/addons/sortgroup
-- https://github.com/Verubato/frame-sort/tree/main/src

local function Compare(leftToken, rightToken)
    if not UnitExists(leftToken) then return false
    elseif not UnitExists(rightToken) then return true
    elseif UnitIsUnit(leftToken, "party1") then return true
    elseif UnitIsUnit(rightToken, "party1") then return false
    elseif UnitIsUnit(leftToken, "player") then return true
    elseif UnitIsUnit(rightToken, "player") then return false
    else
        return leftToken < rightToken;
    end
end

local function TrySort()
    -- nothing to sort if we're not in a group
    if not IsInGroup() then return false end
    -- can't make changes during combat
    if InCombatLockdown() then return false end
    -- don't try if edit mode is active
    if EditModeManagerFrame.editModeActive then return false end

    local maxPartySize = 5;
    local groupSize = GetNumGroupMembers();

    if groupSize <= maxPartySize then
        if CompactPartyFrame:IsForbidden() then return false end

        CompactPartyFrame_SetFlowSortFunction(Compare);
        -- immediately after sorting, unset the sort function
        -- this might help with avoiding taint issues
        -- but shouldn't be necessary and can be removed once blizzard fix their side
        CompactPartyFrame.flowSortFunc = nil;
    end
end

local sortFrame = CreateFrame("Frame");
sortFrame:RegisterEvent("GROUP_ROSTER_UPDATE");
sortFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
-- Fired after ending combat, as regen rates return to normal.
-- Useful for determining when a player has left combat.
-- This occurs when you are not on the hate list of any NPC, or a few seconds after the latest pvp attack that you were involved with.
sortFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
sortFrame:SetScript("OnEvent", TrySort);
