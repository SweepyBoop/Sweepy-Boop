local _, addon = ...;

SlashCmdList["CHAT_AFK"] = function(msg)
    local isArena, isRanked = IsActiveBattlefieldArena();
    if isArena and SweepyBoop.db.profile.arenaSurrenderEnabled then
        if CanSurrenderArena() then
            SurrenderArena();
        elseif isRanked then
            LeaveBattlefield();
        else
            ConfirmOrLeaveBattlefield();
        end
    else
        SendChatMessage(msg, "AFK");
    end
end
