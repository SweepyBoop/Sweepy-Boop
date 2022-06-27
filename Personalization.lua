-- Spell queue window: 100 + latency
-- Check spell queue window: /dump GetCVar("SpellQueueWindow")
-- Change spell queue window: /console SpellQueueWindow 120

-- Purpose of this is to move things closer together to the center, so you don't have to peek the corners of your screen (https://www.youtube.com/watch?v=nIiRSq-9on8&ab_channel=SkillCappedWoWGuides)
-- The following setup targets 27inch monitor with 90% UI scale
PlayerFrame:ClearAllPoints();
PlayerFrame:SetPoint("LEFT", CompactRaidFrameManager, "TOPRIGHT", 175, 0);
PlayerFrame:SetUserPlaced(true);

TargetFrame:ClearAllPoints();
TargetFrame:SetPoint("LEFT", PlayerFrame, "RIGHT", 0, 0);
TargetFrame:SetUserPlaced(true);

FocusFrame:ClearAllPoints();
FocusFrame:SetPoint("LEFT", PlayerFrame, "RIGHT", 0, -385);
FocusFrame:SetUserPlaced(true);



--LossOfControlFrame.blackBg:SetAlpha(0)
--LossOfControlFrame.RedLineTop:SetAlpha(0)
--LossOfControlFrame.RedLineBottom:SetAlpha(0)



local function UpdateCVars(self, event)
    SetCVar("autoLootDefault", 1);
    SetCVar("lossOfControl", 0);
    SetCVar("useCompactPartyFrames", 1);

    SetCVar("cameraDistanceMaxZoomFactor", 2.6);
    SetCVar("weatherDensity", 0);
end
local setCVarFrame = CreateFrame("Frame")
setCVarFrame:RegisterEvent("PLAYER_LOGIN")
setCVarFrame:SetScript("OnEvent", UpdateCVars)



-- Hide target & focus cast bars (duplicate info with sArena cast bars)
TargetFrameSpellBar:UnregisterAllEvents();
FocusFrameSpellBar:UnregisterAllEvents();

-- Hide focus frame target of target (takes some space of Omnibar icons)
FocusFrameToT:SetAlpha(0);

-- Move & scale frames
PaladinPowerBarFrame:SetScale(1.25);

BuffFrame:SetScale(1.1);

-- Hide unnecessary frames
TargetFrameTextureFramePVPIcon:SetAlpha(0)
TargetFrameTextureFramePrestigeBadge:SetAlpha(0)
TargetFrameTextureFramePrestigePortrait:SetAlpha(0)
FocusFrameTextureFramePVPIcon:SetAlpha(0)
FocusFrameTextureFramePrestigeBadge:SetAlpha(0)
FocusFrameTextureFramePrestigePortrait:SetAlpha(0)
ActionBarUpButton:Hide()
ActionBarDownButton:Hide()
MainMenuBarArtFrameBackground:Hide()
MainMenuBarArtFrame.LeftEndCap:Hide()
MainMenuBarArtFrame.RightEndCap:Hide()
MainMenuBarArtFrame.PageNumber:Hide()



-- When in arena, hover over a frame in combat seems to give LUA errors (fixed by addon "Blizzard Raid Frames Fix")
-- Order goes party1 -> player -> party2
-- Make sure to sort by group

LoadAddOn("Blizzard_CompactRaidFrames") 

CRFSort_Group=function(t1, t2) 
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
CompactRaidFrameContainer.flowSortFunc=CRFSort_Group



-- Hide party names in raid frames
hooksecurefunc("CompactUnitFrame_UpdateName",function(frame)
    if (IsActiveBattlefieldArena()) then
        if frame.unit and (UnitIsUnit(frame.unit, "player") or UnitIsUnit(frame.unit, "party1") or UnitIsUnit(frame.unit, "party2")) then
            frame.name:SetText("");
        end
    end
end)
