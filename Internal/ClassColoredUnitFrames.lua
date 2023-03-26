local addonName, NS = ...;

local CreateFrame = CreateFrame;
local RAID_CLASS_COLORS = RAID_CLASS_COLORS;
local UnitClass = UnitClass;
local UnitIsPlayer = UnitIsPlayer;
local UnitExists = UnitExists;
local TargetFrame = TargetFrame;
local PlayerFrame = PlayerFrame;

local frame = CreateFrame("FRAME");
frame:RegisterEvent("GROUP_ROSTER_UPDATE");
frame:RegisterEvent("PLAYER_TARGET_CHANGED");
frame:RegisterEvent("UNIT_FACTION");
frame:RegisterEvent("ADDON_LOADED");

local function Player_CheckColor(unit)
    return RAID_CLASS_COLORS[select(2, UnitClass(unit))];
end

local function UnitFrameLoad()
    local targetColors;
    if UnitIsPlayer("target") then
        targetColors = Player_CheckColor("target");
    end

    if UnitExists("target") then
        if targetColors then
            TargetFrame.TargetFrameContent.TargetFrameContentMain.HealthBar:SetStatusBarDesaturated(true);
            TargetFrame.TargetFrameContent.TargetFrameContentMain.HealthBar:SetStatusBarColor(targetColors.r, targetColors.g, targetColors.b);
            TargetFrame.TargetFrameContent.TargetFrameContentMain.HealthBar.lockColor = true;
        else
            TargetFrame.TargetFrameContent.TargetFrameContentMain.HealthBar:SetStatusBarColor(0, 1, 0);
        end
    end
end

local function PlayerFrameLoad()
    local colors = RAID_CLASS_COLORS[select(2, UnitClass("player"))];
    PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarArea.HealthBar:SetStatusBarDesaturated(true);
    PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarArea.HealthBar:SetStatusBarColor(colors.r, colors.g, colors.b);
end

local function eventHandler(self, event, arg1, ...)
    if event == "ADDON_LOADED" and ( arg1 == addonName ) then
        PlayerFrameLoad();
    elseif event ~= "ADDON_LOADED" then
        UnitFrameLoad();
    end
end

frame:SetScript("OnEvent", eventHandler);
