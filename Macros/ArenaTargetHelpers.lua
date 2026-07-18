local _, addon = ...;

addon.GetArenaHealerUnit = function()
    if IsActiveBattlefieldArena() then
        for i = 1, addon.MAX_ARENA_SIZE do
            local spec = GetArenaOpponentSpec(i);
            if spec then
                local role = select(5, GetSpecializationInfoByID(spec));
                if ( role == "HEALER" ) then
                    return "arena" .. i;
                end
            end
        end
    end

    return "focus";
end
