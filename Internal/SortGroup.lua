-- https://www.curseforge.com/wow/addons/sortgroup
-- https://github.com/Verubato/frame-sort

-- Tried both ways, still getting taint when players join/leave, or pet dies during combat

-- Try leveraging SetPoint to modify the positions of CompactPartyFrames

local UnitIsUnit = UnitIsUnit;
local MEMBERS_PER_RAID_GROUP = MEMBERS_PER_RAID_GROUP;
local InCombatLockdown = InCombatLockdown;
local C_Timer = C_Timer;
local CompactPartyFrame = CompactPartyFrame;
local hooksecurefunc = hooksecurefunc;
local EditModeManagerFrame = EditModeManagerFrame;
local GetNumGroupMembers = GetNumGroupMembers;

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

    return unitId;
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
    end
end

-- This function calls FlowContainer_DoLayout, but hooking FlowContainer_DoLayout means our function will get called quite a lot
-- If hooking LayoutFrames is not enough, we might have to hook FlowContainer_DoLayout
--hooksecurefunc(CompactRaidFrameContainer, "LayoutFrames", function ()
hooksecurefunc("FlowContainer_DoLayout", function(container)
    if ( container.flowPauseUpdates ) then
        return;
    end

    if ( not EditModeManagerFrame:UseRaidStylePartyFrames() ) then return end

    if ( not CompactPartyFrame ) or CompactPartyFrame:IsForbidden() then
        return;
    end

    -- Don't try if edit mode is active
    if EditModeManagerFrame.editModeActive then return end

    local numGroupMembers = GetNumGroupMembers();
    if ( numGroupMembers <= MEMBERS_PER_RAID_GROUP ) then
        TrySort();
    end
end)
