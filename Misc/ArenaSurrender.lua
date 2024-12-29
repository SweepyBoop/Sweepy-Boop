local _, addon = ...;

SlashCmdList["CHAT_AFK"] = function(msg)
    if IsActiveBattlefieldArena() and SweepyBoop.db.profile.misc.arenaSurrenderEnabled then
        if CanSurrenderArena() then
            SurrenderArena();
        elseif SweepyBoop.db.profile.misc.skipLeaveArenaConfirmation then
            LeaveBattlefield();
        else
            ConfirmOrLeaveBattlefield();
        end
    else
        SendChatMessage(msg, "AFK");
    end
end
