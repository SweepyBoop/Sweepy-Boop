local _, NS = ...;
local CreateFrame = CreateFrame;
local UIParent = UIParent;
local C_LossOfControl = C_LossOfControl;
local IsActiveBattlefieldArena = IsActiveBattlefieldArena;
local SendChatMessage = SendChatMessage;

local containerFrame = CreateFrame("Frame", nil, UIParent)
containerFrame:SetSize(30, 30)
containerFrame:SetPoint("CENTER")
local texture = containerFrame:CreateTexture()
texture:SetAllPoints()

-- Assign a name so we can disable it in OmniCC
-- https://github.com/tomrus88/BlizzardInterfaceCode/blob/master/Interface/FrameXML/LossOfControlFrame.xml
local cooldown = CreateFrame("Cooldown", NS.HIDETIMEROMNICC .. "LoseControl", containerFrame, "CooldownFrameTemplate")
cooldown:SetHideCountdownNumbers(true)
cooldown:SetDrawEdge(true);
cooldown:SetAllPoints()

containerFrame:RegisterEvent(NS.LOSS_OF_CONTROL_ADDED)
containerFrame:RegisterEvent(NS.LOSS_OF_CONTROL_UPDATE)
containerFrame:RegisterEvent(NS.PLAYER_ENTERING_WORLD)

function containerFrame:OnEvent(event, ...)
    local locData = C_LossOfControl.GetActiveLossOfControlData(1)

    if ( not locData ) or ( not locData.displayText ) or ( locData.displayType == 0 ) then
        containerFrame:Hide()
        return
    end

    texture:SetTexture(locData.iconTexture)

    if locData.duration then -- Some auras have no duration, such as solar beam
        cooldown:SetCooldown(locData.startTime , locData.duration)
    end

    local locType = locData.locType
    if ( locType == "ROOT" ) or ( locType == "SCHOOL_INTERRUPT" ) or ( locType == "DISARM" ) then
        containerFrame:SetAlpha(0.5)
    else
        containerFrame:SetAlpha(1)
    end

    containerFrame:Show()

    -- Send notification to group
    if IsActiveBattlefieldArena() and ( event == NS.LOSS_OF_CONTROL_ADDED ) then
        local sendMsg;
        if ( locType == "SCHOOL_INTERRUPT" ) then
            -- Only announce for 6s interrupt
            sendMsg = locData.duration and ( locData.duration > 5 );
        elseif ( locType ~= "ROOT" ) and ( locType ~= "DISARM" ) then
            sendMsg = locData.duration and ( locData.duration > 3.5 );
        end

        if sendMsg then
            pcall(function() SendChatMessage("Healer in CC. Use defensives if you need to!", "YELL") end)
        end
    end
end
containerFrame:SetScript("OnEvent", containerFrame.OnEvent)
