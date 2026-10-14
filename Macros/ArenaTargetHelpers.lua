local _, addon = ...;

addon.GetArenaHealerUnit = function()
    if IsActiveBattlefieldArena() then
        for i = 1, addon.MAX_ARENA_SIZE do
            local unit = "arena" .. i;
            local role = UnitGroupRolesAssigned(unit);
            if addon.IsSecretValue(role) then
                role = nil;
            end
            if ( role == "HEALER" ) then
                return unit;
            end

            local spec = addon.GetReadableArenaOpponentSpec(i);
            if spec then
                role = select(5, GetSpecializationInfoByID(spec));
                if ( role == "HEALER" ) then
                    return unit;
                end
            end
        end
    end

    return "focus";
end
