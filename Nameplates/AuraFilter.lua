local _, addon = ...;

local function UpdateNamePlateAuras(buffFrame, unitFrame, unit, unitAuraUpdateInfo, auraSettings)
    
end

addon.OnNamePlateAuraUpdate = function (self, unitFrame, unit, unitAuraUpdateInfo)
    -- Copied from BlizzardInterfaceCode, with HasFriendlyReaction changed
    local filter;
	local showAll = false;

	local isPlayer = UnitIsUnit("player", unit);
	local showDebuffsOnFriendly = self.showDebuffsOnFriendly;

	local auraSettings =
	{
		helpful = false;
		harmful = false;
		raid = false;
		includeNameplateOnly = false;
		showAll = false;
		hideAll = false;
	};

	if isPlayer then
		auraSettings.helpful = true;
		auraSettings.includeNameplateOnly = true;
		auraSettings.showPersonalCooldowns = self.showPersonalCooldowns;
	else
		if ( not addon.UnitIsHostile(unit) ) then
			if (showDebuffsOnFriendly) then
				-- dispellable debuffs
				auraSettings.harmful = true;
				auraSettings.raid = true;
				auraSettings.showAll = true;
			else
				auraSettings.hideAll = true;
			end
		else
			-- Reaction 4 is neutral and less than 4 becomes increasingly more hostile
			auraSettings.harmful = true;
			auraSettings.includeNameplateOnly = true;
		end
	end

    UpdateNamePlateAuras(self, unitFrame, unit, unitAuraUpdateInfo, auraSettings);
end
