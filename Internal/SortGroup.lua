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
            local frame = value.frame;
            frame:ClearAllPoints();
            if ( not prevFrame ) then
                frame:SetPoint("TOP", CompactPartyFrameTitle, "BOTTOM");
            else
                frame:SetPoint("TOP", prevFrame, "BOTTOM");
            end

            prevFrame = frame;
        end
    end
end

hooksecurefunc("CompactRaidGroup_UpdateLayout", function (frame)
    -- This will likely reset the positions of compact party frames
    if ( frame == CompactPartyFrame ) then
        TrySort();
    end
end)

local function PauseUpdates()
    if CompactRaidFrameContainer and not CompactRaidFrameContainer:UnregisterEvent("GROUP_ROSTER_UPDATE") then
        NS:Warning("Failed to unregister event GROUP_ROSTER_UPDATE from CompactRaidFrameContainer.");
    end

    if CompactPartyFrame and not CompactPartyFrame:UnregisterEvent("GROUP_ROSTER_UPDATE") then
        NS:Warning("Failed to register event GROUP_ROSTER_UPDATE from CompactPartyFrame.");
    end
end

local function ResumeUpdates()
    if CompactRaidFrameContainer and not CompactRaidFrameContainer:RegisterEvent("GROUP_ROSTER_UPDATE") then
        NS:Warning("Failed to register event GROUP_ROSTER_UPDATE to CompactRaidFrameContainer.");
    end

    if CompactPartyFrame and not CompactPartyFrame:RegisterEvent("GROUP_ROSTER_UPDATE") then
        NS:Warning("Failed to register event GROUP_ROSTER_UPDATE to CompactPartyFrame.");
    end
end

local function OnEvent(_, event)
    if event == "PLAYER_REGEN_ENABLED" then
        ResumeUpdates();
    elseif event == "PLAYER_REGEN_DISABLED" then
        PauseUpdates();
    elseif "GROUP_ROSTER_UPDATE" and InCombatLockdown() then
        NS:Debug("Blocked raid frame update during combat.");
    end
end

-- Combat blocking: pause updates when entering combat, and resume when leaving combat
local combatBlockingFrame = CreateFrame("Frame");
combatBlockingFrame:HookScript("OnEvent", OnEvent);
combatBlockingFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
combatBlockingFrame:RegisterEvent("PLAYER_REGEN_DISABLED");
combatBlockingFrame:RegisterEvent("GROUP_ROSTER_UPDATE");
