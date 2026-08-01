local _, addon = ...;

local Type, Version = "NameplateBigDebuffsPreview-SweepyBoop", 1;
local AceGUI = LibStub and LibStub("AceGUI-3.0", true);
if not AceGUI or ( AceGUI:GetWidgetVersion(Type) or 0 ) >= Version then return end

local previewWidgets = setmetatable({}, { __mode = "k" });
local TEXTURE_WHITE = "Interface\\BUTTONS\\WHITE8X8";
local previewHeight = 128;
local sampleWidth = 360;
local sampleHeight = 70;
local healthWidth = 210;
local healthHeight = 24;
local previewLeftInset = 8;
local previewMaxIcons = addon.BIG_DEBUFFS_DEFAULTS.MAX_ICONS;
local ccSampleSpell = 118; -- Polymorph
local secondCcSampleSpell = 408; -- Kidney Shot
local defensiveSampleSpell = 642; -- Divine Shield
local importantSampleSpell = 31884; -- Avenging Wrath
local fallbackCcTexture = "Interface\\Icons\\Spell_Nature_Polymorph";
local fallbackSecondCcTexture = "Interface\\Icons\\Ability_Rogue_KidneyShot";
local fallbackDefensiveTexture = "Interface\\Icons\\Spell_Holy_DivineIntervention";
local fallbackImportantTexture = "Interface\\Icons\\Spell_Holy_AvengineWrath";
local cooldownDuration = 10;
local cooldownElapsed = 3;
local sampleAuras = {
    left = {
        { option = "bigDebuffsShowDefensives", spellID = defensiveSampleSpell, fallbackTexture = fallbackDefensiveTexture, color = { 0.2, 0.65, 1 } },
        { option = "bigDebuffsShowImportantBuffs", spellID = importantSampleSpell, fallbackTexture = fallbackImportantTexture, color = { 0, 1, 0 } },
    },
    right = {
        { option = "bigDebuffsShowCrowdControl", spellID = ccSampleSpell, fallbackTexture = fallbackCcTexture, color = { 1, 0.6471, 0 } },
        { option = "bigDebuffsShowCrowdControl", spellID = secondCcSampleSpell, fallbackTexture = fallbackSecondCcTexture, color = { 1, 0.6471, 0 } },
    },
};

local function GetConfig()
    return SweepyBoop.db.profile.nameplatesEnemy;
end

local function GetIconSize(config)
    local iconSize = tonumber(config.bigDebuffsIconSize) or addon.BIG_DEBUFFS_DEFAULTS.ICON_SIZE;
    if iconSize < 20 then return 20 end
    if iconSize > 60 then return 60 end
    return iconSize;
end

local function RestartCooldown(slot)
    slot.cooldown:SetCooldown(GetTime() - cooldownElapsed, cooldownDuration);
    slot.cooldown:Show();
end

local function ConfigureCooldown(cooldown)
    cooldown:SetDrawBling(false);
    cooldown:SetDrawSwipe(true);
    cooldown:SetDrawEdge(true);
    cooldown:SetReverse(true);
    if cooldown.SetSwipeColor then
        cooldown:SetSwipeColor(0, 0, 0, 0.55);
    end
    if cooldown.SetEdgeTexture then
        cooldown:SetEdgeTexture("Interface\\Cooldown\\UI-HUD-ActionBar-LoC");
    end
end

local function CreatePreviewSlot(parent)
    local slot = CreateFrame("Frame", nil, parent);
    slot:Hide();

    slot.backdrop = slot:CreateTexture(nil, "BACKGROUND");
    slot.backdrop:SetAllPoints(slot);
    slot.backdrop:SetTexture(TEXTURE_WHITE);
    slot.backdrop:SetVertexColor(0, 0, 0, 1);

    slot.debuffIcon = slot:CreateTexture(nil, "ARTWORK");
    slot.debuffIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92);

    slot.debuffBorder = slot:CreateTexture(nil, "OVERLAY");
    slot.debuffBorder:SetPoint("TOPLEFT", slot, "TOPLEFT", -1, 1);
    slot.debuffBorder:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", 1, -1);
    slot.debuffBorder:SetTexture(addon.BIG_DEBUFFS_ICON_STYLE.DEBUFF_BORDER_TEXTURE);
    slot.debuffBorder:SetTexCoord(unpack(addon.BIG_DEBUFFS_ICON_STYLE.DEBUFF_BORDER_TEX_COORDS));

    slot.auraHighlightGlow = slot:CreateTexture(nil, "BORDER");
    slot.auraHighlightGlow:SetTexture(addon.BIG_DEBUFFS_ICON_STYLE.AURA_HIGHLIGHT_GLOW_TEXTURE);
    slot.auraHighlightGlow:SetBlendMode("ADD");

    slot.auraHighlightBorder = slot:CreateTexture(nil, "OVERLAY");
    slot.auraHighlightBorder:SetTexture(addon.BIG_DEBUFFS_ICON_STYLE.AURA_HIGHLIGHT_BORDER_TEXTURE);
    slot.auraHighlightBorder:SetBlendMode("ADD");

    slot.glowIcon = slot:CreateTexture(nil, "ARTWORK");
    slot.glowIcon:SetAllPoints(slot);

    slot.bigDebuffsCooldown = CreateFrame("Cooldown", nil, slot, "CooldownFrameTemplate");
    slot.cooldown = slot.bigDebuffsCooldown;
    ConfigureCooldown(slot.cooldown);
    slot.cooldown:SetScript("OnCooldownDone", function()
        RestartCooldown(slot);
    end);

    return slot;
end

local function BuildSample(parent)
    local sample = CreateFrame("Frame", nil, parent);
    sample:SetPoint("TOPLEFT", parent, "TOPLEFT", previewLeftInset, -28);
    sample:SetSize(sampleWidth, sampleHeight);

    local health = CreateFrame("Frame", nil, sample);
    health:SetPoint("CENTER", sample, "CENTER", 0, 0);
    health:SetSize(healthWidth, healthHeight);

    local healthBorder = health:CreateTexture(nil, "BACKGROUND");
    healthBorder:SetAllPoints(health);
    healthBorder:SetTexture(TEXTURE_WHITE);
    healthBorder:SetVertexColor(0, 0, 0, 1);

    local healthInset = health:CreateTexture(nil, "BORDER");
    healthInset:SetPoint("TOPLEFT", health, "TOPLEFT", 2, -2);
    healthInset:SetPoint("BOTTOMRIGHT", health, "BOTTOMRIGHT", -2, 2);
    healthInset:SetTexture(TEXTURE_WHITE);
    healthInset:SetVertexColor(0.16, 0.09, 0.04, 1);

    local healthFill = health:CreateTexture(nil, "ARTWORK");
    healthFill:SetPoint("TOPLEFT", health, "TOPLEFT", 4, -4);
    healthFill:SetPoint("BOTTOMRIGHT", health, "BOTTOMRIGHT", -4, 4);
    healthFill:SetTexture(TEXTURE_WHITE);
    healthFill:SetVertexColor(0.62, 0.28, 0.03, 1);

    local healthHighlight = health:CreateTexture(nil, "OVERLAY");
    healthHighlight:SetPoint("TOPLEFT", healthFill, "TOPLEFT");
    healthHighlight:SetPoint("TOPRIGHT", healthFill, "TOPRIGHT");
    healthHighlight:SetHeight(5);
    healthHighlight:SetTexture(TEXTURE_WHITE);
    healthHighlight:SetVertexColor(1, 0.58, 0.12, 0.45);

    local nameText = health:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmallOutline");
    nameText:SetPoint("LEFT", health, "LEFT", 8, 0);
    nameText:SetText("Target Name");
    nameText:SetTextColor(1, 0.92, 0.78, 1);

    local leftRail = CreateFrame("Frame", nil, sample);
    leftRail:SetSize(1, 1);
    leftRail:Show();
    leftRail.slots = {};

    local rightRail = CreateFrame("Frame", nil, sample);
    rightRail:SetSize(1, 1);
    rightRail:Show();
    rightRail.slots = {};

    return {
        frame = sample,
        health = health,
        leftRail = leftRail,
        rightRail = rightRail,
    };
end

local function EnsureSlot(rail, index)
    if not rail.slots[index] then
        rail.slots[index] = CreatePreviewSlot(rail);
    end

    return rail.slots[index];
end

local HideAuraHighlightGlow;

local function ClearRail(rail)
    for _, slot in ipairs(rail.slots) do
        slot.previewActive = false;
        slot.cooldown:SetCooldown(0, 0);
        slot.cooldown:Hide();
        HideAuraHighlightGlow(slot);
        addon.HideProcGlow(slot);
        slot:Hide();
    end
end

local function GetIconStyle(config)
    return config.bigDebuffsIconStyle or addon.BIG_DEBUFFS_DEFAULTS.ICON_STYLE;
end

local function IsAuraHighlightStyle(config)
    return GetIconStyle(config) == addon.BIG_DEBUFFS_ICON_STYLE_ID.AURA_HIGHLIGHT;
end

local function GetSlotSize(config)
    local iconSize = GetIconSize(config);
    return iconSize, iconSize;
end

local function GetAuraHighlightPadding(config)
    return addon.BIG_DEBUFFS_ICON_STYLE.AURA_HIGHLIGHT_PADDING * GetIconSize(config) / addon.BIG_DEBUFFS_ICON_STYLE.AURA_HIGHLIGHT_PADDING_BASE_SIZE;
end

HideAuraHighlightGlow = function(slot)
    if slot.auraHighlightGlow then
        slot.auraHighlightGlow:Hide();
    end
    if slot.auraHighlightBorder then
        slot.auraHighlightBorder:Hide();
    end
end

local function ShowAuraHighlightGlow(slot, color, config)
    local padding = GetAuraHighlightPadding(config);
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
end

local function SetSlotTint(slot, color, config)
    if GetIconStyle(config) == addon.BIG_DEBUFFS_ICON_STYLE_ID.GLOW then
        HideAuraHighlightGlow(slot);
        addon.ShowProcGlow(slot, { color[1], color[2], color[3], 1 });
    elseif IsAuraHighlightStyle(config) then
        addon.HideProcGlow(slot);
        ShowAuraHighlightGlow(slot, color, config);
    else
        HideAuraHighlightGlow(slot);
        addon.HideProcGlow(slot);
        slot.border:SetVertexColor(color[1], color[2], color[3], 1);
    end
end

local function ConfigureSlotCooldown(slot, config)
    local useGlowStyle = GetIconStyle(config) == addon.BIG_DEBUFFS_ICON_STYLE_ID.GLOW;

    slot.cooldown:SetDrawEdge(true);
    slot.cooldown:SetReverse(true);
    if slot.cooldown.SetSwipeColor then
        slot.cooldown:SetSwipeColor(0, 0, 0, useGlowStyle and 0.5 or 0.55);
    end
    if slot.cooldown.SetEdgeTexture then
        slot.cooldown:SetEdgeTexture(addon.BIG_DEBUFFS_ICON_STYLE.GLOW_COOLDOWN_EDGE_TEXTURE);
    end
end

local function RenderRail(rail, anchor, point, relativePoint, direction, sampleData, config, enabled)
    local slotWidth, slotHeight = GetSlotSize(config);
    local spacing = config.bigDebuffsSpacing or addon.BIG_DEBUFFS_DEFAULTS.SPACING;
    local slotStep = slotWidth + spacing;
    if IsAuraHighlightStyle(config) then
        slotStep = slotStep + ( 2 * GetAuraHighlightPadding(config) );
    end
    local maxIcons = math.min(config.bigDebuffsMaxIcons or addon.BIG_DEBUFFS_DEFAULTS.MAX_ICONS, previewMaxIcons);
    local shownCount = 0;

    rail:SetSize(math.max(maxIcons, 1) * slotWidth + math.max(maxIcons - 1, 0) * ( slotStep - slotWidth ), slotHeight);
    rail:ClearAllPoints();
    rail:SetPoint(point, anchor, relativePoint, direction * (2 + (config.bigDebuffsOffsetX or addon.BIG_DEBUFFS_DEFAULTS.OFFSET_X)), config.bigDebuffsOffsetY or addon.BIG_DEBUFFS_DEFAULTS.OFFSET_Y);
    rail:Show();

    for _, aura in ipairs(sampleData) do
        if config[aura.option] and shownCount < maxIcons then
            shownCount = shownCount + 1;
            local slot = EnsureSlot(rail, shownCount);
            local offset = ( shownCount - 1 ) * slotStep;

            slot:SetSize(slotWidth, slotHeight);
            SetSlotStyle(slot, config);
            ConfigureSlotCooldown(slot, config);
            slot:ClearAllPoints();
            if direction < 0 then
                slot:SetPoint("RIGHT", rail, "RIGHT", -offset, 0);
            else
                slot:SetPoint("LEFT", rail, "LEFT", offset, 0);
            end

            slot.previewActive = true;
            slot.icon:SetTexture(addon.GetSpellTexture(aura.spellID) or aura.fallbackTexture);
            SetSlotTint(slot, aura.color, config);
            RestartCooldown(slot);
            slot:SetAlpha(enabled and 1 or 0.35);
            slot:Show();
        end
    end

    for index = shownCount + 1, #rail.slots do
        rail.slots[index].previewActive = false;
        HideAuraHighlightGlow(rail.slots[index]);
        addon.HideProcGlow(rail.slots[index]);
        rail.slots[index]:Hide();
    end
end

local function RenderPreview(widget)
    local config = GetConfig();
    local enabled = config.bigDebuffsEnabled;
    RenderRail(widget.sample.leftRail, widget.sample.health, "RIGHT", "LEFT", -1, sampleAuras.left, config, enabled);
    RenderRail(widget.sample.rightRail, widget.sample.health, "LEFT", "RIGHT", 1, sampleAuras.right, config, enabled);
    widget.sample.frame:SetAlpha(enabled and 1 or 0.45);
    widget.disabledText:SetShown(not enabled);
end

local function CleanupPreview(widget)
    if not widget or not widget.sample then return end

    ClearRail(widget.sample.leftRail);
    ClearRail(widget.sample.rightRail);
end

local methods = {
    ["OnAcquire"] = function(self)
        self:SetFullWidth(true);
        self:SetHeight(previewHeight);
        self.frame:SetHeight(previewHeight);
        previewWidgets[self] = true;
        self:Refresh();
    end,

    ["OnRelease"] = function(self)
        previewWidgets[self] = nil;
        CleanupPreview(self);
    end,

    ["SetText"] = function(self, text)
        self.label:SetText(text or addon.L["Preview"]);
    end,

    ["SetFontObject"] = function(self, fontObject)
        self.label:SetFontObject(fontObject or GameFontNormal);
    end,

    ["SetDisabled"] = function(self, disabled)
        self.disabled = disabled;
        self:Refresh();
    end,

    ["OnWidthSet"] = function(self, width)
        self.frame:SetWidth(width);
        self:Refresh();
    end,

    ["Refresh"] = function(self)
        if not SweepyBoop or not SweepyBoop.db then return end
        if not self.frame:IsShown() then
            CleanupPreview(self);
            return;
        end

        RenderPreview(self);
    end,
};

function addon.RefreshNameplateBigDebuffsPreviewWidgets()
    for widget in pairs(previewWidgets) do
        widget:Refresh();
    end
end

local function Constructor()
    local frame = CreateFrame("Frame", nil, UIParent);
    frame:Hide();
    frame:SetHeight(previewHeight);

    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    label:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -4);
    label:SetTextColor(1, 0.82, 0, 1);

    local sample = BuildSample(frame);

    local disabledText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall");
    disabledText:SetPoint("TOPLEFT", sample.frame, "BOTTOMLEFT", 0, -6);
    disabledText:SetText(addon.L["Disabled"]);

    local widget = {
        frame = frame,
        label = label,
        sample = sample,
        disabledText = disabledText,
        type = Type,
    };

    frame:SetScript("OnShow", function()
        addon.RefreshNameplateBigDebuffsPreviewWidgets();
    end);
    frame:SetScript("OnHide", function()
        CleanupPreview(widget);
    end);

    for method, func in pairs(methods) do
        widget[method] = func;
    end

    return AceGUI:RegisterAsWidget(widget);
end

AceGUI:RegisterWidgetType(Type, Constructor, Version);
