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

local function ApplySort()
    --combat status check
    if not InCombatLockdown() then
        if IsInGroup() and GetNumGroupMembers() <= 5 and HasLoadedCUFProfiles() then
            CompactPartyFrame_SetFlowSortFunction(CFRSort_PlayerMiddle)
        end
    end
end

local Main_Frame = CreateFrame('Frame', 'MainPanel', InterfaceOptionsFramePanelContainer)
Main_Frame:RegisterEvent('GROUP_ROSTER_UPDATE')
Main_Frame:RegisterEvent('PLAYER_ENTERING_WORLD')
Main_Frame:SetScript('OnEvent',
    function(self, event, ...)
        if event == 'GROUP_ROSTER_UPDATE' then
            ApplySort()
        elseif event == 'PLAYER_ENTERING_WORLD' and HasLoadedCUFProfiles() then
            ApplySort()
        end
    end)

UIWidgetTopCenterContainerFrame:ClearAllPoints()
UIWidgetTopCenterContainerFrame:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", 0, -25)
UIWidgetTopCenterContainerFrame.SetPoint = function() end


