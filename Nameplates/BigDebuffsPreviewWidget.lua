local _, addon = ...;

local Type, Version = "NameplateBigDebuffsPreview-SweepyBoop", 1;
local AceGUI = LibStub and LibStub("AceGUI-3.0", true);
if not AceGUI or ( AceGUI:GetWidgetVersion(Type) or 0 ) >= Version then return end

local previewWidgets = setmetatable({}, { __mode = "k" });
local TEXTURE_WHITE = "Interface\\BUTTONS\\WHITE8X8";
local previewHeight = 128;
local sampleWidth = 360;
local sampleHeight = 70;
local healthWidth = 96;
local healthHeight = 12;
local previewLeftInset = 8;
local previewMaxIcons = addon.BIG_DEBUFFS_DEFAULTS.MAX_ICONS;
local ccSampleSpell = 118; -- Polymorph
local defensiveSampleSpell = 642; -- Divine Shield
local importantSampleSpell = 31884; -- Avenging Wrath
local fallbackCcTexture = "Interface\\Icons\\Spell_Nature_Polymorph";
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

local function PaintEdge(texture, pointA, pointB, sizeSetter)
    texture:SetPoint(pointA, texture:GetParent(), pointA);
    texture:SetPoint(pointB, texture:GetParent(), pointB);
    sizeSetter(texture, 2);
    texture:SetTexture(TEXTURE_WHITE);
end

local function CreatePreviewSlot(parent)
    local slot = CreateFrame("Frame", nil, parent);
    slot:Hide();

    slot.backdrop = slot:CreateTexture(nil, "BACKGROUND");
    slot.backdrop:SetAllPoints(slot);
    slot.backdrop:SetTexture(TEXTURE_WHITE);
    slot.backdrop:SetVertexColor(0, 0, 0, 1);

    slot.icon = slot:CreateTexture(nil, "BORDER");
    slot.icon:SetPoint("TOPLEFT", slot, "TOPLEFT", 1, -1);
    slot.icon:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", -1, 1);
    slot.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92);

    slot.edgeTop = slot:CreateTexture(nil, "OVERLAY");
    PaintEdge(slot.edgeTop, "TOPLEFT", "TOPRIGHT", function(texture, size) texture:SetHeight(size); end);

    slot.edgeBottom = slot:CreateTexture(nil, "OVERLAY");
    PaintEdge(slot.edgeBottom, "BOTTOMLEFT", "BOTTOMRIGHT", function(texture, size) texture:SetHeight(size); end);

    slot.edgeLeft = slot:CreateTexture(nil, "OVERLAY");
    PaintEdge(slot.edgeLeft, "TOPLEFT", "BOTTOMLEFT", function(texture, size) texture:SetWidth(size); end);

    slot.edgeRight = slot:CreateTexture(nil, "OVERLAY");
    PaintEdge(slot.edgeRight, "TOPRIGHT", "BOTTOMRIGHT", function(texture, size) texture:SetWidth(size); end);

    slot.cooldown = CreateFrame("Cooldown", nil, slot, "CooldownFrameTemplate");
    slot.cooldown:SetAllPoints(slot.icon);
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

    local nameText = sample:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
    nameText:SetPoint("BOTTOM", sample, "CENTER", 0, 3);
    nameText:SetText("Enemy nameplate");
    nameText:SetTextColor(1, 0.82, 0, 1);

    local health = CreateFrame("Frame", nil, sample);
    health:SetPoint("TOP", sample, "CENTER", 0, -3);
    health:SetSize(healthWidth, healthHeight);

    local healthBorder = health:CreateTexture(nil, "BACKGROUND");
    healthBorder:SetAllPoints(health);
    healthBorder:SetTexture(TEXTURE_WHITE);
    healthBorder:SetVertexColor(0, 0, 0, 1);

    local healthFill = health:CreateTexture(nil, "BORDER");
    healthFill:SetPoint("TOPLEFT", health, "TOPLEFT", 1, -1);
    healthFill:SetPoint("BOTTOMRIGHT", health, "BOTTOMRIGHT", -1, 1);
    healthFill:SetTexture(TEXTURE_WHITE);
    healthFill:SetVertexColor(0.55, 0.05, 0.05, 1);

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

local function ClearRail(rail)
    for _, slot in ipairs(rail.slots) do
        slot.previewActive = false;
        slot.cooldown:SetCooldown(0, 0);
        slot.cooldown:Hide();
        slot:Hide();
    end
end

local function SetSlotTint(slot, color)
    slot.edgeTop:SetVertexColor(color[1], color[2], color[3], 1);
    slot.edgeBottom:SetVertexColor(color[1], color[2], color[3], 1);
    slot.edgeLeft:SetVertexColor(color[1], color[2], color[3], 1);
    slot.edgeRight:SetVertexColor(color[1], color[2], color[3], 1);
end

local function RenderRail(rail, anchor, point, relativePoint, direction, sampleData, config, enabled)
    local iconSize = GetIconSize(config);
    local spacing = config.bigDebuffsSpacing or addon.BIG_DEBUFFS_DEFAULTS.SPACING;
    local maxIcons = math.min(config.bigDebuffsMaxIcons or addon.BIG_DEBUFFS_DEFAULTS.MAX_ICONS, previewMaxIcons);
    local shownCount = 0;

    rail:SetSize(math.max(maxIcons, 1) * iconSize + math.max(maxIcons - 1, 0) * spacing, iconSize);
    rail:ClearAllPoints();
    rail:SetPoint(point, anchor, relativePoint, direction * (2 + (config.bigDebuffsOffsetX or addon.BIG_DEBUFFS_DEFAULTS.OFFSET_X)), config.bigDebuffsOffsetY or addon.BIG_DEBUFFS_DEFAULTS.OFFSET_Y);
    rail:Show();

    for _, aura in ipairs(sampleData) do
        if config[aura.option] and shownCount < maxIcons then
            shownCount = shownCount + 1;
            local slot = EnsureSlot(rail, shownCount);
            local offset = ( shownCount - 1 ) * ( iconSize + spacing );

            slot:SetSize(iconSize, iconSize);
            slot:ClearAllPoints();
            if direction < 0 then
                slot:SetPoint("RIGHT", rail, "RIGHT", -offset, 0);
            else
                slot:SetPoint("LEFT", rail, "LEFT", offset, 0);
            end

            slot.previewActive = true;
            slot.icon:SetTexture(addon.GetSpellTexture(aura.spellID) or aura.fallbackTexture);
            SetSlotTint(slot, aura.color);
            RestartCooldown(slot);
            slot:SetAlpha(enabled and 1 or 0.35);
            slot:Show();
        end
    end

    for index = shownCount + 1, #rail.slots do
        rail.slots[index].previewActive = false;
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
