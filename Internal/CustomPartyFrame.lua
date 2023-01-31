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

hooksecure("CompactPartyFrame_UpdateVisibility", function ()
	if not CustomCompactPartyFrame then
		return;
	end
	
	local isInArena = IsActiveBattlefieldArena();
	local groupFramesShown = (IsInGroup() and (isInArena or not IsInRaid())) or EditModeManagerFrame:ArePartyFramesForcedShown();
	local showCompactPartyFrame = groupFramesShown and EditModeManagerFrame:UseRaidStylePartyFrames();
	CompactPartyFrame:SetShown(not showCompactPartyFrame);
	CustomCompactPartyFrame:SetShown(showCompactPartyFrame);
end)

function CustomCompactPartyFrame_RefreshMembers()
	if not CustomCompactPartyFrame then
		return;
	end

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
		CompactUnitFrame_SetUpFrame(unitFrame, DefaultCompactUnitFrameSetup);
		CompactUnitFrame_SetUpdateAllEvent(unitFrame, "GROUP_ROSTER_UPDATE");
	end

	CompactRaidGroup_UpdateBorder(CustomCompactPartyFrame);
end

hooksecurefunc("CompactPartyFrame_SetFlowSortFunction", function()
	if not CustomCompactPartyFrame then
		return;
	end
	CustomCompactPartyFrame_RefreshMembers();
end)

hooksecurefunc("CompactPartyFrame_Generate", function ()
	local frame = CustomCompactPartyFrame;
	local didCreate = false;
	if not frame then
		frame = CreateFrame("Frame", "CustomCompactPartyFrame", PartyFrame, "CompactPartyFrameTemplate");
		CompactRaidGroup_UpdateBorder(frame);
		frame:RegisterEvent("GROUP_ROSTER_UPDATE");
		didCreate = true;
	end
	return frame, didCreate;
end)
