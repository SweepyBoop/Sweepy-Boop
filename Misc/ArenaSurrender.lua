local _, addon = ...;

SlashCmdList["CHAT_AFK"] = function(msg)
    if IsActiveBattlefieldArena() and SweepyBoop.db.profile.arenaSurrenderEnabled then
        if CanSurrenderArena() then
            SurrenderArena();
        elseif SweepyBoop.db.profile.skipLeaveArenaConfirmation then
            LeaveBattlefield();
        else
            ConfirmOrLeaveBattlefield();
        end
    else
        SendChatMessage(msg, "AFK");
    end
end
