-- https://www.curseforge.com/wow/addons/sortgroup
-- https://github.com/Verubato/frame-sort

-- Tried both ways, still getting taint when players join/leave, or pet dies during combat

--[[ local sortGroupFilter = {"party1", "player", "party2", "party3", "party4"};
local compactPartyFramePrefix = "CompactPartyFrameMember";

local function ApplyFilter()
    if ( not CompactPartyFrame ) or CompactPartyFrame:IsForbidden() then
        print("CompactPartyFrameMember is forbidden")
        return;
    end

    if InCombatLockdown() or ( not IsInGroup() ) or ( GetNumGroupMembers() > 5 ) then
        return;
    end

    local units = {};
    for index, token in ipairs(sortGroupFilter) do
        table.insert(units, token);
    end

    for index, realPartyMemberToken in ipairs(units) do
        local unitFrame = _G[compactPartyFramePrefix .. index];
        CompactUnitFrame_ClearWidgetSet(unitFrame);
        unitFrame:Hide();
        unitFrame.unitExists = false;
    end

    local playerDisplayed = false;
    for index, realPartyMemberToken in ipairs(units) do
        local unitFrame = _G[compactPartyFramePrefix .. index];
        local usePlayerOverride = EditModeManagerFrame:ArePartyFramesForcedShown() and
                                      not UnitExists(realPartyMemberToken);
        local unitToken = usePlayerOverride and "player" or realPartyMemberToken;

        CompactUnitFrame_SetUnit(unitFrame, unitToken);
        CompactUnitFrame_SetUpFrame(unitFrame, DefaultCompactUnitFrameSetup);
        CompactUnitFrame_SetUpdateAllEvent(unitFrame, "GROUP_ROSTER_UPDATE");
    end

    CompactRaidGroup_UpdateBorder(CompactPartyFrame);
    PartyFrame:UpdatePaddingAndLayout();
end

local function TryApplyFilter()
    if ( not EditModeManagerFrame:UseRaidStylePartyFrames() ) or ( not HasLoadedCUFProfiles() ) then
        return;
    end

    if InCombatLockdown() then
        -- If in combat, retry after a few sec
        C_Timer.After(3, TryApplyFilter);
    else
        ApplyFilter();
    end
end

local sortFrame = CreateFrame("Frame");
sortFrame:RegisterEvent("GROUP_ROSTER_UPDATE");
sortFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
sortFrame:SetScript("OnEvent", TryApplyFilter); ]]

-- All we need is when there are <= 3 players, sort by party1, player, party2
-- Try leveraging SetPoint to modify the positions of CompactPartyFrames

local function TrySort()
    if InCombatLockdown() then
        C_Timer.After(3, TrySort);
    else
        local topPoints;
        local frames = {};
        for i = 1, MEMBERS_PER_RAID_GROUP do
            local frame = _G["CompactPartyFrameMember"..i];
            local point, relativeTo, relativePoint, offsetX, offsetY = frame:GetPoint();
            local points = { point = point, relativeTo = relativeTo, relativePoint = relativePoint, offsetX = offsetX, offsetY = offsetY };
            if ( relativeTo == CompactPartyFrame ) then
                topPoints = points;
            end
            frame[i] = { frame.unit, points };
        end

        --[[ for i = 1, 3 do
            local frame = _G["CompactPartyFrameMember"..i];
            local point;
            if frame.unit == "party1" then
                point = points[1];
            elseif frame.unit == "party2" then
                point = points[3];
                point.relativeTo = _G["CompactPartyFrameMember2"];
            elseif frame.unit == "player" then
                point = points[2];
                point.relativeTo = _G["CompactPartyFrameMember1"];
            end
            frame:SetPoint(point.point, point.relativeTo, point.relativePoint, point.offsetX, point.offsetY);
        end ]]

        --CompactUnitFrame_SetUnit(CompactPartyFrameMember1, "party1");
        --CompactUnitFrame_SetUnit(CompactPartyFrameMember2, "player");
        --CompactUnitFrame_SetUnit(CompactPartyFrameMember3, "party2");
    end
end

hooksecurefunc("CompactPartyFrame_RefreshMembers", function ()
    if ( not CompactPartyFrame ) or CompactPartyFrame:IsForbidden() then
		return;
	end

    -- nothing to sort if we're not in a group
    --if not IsInGroup() then return end
    -- don't try if edit mode is active
    if EditModeManagerFrame.editModeActive then return end

    local numGroupMembers = GetNumGroupMembers();
    if ( numGroupMembers <= 3 ) then
        TrySort();
    end
end)
