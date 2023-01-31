local function EnsureCustomCompactPartyFrame()
    local frame = CustomCompactPartyFrame;
    if not frame then
        frame = CreateFrame("Frame", "CustomCompactPartyFrame", PartyFrame, "CustomCompactPartyFrameTemplate");
        CompactRaidGroup_UpdateBorder(frame);
        PartyFrame:UpdatePaddingAndLayout();
        frame:RegisterEvent("GROUP_ROSTER_UPDATE");
    end
end

function CustomCompactPartyFrame_OnLoad(self)
    self.applyFunc = CompactRaidGroup_ApplyFunctionToAllFrames;
    self.isParty = true;

    for i=1, MEMBERS_PER_RAID_GROUP do
        local unitFrame = _G["CustomCompactPartyFrameMember"..i];
        unitFrame.isParty = true;
    end
    
    CustomCompactPartyFrame_RefreshMembers();
    
    self.title:SetText("Custom " .. PARTY);
    self.title:Disable();
end

hooksecurefunc("CompactPartyFrame_UpdateVisibility", function ()
    if ( not CompactPartyFrame ) then
        return;
    end

    EnsureCustomCompactPartyFrame();
    
    local isInArena = IsActiveBattlefieldArena();
    local groupFramesShown = (IsInGroup() and (isInArena or not IsInRaid())) or EditModeManagerFrame:ArePartyFramesForcedShown();
    local showCompactPartyFrame = groupFramesShown and EditModeManagerFrame:UseRaidStylePartyFrames();
    local editModeActive = EditModeManagerFrame.editModeActive;

    -- Only show the original in edit mode
    CompactPartyFrame:SetShown(groupFramesShown and editModeActive);

    -- Show custom when not in edit mode
    CustomCompactPartyFrame:SetShown(showCompactPartyFrame and ( not editModeActive));

    PartyFrame:UpdatePaddingAndLayout();
end)

function CustomCompactPartyFrame_RefreshMembers()
    if not CompactPartyFrame then
        return;
    end

    EnsureCustomCompactPartyFrame();

    local units = {};

    table.insert(units, "party1");
    table.insert(units, "player");
    for i=3, MEMBERS_PER_RAID_GROUP do
        table.insert(units, "party"..(i-1));
    end

    for index, realPartyMemberToken in ipairs(units) do
        local unitFrame = _G["CustomCompactPartyFrameMember"..index];

        local usePlayerOverride = EditModeManagerFrame:ArePartyFramesForcedShown() and not UnitExists(realPartyMemberToken);
        local unitToken = usePlayerOverride and "player" or realPartyMemberToken;

        CompactUnitFrame_SetUnit(unitFrame, unitToken);
        CompactUnitFrame_SetUpFrame(unitFrame, DefaultCompactUnitFrameSetup); -- Where is the size for the frame set?
        CompactUnitFrame_SetUpdateAllEvent(unitFrame, "GROUP_ROSTER_UPDATE");
    end

    CompactRaidGroup_UpdateBorder(CustomCompactPartyFrame);
    PartyFrame:UpdatePaddingAndLayout();
end

hooksecurefunc("CompactPartyFrame_SetFlowSortFunction", function()
    if not CompactPartyFrame then
        return;
    end

    EnsureCustomCompactPartyFrame();
    CustomCompactPartyFrame_RefreshMembers();
end)

hooksecurefunc("CompactPartyFrame_Generate", function ()
    EnsureCustomCompactPartyFrame();
end)
