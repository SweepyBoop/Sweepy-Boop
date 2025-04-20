local _, addon = ...;

function SweepyBoop:SetupArenaSurrender()
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

    SLASH_ArenaGG1 = "/gg";
    SlashCmdList.ArenaGG = function(msg)
        if IsActiveBattlefieldArena() and SweepyBoop.db.profile.misc.arenaSurrenderEnabled then
            LeaveBattlefield();
        end
    end
end
