local _, addon = ...;

local AURA_KIND = {
    CROWD_CONTROL = 1,
    DEFENSIVE = 2,
    IMPORTANT_BUFF = 3,
};

local KIND_TINT = {
    [AURA_KIND.CROWD_CONTROL] = { 1, 0.6471, 0 },
    [AURA_KIND.DEFENSIVE] = { 0.2, 0.65, 1 },
    [AURA_KIND.IMPORTANT_BUFF] = { 0, 1, 0 },
};

local RAIL = {
    LEFT = {
        frameKey = "sweepyBoopBigDebuffsLeftRail",
        anchorPoint = "RIGHT",
        anchorRelativePoint = "LEFT",
        direction = -1,
    },
    RIGHT = {
        frameKey = "sweepyBoopBigDebuffsRightRail",
        anchorPoint = "LEFT",
        anchorRelativePoint = "RIGHT",
        direction = 1,
    },
};

local scratchLeft = {};
local scratchRight = {};
local scratchLeftAuraIDs = {};

local function ResetArray(array)
    for i = #array, 1, -1 do
        array[i] = nil;
    end
end

local function AuraComesFirst(auraA, auraB)
    if auraA.sweepyBoopKind ~= auraB.sweepyBoopKind then
        return auraA.sweepyBoopKind < auraB.sweepyBoopKind;
    end

    return ( auraA.sweepyBoopOrder or 0 ) < ( auraB.sweepyBoopOrder or 0 );
end

local function IsTrueOrSecret(value)
    return addon.IsSecretValue(value) or value;
end

local function AddAuraCandidate(target, auraData, kind)
    if not auraData then return end

    auraData.sweepyBoopKind = kind;
    auraData.sweepyBoopOrder = #target;
    table.insert(target, auraData);
end

local function VisitCurrentAuras(unit, filter, visitor)
    local auras = C_UnitAuras.GetUnitAuras(unit, filter, nil, Enum.UnitAuraSortRule.Unsorted, Enum.UnitAuraSortDirection.Reverse);
    if not auras then return end

    for _, auraData in ipairs(auras) do
        visitor(auraData);
    end
end

local function AddCrowdControlAura(auraData)
    if ( not auraData ) or ( not auraData.spellId ) then return end

    if addon.IsSecretValue(auraData.spellId) or IsTrueOrSecret(C_Spell.IsSpellCrowdControl(auraData.spellId)) then
        AddAuraCandidate(scratchRight, auraData, AURA_KIND.CROWD_CONTROL);
    end
end

local function RememberLeftAura(auraData, kind)
    AddAuraCandidate(scratchLeft, auraData, kind);
    if auraData.auraInstanceID and not addon.IsSecretValue(auraData.auraInstanceID) then
        scratchLeftAuraIDs[auraData.auraInstanceID] = true;
    end
end

local function AddBigDefensiveAura(auraData)
    if ( not auraData ) or ( not auraData.spellId ) then return end

    local isDefensive = addon.IsSecretValue(auraData.spellId) or ( C_UnitAuras.AuraIsBigDefensive and C_UnitAuras.AuraIsBigDefensive(auraData.spellId) );
    if ( not C_UnitAuras.AuraIsBigDefensive ) or IsTrueOrSecret(isDefensive) then
        RememberLeftAura(auraData, AURA_KIND.DEFENSIVE);
    end
end

local function AddExternalDefensiveAura(auraData)
    if not auraData then return end
    if auraData.auraInstanceID and ( not addon.IsSecretValue(auraData.auraInstanceID) ) and scratchLeftAuraIDs[auraData.auraInstanceID] then return end

    RememberLeftAura(auraData, AURA_KIND.DEFENSIVE);
end

local function GetBlizzardNameplateBuffIDs(nameplate)
    local frame = nameplate and nameplate.UnitFrame;
    local auraFrame = frame and frame.AurasFrame;
    if auraFrame and auraFrame.buffList and auraFrame.buffList.Iterate and ( not auraFrame.IsForbidden or not auraFrame:IsForbidden() ) then
        return auraFrame.buffList;
    end
end

local function AddNameplateImportantBuff(unit, auraInstanceID)
    if ( not auraInstanceID ) or addon.IsSecretValue(auraInstanceID) then return end
    if scratchLeftAuraIDs[auraInstanceID] then return end

    local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, auraInstanceID);
    if auraData then
        RememberLeftAura(auraData, AURA_KIND.IMPORTANT_BUFF);
    end
end

local function BuildAuraSnapshot(nameplate, unit, config)
    ResetArray(scratchLeft);
    ResetArray(scratchRight);
    wipe(scratchLeftAuraIDs);

    if config.bigDebuffsShowCrowdControl then
        VisitCurrentAuras(unit, "HARMFUL|CROWD_CONTROL", AddCrowdControlAura);
    end

    if config.bigDebuffsShowDefensives then
        VisitCurrentAuras(unit, "HELPFUL|BIG_DEFENSIVE", AddBigDefensiveAura);
        VisitCurrentAuras(unit, "HELPFUL|EXTERNAL_DEFENSIVE", AddExternalDefensiveAura);
    end

    if config.bigDebuffsShowImportantBuffs then
        local buffIDs = GetBlizzardNameplateBuffIDs(nameplate);
        if buffIDs then
            buffIDs:Iterate(function(auraInstanceID)
                AddNameplateImportantBuff(unit, auraInstanceID);
            end);
        end
    end

    table.sort(scratchLeft, AuraComesFirst);
    table.sort(scratchRight, AuraComesFirst);
end

local function PositionRail(rail, nameplate, railInfo, config)
    local anchor = nameplate.UnitFrame and nameplate.UnitFrame.healthBar or nameplate;
    local offsetX = config.bigDebuffsOffsetX or addon.BIG_DEBUFFS_DEFAULTS.OFFSET_X;
    local offsetY = config.bigDebuffsOffsetY or addon.BIG_DEBUFFS_DEFAULTS.OFFSET_Y;

    rail:ClearAllPoints();
    rail:SetPoint(railInfo.anchorPoint, anchor, railInfo.anchorRelativePoint, railInfo.direction * (2 + offsetX), offsetY);
    rail.sweepyBoopLastModified = config.lastModified;
end

local function EnsureRail(nameplate, railInfo)
    local rail = nameplate[railInfo.frameKey];
    if rail then return rail end

    rail = CreateFrame("Frame", nil, nameplate);
    rail:SetMouseClickEnabled(false);
    rail:SetIgnoreParentAlpha(true);
    rail:SetFrameStrata("HIGH");
    rail:SetSize(1, 1);
    rail.sweepyBoopSlots = {};
    nameplate[railInfo.frameKey] = rail;

    return rail;
end

local function CreateSlot(rail)
    local slot = CreateFrame("Frame", nil, rail);
    slot:SetMouseClickEnabled(false);
    slot:SetIgnoreParentAlpha(true);

    slot.backdrop = slot:CreateTexture(nil, "BACKGROUND");
    slot.backdrop:SetAllPoints(slot);
    slot.backdrop:SetColorTexture(0, 0, 0, 1);

    slot.debuffIcon = slot:CreateTexture(nil, "ARTWORK");
    slot.debuffIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92);

    slot.debuffBorder = slot:CreateTexture(nil, "OVERLAY");
    slot.debuffBorder:SetPoint("TOPLEFT", slot, "TOPLEFT", -1, 1);
    slot.debuffBorder:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", 1, -1);
    slot.debuffBorder:SetTexture(addon.BIG_DEBUFFS_ICON_STYLE.DEBUFF_BORDER_TEXTURE);
    slot.debuffBorder:SetTexCoord(unpack(addon.BIG_DEBUFFS_ICON_STYLE.DEBUFF_BORDER_TEX_COORDS));

    slot.auraHighlightFrame = CreateFrame("Frame", nil, slot);
    slot.auraHighlightFrame:SetSize(addon.BIG_DEBUFFS_ICON_STYLE.AURA_HIGHLIGHT_BASE_SIZE, addon.BIG_DEBUFFS_ICON_STYLE.AURA_HIGHLIGHT_BASE_SIZE);
    slot.auraHighlightFrame:SetPoint("CENTER", slot, "CENTER");

    slot.auraHighlightGlow = slot.auraHighlightFrame:CreateTexture(nil, "BORDER");
    slot.auraHighlightGlow:SetTexture(addon.BIG_DEBUFFS_ICON_STYLE.AURA_HIGHLIGHT_GLOW_TEXTURE);
    slot.auraHighlightGlow:SetBlendMode("ADD");

    slot.auraHighlightBorder = slot.auraHighlightFrame:CreateTexture(nil, "OVERLAY");
    slot.auraHighlightBorder:SetTexture(addon.BIG_DEBUFFS_ICON_STYLE.AURA_HIGHLIGHT_BORDER_TEXTURE);
    slot.auraHighlightBorder:SetBlendMode("ADD");

    slot.glowIcon = slot:CreateTexture(nil, "ARTWORK");
    slot.glowIcon:SetAllPoints(slot);

    slot.bigDebuffsCooldown = CreateFrame("Cooldown", nil, slot, "CooldownFrameTemplate");
    slot.bigDebuffsCooldown:SetHideCountdownNumbers(false);
    slot.cooldown = slot.bigDebuffsCooldown;

    slot.bigDebuffsCount = slot:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall");
    slot.count = slot.bigDebuffsCount;

    return slot;
end

local function EnsureSlot(rail, index)
    local slot = rail.sweepyBoopSlots[index];
    if slot then return slot end

    slot = CreateSlot(rail);
    rail.sweepyBoopSlots[index] = slot;

    return slot;
end

local function GetIconStyle(config)
    return config.bigDebuffsIconStyle or addon.BIG_DEBUFFS_DEFAULTS.ICON_STYLE;
end

local function IsAuraHighlightStyle(config)
    return GetIconStyle(config) == addon.BIG_DEBUFFS_ICON_STYLE_ID.AURA_HIGHLIGHT;
end

local function GetSlotSize(config)
    local iconSize = config.bigDebuffsIconSize or addon.BIG_DEBUFFS_DEFAULTS.ICON_SIZE;
    return iconSize, iconSize;
end

local function GetAuraHighlightScale(config)
    local iconSize = config.bigDebuffsIconSize or addon.BIG_DEBUFFS_DEFAULTS.ICON_SIZE;
    return iconSize / addon.BIG_DEBUFFS_ICON_STYLE.AURA_HIGHLIGHT_BASE_SIZE;
end

local function GetAuraHighlightPadding()
    return addon.BIG_DEBUFFS_ICON_STYLE.AURA_HIGHLIGHT_PADDING;
end

local function HideAuraHighlightGlow(slot)
    if slot.auraHighlightGlow then
        slot.auraHighlightGlow:Hide();
    end
    if slot.auraHighlightBorder then
        slot.auraHighlightBorder:Hide();
    end
end

local function ShowAuraHighlightGlow(slot, color, config)
    local padding = GetAuraHighlightPadding();
    slot.auraHighlightFrame:SetScale(GetAuraHighlightScale(config));
    slot.auraHighlightFrame:ClearAllPoints();
    slot.auraHighlightFrame:SetPoint("CENTER", slot, "CENTER");
    slot.auraHighlightGlow:SetVertexColor(color[1], color[2], color[3], 0.9);
    slot.auraHighlightGlow:ClearAllPoints();
    slot.auraHighlightGlow:SetPoint("TOPLEFT", slot, "TOPLEFT", -padding, padding);
    slot.auraHighlightGlow:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", padding, -padding);
    slot.auraHighlightGlow:Show();

    slot.auraHighlightBorder:SetVertexColor(color[1], color[2], color[3], 1);
    slot.auraHighlightBorder:ClearAllPoints();
    slot.auraHighlightBorder:SetPoint("TOPLEFT", slot, "TOPLEFT", -padding, padding);
    slot.auraHighlightBorder:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", padding, -padding);
    slot.auraHighlightBorder:Show();
end

local function SetSlotStyle(slot, config)
    local useAuraHighlightStyle = IsAuraHighlightStyle(config);
    local useGlowStyle = GetIconStyle(config) == addon.BIG_DEBUFFS_ICON_STYLE_ID.GLOW;

    slot.backdrop:SetShown(true);
    slot.debuffIcon:SetShown(not useGlowStyle);
    slot.debuffBorder:SetShown(not useAuraHighlightStyle and not useGlowStyle);
    if not useAuraHighlightStyle then
        HideAuraHighlightGlow(slot);
    end
    slot.glowIcon:SetShown(useGlowStyle);

    slot.cooldown = slot.bigDebuffsCooldown;
    slot.count = slot.bigDebuffsCount;

    if useGlowStyle then
        slot.icon = slot.glowIcon;
        slot.border = nil;
        slot.icon:ClearAllPoints();
        slot.icon:SetAllPoints(slot);
        slot.icon:SetTexCoord(0, 1, 0, 1);
    else
        slot.icon = slot.debuffIcon;
        slot.border = useAuraHighlightStyle and nil or slot.debuffBorder;
        slot.icon:ClearAllPoints();
        if useAuraHighlightStyle then
            slot.icon:SetAllPoints(slot);
        else
            slot.icon:SetPoint("TOPLEFT", slot, "TOPLEFT", addon.BIG_DEBUFFS_ICON_STYLE.DEBUFF_ICON_INSET, -addon.BIG_DEBUFFS_ICON_STYLE.DEBUFF_ICON_INSET);
            slot.icon:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", -addon.BIG_DEBUFFS_ICON_STYLE.DEBUFF_ICON_INSET, addon.BIG_DEBUFFS_ICON_STYLE.DEBUFF_ICON_INSET);
        end
        slot.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92);
    end

    slot.cooldown:ClearAllPoints();
    slot.cooldown:SetAllPoints(slot.icon);
    slot.count:ClearAllPoints();
    slot.count:SetFontObject(NumberFontNormalSmall);
    slot.count:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", 2, -2);
end

local function GetSlotTint(auraData)
    local color = KIND_TINT[auraData.sweepyBoopKind] or KIND_TINT[AURA_KIND.IMPORTANT_BUFF];
    return color;
end

local function SetSlotTint(slot, auraData, config)
    local color = GetSlotTint(auraData);
    if GetIconStyle(config) == addon.BIG_DEBUFFS_ICON_STYLE_ID.GLOW then
        HideAuraHighlightGlow(slot);
        addon.ShowProcGlow(slot, { color[1], color[2], color[3], 1 });
    elseif IsAuraHighlightStyle(config) then
        addon.HideProcGlow(slot);
        ShowAuraHighlightGlow(slot, color, config);
    else
        HideAuraHighlightGlow(slot);
        addon.HideProcGlow(slot);
        slot.border:SetVertexColor(color[1], color[2], color[3]);
    end
end

local function ConfigureSlotCooldown(slot, config)
    local useGlowStyle = GetIconStyle(config) == addon.BIG_DEBUFFS_ICON_STYLE_ID.GLOW;

    slot.cooldown:SetDrawBling(false);
    slot.cooldown:SetDrawSwipe(true);
    slot.cooldown:SetDrawEdge(true);
    slot.cooldown:SetReverse(true);
    if slot.cooldown.SetSwipeColor then
        slot.cooldown:SetSwipeColor(0, 0, 0, useGlowStyle and 0.5 or 0.55);
    end
    if slot.cooldown.SetEdgeTexture then
        slot.cooldown:SetEdgeTexture(addon.BIG_DEBUFFS_ICON_STYLE.GLOW_COOLDOWN_EDGE_TEXTURE);
    end
end

local function SetSlotCooldown(slot, unit, auraData)
    local durationObject = auraData.auraInstanceID and ( not addon.IsSecretValue(auraData.auraInstanceID) ) and C_UnitAuras.GetAuraDuration(unit, auraData.auraInstanceID);
    if durationObject and slot.cooldown.SetCooldownFromDurationObject then
        slot.cooldown:SetCooldownFromDurationObject(durationObject);
        slot.cooldown:Show();
        return;
    end

    if auraData.duration and auraData.expirationTime and ( not addon.IsSecretValue(auraData.duration) ) and ( not addon.IsSecretValue(auraData.expirationTime) ) then
        slot.cooldown:SetCooldown(auraData.expirationTime - auraData.duration, auraData.duration);
        slot.cooldown:Show();
        return;
    end

    slot.cooldown:SetCooldown(0, 0);
    slot.cooldown:Hide();
end

local function SetSlotIcon(slot, icon)
    if icon then
        local success = pcall(slot.icon.SetTexture, slot.icon, icon);
        if success then return end
    end

    slot.icon:SetTexture(addon.ICON_ID_PVP_CURSOR);
end

local function SetSlotCount(slot, applications)
    if applications and ( not addon.IsSecretValue(applications) ) and applications > 1 then
        slot.count:SetText(applications);
        slot.count:Show();
    else
        slot.count:Hide();
    end
end

local function SetSlotAura(slot, unit, auraData, config)
    slot:SetSize(GetSlotSize(config));
    SetSlotStyle(slot, config);
    ConfigureSlotCooldown(slot, config);
    SetSlotIcon(slot, auraData.icon);
    SetSlotTint(slot, auraData, config);
    SetSlotCooldown(slot, unit, auraData);

    SetSlotCount(slot, auraData.applications);

    slot:Show();
end

local function HideRail(rail)
    if not rail then return end

    for _, slot in ipairs(rail.sweepyBoopSlots) do
        HideAuraHighlightGlow(slot);
        addon.HideProcGlow(slot);
        slot:Hide();
    end
    rail:Hide();
end

local function PaintRail(rail, railInfo, auras, config, unit)
    local slotWidth, slotHeight = GetSlotSize(config);
    local spacing = config.bigDebuffsSpacing or addon.BIG_DEBUFFS_DEFAULTS.SPACING;
    local slotStep = slotWidth + spacing;
    if IsAuraHighlightStyle(config) then
        slotStep = slotStep + ( 2 * addon.BIG_DEBUFFS_ICON_STYLE.AURA_HIGHLIGHT_PADDING * GetAuraHighlightScale(config) );
    end
    local visibleSlots = math.min(#auras, config.bigDebuffsMaxIcons or addon.BIG_DEBUFFS_DEFAULTS.MAX_ICONS);

    rail:SetSize(math.max(visibleSlots, 1) * slotWidth + math.max(visibleSlots - 1, 0) * ( slotStep - slotWidth ), slotHeight);

    for index, slot in ipairs(rail.sweepyBoopSlots) do
        if index > visibleSlots then
            HideAuraHighlightGlow(slot);
            addon.HideProcGlow(slot);
            slot:Hide();
        end
    end

    for index = 1, visibleSlots do
        local slot = EnsureSlot(rail, index);
        local offset = ( index - 1 ) * slotStep;

        slot:ClearAllPoints();
        if railInfo.direction < 0 then
            slot:SetPoint("RIGHT", rail, "RIGHT", -offset, 0);
        else
            slot:SetPoint("LEFT", rail, "LEFT", offset, 0);
        end

        SetSlotAura(slot, unit, auras[index], config);
    end

    rail:SetShown(visibleSlots > 0);
end

addon.UpdateBigDebuffs = function(nameplate, frame)
    if not addon.PROJECT_MAINLINE then return end
    if ( not nameplate ) or ( not frame ) or ( not frame.unit ) then return end

    local config = SweepyBoop.db.profile.nameplatesEnemy;
    if ( not config.bigDebuffsEnabled ) or ( not UnitIsPlayer(frame.unit) ) or ( not addon.UnitIsHostile(frame.unit) ) then
        addon.HideBigDebuffs(nameplate);
        return;
    end

    BuildAuraSnapshot(nameplate, frame.unit, config);

    local leftRail = EnsureRail(nameplate, RAIL.LEFT);
    local rightRail = EnsureRail(nameplate, RAIL.RIGHT);
    if leftRail.sweepyBoopLastModified ~= config.lastModified then
        PositionRail(leftRail, nameplate, RAIL.LEFT, config);
    end
    if rightRail.sweepyBoopLastModified ~= config.lastModified then
        PositionRail(rightRail, nameplate, RAIL.RIGHT, config);
    end

    PaintRail(leftRail, RAIL.LEFT, scratchLeft, config, frame.unit);
    PaintRail(rightRail, RAIL.RIGHT, scratchRight, config, frame.unit);
end

addon.HideBigDebuffs = function(nameplate)
    if not nameplate then return end

    HideRail(nameplate.sweepyBoopBigDebuffsLeftRail);
    HideRail(nameplate.sweepyBoopBigDebuffsRightRail);
end
