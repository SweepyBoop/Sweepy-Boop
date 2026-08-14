local _, addon = ...;

local baseIconSize = addon.DEFAULT_ICON_SIZE or 32;
local drWindowDuration = 16;
local iconPadding = 3;
local cleanStunGlowColor = { 1, 0.82, 0, 1 };
local testCooldownBaseDuration = 5;

local trackedCategories = {
    "stun",
    "incapacitate",
    "disorient",
    "root",
    "silence",
    "disarm",
};
local testDisplayDuration = testCooldownBaseDuration + #trackedCategories;

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

local PHASE_CLEAN = "clean";
local PHASE_CONTROLLED = "controlled";
local PHASE_RECOVERING = "recovering";

local eventFrame;
local iconGroup;
local stateByCategory = {};
local isInTest = false;
local testGeneration = 0;

local function GetState(category)
    local state = stateByCategory[category];
    if state then return state end

    state = {
        phase = PHASE_CLEAN,
        tier = 0,
        observations = {},
        windowStart = nil,
        expiresAt = nil,
        transitionVersion = 0,
    };
    stateByCategory[category] = state;
    return state;
end

local function ClearObservations(state)
    wipe(state.observations);
end

local function SetCleanState(state)
    state.phase = PHASE_CLEAN;
    state.tier = 0;
    state.windowStart = nil;
    state.expiresAt = nil;
    state.transitionVersion = state.transitionVersion + 1;
    ClearObservations(state);
end

local function GetConfig()
    return SweepyBoop.db.profile.misc;
end

local function IsCategoryTracked(category)
    local info = categoryConfig[category];
    return info and GetConfig()[info.option];
end

local function ShouldShowCleanStunIcon()
    local config = GetConfig();
    return config.personalDR and config.personalDRShowCleanStun and IsCategoryTracked("stun");
end

local function GetTrackedCategoriesForSpell(spellId)
    local categories = {};
    local drCategory = addon.DRList and addon.DRList[spellId];
    if type(drCategory) == "table" then
        for _, category in ipairs(drCategory) do
            if categoryConfig[category] then
                categories[#categories + 1] = category;
            end
        end
    elseif categoryConfig[drCategory] then
        categories[1] = drCategory;
    end
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

local function UpdateCooldownFontSize(cooldown, iconSize)
    if ( not cooldown ) or ( not iconSize ) then return end

    if ( not cooldown.sweepyBoopCountdownFontString ) then
        local numRegions = cooldown:GetNumRegions();
        for i = 1, numRegions do
            local region = select(i, cooldown:GetRegions());
            if region and ( region:GetObjectType() == "FontString" ) then
                cooldown.sweepyBoopCountdownFontString = region;
                break;
            end
        end
    end

    local region = cooldown.sweepyBoopCountdownFontString;
    if region then
        local font, _, flags = region:GetFont();
        if font then
            region:SetFont(font, math.floor(iconSize * addon.COUNTDOWN_FONT_SIZE_COEFFICIENT), flags);
        end
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
    if ( not iconGroup ) or ( not ShouldShowCleanStunIcon() ) then return false end

    local icon = iconGroup.icons[categoryConfig.stun.priority];
    if not icon then return false end

    iconGroup:Show();
    if not icon.cleanOnly then
        ResetIcon(icon);
        icon.cleanOnly = true;
        addon.ShowProcGlow(icon, cleanStunGlowColor);
    end
    addon.IconGroup_Insert(iconGroup, icon, categoryConfig.stun.priority);
    return true;
end

local function HideCategoryIcon(category)
    if not iconGroup then return end

    local icon = iconGroup.icons[categoryConfig[category].priority];
    if not icon then return end

    ResetIcon(icon);
    if ( category == "stun" ) and ShowCleanStunIcon() then
        return;
    end
    addon.IconGroup_Remove(iconGroup, icon);
end

local function ShowControlledIcon(category, tier)
    if ( not iconGroup ) or ( not IsCategoryTracked(category) ) then return end

    local info = categoryConfig[category];
    local icon = iconGroup.icons[info.priority];
    if not icon then return end

    ResetIcon(icon);
    iconGroup:Show();
    icon.texture:SetTexture(info.icon);
    SetBorderColor(icon, tier);
    icon.border:Show();
    addon.IconGroup_Insert(iconGroup, icon, info.priority);
end

local function ShowDRIcon(category, tier, windowStart)
    if ( not iconGroup ) or ( not IsCategoryTracked(category) ) then return end

    local info = categoryConfig[category];
    local icon = iconGroup.icons[info.priority];
    if not icon then return end

    iconGroup:Show();
    icon.cleanOnly = false;
    addon.HideProcGlow(icon);
    icon.texture:SetTexture(info.icon);
    SetBorderColor(icon, tier);
    icon.border:Show();
    if isInTest then
        icon.cooldown:SetScript("OnCooldownDone", nil);
    else
        local state = GetState(category);
        local recoveryVersion = state.transitionVersion;
        local recoveryStart = state.windowStart;
        local function CompleteRecovery()
            local currentState = GetState(category);
            if ( currentState.phase ~= PHASE_RECOVERING )
                or ( currentState.transitionVersion ~= recoveryVersion )
                or ( currentState.windowStart ~= recoveryStart )
                or ( not currentState.expiresAt ) then

                return;
            end

            local remaining = currentState.expiresAt - GetTime();
            if remaining > 0 then
                C_Timer.After(remaining, CompleteRecovery);
                return;
            end

            SetCleanState(currentState);
            HideCategoryIcon(category);
        end
        icon.cooldown:SetScript("OnCooldownDone", CompleteRecovery);
    end
    icon.cooldown:SetCooldown(windowStart or GetTime(), drWindowDuration);
    UpdateCooldownFontSize(icon.cooldown, icon:GetWidth());
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
    UpdateCooldownFontSize(icon.cooldown, baseIconSize);
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
        UpdateCooldownFontSize(icon.cooldown, size);
    end
    if restartCleanGlow then
        addon.HideProcGlow(cleanStunIcon);
        addon.ShowProcGlow(cleanStunIcon, cleanStunGlowColor);
    end
end

local function ResetCategoryState(category)
    SetCleanState(GetState(category));
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

local function StartDRWindow(category, now)
    local state = GetState(category);
    state.phase = PHASE_RECOVERING;
    state.windowStart = now;
    state.expiresAt = now + drWindowDuration;
    state.transitionVersion = state.transitionVersion + 1;
    ClearObservations(state);
    ShowDRIcon(category, state.tier, state.windowStart);
end

local function ExitTestMode()
    if not isInTest then return end

    isInTest = false;
    ResetAllState(GetConfig().personalDR);
end

local function HasMatchingObservation(observations, candidate)
    for _, observation in ipairs(observations) do
        local sameSpell = ( observation.spellId == candidate.spellId );
        local sameStart = observation.startTime
            and candidate.startTime
            and observation.startTime == candidate.startTime;
        if sameSpell and sameStart then
            return true;
        end

        local sameAura = observation.auraInstanceID
            and candidate.auraInstanceID
            and observation.auraInstanceID == candidate.auraInstanceID;
        local startUnavailable = ( not observation.startTime ) or ( not candidate.startTime );
        if sameAura and startUnavailable then
            return true;
        end
        if sameSpell and startUnavailable
            and ( ( not observation.auraInstanceID ) or ( not candidate.auraInstanceID ) ) then

            return true;
        end
    end
    return false;
end

local function AddObservation(categories, category, observation)
    local observations = categories[category];
    if not observations then
        observations = {};
        categories[category] = observations;
    end

    for _, existing in ipairs(observations) do
        if HasMatchingObservation({ existing }, observation) then
            existing.auraInstanceID = existing.auraInstanceID or observation.auraInstanceID;
            existing.startTime = existing.startTime or observation.startTime;
            return;
        end
    end
    observations[#observations + 1] = observation;
end

local function NormalizeLossOfControlData(locData)
    local spellId = locData.spellID;
    if addon.IsSecretValue(spellId) or ( type(spellId) ~= "number" ) then
        return nil;
    end

    local auraInstanceID = locData.auraInstanceID;
    if addon.IsSecretValue(auraInstanceID) or ( type(auraInstanceID) ~= "number" ) then
        auraInstanceID = nil;
    end
    local startTime = locData.startTime;
    if addon.IsSecretValue(startTime) or ( type(startTime) ~= "number" ) then
        startTime = nil;
    end
    return {
        auraInstanceID = auraInstanceID,
        spellId = spellId,
        startTime = startTime,
    };
end

-- Blizzard exposes a player-specific count/getter pair. Only a complete readable
-- snapshot is authoritative enough to remove observations or start DR windows.
local function ScanCurrentObservations()
    if ( not C_LossOfControl )
        or ( not C_LossOfControl.GetActiveLossOfControlDataCount )
        or ( not C_LossOfControl.GetActiveLossOfControlData ) then

        return nil;
    end

    local countSuccess, count = pcall(C_LossOfControl.GetActiveLossOfControlDataCount);
    if ( not countSuccess )
        or addon.IsSecretValue(count)
        or ( type(count) ~= "number" ) then

        return nil;
    end

    local categories = {};
    for index = 1, count do
        local dataSuccess, locData = pcall(C_LossOfControl.GetActiveLossOfControlData, index);
        if ( not dataSuccess ) or ( not locData ) then
            return nil;
        end

        local normalizeSuccess, observation = pcall(NormalizeLossOfControlData, locData);
        if ( not normalizeSuccess ) or ( not observation ) then
            return nil;
        end

        local resolvedCategories = GetTrackedCategoriesForSpell(observation.spellId);
        for _, category in ipairs(resolvedCategories) do
            if IsCategoryTracked(category) then
                AddObservation(categories, category, observation);
            end
        end
    end
    return categories;
end

-- Identity quality can vary across updates, so reconciliation prefers exact
-- spell timing, then an aura instance, and finally conservative continuity.
local function MatchObservations(previous, current)
    local previousMatched = {};
    local currentMatched = {};

    local function MatchPass(predicate)
        for currentIndex, currentObservation in ipairs(current) do
            if not currentMatched[currentIndex] then
                for previousIndex, previousObservation in ipairs(previous) do
                    if ( not previousMatched[previousIndex] )
                        and predicate(previousObservation, currentObservation) then

                        previousMatched[previousIndex] = true;
                        currentMatched[currentIndex] = true;
                        break;
                    end
                end
            end
        end
    end

    MatchPass(function(previousObservation, currentObservation)
        return previousObservation.spellId == currentObservation.spellId
            and previousObservation.startTime
            and currentObservation.startTime
            and previousObservation.startTime == currentObservation.startTime;
    end);
    MatchPass(function(previousObservation, currentObservation)
        return previousObservation.auraInstanceID
            and currentObservation.auraInstanceID
            and previousObservation.auraInstanceID == currentObservation.auraInstanceID
            and ( ( not previousObservation.startTime ) or ( not currentObservation.startTime ) );
    end);
    MatchPass(function(previousObservation, currentObservation)
        return previousObservation.spellId == currentObservation.spellId
            and ( ( not previousObservation.auraInstanceID ) or ( not currentObservation.auraInstanceID ) )
            and ( ( not previousObservation.startTime ) or ( not currentObservation.startTime ) );
    end);

    for currentIndex in ipairs(current) do
        if not currentMatched[currentIndex] then
            return true;
        end
    end
    return false;
end

local function StoreObservations(state, observations)
    ClearObservations(state);
    for _, observation in ipairs(observations) do
        state.observations[#state.observations + 1] = observation;
    end
end

local function UpdateDRs()
    if not iconGroup then return end

    ExitTestMode();

    local currentByCategory = ScanCurrentObservations();
    if not currentByCategory then return end

    local now = GetTime();
    for _, category in ipairs(trackedCategories) do
        local state = GetState(category);
        if not IsCategoryTracked(category) then
            ResetCategoryState(category);
            HideCategoryIcon(category);
        else
            if ( state.phase == PHASE_RECOVERING )
                and state.expiresAt
                and state.expiresAt <= now then

                SetCleanState(state);
                HideCategoryIcon(category);
            end

            local current = currentByCategory[category] or {};
            local hasCurrent = ( #current > 0 );
            if hasCurrent then
                local hasNewApplication = MatchObservations(state.observations, current);
                if ( state.phase ~= PHASE_CONTROLLED ) or hasNewApplication then
                    state.tier = math.min(state.tier + 1, 2);
                    state.transitionVersion = state.transitionVersion + 1;
                end
                state.phase = PHASE_CONTROLLED;
                state.windowStart = nil;
                state.expiresAt = nil;
                StoreObservations(state, current);
                ShowControlledIcon(category, state.tier);
            elseif state.phase == PHASE_CONTROLLED then
                StartDRWindow(category, now);
            end
        end
    end

    if GetState("stun").phase == PHASE_CLEAN then
        ShowCleanStunIcon();
    end
end

local function HasRealDRState()
    for _, category in ipairs(trackedCategories) do
        local state = GetState(category);
        if IsCategoryTracked(category) and ( state.phase ~= PHASE_CLEAN ) then
            return true;
        end
    end

    return false;
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
    if GetConfig().personalDR then
        UpdateDRs();
        if HasRealDRState() then return end
    end

    isInTest = true;
    testGeneration = testGeneration + 1;
    local currentTestGeneration = testGeneration;
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
                icon.cooldown:SetCooldown(GetTime(), testCooldownBaseDuration + categoryConfig[category].priority);
                UpdateCooldownFontSize(icon.cooldown, icon:GetWidth());
            end
        end
    end

    C_Timer.After(testDisplayDuration, function ()
        if isInTest and ( testGeneration == currentTestGeneration ) then
            SweepyBoop:HideTestPersonalDR();
        end
    end);
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
