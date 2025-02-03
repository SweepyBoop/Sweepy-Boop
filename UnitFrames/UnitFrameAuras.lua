local _, addon = ...;

local AuraUpdateChangedType = EnumUtil.MakeEnum(
	"None",
	"Debuff",
	"Buff"
);

local function ProcessAura(self, aura)
	if aura == nil or aura.icon == nil then
		return AuraUpdateChangedType.None;
	end

    --local shouldFilter = SweepyBoop.db.profile.unitFrames.auraFilterEnabled;
    local shouldFilter = SweepyBoop.db.profile.unitFrames.auraFilterEnabled and ( IsActiveBattlefieldArena() or ( UnitInBattleground("player") ~= nil ) );

	if aura.isHelpful and not aura.isNameplateOnly and self:ShouldShowBuffs() then
        if shouldFilter and ( not aura.isRaid ) then
            return AuraUpdateChangedType.None;
        end

		self.activeBuffs[aura.auraInstanceID] = aura;
		return AuraUpdateChangedType.Buff;
	elseif aura.isHarmful and self:ShouldShowDebuffs(self.unit, aura.sourceUnit, aura.nameplateShowAll, aura.isFromPlayerOrPlayerPet) then
        if shouldFilter and ( not aura.isRaid ) then
            return AuraUpdateChangedType.None;
        end

		self.activeDebuffs[aura.auraInstanceID] = aura;
		return AuraUpdateChangedType.Debuff;
	end

	return AuraUpdateChangedType.None;
end

function SweepyBoop:SetupUnitFrameAuraModule()
    TargetFrame.ProcessAura = ProcessAura;
end
