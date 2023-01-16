local _, NS = ...

local loseControl = CreateFrame("Cooldown", nil, UIParent, "CooldownFrameTemplate")
loseControl:SetSize(30, 30)
loseControl:SetAllPoints()
loseControl:RegisterEvent("LOSS_OF_CONTROL_ADDED")
loseControl:RegisterEvent("LOSS_OF_CONTROL_UPDATE")
loseControl:RegisterEvent("PLAYER_ENTERING_WORLD")

function loseControl:OnEvent(event, ...)
    local locData = C_LossOfControl.GetActiveLossOfControlData(1)
    if ( not locData ) then
        loseControl:Hide()
        return
    end

    loseControl:SetTexture(locData[iconTexture])
    loseControl:SetCooldown(locData["startTime"], locData["duration"])

    if locData["locType"] == "ROOT" then
        loseControl:SetAlpha(0.5)
    else
        loseControl:SetAlpha(1)
    end

    loseControl:Show()
end