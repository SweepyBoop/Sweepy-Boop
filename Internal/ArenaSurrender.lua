SlashCmdList["CHAT_AFK"] = function(msg)
	if IsActiveBattlefieldArena() then
		if CanSurrenderArena() then
			print("Successfully surrendered arena.")
			SurrenderArena();
		else
			print("Failed to surrender arena. Partners still alive.")
		end
	else
		SendChatMessage(msg, "AFK");
	end
end
