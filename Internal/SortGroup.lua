-- https://www.curseforge.com/wow/addons/sortgroup
-- https://github.com/Verubato/frame-sort/blob/main
local sortGroupFilter = {"party1", "player", "party2", "party3", "party4"};
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
sortFrame:SetScript("OnEvent", TryApplyFilter);