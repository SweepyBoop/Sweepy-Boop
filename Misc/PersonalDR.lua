local _, addon = ...;

local baseIconSize = addon.DEFAULT_ICON_SIZE or 32;
local drWindowDuration = 16;
local iconPadding = 3;
local cleanStunTexture = addon.GetSpellTexture(5384); -- Feign Death
local cleanStunGlowColor = { 1, 0.82, 0, 1 };

local trackedCategories = {
    "stun",
    "incapacitate",
    "disorient",
    "root",
    "silence",
    "disarm",
};

local categoryConfig = {
    stun = {
        priority = 1,
        icon = addon.GetSpellTexture(1833), -- Cheap Shot
        option = "personalDRTrackStun",
    },
    incapacitate = {
        priority = 2,
        icon = addon.GetSpellTexture(118), -- Polymorph
        option = "personalDRTrackIncapacitate",
    },
    disorient = {
        priority = 3,
        icon = addon.GetSpellTexture(5782), -- Fear
        option = "personalDRTrackDisorient",
    },
    root = {
        priority = 4,
        icon = addon.GetSpellTexture(339), -- Entangling Roots
        option = "personalDRTrackRoot",
    },
    silence = {
        priority = 5,
        icon = addon.GetSpellTexture(15487), -- Silence
        option = "personalDRTrackSilence",
    },
    disarm = {
        priority = 6,
        icon = addon.GetSpellTexture(236077), -- Disarm
        option = "personalDRTrackDisarm",
    },
};

local locTypeToDRCategory = {
    STUN = "incapacitate",
    STUN_MECHANIC = "stun",
    FEAR = "disorient",
    FEAR_MECHANIC = "disorient",
    CHARM = "disorient",
    CYCLONE = "disorient",
    POSSESS = "disorient",
    CONFUSE = "incapacitate",
    ROOT = "root",
    DISARM = "disarm",
    SILENCE = "silence",
};

local nonDrLossOfControlSpellIds = {
    [87204] = true, -- Sin and Punishment (Vampiric Touch dispel horror)
    [196364] = true, -- Unstable Affliction dispel silence
    [6789] = true, -- Mortal Coil
    [100] = true, -- Charge
    [105771] = true, -- Charge Root
    [78675] = true, -- Solar Beam cast
    [157997] = true, -- Ice Nova
    [370970] = true, -- The Hunt root
    [45334] = true, -- Bear Charge
};

local eventFrame;
local iconGroup;
local stateByCategory = {};
local isInTest = false;

local function GetState(category)
    local state = stateByCategory[category];
    if state then return state end

    state = {
        isActive = false,
        auraIds = {},
        lastSeenStartTime = 0,
        stacks = 0,
        expiresAt = nil,
    };
    stateByCategory[category] = state;
    return state;
end

local function GetConfig()
    return SweepyBoop.db.profile.misc;
end

local function IsCategoryTracked(category)
    local info = categoryConfig[category];
    return info and GetConfig()[info.option];
end

local function AddResolvedCategory(categories, category)
    if categoryConfig[category] then
        categories[category] = true;
    end
end

local function ResolveDRCategories(spellId, locType)
    local categories = {};
    if spellId and nonDrLossOfControlSpellIds[spellId] then
        return categories;
    end

    if spellId then
        local drType = addon.DRList and addon.DRList[spellId];
        if drType ~= nil then
            if type(drType) == "table" then
                for _, category in ipairs(drType) do
                    AddResolvedCategory(categories, category);
                end
            else
                AddResolvedCategory(categories, drType);
            end
            return categories;
        end
    end

    AddResolvedCategory(categories, locTypeToDRCategory[locType]);

    return categories;
end

local function GetGrowOptions(config)
    local direction = config.personalDRGrowDirection or "CENTER";
    if direction == "CENTER" then
        return { direction = "CENTER", anchor = "CENTER", margin = iconPadding };
    elseif direction == "RIGHT" then
        return { direction = "RIGHT", anchor = "BOTTOMLEFT", margin = iconPadding };
    elseif direction == "UP" then
        return { direction = "RIGHT", anchor = "BOTTOMLEFT", margin = iconPadding, columns = 1, growUpward = true };
    elseif direction == "DOWN" then
        return { direction = "RIGHT", anchor = "TOPLEFT", margin = iconPadding, columns = 1, growUpward = false };
    end

    return { direction = "LEFT", anchor = "BOTTOMRIGHT", margin = iconPadding };
end

local function GetSetPointOptions(config)
    return {
        point = config.personalDRAnchorPoint or "CENTER",
        relativeTo = "UIParent",
        relativePoint = config.personalDRRelativePoint or "CENTER",
        offsetX = config.personalDROffsetX or 0,
        offsetY = config.personalDROffsetY or -50,
    };
end

local function SetBorderColor(icon, stacks)
    if stacks <= 1 then
        icon.border:SetVertexColor(1, 1, 0); -- 50% DR
    else
        icon.border:SetVertexColor(1, 0, 0); -- immune DR
    end
end

local function StyleCooldown(cooldown)
    cooldown:SetDrawBling(false);
    cooldown:SetReverse(true);
    cooldown:SetDrawSwipe(true);
    cooldown:SetSwipeColor(0, 0, 0, 0.5);
    cooldown:SetDrawEdge(true);
    cooldown:SetEdgeTexture("Interface\\Cooldown\\UI-HUD-ActionBar-LoC");
    cooldown:SetHideCountdownNumbers(false);
    if cooldown.SetCountdownMillisecondsThreshold then
        cooldown:SetCountdownMillisecondsThreshold(0);
    end
end

local function ResetIcon(icon)
    icon.cleanOnly = false;
    icon.cooldown:SetCooldown(0, 0);
    icon.cooldown:Hide();
    icon.border:Hide();
    addon.HideProcGlow(icon);
end

local function ShowCleanStunIcon()
    if ( not iconGroup ) or ( not IsCategoryTracked("stun") ) then return end

    local icon = iconGroup.icons[categoryConfig.stun.priority];
    if not icon then return end

    iconGroup:Show();
    if not icon.cleanOnly then
        ResetIcon(icon);
        icon.cleanOnly = true;
        icon.texture:SetTexture(cleanStunTexture);
        addon.ShowProcGlow(icon, cleanStunGlowColor);
    end
    addon.IconGroup_Insert(iconGroup, icon, categoryConfig.stun.priority);
end

local function HideCategoryIcon(category)
    if not iconGroup then return end

    local icon = iconGroup.icons[categoryConfig[category].priority];
    if not icon then return end

    ResetIcon(icon);
    local state = GetState(category);
    state.stacks = 0;
    state.expiresAt = nil;
    if category == "stun" then
        ShowCleanStunIcon();
    else
        addon.IconGroup_Remove(iconGroup, icon);
    end
end

local function ShowDRIcon(category, stacks)
    if ( not iconGroup ) or ( not IsCategoryTracked(category) ) then return end

    local info = categoryConfig[category];
    local icon = iconGroup.icons[info.priority];
    if not icon then return end

    iconGroup:Show();
    icon.cleanOnly = false;
    addon.HideProcGlow(icon);
    icon.texture:SetTexture(info.icon);
    SetBorderColor(icon, stacks);
    icon.border:Show();
    icon.cooldown:SetCooldown(GetTime(), drWindowDuration);
    icon.cooldown:Show();
    addon.IconGroup_Insert(iconGroup, icon, info.priority);
end

local function CreateDRIcon(category)
    local icon = CreateFrame("Frame", nil, UIParent);
    icon:SetMouseClickEnabled(false);
    icon:SetFrameStrata("HIGH");
    icon:SetSize(baseIconSize, baseIconSize);
    icon.category = category;

    icon.texture = icon:CreateTexture(nil, "ARTWORK");
    icon.texture:SetAllPoints(icon);
    icon.texture:SetTexture(categoryConfig[category].icon);

    icon.border = icon:CreateTexture(nil, "OVERLAY");
    icon.border:SetAtlas("Forge-ColorSwatchSelection");
    icon.border:SetScale(0.4);
    icon.border:SetDesaturated(true);
    icon.border:SetPoint("TOPLEFT", icon, "TOPLEFT", -8, 16 / 3);
    icon.border:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 8, -16 / 3);
    icon.border:Hide();

    icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate");
    icon.cooldown:SetAllPoints(icon);
    StyleCooldown(icon.cooldown);
    icon.cooldown:SetScript("OnCooldownDone", function()
        if isInTest then return end
        HideCategoryIcon(category);
    end);
    icon.cooldown:Hide();

    icon:Hide();
    return icon;
end

local function EnsureIconGroup()
    if iconGroup then return iconGroup end

    local config = GetConfig();
    iconGroup = addon.CreateIconGroup(GetSetPointOptions(config), GetGrowOptions(config));
    for _, category in ipairs(trackedCategories) do
        local info = categoryConfig[category];
        local icon = CreateDRIcon(category);
        icon.spellID = info.priority;
        addon.IconGroup_PopulateIcon(iconGroup, icon, info.priority);
    end

    return iconGroup;
end

local function RefreshIconSizes()
    if not iconGroup then return end

    local size = GetConfig().personalDRSize or baseIconSize;
    local cleanStunIcon = iconGroup.icons[categoryConfig.stun.priority];
    local restartCleanGlow = cleanStunIcon and cleanStunIcon.cleanOnly;
    for _, icon in pairs(iconGroup.icons) do
        icon:SetSize(size, size);
    end
    if restartCleanGlow then
        addon.HideProcGlow(cleanStunIcon);
        addon.ShowProcGlow(cleanStunIcon, cleanStunGlowColor);
    end
end

local function ClearAuras(state)
    wipe(state.auraIds);
    state.lastSeenStartTime = 0;
end

local function ResetCategoryState(category)
    local state = GetState(category);
    state.isActive = false;
    state.stacks = 0;
    state.expiresAt = nil;
    ClearAuras(state);
end

local function ResetAllState(showCleanStun)
    if not iconGroup then return end

    for _, category in ipairs(trackedCategories) do
        ResetCategoryState(category);
        local icon = iconGroup.icons[categoryConfig[category].priority];
        if icon then
            ResetIcon(icon);
            if icon:IsShown() then
                addon.IconGroup_Remove(iconGroup, icon);
            end
        end
    end

    wipe(iconGroup.active);
    wipe(iconGroup.activeMap);
    if showCleanStun then
        ShowCleanStunIcon();
    end
end

local function StartDRWindow(category, stacks)
    local state = GetState(category);
    state.isActive = false;
    state.stacks = stacks;
    state.expiresAt = GetTime() + drWindowDuration;
    ClearAuras(state);
    ShowDRIcon(category, stacks);
end

local function BuildActiveCategories()
    local active = {};
    local locEntries = {};

    if ( not C_LossOfControl ) or ( not C_LossOfControl.GetActiveLossOfControlDataByUnit ) then
        return active;
    end

    for i = 1, 10 do
        local success, locData = pcall(C_LossOfControl.GetActiveLossOfControlDataByUnit, "player", i);
        if success and locData then
            locEntries[#locEntries + 1] = locData;
        end
    end

    for _, locData in ipairs(locEntries) do
        local categories = ResolveDRCategories(locData.spellID, locData.lockType or locData.locType);
        for category in pairs(categories) do
            if IsCategoryTracked(category) then
                local categoryState = active[category];
                if not categoryState then
                    categoryState = { auraIds = {}, startTime = 0 };
                    active[category] = categoryState;
                end
                if locData.auraInstanceID then
                    categoryState.auraIds[locData.auraInstanceID] = true;
                end
                if locData.startTime and locData.startTime > categoryState.startTime then
                    categoryState.startTime = locData.startTime;
                end
            end
        end
    end

    return active;
end

local function UpdateDRs()
    if isInTest or ( not iconGroup ) then return end

    local active = BuildActiveCategories();
    local now = GetTime();

    for _, category in ipairs(trackedCategories) do
        local state = GetState(category);
        if not IsCategoryTracked(category) then
            ResetCategoryState(category);
            local icon = iconGroup.icons[categoryConfig[category].priority];
            if icon and icon:IsShown() then
                ResetIcon(icon);
                addon.IconGroup_Remove(iconGroup, icon);
            end
        else
            local activeState = active[category];
            local isActive = ( activeState ~= nil );
            local newApplication = false;

            if isActive then
                if not state.isActive then
                    newApplication = true;
                else
                    for auraId in pairs(activeState.auraIds) do
                        if not state.auraIds[auraId] then
                            newApplication = true;
                            break;
                        end
                    end
                    if ( not newApplication ) and activeState.startTime > ( state.lastSeenStartTime or 0 ) + 0.05 then
                        newApplication = true;
                    end
                end
            end

            if newApplication then
                state.stacks = math.min(( state.stacks or 0 ) + 1, 2);
                local icon = iconGroup.icons[categoryConfig[category].priority];
                if icon then
                    ResetIcon(icon);
                    icon.texture:SetTexture(categoryConfig[category].icon);
                    SetBorderColor(icon, state.stacks);
                    icon.border:Show();
                    addon.IconGroup_Insert(iconGroup, icon, categoryConfig[category].priority);
                end
            end

            if state.isActive and ( not isActive ) and ( state.stacks > 0 ) then
                StartDRWindow(category, state.stacks);
            elseif ( not isActive ) and state.expiresAt and state.expiresAt <= now then
                HideCategoryIcon(category);
            end

            state.isActive = isActive;
            ClearAuras(state);
            if isActive then
                for auraId in pairs(activeState.auraIds) do
                    state.auraIds[auraId] = true;
                end
                state.lastSeenStartTime = activeState.startTime;
            end
        end
    end

    if ( not GetState("stun").isActive ) and ( not GetState("stun").expiresAt ) then
        ShowCleanStunIcon();
    end
end

local function OnEvent(self, event, unit)
    if event == addon.UNIT_AURA then
        if unit == "player" then
            UpdateDRs();
        end
    elseif event == addon.PLAYER_ENTERING_WORLD or event == addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS then
        ResetAllState(true);
        UpdateDRs();
    end
end

local function RegisterEvents()
    eventFrame:RegisterEvent(addon.UNIT_AURA);
    eventFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
    eventFrame:RegisterEvent(addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS);
end

local function UnregisterEvents()
    eventFrame:UnregisterEvent(addon.UNIT_AURA);
    eventFrame:UnregisterEvent(addon.PLAYER_ENTERING_WORLD);
    eventFrame:UnregisterEvent(addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS);
end

function SweepyBoop:UpdatePersonalDR()
    if not addon.PROJECT_MAINLINE then return end

    EnsureIconGroup();
    iconGroup:Show();
    local config = GetConfig();
    addon.UpdateIconGroupSetPointOptions(iconGroup, GetSetPointOptions(config), GetGrowOptions(config));
    RefreshIconSizes();
    addon.IconGroup_Position(iconGroup);

    if not isInTest then
        UpdateDRs();
    end
end

function SweepyBoop:SetupPersonalDR()
    if not addon.PROJECT_MAINLINE then return end

    isInTest = false;
    eventFrame = eventFrame or CreateFrame("Frame");
    eventFrame:SetScript("OnEvent", OnEvent);
    EnsureIconGroup();
    self:UpdatePersonalDR();

    if GetConfig().personalDR then
        iconGroup:Show();
        RegisterEvents();
        ResetAllState(true);
        UpdateDRs();
    else
        UnregisterEvents();
        ResetAllState(false);
        if iconGroup then
            iconGroup:Hide();
        end
    end
end

function SweepyBoop:TestPersonalDR()
    if not addon.PROJECT_MAINLINE then return end

    EnsureIconGroup();
    isInTest = true;
    iconGroup:Show();
    ResetAllState(false);
    self:UpdatePersonalDR();

    local testStacks = {
        stun = 1,
        incapacitate = 2,
        disorient = 1,
        root = 1,
        silence = 2,
        disarm = 1,
    };
    for _, category in ipairs(trackedCategories) do
        if IsCategoryTracked(category) then
            ShowDRIcon(category, testStacks[category] or 1);
            local icon = iconGroup.icons[categoryConfig[category].priority];
            if icon then
                icon.cooldown:SetCooldown(GetTime(), 5 + categoryConfig[category].priority);
            end
        end
    end
end

function SweepyBoop:HideTestPersonalDR()
    if not addon.PROJECT_MAINLINE then return end

    isInTest = false;
    ResetAllState(GetConfig().personalDR);
    if GetConfig().personalDR then
        UpdateDRs();
    end
end

function SweepyBoop:ResetPersonalDR()
    if not addon.PROJECT_MAINLINE then return end

    isInTest = false;
    ResetAllState(GetConfig().personalDR);
    if GetConfig().personalDR then
        UpdateDRs();
    end
end
