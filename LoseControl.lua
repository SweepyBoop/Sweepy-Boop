local _, NS = ...

local containerFrame = CreateFrame("Frame", nil, UIParent)
containerFrame:SetSize(30, 30)
containerFrame:SetPoint("CENTER")
local texture = containerFrame:CreateTexture()
texture:SetAllPoints()

local cooldown = CreateFrame("Cooldown", "myCooldown", containerFrame, "CooldownFrameTemplate")
cooldown:SetAllPoints()

containerFrame:RegisterEvent("LOSS_OF_CONTROL_ADDED")
containerFrame:RegisterEvent("LOSS_OF_CONTROL_UPDATE")
containerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

function containerFrame:OnEvent(event, ...)
    local locData = C_LossOfControl.GetActiveLossOfControlData(1)

    if ( not locData ) or ( not locData.displayText ) or ( locData.displayType == 0 ) then
        containerFrame:Hide()
        return
    end

    texture:SetTexture(locData.iconTexture)
    cooldown:SetCooldown(locData.startTime , locData.duration)

    local locType = locData.locType
    if ( locType == "ROOT" ) or ( locType == "SCHOOL_INTERRUPT" ) then
        containerFrame:SetAlpha(0.5)
    else
        containerFrame:SetAlpha(1)
    end

    containerFrame:Show()
end
containerFrame:SetScript("OnEvent", containerFrame.OnEvent)
