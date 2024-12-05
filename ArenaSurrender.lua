local _, NS = ...;

SlashCmdList["CHAT_AFK"] = function(msg)
	if IsActiveBattlefieldArena() and SweepyBoop.db.profile.arenaSurrenderEnabled then
		if CanSurrenderArena() then
			SurrenderArena();
		else
			ConfirmSurrenderArena();
		end
	else
		SendChatMessage(msg, "AFK");
	end
end
