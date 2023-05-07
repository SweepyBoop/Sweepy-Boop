-- https://www.curseforge.com/wow/addons/sortgroup
-- https://github.com/Verubato/frame-sort

-- Tried both ways, still getting taint when players join/leave, or pet dies during combat

-- Try leveraging SetPoint to modify the positions of CompactPartyFrames

local _, NS = ...;

local UnitIsUnit = UnitIsUnit;
local MEMBERS_PER_RAID_GROUP = MEMBERS_PER_RAID_GROUP;
local InCombatLockdown = InCombatLockdown;
local C_Timer = C_Timer;
local CompactPartyFrame = CompactPartyFrame;
local CompactPartyFrameTitle = CompactPartyFrameTitle;
local hooksecurefunc = hooksecurefunc;
local EditModeManagerFrame = EditModeManagerFrame;
local GetNumGroupMembers = GetNumGroupMembers;
local IsInGroup = IsInGroup;

local function Compare(left, right)
    local leftToken, rightToken = left.unit, right.unit;

    if ( leftToken == "party1" ) then return true
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
        C_Timer.After(1, TrySort);
    else
        local frames = {};
        for i = 1, MEMBERS_PER_RAID_GROUP do
            local frame = _G["CompactPartyFrameMember"..i];
            local unit = GetPartyUnitId(frame.unit);
            frames[i] = { unit = unit, frame = frame };
        end

        table.sort(frames, Compare);

        local prevFrame;
        for _, value in ipairs(frames) do
            --print(value.unit, value.frame:GetName());

            local frame = value.frame;
            frame:ClearAllPoints();
            if ( not prevFrame ) then
                frame:SetPoint("TOP", CompactPartyFrameTitle, "BOTTOM");
            else
                frame:SetPoint("TOP", prevFrame, "BOTTOM");
            end

            prevFrame = frame;
        end
        --print("\n");
    end
end

hooksecurefunc("CompactRaidGroup_UpdateLayout", function (frame)
    -- This will likely reset the positions of compact party frames
    if ( frame == CompactPartyFrame ) then
        TrySort();
    end
end)
