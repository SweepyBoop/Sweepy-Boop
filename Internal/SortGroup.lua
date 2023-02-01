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

local function Compare(left, right)
    local leftToken, rightToken = left.unit, right.unit;

    if ( not leftToken ) then return false
    elseif ( not rightToken ) then return true
    elseif ( leftToken == "party1" ) then return true
    elseif ( rightToken == "party1" ) then return false
    elseif ( leftToken == "player" ) then return true
    elseif ( rightToken == "player" ) then return false
    else
        return leftToken < rightToken;
    end
end

local function GetPartyUnitId(unitId)
    if UnitIsUnit(unitId, "player") then
        return "player";
    else
        for i = 1, (MEMBERS_PER_RAID_GROUP - 1) do
            if UnitIsUnit(unitId, "party" .. i) then
                return "party" .. i;
            end
        end
    end
end

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
            frames[i] = { unit = GetPartyUnitId(frame.unit), frame = frame };
        end

        table.sort(frames, Compare);

        local prevFrame;
        for _, value in ipairs(frames) do
            local frame = value.frame;
            frame:ClearAllPoints();
            if ( not prevFrame ) then
                frame:SetPoint(topPoints.point, topPoints.relativeTo, topPoints.relativePoint, topPoints.offsetX, topPoints.offsetY);
            else
                frame:SetPoint("TOP", prevFrame, "BOTTOM");
            end

            prevFrame = frame;
        end

        --CompactUnitFrame_SetUnit(CompactPartyFrameMember1, "party1");
        --CompactUnitFrame_SetUnit(CompactPartyFrameMember2, "player");
        --CompactUnitFrame_SetUnit(CompactPartyFrameMember3, "party2");
    end
end

hooksecurefunc("FlowContainer_DoLayout", function (container)
    -- Check container is CompactPartyFrame?
    --print(container:GetName())

    if container.flowPauseUpdates or ( not CompactPartyFrame ) or CompactPartyFrame:IsForbidden() then
		return;
	end

    print(container:GetName())

    -- nothing to sort if we're not in a group
    --if not IsInGroup() then return end
    -- don't try if edit mode is active
    if EditModeManagerFrame.editModeActive then return end

    local numGroupMembers = GetNumGroupMembers();
    if ( numGroupMembers <= MEMBERS_PER_RAID_GROUP ) then
        TrySort();
    end
end)

--[[ hooksecurefunc(CompactRaidFrameContainer, "AddGroups", function ()
    print("AddGroups");

    if ( not CompactPartyFrame ) or CompactPartyFrame:IsForbidden() then
		return;
	end

    -- nothing to sort if we're not in a group
    --if not IsInGroup() then return end
    -- don't try if edit mode is active
    if EditModeManagerFrame.editModeActive then return end

    local numGroupMembers = GetNumGroupMembers();
    if ( numGroupMembers <= MEMBERS_PER_RAID_GROUP ) then
        TrySort();
    end
end)

hooksecurefunc(CompactRaidFrameContainer, "LayoutFrames", function ()
    print("LayoutFrames");

    if ( not CompactPartyFrame ) or CompactPartyFrame:IsForbidden() then
		return;
	end

    -- nothing to sort if we're not in a group
    --if not IsInGroup() then return end
    -- don't try if edit mode is active
    if EditModeManagerFrame.editModeActive then return end

    local numGroupMembers = GetNumGroupMembers();
    if ( numGroupMembers <= MEMBERS_PER_RAID_GROUP ) then
        TrySort();
    end
end) ]]

-- Possibly only need to hook CompactRaidFrameContainerMixin:LayoutFrames