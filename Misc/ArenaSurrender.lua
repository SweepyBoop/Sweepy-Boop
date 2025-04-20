local _, addon = ...;

SlashCmdList["CHAT_AFK"] = function(msg)
    if IsActiveBattlefieldArena() and SweepyBoop.db.profile.misc.arenaSurrenderEnabled then
        if CanSurrenderArena() then
            SurrenderArena();
        else
            ConfirmOrLeaveBattlefield();
        end
    else
        SendChatMessage(msg, "AFK");
    end
end

SlashCmdList["CHAT_GG"] = function(msg)
    if IsActiveBattlefieldArena() and SweepyBoop.db.profile.misc.arenaSurrenderEnabled then
        LeaveBattlefield();
    else
        SendChatMessage(msg, "GG");
    end
end
