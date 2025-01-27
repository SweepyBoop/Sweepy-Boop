local _, addon = ...;

local function ShouldShowBuffOverride(self, aura, forceAll)
    if ( not aura ) or ( not aura.spellId ) then
        return false;
    end

    -- Some crowd controls are hidden by Blizzard, override the logic
    if addon.CrowdControlAuras[aura.spellId] then
        return true;
    end

    if aura.nameplateShowAll or forceAll then
        return true;
    elseif (aura.sourceUnit == "player" or aura.sourceUnit == "pet" or aura.sourceUnit == "vehicle") then
        return SweepyBoop.db.profile.nameplatesEnemy.auraWhiteList[tostring(aura.spellId)];
    end
end

local function ParseAllAurasOverride(self, forceAll)
    if self.auras == nil then
        self.auras = TableUtil.CreatePriorityTable(AuraUtil.DefaultAuraCompare, TableUtil.Constants.AssociativePriorityTable);
    else
        self.auras:Clear();
    end

    local function HandleAura(aura)
        if ShouldShowBuffOverride(self, aura, forceAll) then
            self.auras[aura.auraInstanceID] = aura;
        end

        return false;
    end

    local batchCount = nil;
    local usePackedAura = true;
    AuraUtil.ForEachAura(self.unit, self.filter, batchCount, HandleAura, usePackedAura);
end

addon.UpdateBuffsOverride = function(self, unit, unitAuraUpdateInfo, auraSettings)
    -- Override auraSettings because Blizzard code doesn't properly check unit hostility under Mind Control
    local isEnemy;
    if SweepyBoop.db.profile.nameplatesEnemy.auraFilterEnabled then
        isEnemy = addon.UnitIsHostile(unit);
        local isPlayer = UnitIsUnit("player", unit);
        local showDebuffsOnFriendly = self.showDebuffsOnFriendly;

        if ( not isPlayer ) then
            auraSettings =
            {
                helpful = false;
                harmful = false;
                raid = false;
                includeNameplateOnly = false;
                showAll = false;
                hideAll = false;
            };

            if isEnemy then
                auraSettings.harmful = true;
                auraSettings.includeNameplateOnly = true;
            else
                if (showDebuffsOnFriendly) then
                    -- dispellable debuffs
                    auraSettings.harmful = true;
                    auraSettings.raid = true;
                    auraSettings.showAll = true;
                else
                    auraSettings.hideAll = true;
                end
            end
        end
    end

    local filters = {};
    if auraSettings.helpful then
        table.insert(filters, AuraUtil.AuraFilters.Helpful);
    end
    if auraSettings.harmful then
        table.insert(filters, AuraUtil.AuraFilters.Harmful);
    end
    if auraSettings.raid then
        table.insert(filters, AuraUtil.AuraFilters.Raid);
    end
    if auraSettings.includeNameplateOnly then
        table.insert(filters, AuraUtil.AuraFilters.IncludeNameplateOnly);
    end
    local filterString = AuraUtil.CreateFilterString(unpack(filters));

    local previousFilter = self.filter;
    local previousUnit = self.unit;
    self.unit = unit;
    self.filter = filterString;
    self.showFriendlyBuffs = auraSettings.showFriendlyBuffs;

    local aurasChanged = false;
    if unitAuraUpdateInfo == nil or unitAuraUpdateInfo.isFullUpdate or unit ~= previousUnit or self.auras == nil or filterString ~= previousFilter then
        if SweepyBoop.db.profile.nameplatesEnemy.auraFilterEnabled and isEnemy then
            ParseAllAurasOverride(self, auraSettings.showAll);
        else
            self:ParseAllAuras(auraSettings.showAll);
        end
        aurasChanged = true;
    else
        if unitAuraUpdateInfo.addedAuras ~= nil then
            for _, aura in ipairs(unitAuraUpdateInfo.addedAuras) do
                -- if aura.sourceUnit == "player" or aura.sourceUnit == "pet" or aura.sourceUnit == "vehicle" then
                --     print(aura.name, aura.spellId);
                -- end

                local shouldShowBuff;
                if SweepyBoop.db.profile.nameplatesEnemy.auraFilterEnabled and isEnemy then
                    shouldShowBuff = ShouldShowBuffOverride(self, aura, auraSettings.showAll);
                else
                    shouldShowBuff = self:ShouldShowBuff(aura, auraSettings.showAll) and not C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, aura.auraInstanceID, filterString);
                end

                if shouldShowBuff then
                    self.auras[aura.auraInstanceID] = aura;
                    aurasChanged = true;
                end
            end
        end

        if unitAuraUpdateInfo.updatedAuraInstanceIDs ~= nil then
            for _, auraInstanceID in ipairs(unitAuraUpdateInfo.updatedAuraInstanceIDs) do
                if self.auras[auraInstanceID] ~= nil then
                    local newAura = C_UnitAuras.GetAuraDataByAuraInstanceID(self.unit, auraInstanceID);
                    self.auras[auraInstanceID] = newAura;
                    aurasChanged = true;
                end
            end
        end

        if unitAuraUpdateInfo.removedAuraInstanceIDs ~= nil then
            for _, auraInstanceID in ipairs(unitAuraUpdateInfo.removedAuraInstanceIDs) do
                if self.auras[auraInstanceID] ~= nil then
                    self.auras[auraInstanceID] = nil;
                    aurasChanged = true;
                end
            end
        end
    end

    self:UpdateAnchor();

    if not aurasChanged then
        return;
    end

    self.buffPool:ReleaseAll();

    if auraSettings.hideAll or not self.isActive then
        return;
    end

    local buffIndex = 1;
    self.auras:Iterate(function(auraInstanceID, aura)
        local buff = self.buffPool:Acquire();
        buff.auraInstanceID = auraInstanceID;
        buff.isBuff = aura.isHelpful;
        buff.layoutIndex = buffIndex;
        buff.spellID = aura.spellId;

        buff.Icon:SetTexture(aura.icon);
        if (aura.applications > 1) then
            buff.CountFrame.Count:SetText(aura.applications);
            buff.CountFrame.Count:Show();
        else
            buff.CountFrame.Count:Hide();
        end
        CooldownFrame_Set(buff.Cooldown, aura.expirationTime - aura.duration, aura.duration, aura.duration > 0, true);

        buff:Show();

        buffIndex = buffIndex + 1;
        return buffIndex >= BUFF_MAX_DISPLAY;
    end);

    --Add Cooldowns 
    if(auraSettings.showPersonalCooldowns and buffIndex < BUFF_MAX_DISPLAY and UnitIsUnit(unit, "player")) then 
        local nameplateSpells = C_SpellBook.GetTrackedNameplateCooldownSpells(); 
        for _, spellID in ipairs(nameplateSpells) do 
            if (not self:HasActiveBuff(spellID) and buffIndex < BUFF_MAX_DISPLAY) then
                local locStart, locDuration = C_Spell.GetSpellLossOfControlCooldown(spellID);
                local cooldownInfo = C_Spell.GetSpellCooldown(spellID);
                if ((locDuration and locDuration ~= 0) or (cooldownInfo and cooldownInfo.duration ~= 0)) then
                    local spellInfo = C_Spell.GetSpellInfo(spellID);
                    if(spellInfo) then 
                        local buff = self.buffPool:Acquire();
                        buff.isBuff = true;
                        buff.layoutIndex = buffIndex;
                        buff.spellID = spellID; 
                        buff.auraInstanceID = nil;
                        buff.Icon:SetTexture(spellInfo.iconID); 

                        local chargeInfo = C_Spell.GetSpellCharges(spellID) or {};
                        local charges, maxCharges = chargeInfo.currentCharges, chargeInfo.maxCharges;
                        buff.Cooldown:SetSwipeColor(0, 0, 0);

                        if (cooldownInfo and cooldownInfo.duration ~= 0) then
                            CooldownFrame_Set(buff.Cooldown, cooldownInfo.startTime, cooldownInfo.duration, cooldownInfo.isEnabled, true, cooldownInfo.modRate);
                        else
                            CooldownFrame_Set(buff.Cooldown, locStart, locDuration, true, true);
                        end

                        if (maxCharges and maxCharges > 1) then
                            buff.CountFrame.Count:SetText(charges);
                            buff.CountFrame.Count:Show();
                        else
                            buff.CountFrame.Count:Hide();
                        end
                        buff:Show();
                        buffIndex = buffIndex + 1;
                    end
                end
            end
        end 
    end

    self:Layout();
end

-- Issue: auras are filtered properly initially but as a fight goes on, auras that are supposed to be hidden show up again
addon.OnNamePlateAuraUpdate = function (self, unit, unitAuraUpdateInfo)
    -- Copied from BlizzardInterfaceCode but checking ( not addon.UnitIsHostile ) instead of PlayerUtil.HasFriendlyReaction
    -- This function is only called on hostile units (factoring in Mind Control)
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
        if addon.UnitIsHostile(unit) then
            auraSettings.harmful = true;
            auraSettings.includeNameplateOnly = true;
        else -- Friendly units
            if (showDebuffsOnFriendly) then
                -- dispellable debuffs
                auraSettings.harmful = true;
                auraSettings.raid = true;
                auraSettings.showAll = true;
            else
                auraSettings.hideAll = true;
            end
        end
    end

    addon.UpdateBuffsOverride(self, unit, unitAuraUpdateInfo, auraSettings);
end
