local _, addon = ...;

local AURA_CATEGORY = { -- Maybe apply different borders based on category?
    CROWD_CONTROL = 1,
    DEBUFF = 2,
    BUFF = 3,
};

local rowGap = 2;
local spacing = 4;

local function IsLayoutFrame(frame)
    return frame.IsLayoutFrame and frame:IsLayoutFrame();
end

local function EnsureGlowFrame(buff)
    if not buff.CustomGlowFrame then
        buff.CustomGlowFrame = CreateFrame("Frame", nil, buff);
        if buff.CountFrame then
            buff.CountFrame:SetFrameLevel(999); -- Make sure the glow doesn't block the count
        end
    end

    return buff.CustomGlowFrame;
end

local function UpdateCrowdControlGlow(buff, show)
    if show then
        local container = EnsureGlowFrame(buff);
        if not container.CrowdControlGlow then
            container.CrowdControlGlow = container:CreateTexture(nil, "ARTWORK");
            container.CrowdControlGlow:SetAtlas("newplayertutorial-drag-slotgreen");
            container.CrowdControlGlow:SetDesaturated(true);
            container.CrowdControlGlow:SetVertexColor(1, 0.6471, 0); -- Orange
        end

        container.CrowdControlGlow:SetPoint("TOPLEFT", buff, "TOPLEFT", -9, 6);
        container.CrowdControlGlow:SetPoint("BOTTOMRIGHT", buff, "BOTTOMRIGHT", 9, -6);
        container.CrowdControlGlow:Show();
    else
        if buff.CustomGlowFrame and buff.CustomGlowFrame.CrowdControlGlow then
            buff.CustomGlowFrame.CrowdControlGlow:Hide();
        end
    end
end

local function UpdatePurgableGlow(buff, show)
    if show then
        local container = EnsureGlowFrame(buff);
        if not container.PurgableGlow then
            container.PurgableGlow = container:CreateTexture(nil, "ARTWORK");
            container.PurgableGlow:SetAtlas("newplayertutorial-drag-slotblue");
        end

        container.PurgableGlow:SetPoint("TOPLEFT", buff, "TOPLEFT", -9, 6);
        container.PurgableGlow:SetPoint("BOTTOMRIGHT", buff, "BOTTOMRIGHT", 9, -6);
        container.PurgableGlow:Show();
    else
        if buff.CustomGlowFrame and buff.CustomGlowFrame.PurgableGlow then
            buff.CustomGlowFrame.PurgableGlow:Hide();
        end
    end
end

local function UpdateBuffGlow(buff, show)
    if show then
        local container = EnsureGlowFrame(buff);
        if not container.BuffGlow then
            container.BuffGlow = container:CreateTexture(nil, "ARTWORK");
            container.BuffGlow:SetAtlas("newplayertutorial-drag-slotgreen");
            container.BuffGlow:SetDesaturated(true);
            container.BuffGlow:SetVertexColor(0, 1, 0); -- Green
        end

        container.BuffGlow:SetPoint("TOPLEFT", buff, "TOPLEFT", -9, 6);
        container.BuffGlow:SetPoint("BOTTOMRIGHT", buff, "BOTTOMRIGHT", 9, -6);
        container.BuffGlow:Show();
    else
        if buff.CustomGlowFrame and buff.CustomGlowFrame.BuffGlow then
            buff.CustomGlowFrame.BuffGlow:Hide();
        end
    end
end

-- Return aura category if should be shown, nil otherwise
local function ShouldShowBuffOverride(self, aura)
    if ( not aura ) or ( not aura.spellId ) then
        return nil;
    end

    -- Basically only show crowd controls and whitelisted debuffs applied by the player

    -- Some crowd controls are hidden by Blizzard, override the logic
    if addon.CrowdControlAuras[aura.spellId] then
        return AURA_CATEGORY.CROWD_CONTROL;
    end

    -- Parse non crowd control debuffs
    if aura.isHarmful then
        if (aura.sourceUnit == "player" or aura.sourceUnit == "pet" or aura.sourceUnit == "vehicle") then
            local spellId = aura.spellId;
            if addon.AuraParent[spellId] then
                spellId = addon.AuraParent[spellId];
            end

            return SweepyBoop.db.profile.nameplatesEnemy.debuffWhiteList[tostring(spellId)] and AURA_CATEGORY.DEBUFF;
        else
            return nil;
        end
    end

    -- Parse buffs
    if aura.isHelpful then
        local spellId = aura.spellId;
        if addon.AuraParent[spellId] then
            spellId = addon.AuraParent[spellId];
        end

        return SweepyBoop.db.profile.nameplatesEnemy.buffWhiteList[tostring(spellId)] and AURA_CATEGORY.BUFF;
    end
end

local function ParseAllAurasOverride(self)
    if self.auras == nil then
        self.auras = TableUtil.CreatePriorityTable(AuraUtil.DefaultAuraCompare, TableUtil.Constants.AssociativePriorityTable);
    else
        self.auras:Clear();
    end

    local function HandleAura(aura)
        local customCategory = ShouldShowBuffOverride(self, aura);
        if customCategory then
            aura.customCategory = customCategory;
            self.auras[aura.auraInstanceID] = aura;
        end

        return false;
    end

    local batchCount = nil;
    local usePackedAura = true;
    AuraUtil.ForEachAura(self.unit, "HARMFUL", batchCount, HandleAura, usePackedAura);

    if SweepyBoop.db.profile.nameplatesEnemy.showBuffsOnEnemy then
        AuraUtil.ForEachAura(self.unit, "HELPFUL", batchCount, HandleAura, usePackedAura);
    end
end

local function LayoutAuras(self, children, expandToHeight, verticalOffset)
    verticalOffset = verticalOffset or 0; -- buff row will set this based on the height of the debuff row
    if verticalOffset > 0 then
        verticalOffset = verticalOffset + rowGap;
    end

    local leftOffset, rightOffset, frameTopPadding, frameBottomPadding = self:GetPadding();
    local spacing = self.spacing or 0;
    local childrenWidth, childrenHeight = 0, 0;
    local hasExpandableChild = false;

    -- Calculate width and height based on children
    for i, child in ipairs(children) do
        if not self.skipChildLayout and IsLayoutFrame(child) then
            child:Layout();
        end

        local childWidth, childHeight = child:GetSize();
        local leftPadding, rightPadding, topPadding, bottomPadding = self:GetChildPadding(child);
        if (child.expand) then
            hasExpandableChild = true;
        end

        -- Expand child height if it is set to expand and we also have an expandToHeight value.
        if (child.expand and expandToHeight) then
            childHeight = expandToHeight - topPadding - bottomPadding - frameTopPadding - frameBottomPadding;
            child:SetHeight(childHeight);
            childWidth = child:GetWidth();
        end

        local childScale = child:GetScale();
        childWidth = childWidth * childScale;
        childHeight = childHeight * childScale;

        childrenHeight = math.max(childrenHeight, childHeight + topPadding + bottomPadding);
        childrenWidth = childrenWidth + childWidth + leftPadding + rightPadding;
        if (i > 1) then
            childrenWidth = childrenWidth + spacing;
        end

        -- Set child position
        child:ClearAllPoints();

        leftOffset = leftOffset + leftPadding;
        local bottomOffset = frameBottomPadding + bottomPadding;
        child:SetPoint("BOTTOMLEFT", leftOffset / childScale, (bottomOffset + verticalOffset) / childScale);
        leftOffset = leftOffset + childWidth + rightPadding + spacing;
    end

    return childrenWidth, childrenHeight, hasExpandableChild;
end

local function LayoutChildrenOverride (self, children, ignored, expandToHeight)
    -- Separate buffs and debuffs
    local buffs = {};
    local debuffs = {};
    for _, child in ipairs(children) do
        if child.isBuff then
            table.insert(buffs, child);
        else
            table.insert(debuffs, child);
        end
    end

    if debuffs then
        table.sort(debuffs, function (a, b)
            if a.customCategory ~= b.customCategory then
                if ( not b.customCategory ) then
                    return true;
                elseif ( not a.customCategory ) then
                    return false;
                else
                    return a.customCategory < b.customCategory;
                end
            end

            return AuraUtil.DefaultAuraCompare(a, b);
        end)
    end

    local debuffWidth, debuffHeight, debuffHasExpandableChild = LayoutAuras(self, debuffs, expandToHeight);
    local buffWidth, buffHeight, buffHasExpandableChild = LayoutAuras(self, buffs, expandToHeight, debuffHeight);

    return math.max(debuffWidth, buffWidth), debuffHeight + buffHeight, debuffHasExpandableChild or buffHasExpandableChild;
end

local function LayoutOverride(self)
    local children = self:GetLayoutChildren();
	local childrenWidth, childrenHeight, hasExpandableChild = LayoutChildrenOverride(self, children);

	local frameWidth, frameHeight = self:CalculateFrameSize(childrenWidth, childrenHeight);

	-- If at least one child had "expand" set and we did not already expand them, call LayoutChildren() again to expand them
	if (hasExpandableChild) then
		childrenWidth, childrenHeight = self:LayoutChildren(children, frameWidth, frameHeight);
		frameWidth, frameHeight = self:CalculateFrameSize(childrenWidth, childrenHeight);
	end

	self:SetSize(frameWidth, frameHeight);
	self:MarkClean();
end

addon.UpdateBuffsOverride = function(self, unit, unitAuraUpdateInfo, auraSettings)
    -- Override auraSettings because Blizzard code doesn't properly check unit hostility under Mind Control
    local isEnemy = addon.UnitIsHostile(unit);
    local shouldOverride = isEnemy and SweepyBoop.db.profile.nameplatesEnemy.auraFilterEnabled;

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
        if shouldOverride then
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
                if shouldOverride then
                    shouldShowBuff = ShouldShowBuffOverride(self, aura, auraSettings.showAll);
                else
                    shouldShowBuff = self:ShouldShowBuff(aura, auraSettings.showAll) and not C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, aura.auraInstanceID, filterString);
                end

                if shouldShowBuff then
                    aura.customCategory = shouldShowBuff;
                    self.auras[aura.auraInstanceID] = aura;
                    aurasChanged = true;
                end
            end
        end

        if unitAuraUpdateInfo.updatedAuraInstanceIDs ~= nil then
            for _, auraInstanceID in ipairs(unitAuraUpdateInfo.updatedAuraInstanceIDs) do
                if self.auras[auraInstanceID] ~= nil then
                    local newAura = C_UnitAuras.GetAuraDataByAuraInstanceID(self.unit, auraInstanceID);
                    if newAura then
                        newAura.customCategory = self.auras[auraInstanceID].customCategory;
                    end
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
        buff.customCategory = aura.customCategory;

        buff.Icon:SetTexture(aura.icon);
        if (aura.applications > 1) then
            buff.CountFrame.Count:SetText(aura.applications);
            buff.CountFrame.Count:Show();
        else
            buff.CountFrame.Count:Hide();
        end

        if buff.Border then
            if ( not shouldOverride ) then -- Use Blizzard default logic for non-hostile units
                UpdateCrowdControlGlow(buff, false);
                UpdatePurgableGlow(buff, false);
                UpdateBuffGlow(buff, false);
            elseif aura.isStealable then
                UpdateCrowdControlGlow(buff, false);
                UpdatePurgableGlow(buff, true);
                UpdateBuffGlow(buff, false);
            elseif aura.isHelpful then
                UpdateCrowdControlGlow(buff, false);
                UpdatePurgableGlow(buff, false);
                UpdateBuffGlow(buff, true);
            elseif aura.customCategory == AURA_CATEGORY.CROWD_CONTROL then
                UpdateCrowdControlGlow(buff, true);
                UpdatePurgableGlow(buff, false);
                UpdateBuffGlow(buff, false);
            else
                UpdateCrowdControlGlow(buff, false);
                UpdatePurgableGlow(buff, false);
                UpdateBuffGlow(buff, false);
            end
        end

        local largeIcon = shouldOverride and ( buff.isBuff or aura.customCategory == AURA_CATEGORY.CROWD_CONTROL );
        buff:SetScale(largeIcon and 1.25 or 1);

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

    if shouldOverride then
        LayoutOverride(self);
    else
        self:Layout();
    end
end

local function LayoutRow(self, auras, verticalOffset)
    verticalOffset = verticalOffset or 0; -- buff row will set this based on the height of the debuff row
    if verticalOffset > 0 then
        verticalOffset = verticalOffset + rowGap;
    end

    local leftOffset, rightOffset, frameTopPadding, frameBottomPadding = 0, 0, 0, 0;
    local childrenWidth, childrenHeight = 0, 0;

    for i, child in ipairs(auras) do
        if not self.skipChildLayout and IsLayoutFrame(child) then
            child:Layout();
        end

        local childWidth, childHeight = child:GetSize();
        local leftPadding, rightPadding, topPadding, bottomPadding = 0, 0, 0, 0;
        local childScale = child:GetScale();
        childWidth = childWidth * childScale;
        childHeight = childHeight * childScale;

        childrenHeight = math.max(childrenHeight, childHeight + topPadding + bottomPadding);
        childrenWidth = childrenWidth + childWidth + leftPadding + rightPadding;
        if (i > 1) then
            childrenWidth = childrenWidth + spacing;
        end

        -- Set child position
        child:ClearAllPoints();

        leftOffset = leftOffset + leftPadding;
        local bottomOffset = frameBottomPadding + bottomPadding;
        print(child.spellID, child:IsShown(), childScale, child.Icon:GetTexture());
        child:SetPoint("BOTTOMLEFT", leftOffset / childScale, (bottomOffset + verticalOffset) / childScale);
        leftOffset = leftOffset + childWidth + rightPadding + spacing;
    end

    return childrenWidth, childrenHeight;
end

local function CustomLayout(self)
    -- Separate buffs and debuffs
    local buffs = {};
    local debuffs = {};
    for _, child in ipairs(self.auraFrames) do
        if child.isBuff then
            table.insert(buffs, child);
        else
            table.insert(debuffs, child);
        end
    end

    if debuffs then
        table.sort(debuffs, function (a, b)
            if a.customCategory ~= b.customCategory then
                if ( not b.customCategory ) then
                    return true;
                elseif ( not a.customCategory ) then
                    return false;
                else
                    return a.customCategory < b.customCategory;
                end
            end

            return AuraUtil.DefaultAuraCompare(a, b);
        end)
    end

    local _, debuffHeight = LayoutRow(self, debuffs);
    LayoutRow(self, buffs, debuffHeight);
end

local function UpdateBuffs(self, blizzardBuffFrame, unit, unitAuraUpdateInfo)
    local previousUnit = self.unit;
    self.unit = unit;

    local aurasChanged = false;
    if unitAuraUpdateInfo == nil or unitAuraUpdateInfo.isFullUpdate or unit ~= previousUnit then
        ParseAllAurasOverride(self);
        aurasChanged = true;
    else
        if unitAuraUpdateInfo.addedAuras ~= nil then
            for _, aura in ipairs(unitAuraUpdateInfo.addedAuras) do
                local customCategory = ShouldShowBuffOverride(self, aura);

                if customCategory then
                    aura.customCategory = customCategory;
                    self.auras[aura.auraInstanceID] = aura;
                    aurasChanged = true;
                end
            end
        end

        if unitAuraUpdateInfo.updatedAuraInstanceIDs ~= nil then
            for _, auraInstanceID in ipairs(unitAuraUpdateInfo.updatedAuraInstanceIDs) do
                if self.auras[auraInstanceID] ~= nil then
                    local newAura = C_UnitAuras.GetAuraDataByAuraInstanceID(self.unit, auraInstanceID);
                    if newAura then
                        newAura.customCategory = self.auras[auraInstanceID].customCategory;
                    end
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

    if not aurasChanged then return end

    if ( not addon.UnitIsHostile(unit) ) then
        self:SetAlpha(0);
        if blizzardBuffFrame then
            blizzardBuffFrame:SetAlpha(1);
        end

        return;
    end

    local buffIndex = 1;
    self.auras:Iterate(function(auraInstanceID, aura)
        local buff = self.auraFrames[buffIndex];
        if ( not buff ) then
            buff = CreateFrame("Frame", nil, self, "CustomNameplateBuffButtonTemplate");
            self.auraFrames[buffIndex] = buff;
        end
        buff.auraInstanceID = auraInstanceID;
        buff.isBuff = aura.isHelpful;
        buff.layoutIndex = buffIndex;
        buff.spellID = aura.spellId;
        buff.customCategory = aura.customCategory;

        buff.Icon:SetTexture(aura.icon);
        if (aura.applications > 1) then
            buff.CountFrame.Count:SetText(aura.applications);
            buff.CountFrame.Count:Show();
        else
            buff.CountFrame.Count:Hide();
        end

        if (aura.isStealable) then
            UpdateCrowdControlGlow(buff, false);
            UpdatePurgableGlow(buff, true);
            UpdateBuffGlow(buff, false);
        elseif aura.isHelpful then
            UpdateCrowdControlGlow(buff, false);
            UpdatePurgableGlow(buff, false);
            UpdateBuffGlow(buff, true);
        elseif aura.customCategory == AURA_CATEGORY.CROWD_CONTROL then
            UpdateCrowdControlGlow(buff, true);
            UpdatePurgableGlow(buff, false);
            UpdateBuffGlow(buff, false);
        else
            UpdateCrowdControlGlow(buff, false);
            UpdatePurgableGlow(buff, false);
            UpdateBuffGlow(buff, false);
        end

        local largeIcon = (buff.isBuff or aura.customCategory == AURA_CATEGORY.CROWD_CONTROL);
        buff:SetScale(largeIcon and 1.25 or 1);

        CooldownFrame_Set(buff.Cooldown, aura.expirationTime - aura.duration, aura.duration, aura.duration > 0, true);

        buff:Show();

        buffIndex = buffIndex + 1;
        return buffIndex >= BUFF_MAX_DISPLAY;
    end);

    if blizzardBuffFrame then
        blizzardBuffFrame:SetAlpha(0);
    end
    self:SetAlpha(1);
    CustomLayout(self);
end

-- Issue: auras are filtered properly initially but as a fight goes on, auras that are supposed to be hidden show up again
-- Possibly need to override logic for isFullUpdate
addon.OnNamePlateAuraUpdate = function (frame, unit, unitAuraUpdateInfo)
    if not frame.CustomBuffFrame then
        frame.CustomBuffFrame = CreateFrame("Frame", nil, self);
        frame.CustomBuffFrame.auraFrames = {};

        if addon.PROJECT_MAINLINE then
            frame.CustomBuffFrame:SetPoint("BOTTOMLEFT", frame.BuffFrame, "BOTTOMLEFT");
            frame.CustomBuffFrame:SetIgnoreParentAlpha(true);
        else
            frame.CustomBuffFrame:SetPoint("BOTTOMLEFT", frame.healthBar, "TOPLEFT", 0, 5);
        end
    end

    UpdateBuffs(frame.CustomBuffFrame, frame.BuffFrame, unit, unitAuraUpdateInfo);
end
