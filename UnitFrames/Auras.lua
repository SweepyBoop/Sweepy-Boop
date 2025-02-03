local _, addon = ...;

local AuraUpdateChangedType = EnumUtil.MakeEnum(
	"None",
	"Debuff",
	"Buff"
);

local function ProcessAuraOverride(self, aura)
    print(aura);
    if aura == nil or aura.icon == nil then
		return AuraUpdateChangedType.None;
	end

	if aura.isHelpful and not aura.isNameplateOnly and self:ShouldShowBuffs() then
		self.activeBuffs[aura.auraInstanceID] = aura;
		return AuraUpdateChangedType.Buff;
	elseif aura.isHarmful and self:ShouldShowDebuffs(self.unit, aura.sourceUnit, aura.nameplateShowAll, aura.isFromPlayerOrPlayerPet) then
		self.activeDebuffs[aura.auraInstanceID] = aura;
		return AuraUpdateChangedType.Debuff;
	end

	return AuraUpdateChangedType.None;
end

function SweepyBoop:SetupUnitFrameAuraModule()
    TargetFrame.ProcessAura = ProcessAuraOverride;
end
