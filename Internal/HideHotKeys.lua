local _, addon = ...;

local IsActionInRange = IsActionInRange;
local RANGE_INDICATOR = RANGE_INDICATOR;
local SlashCmdList = SlashCmdList;
local CreateFrame = CreateFrame;

local function HideHotKeys_HideBar(b, f)
    for i = 1, 12 do
        local o = _G[b.."Button"..i..f]
        if (o) then
            o:Hide()
        end
    end
end

local function HideHotKeys_ShowBar(b, f)
    for i = 1, 12 do
        local o = _G[b.."Button"..i..f]
        if (o) then
            if f == "HotKey" then
                local action = _G[b.."Button"..i].action
                local range = IsActionInRange(action)
                if o:GetText() ~= RANGE_INDICATOR or range or range == false then
                    o:Show()
                end
            else
                o:Show()
            end
        end
    end
end

local function HideHotKeys_HK_HideAll()
    HideHotKeys_HideBar("Action", "HotKey")
    HideHotKeys_HideBar("BonusAction", "HotKey")
    HideHotKeys_HideBar("PetAction", "HotKey")
    HideHotKeys_HideBar("MultiBarBottomLeft", "HotKey")
    HideHotKeys_HideBar("MultiBarBottomRight", "HotKey")
    HideHotKeys_HideBar("MultiBarRight", "HotKey")
    HideHotKeys_HideBar("MultiBarLeft", "HotKey")
    HideHotKeys_HideBar("MultiBar5", "HotKey")
    HideHotKeys_HideBar("MultiBar6", "HotKey")
end

local function HideHotKeys_HK_ShowAll()
    HideHotKeys_ShowBar("Action", "HotKey")
    HideHotKeys_ShowBar("BonusAction", "HotKey")
    HideHotKeys_ShowBar("PetAction", "HotKey")
    HideHotKeys_ShowBar("MultiBarBottomLeft", "HotKey")
    HideHotKeys_ShowBar("MultiBarBottomRight", "HotKey")
    HideHotKeys_ShowBar("MultiBarRight", "HotKey")
    HideHotKeys_ShowBar("MultiBarLeft", "HotKey")
    HideHotKeys_ShowBar("MultiBar5", "HotKey")
    HideHotKeys_ShowBar("MultiBar6", "HotKey")
end

local function HideHotKeys_MN_HideAll()
    HideHotKeys_HideBar("Action", "Name")
    HideHotKeys_HideBar("BonusAction", "Name")
    HideHotKeys_HideBar("MultiBarBottomLeft", "Name")
    HideHotKeys_HideBar("MultiBarBottomRight", "Name")
    HideHotKeys_HideBar("MultiBarRight", "Name")
    HideHotKeys_HideBar("MultiBarLeft", "Name")
    HideHotKeys_HideBar("MultiBar5", "Name")
    HideHotKeys_HideBar("MultiBar6", "Name")
end


local function HideHotKeys_MN_ShowAll()
    HideHotKeys_ShowBar("Action", "Name")
    HideHotKeys_ShowBar("PetAction", "Name")
    HideHotKeys_ShowBar("BonusAction", "Name")
    HideHotKeys_ShowBar("MultiBarBottomLeft", "Name")
    HideHotKeys_ShowBar("MultiBarBottomRight", "Name")
    HideHotKeys_ShowBar("MultiBarRight", "Name")
    HideHotKeys_ShowBar("MultiBarLeft", "Name")
    HideHotKeys_ShowBar("MultiBar5", "Name")
    HideHotKeys_ShowBar("MultiBar6", "Name")
end

local function ShowHotKeys()
    HideHotKeys_HK_ShowAll()
    HideHotKeys_MN_ShowAll()
end

local function HideHotKeys()
    HideHotKeys_HK_HideAll()
    HideHotKeys_MN_HideAll()
end

SLASH_HIDEHOTKEYSHK1 = "/shk"
SlashCmdList["HIDEHOTKEYSHK"] = ShowHotKeys

SLASH_HIDEHOTKEYHHK1 = "/hhk"
SlashCmdList["HIDEHOTKEYHHK"] = HideHotKeys

local frame = CreateFrame("Frame")
frame:RegisterEvent(addon.PLAYER_ENTERING_WORLD)
frame:SetScript("OnEvent", function ()
    HideHotKeys()
end)
