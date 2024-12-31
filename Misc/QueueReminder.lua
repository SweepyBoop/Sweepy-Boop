local _, addon = ...;

local battlefieldId;
local updateFrame; -- For update timer text
local eventFrame; -- For listening to UPDATE_BATTLEFIELD_STATUS events
local queues = {};

local queueTypeText = {
    ["ARENASKIRMISH"] = "Arena skirmish",
    ["ARENA"] = "Arena",
    ["RATEDSHUFFLE"] = "Arena",
};

local function EnsureTimerText(dialogFrame)
    if dialogFrame.labelOverride then return end -- Only create once

    local maxWidth = dialogFrame:GetWidth();

    -- The original label (e.g., "Your Arena is ready!") will be hidden by calling SetText("")
    dialogFrame.labelOverride = dialogFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge");
    dialogFrame.labelOverride:SetPoint("TOP", dialogFrame.label, "TOP", 0, 0);
    dialogFrame.labelOverride:SetText(""); -- e.g., Expires in 1 min 30 Sec, the time portion will change color based on time left
    dialogFrame.labelOverride:SetWidth(maxWidth);
end

local addonOverrides = {
    -- From BBF
    "customLabel",
    "timerLabel",
    "bgLabel",
    "statusTextLabel",
};

local function SetExpiresText()
    if ( not SweepyBoop.db.profile.misc.queueReminder) or ( not PVPReadyDialog ) or ( not battlefieldId ) then
        if PVPReadyDialog.labelOverride then
            PVPReadyDialog.labelOverride:SetText("");
        end
        return;
    end

    -- Hide timers from other addons
    for i = 1, #(addonOverrides) do
        local field = addonOverrides[i];
        if PVPReadyDialog[field] and PVPReadyDialog[field].SetText then
            PVPReadyDialog[field]:SetText("");
        end
    end

    local seconds = GetBattlefieldPortExpiration(battlefieldId);
    if ( seconds <= 0 ) then seconds = 1 end
    local color = ( seconds > 20 and "20ff20" ) or ( seconds > 10 and "ffff00" ) or "ff0000"; -- green -> yellow -> red
    local queueType = select(6, GetBattlefieldStatus(battlefieldId));
    local prefix = ( queueType and queueTypeText[queueType] and ( queueTypeText[queueType] .. " expires" ) ) or "Expires";
    local text = format("%s in |cff%s%s|r", prefix, color, SecondsToTime(seconds)); -- Only the time portion will change color

    EnsureTimerText(PVPReadyDialog);
    PVPReadyDialog.label:SetText(""); -- Hide the original label
    local labelOverride = PVPReadyDialog.labelOverride;
    labelOverride:SetText(text);

    -- Play sound when remaining time text changes color (green -> yellow, yellow -> red)
    if labelOverride.prevSeconds then
        local shouldPlaySound = ( labelOverride.prevSeconds > 20 and seconds <= 20 ) or ( labelOverride.prevSeconds > 10 and seconds <= 10 );
        if shouldPlaySound then
            PlaySoundFile(567458, "master"); -- sound/interface/alarmclockwarning3.ogg
        end
    end

    labelOverride.prevSeconds = seconds;
end

addon.StartUpdateQueueReminder = function ()
    if ( not updateFrame ) then
        updateFrame = CreateFrame("Frame");
        updateFrame.timer = TOOLTIP_UPDATE_TIME;
        updateFrame:SetScript("OnUpdate", function (self, elapsed)
            if (not battlefieldId) then return end
            local timer = self.timer;
            timer = timer - elapsed;
            if timer <= 0 then
                if GetBattlefieldStatus(battlefieldId) == "confirm" then
                    SetExpiresText();
                end
            end
            self.timer = timer;
        end)
    end

    updateFrame:Show();
end

addon.StopUpdateQueueReminder = function ()
    if updateFrame then
        updateFrame:Hide(); -- A frame does not receive events when it's hidden, we only need to do updates when there is currently a queue pop
    end
end

SweepyBoop.SetupQueueReminder = function ()
    if ( not SweepyBoop.db.profile.misc.queueReminder ) then return end

    if C_AddOns.IsAddOnLoaded("SafeQueue") then
        DEFAULT_CHAT_FRAME:AddMessage(addon.BLIZZARD_CHAT_ICON .. "|cff00c0ffSweepyBoop's PvP Helper:|r SafeQueue is enabled, disable it to use PvP Queue Timer.");
    end

    if ( not eventFrame ) then -- Only init once
        hooksecurefunc("PVPReadyDialog_Display", function(_, i) -- Does this get triggered when logging off and on with a queue pop?
            battlefieldId = i;
            addon.StartUpdateQueueReminder();
            SetExpiresText();
        end)

        eventFrame = CreateFrame("Frame");
        eventFrame:RegisterEvent("UPDATE_BATTLEFIELD_STATUS");
        eventFrame:SetScript("OnEvent", function ()
            local isConfirm;

            for i = 1, GetMaxBattlefieldID() do
                local status, _, _, _, _, queueType = GetBattlefieldStatus(i);
                if status == "queued" then
                    queues[i] = queues[i] or ( GetTime() - (GetBattlefieldTimeWaited(i) / 1000) );
                    --print(queueType); -- for debugging queue types
                elseif status == "confirm" then
                    if queues[i] then
                        local seconds = GetTime() - queues[i];
                        local message;
                        if ( seconds < 1 ) then
                            message = "Queue popped instantly!";
                        else
                            message = format("Queue popped after %s", SecondsToTime(seconds));
                        end

                        queues[i] = nil;
                        print(message);
                    end

                    isConfirm = true;
                else
                    queues[i] = nil;
                end
            end

            if ( not isConfirm ) then
                addon.StopUpdateQueueReminder();
                battlefieldId = nil;
            end
        end)
    end
end
