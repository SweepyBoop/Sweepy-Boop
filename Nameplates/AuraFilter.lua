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

local function ParseAllAuras(self, forceAll)
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
    -- Copied from BlizzardInterfaceCode
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
        ParseAllAuras(self, auraSettings.showAll);
        aurasChanged = true;
    else
        if unitAuraUpdateInfo.addedAuras ~= nil then
            for _, aura in ipairs(unitAuraUpdateInfo.addedAuras) do
                --local shouldShowByBlizzard = self:ShouldShowBuff(aura, auraSettings.showAll) and not C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, aura.auraInstanceID, filterString);
                local shouldShowOverride = ShouldShowBuffOverride(self, aura, auraSettings.showAll);
                if shouldShowOverride then
                    print("Should show buff", aura.name);
                    self.auras[aura.auraInstanceID] = aura;
                end
                aurasChanged = true;
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

    if not self.isActive then
        return;
    end

    -- Can show extra debuffs, but cannot hide buffs that are shown by Blizzard
    -- Possibly messed up by CompactUnitFrame_UpdateAuras

    local buffIndex = 1;
    self.auras:Iterate(function(auraInstanceID, aura)
        print("Actually show buff", aura.name);
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
        buff:SetMouseClickEnabled(false);

        buffIndex = buffIndex + 1;
        return buffIndex >= BUFF_MAX_DISPLAY;
    end);

    self:Layout();
end

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

    addon.UpdateBuffsOverride(self, unit, unitAuraUpdateInfo, auraSettings);
end
