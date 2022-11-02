SetCVar("cameraDistanceMaxZoomFactor", 2.6);
SetCVar("weatherDensity", 0);

-- Hide target & focus cast bars (duplicate info with sArena cast bars)
TargetFrameSpellBar:UnregisterAllEvents();
FocusFrameSpellBar:UnregisterAllEvents();

-- Hide focus frame
FocusFrame:SetAlpha(0);

-- Setting CRFSort_Group blocks the action bars when switching map
-- Easily repro when pressing a-S
local sortFunc = function(t1, t2)
    if UnitIsUnit(t1, "party1") then
        return true
    elseif UnitIsUnit(t2, "party1") then
        return false
    elseif UnitIsUnit(t1,"player") then 
        return true 
    elseif UnitIsUnit(t2,"player") then 
        return false
    else 
        return t1 < t2 
    end
end

hooksecurefunc("CompactPartyFrame_SetFlowSortFunction", function(flowSortFunc)
	if not CompactPartyFrame then
		return;
	end
	CompactPartyFrame.flowSortFunc = sortFunc;
	CompactPartyFrame_RefreshMembers();
end)

hooksecurefunc("CompactPartyFrame_Generate", function()
	local frame = CompactPartyFrame;
	if frame then
		frame.flowSortFunc = sortFunc;
    end
end)
