SetCVar("cameraDistanceMaxZoomFactor", 2.6)
SetCVar("weatherDensity", 0)

-- Hide target & focus cast bars (duplicate info with sArena cast bars)
TargetFrameSpellBar:UnregisterAllEvents()
FocusFrameSpellBar:UnregisterAllEvents()

-- Hide focus frame
FocusFrame:SetAlpha(0)

-- Setting CRFSort_Group blocks the action bars when switching map
-- Easily repro when pressing a-S, something about ForceTaint_Strong
local CFRSort_PlayerMiddle = function(t1, t2)
    if (not UnitExists(t1)) then
        return false
    elseif (not UnitExists(t2)) then
        return true
    elseif UnitIsUnit(t1, "party1") then
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

-- https://www.curseforge.com/wow/addons/sortgroup

hooksecurefunc("CompactPartyFrame_SetFlowSortFunction", function (...)
    if not CompactPartyFrame then
		return;
	end

    CompactPartyFrame.flowSortFunc = CFRSort_PlayerMiddle;
	CompactPartyFrame_RefreshMembers();
end)



-- Move arena scoreboard on screen top
UIWidgetTopCenterContainerFrame:ClearAllPoints()
UIWidgetTopCenterContainerFrame:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", 0, -25)
UIWidgetTopCenterContainerFrame.SetPoint = function() end

ArenaEnemyMatchFrame1PetFrame:SetAlpha(0)
ArenaEnemyMatchFrame2PetFrame:SetAlpha(0)
ArenaEnemyMatchFrame3PetFrame:SetAlpha(0)

StatusTrackingBarManager:Hide()

-- Hide group indicator
hooksecurefunc("PlayerFrame_UpdateGroupIndicator", function ()
    local groupIndicator = PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.GroupIndicator
    if GetNumGroupMembers() <= 5 then
        groupIndicator:Hide()
    end
end)

-- Hide group leader icon
hooksecurefunc("PlayerFrame_UpdatePartyLeader", function ()
    local playerFrameTargetContextual = PlayerFrame_GetPlayerFrameContentContextual()
    playerFrameTargetContextual.LeaderIcon:Hide()
    playerFrameTargetContextual.GuideIcon:Hide()
end)