local addonName, NS = ...;

local CreateFrame = CreateFrame;
local RAID_CLASS_COLORS = RAID_CLASS_COLORS;
local UnitClass = UnitClass;
local UnitIsPlayer = UnitIsPlayer;
local UnitExists = UnitExists;
local TargetFrame = TargetFrame;
local PlayerFrame = PlayerFrame;
local TargetFrameToT = TargetFrameToT;

local frame = CreateFrame("FRAME");
frame:RegisterEvent("GROUP_ROSTER_UPDATE");
frame:RegisterEvent("PLAYER_TARGET_CHANGED");
frame:RegisterEvent("UNIT_FACTION");
frame:RegisterEvent("ADDON_LOADED");

local function Player_CheckColor(unit)
    return RAID_CLASS_COLORS[select(2, UnitClass(unit))];
end

local function UnitFrameLoad()
    if UnitExists("target") then
        local targetColors = UnitIsPlayer("target") and Player_CheckColor("target");

        if targetColors then
            TargetFrame.TargetFrameContent.TargetFrameContentMain.HealthBar:SetStatusBarDesaturated(true);
            TargetFrame.TargetFrameContent.TargetFrameContentMain.HealthBar:SetStatusBarColor(targetColors.r, targetColors.g, targetColors.b);
            TargetFrame.TargetFrameContent.TargetFrameContentMain.HealthBar.lockColor = true;
        else
            TargetFrame.TargetFrameContent.TargetFrameContentMain.HealthBar:SetStatusBarColor(0, 1, 0);
        end
    end

    if UnitExists("targettarget") then
        local totColors = UnitIsPlayer("targettarget") and Player_CheckColor("targettarget");

        if totColors then
            TargetFrameToT.HealthBar:SetStatusBarDesaturated(true);
            TargetFrameToT.HealthBar:SetStatusBarColor(totColors.r, totColors.g, totColors.b);
            TargetFrameToT.HealthBar.lockColor = true;
        else
            TargetFrameToT.HealthBar:SetStatusBarColor(0, 1, 0);
        end
    end
end

local function PlayerFrameLoad()
    local colors = RAID_CLASS_COLORS[select(2, UnitClass("player"))];
    PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.HealthBar:SetStatusBarDesaturated(true);
    PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.HealthBar:SetStatusBarColor(colors.r, colors.g, colors.b);
end

local function eventHandler(self, event, arg1, ...)
    if event == "ADDON_LOADED" and ( arg1 == addonName ) then
        PlayerFrameLoad();
        -- Remove target frame name background
        TargetFrame.TargetFrameContent.TargetFrameContentMain.ReputationColor:SetTexture(nil);
    elseif event ~= "ADDON_LOADED" then
        UnitFrameLoad();
    end
end

frame:SetScript("OnEvent", eventHandler);
