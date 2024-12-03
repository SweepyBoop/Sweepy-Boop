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
local CompactRaidFrameContainer = CompactRaidFrameContainer;
local hooksecurefunc = hooksecurefunc;
local CreateFrame = CreateFrame;

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

local sortPending = false;

local function TrySort()
    if InCombatLockdown() then
        sortPending = true;
    end

    local frames = {};
    for i = 1, MEMBERS_PER_RAID_GROUP do
        local frame = _G["CompactPartyFrameMember"..i];
        local unit = GetPartyUnitId(frame.unit);
        frames[i] = { unit = unit, frame = frame };
    end

    table.sort(frames, Compare);

    local prevFrame;
    for _, value in ipairs(frames) do
        local frame = value.frame;
        frame:ClearAllPoints();
        if ( not prevFrame ) then
            frame:SetPoint("TOP", CompactPartyFrameTitle, "BOTTOM");
        else
            frame:SetPoint("TOP", prevFrame, "BOTTOM");
        end

        prevFrame = frame;
    end

    sortPending = false;
end

hooksecurefunc("CompactRaidGroup_UpdateLayout", function (frame)
    if ( frame == CompactPartyFrame ) and IsInGroup() and ( not EditModeManagerFrame.editModeActive ) then
        TrySort();
    end
end)

local function RegisterEventEx(frame, event)
    if ( not frame:RegisterEvent(event) ) then
        print("Failed to register event", event, "to", frame:GetName());
    end
end

local function UnregisterEventEx(frame, event)
    if ( not frame:UnregisterEvent(event) ) then
        print("Failed to unregister event", event, "from", frame:GetName());
    end
end

local function PauseUpdates()
    if CompactRaidFrameContainer then
        UnregisterEventEx(CompactRaidFrameContainer, NS.GROUP_ROSTER_UPDATE);
        UnregisterEventEx(CompactRaidFrameContainer, NS.UNIT_PET);
    end

    if CompactPartyFrame then
        UnregisterEventEx(CompactPartyFrame, NS.GROUP_ROSTER_UPDATE);
        UnregisterEventEx(CompactPartyFrame, NS.UNIT_PET);
    end
end

local function ResumeUpdates()
    if CompactRaidFrameContainer then
        RegisterEventEx(CompactRaidFrameContainer, NS.GROUP_ROSTER_UPDATE);
        RegisterEventEx(CompactRaidFrameContainer, NS.UNIT_PET);
    end

    if CompactPartyFrame then
        RegisterEventEx(CompactPartyFrame, NS.GROUP_ROSTER_UPDATE);
        RegisterEventEx(CompactPartyFrame, NS.UNIT_PET);
    end

    if sortPending then
        TrySort();
    end
end

local function OnEvent(_, event)
    if event == "PLAYER_REGEN_ENABLED" then
        ResumeUpdates();
    elseif event == "PLAYER_REGEN_DISABLED" then
        PauseUpdates();
    end
end

-- Combat blocking: pause updates when entering combat, and resume when leaving combat
local combatBlockingFrame = CreateFrame("Frame");
combatBlockingFrame:HookScript("OnEvent", OnEvent);
combatBlockingFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
combatBlockingFrame:RegisterEvent("PLAYER_REGEN_DISABLED");
