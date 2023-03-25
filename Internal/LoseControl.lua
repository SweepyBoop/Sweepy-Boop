local _, NS = ...;
local CreateFrame = CreateFrame;
local UIParent = UIParent;
local C_LossOfControl = C_LossOfControl;
local IsActiveBattlefieldArena = IsActiveBattlefieldArena;
local SendChatMessage = SendChatMessage;
local UnitIsGroupLeader = UnitIsGroupLeader;
local GetTime = GetTime;
local UnitGroupRolesAssigned = UnitGroupRolesAssigned;

local containerFrame = CreateFrame("Frame", nil, UIParent)
containerFrame:SetSize(30, 30)
containerFrame:SetPoint("CENTER")
containerFrame.texture = containerFrame:CreateTexture()
containerFrame.texture:SetAllPoints()

-- Assign a name so we can disable it in OmniCC
-- https://github.com/tomrus88/BlizzardInterfaceCode/blob/master/Interface/FrameXML/LossOfControlFrame.xml
containerFrame.cooldown = CreateFrame("Cooldown", NS.HIDETIMEROMNICC .. "LoseControl", containerFrame, "CooldownFrameTemplate")
containerFrame.cooldown:SetHideCountdownNumbers(true)
containerFrame.cooldown:SetDrawEdge(true);
containerFrame.cooldown:SetAllPoints()

containerFrame.lastMsgSent = 0;
containerFrame:RegisterEvent(NS.LOSS_OF_CONTROL_ADDED);
containerFrame:RegisterEvent(NS.LOSS_OF_CONTROL_UPDATE);
containerFrame:RegisterEvent(NS.PLAYER_ENTERING_WORLD);

function containerFrame:OnEvent(event, ...)
    local locData = C_LossOfControl.GetActiveLossOfControlData(1)

    if ( not locData ) or ( not locData.displayText ) or ( locData.displayType == 0 ) then
        self:Hide()
        return
    end

    self.texture:SetTexture(locData.iconTexture)

    if locData.duration then -- Some auras have no duration, such as solar beam
        self.cooldown:SetCooldown(locData.startTime , locData.duration)
    end

    local locType = locData.locType
    if ( locType == "ROOT" ) or ( locType == "SCHOOL_INTERRUPT" ) or ( locType == "DISARM" ) then
        self:SetAlpha(0.5)
    else
        self:SetAlpha(1)
    end

    self:Show()

    -- Send notification to group
    if IsActiveBattlefieldArena() and ( event == NS.LOSS_OF_CONTROL_ADDED ) and ( UnitGroupRolesAssigned("player") == "HEALER" ) then
        local now = GetTime();
        if ( now < self.lastMsgSent + 1.5 ) then
            -- Don't send more than one messages within 1.5 sec.
            return;
        end

        -- Check remaining time of current CC
        local sendMsg;
        if ( locType ~= "ROOT" ) and ( locType ~= "DISARM" ) and ( locType ~= "SCHOOL_INTERRUPT" ) then
            sendMsg = locData.duration and ( now < locData.startTime + locData.duration - 3 );
        end

        if sendMsg then
            local channel = UnitIsGroupLeader("player") and "RAID_WARNING" or "YELL";
            pcall(function() SendChatMessage("Healer in CC. Press buttons to live!!!", channel) end)
            self.lastMsgSent = now;
        end
    end
end
containerFrame:SetScript("OnEvent", containerFrame.OnEvent)
