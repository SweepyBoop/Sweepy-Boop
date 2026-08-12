local _, addon = ...;

local markOfTheWild = 1126;
local blessingOfTheBronze = 381748;
local blessingOfTheBronzeAuras = {
    [381732] = true, -- Death Knight
    [381741] = true, -- Demon Hunter
    [381746] = true, -- Druid
    [381748] = true, -- Evoker
    [381749] = true, -- Hunter
    [381750] = true, -- Mage
    [381751] = true, -- Monk
    [381752] = true, -- Paladin
    [381753] = true, -- Priest
    [381754] = true, -- Rogue
    [381756] = true, -- Shaman
    [381757] = true, -- Warlock
    [381758] = true, -- Warrior
};

local profiles = {
    [addon.SPECID.RESTORATION_DRUID] = {
        class = addon.DRUID,
        enabledSetting = "druidBuffHelper",
        row2WarningSetting = "druidBuffHelperWarning",
        primaryRefreshFraction = 0.3,
        primaryRefreshMaxSeconds = 4.5,
        classBuff = markOfTheWild,
        classBuffAuras = {
            [markOfTheWild] = true,
        },
        primaryBuffs = {
            [33763] = true,  -- Lifebloom
            [290754] = true, -- Lifebloom (Early Spring)
        },
        row2Priority = {
            8936,   -- Regrowth
            48438,  -- Wild Growth
            774,    -- Rejuvenation
            155777, -- Germination
        },
        row2Auras = {
            [8936] = 8936,
            [48438] = 48438,
            [774] = 774,
            [155777] = 155777,
        },
    },
    [addon.SPECID.PRESERVATION] = {
        class = addon.EVOKER,
        enabledSetting = "evokerBuffHelper",
        classBuff = blessingOfTheBronze,
        classBuffAuras = blessingOfTheBronzeAuras,
        primaryBuffs = {
            [364343] = true, -- Echo
        },
        row2Priority = {
            366155, -- Reversion
            355941, -- Dream Breath
            373267, -- Lifebind
            357170, -- Time Dilation
        },
        row2Auras = {
            [366155] = 366155,
            [1256577] = 366155,
            [355936] = 355941,
            [355941] = 355941,
            [373267] = 373267,
            [373270] = 373267,
            [357170] = 357170,
        },
    },
};

local supportedClasses = {
    [addon.DRUID] = true,
    [addon.EVOKER] = true,
};

local PRIMARY_BUFF_SIZE = 20;
local ROW2_BUFF_SIZE = 16;
local ROW2_BUFF_SPACING = 1;
local ROW_SPACING = 2;
local RIGHT_PAD = 2;
local FRAME_LEVEL_OFFSET = 10;
local warningTexture = "Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew";
local missingClassBuffGlowColor = { 1, 0, 0, 1 };
local lifebloomGlowColor = { 0, 1, 0, 1 };
local LIFEBLOOM_SCAN_INTERVAL = 0.25;
local LIFEBLOOM_GLOW_INTERVAL = 0.05;

local playerClass = addon.GetUnitClass("player");
local isSupportedClass = supportedClasses[playerClass] and true or false;
local playerProfile;
local activeProfile;
local cufPool = {};
local setupComplete = false;
local editModePreviewActive = false;
local restylePending = false;
local restyleTicker;
local lifebloomUpdater;
local ApplyLayout;

for _, profile in pairs(profiles) do
    if profile.class == playerClass then
        playerProfile = profile;
        break;
    end
end

local function GetConfig()
    return SweepyBoop.db.profile.raidFrames;
end

local function GetScale()
    local scale = tonumber(GetConfig().healerBuffHelperScale) or 1;
    return scale > 0 and scale or 1;
end

local function CanStyleAuraButtons()
    return ( not C_Secrets )
        or ( not C_Secrets.ShouldAurasBeSecret )
        or ( not C_Secrets.ShouldAurasBeSecret() );
end

local function IsProfileEnabled(profile)
    return profile
        and GetConfig()[profile.enabledSetting]
        and ( not addon.IsConflictingHealerBuffHelperAddonLoaded() );
end

local function CheckSpec()
    local specID = addon.GetSpecForPlayerOrArena("player");
    local profile = profiles[specID];
    activeProfile = profile and ( profile.class == playerClass ) and profile or nil;
end

local function StyleCooldown(cooldown)
    cooldown:SetDrawBling(false);
    cooldown:SetReverse(true);
    cooldown:SetDrawSwipe(true);
    cooldown:SetSwipeColor(0, 0, 0, 0.5);
    cooldown:SetDrawEdge(true);
    cooldown:SetEdgeTexture("Interface\\Cooldown\\UI-HUD-ActionBar-LoC", 1, 1, 1, 1);
    cooldown:SetHideCountdownNumbers(true);
    cooldown.noCooldownCount = true;
end

local function InitializeAuraButton(button, helper, baseSize)
    local size = baseSize * GetScale();
    helper.buttons[#helper.buttons + 1] = button;
    button.sweepyBoopBaseSize = baseSize;
    button:SetSize(size, size);
    button:SetMouseMotionEnabled(false);

    local icon = button:CreateTexture(nil, "ARTWORK");
    icon:SetAllPoints(button);
    button:SetIcon(icon);

    local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate");
    cooldown:SetAllPoints(button);
    StyleCooldown(cooldown);
    button:SetDurationCooldown(cooldown);
end

local function BuildRow2SpellMap(profile, canonicalSpellID)
    local spellIDs = {};
    for auraSpellID, row2SpellID in pairs(profile.row2Auras) do
        if row2SpellID == canonicalSpellID then
            spellIDs[auraSpellID] = true;
        end
    end
    return spellIDs;
end

local function EnsureContainers(frame)
    local helper = frame.healerBuffHelper;
    if helper then return helper end
    if ( not playerProfile ) then return end

    helper = {
        buttons = {},
    };

    helper.primary = CreateFrame(
        "AuraContainer",
        nil,
        frame,
        "CustomAuraContainerTemplate"
    );
    helper.primary:SetFrameLevel(frame:GetFrameLevel() + FRAME_LEVEL_OFFSET);
    helper.primary:SetFlowLayoutAxis(AnchorUtil.FlowLayoutAxis.Horizontal);
    helper.primary:SetFlowLayoutAnchorPoint("TOPRIGHT");
    helper.primary:SetFlowLayoutGrowthDirection(
        AnchorUtil.FlowDirection.Left,
        AnchorUtil.FlowDirection.Down
    );
    helper.primary:SetEnabled(false);
    helper.primary:Hide();
    helper.primary:AddAuraGroup("Primary", "HELPFUL", {
        maxFrameCount = 1,
        candidateFilters = {
            includeSpellIDs = playerProfile.primaryBuffs,
            isFromPlayerOrPlayerPet = true,
        },
        sortMethod = AuraContainerSortMethod.Expiration,
        sortDirection = AuraContainerSortDirection.Normal,
        initializeFrame = function(button)
            InitializeAuraButton(button, helper, PRIMARY_BUFF_SIZE);
        end,
        layout = {
            elementWidth = PRIMARY_BUFF_SIZE * GetScale(),
            elementHeight = PRIMARY_BUFF_SIZE * GetScale(),
        },
    });

    if playerProfile.primaryRefreshFraction then
        helper.primaryGlowAnchor = CreateFrame("Frame", nil, frame);
        helper.primaryGlowAnchor:SetFrameLevel(
            frame:GetFrameLevel() + FRAME_LEVEL_OFFSET + 5
        );
        helper.primaryGlowAnchor.SpellActivationAlert = addon.CreateOverlayGlow(
            helper.primaryGlowAnchor,
            PRIMARY_BUFF_SIZE,
            lifebloomGlowColor,
            true
        );
        helper.primaryGlowAnchor.SpellActivationAlert:SetFrameLevel(
            helper.primaryGlowAnchor:GetFrameLevel() + 1
        );
        helper.primaryGlowAnchor:Hide();
    end

    helper.row2 = CreateFrame(
        "AuraContainer",
        nil,
        frame,
        "CustomAuraContainerTemplate"
    );
    helper.row2:SetFrameLevel(frame:GetFrameLevel() + FRAME_LEVEL_OFFSET);
    helper.row2:SetFlowLayoutAxis(AnchorUtil.FlowLayoutAxis.Horizontal);
    helper.row2:SetFlowLayoutAnchorPoint("TOPRIGHT");
    helper.row2:SetFlowLayoutGrowthDirection(
        AnchorUtil.FlowDirection.Left,
        AnchorUtil.FlowDirection.Down
    );
    helper.row2:SetEnabled(false);
    helper.row2:Hide();

    helper.row2Warning = helper.row2:CreateTexture(nil, "BACKGROUND");
    helper.row2Warning:SetTexture(warningTexture);
    helper.row2Warning:SetPoint("TOPRIGHT", helper.row2, "TOPRIGHT");

    for i = #playerProfile.row2Priority, 1, -1 do
        local spellID = playerProfile.row2Priority[i];
        helper.row2:AddAuraGroup("Row2-" .. spellID, "HELPFUL", {
            maxFrameCount = 1,
            candidateFilters = {
                includeSpellIDs = BuildRow2SpellMap(playerProfile, spellID),
                isFromPlayerOrPlayerPet = true,
            },
            sortMethod = AuraContainerSortMethod.Expiration,
            sortDirection = AuraContainerSortDirection.Normal,
            initializeFrame = function(button)
                InitializeAuraButton(button, helper, ROW2_BUFF_SIZE);
            end,
            layout = {
                groupSpacing = ROW2_BUFF_SPACING,
                elementWidth = ROW2_BUFF_SIZE * GetScale(),
                elementHeight = ROW2_BUFF_SIZE * GetScale(),
            },
        });
    end

    helper.classBuffAnchor = CreateFrame("Frame", nil, frame);
    helper.classBuffAnchor:SetFrameLevel(frame:GetFrameLevel() + FRAME_LEVEL_OFFSET);
    helper.classBuffAnchor:Hide();

    helper.classBuff = CreateFrame(
        "AuraContainer",
        nil,
        frame,
        "CustomAuraContainerTemplate"
    );
    helper.classBuff:SetFrameLevel(frame:GetFrameLevel() + FRAME_LEVEL_OFFSET);
    helper.classBuff:SetPoint("CENTER", helper.classBuffAnchor, "CENTER");
    helper.classBuff:SetEnabled(false);
    helper.classBuff:Hide();

    local warningLevel = helper.classBuffAnchor:GetFrameLevel() + 1;
    helper.classBuffWarning = CreateFrame("Frame", nil, helper.classBuffAnchor);
    helper.classBuffWarning:SetFrameLevel(warningLevel);
    helper.classBuffWarning:SetAllPoints(helper.classBuffAnchor);
    helper.classBuffWarning.texture = helper.classBuffWarning:CreateTexture(nil, "ARTWORK");
    helper.classBuffWarning.texture:SetAllPoints(helper.classBuffWarning);
    helper.classBuffWarning.texture:SetTexture(addon.GetSpellTexture(playerProfile.classBuff));
    helper.classBuffWarning.texture:SetDesaturated(true);
    helper.classBuffWarning.fixedPixelGlow = addon.CreateFixedPixelGlow(
        helper.classBuffWarning,
        ROW2_BUFF_SIZE,
        ROW2_BUFF_SIZE,
        missingClassBuffGlowColor,
        10,
        nil,
        nil,
        0
    );
    helper.classBuffWarning.fixedPixelGlow:SetFrameLevel(warningLevel + 1);
    addon.ShowFixedPixelGlow(helper.classBuffWarning.fixedPixelGlow);

    helper.classBuff:AddAuraSlot("ClassBuff", "HELPFUL", {
        candidateFilters = {
            includeSpellIDs = playerProfile.classBuffAuras,
        },
        sortMethod = AuraContainerSortMethod.Expiration,
        sortDirection = AuraContainerSortDirection.Normal,
        initializeFrame = function(button)
            button:SetFrameLevel(warningLevel + 2);
            button:SetAllPoints(helper.classBuffAnchor);
            button:SetMouseMotionEnabled(false);

            local background = button:CreateTexture(nil, "BACKGROUND");
            background:SetPoint("TOPLEFT", button, "TOPLEFT", -1, 1);
            background:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 1, -1);
            background:SetColorTexture(0, 0, 0, 1);

            local icon = button:CreateTexture(nil, "ARTWORK");
            icon:SetAllPoints(button);
            button:SetIcon(icon);
        end,
    });

    frame.healerBuffHelper = helper;
    ApplyLayout(frame, helper);
    return helper;
end

ApplyLayout = function(frame, helper)
    local config = GetConfig();
    local scale = GetScale();
    local primarySize = PRIMARY_BUFF_SIZE * scale;
    local row2Size = ROW2_BUFF_SIZE * scale;
    local offsetX = -RIGHT_PAD + ( config.healerBuffHelperOffsetX or 0 );
    local offsetY = config.healerBuffHelperOffsetY or 0;

    helper.primary:ClearAllPoints();
    helper.primary:SetPoint(
        "TOPRIGHT",
        frame,
        "RIGHT",
        offsetX,
        offsetY + primarySize + ( ROW_SPACING / 2 )
    );
    helper.primary:SetAuraGroupLayout("Primary", {
        elementWidth = primarySize,
        elementHeight = primarySize,
    });

    if helper.primaryGlowAnchor then
        helper.primaryGlowAnchor:ClearAllPoints();
        helper.primaryGlowAnchor:SetSize(primarySize, primarySize);
        helper.primaryGlowAnchor:SetPoint(
            "TOPRIGHT",
            frame,
            "RIGHT",
            offsetX,
            offsetY + primarySize + ( ROW_SPACING / 2 )
        );
        helper.primaryGlowAnchor.SpellActivationAlert:SetSize(
            primarySize * 1.4,
            primarySize * 1.4
        );
    end

    helper.classBuffAnchor:ClearAllPoints();
    helper.classBuffAnchor:SetSize(row2Size, row2Size);
    helper.classBuffAnchor:SetPoint(
        "RIGHT",
        frame,
        "RIGHT",
        offsetX - primarySize - ROW2_BUFF_SPACING,
        offsetY + ( primarySize / 2 ) + ( ROW_SPACING / 2 )
    );
    addon.SetFixedPixelGlowSize(
        helper.classBuffWarning.fixedPixelGlow,
        row2Size,
        row2Size,
        0
    );

    helper.row2:ClearAllPoints();
    helper.row2:SetPoint(
        "TOPRIGHT",
        frame,
        "RIGHT",
        offsetX,
        offsetY - ( ROW_SPACING / 2 )
    );
    helper.row2Warning:SetSize(row2Size, row2Size);
    local warningSetting = playerProfile.row2WarningSetting;
    helper.row2Warning:SetShown(
        warningSetting
            and config[warningSetting]
            and true
            or false
    );

    for _, spellID in ipairs(playerProfile.row2Priority) do
        helper.row2:SetAuraGroupLayout("Row2-" .. spellID, {
            groupSpacing = ROW2_BUFF_SPACING,
            elementWidth = row2Size,
            elementHeight = row2Size,
        });
    end
end

local lifebloomSpellIDs = {
    33763,
    290754,
};
local lifebloomSpellName;

local function IsPlayerLifebloom(aura)
    if not aura then return false end

    local spellID = aura.spellId;
    local sourceUnit = aura.sourceUnit;
    return ( not addon.IsSecretValue(spellID) )
        and playerProfile.primaryBuffs[spellID]
        and ( not addon.IsSecretValue(sourceUnit) )
        and sourceUnit == "player";
end

local function FindReadableLifebloom(unit)
    if C_UnitAuras.GetUnitAuraBySpellID then
        for _, spellID in ipairs(lifebloomSpellIDs) do
            local aura = C_UnitAuras.GetUnitAuraBySpellID(unit, spellID);
            if IsPlayerLifebloom(aura) then
                return aura;
            end
        end
    end

    if not C_UnitAuras.GetAuraDataBySpellName then return end

    lifebloomSpellName = lifebloomSpellName or C_Spell.GetSpellName(33763);
    if not lifebloomSpellName then return end

    local aura = C_UnitAuras.GetAuraDataBySpellName(
        unit,
        lifebloomSpellName,
        "HELPFUL|PLAYER"
    );
    return IsPlayerLifebloom(aura) and aura or nil;
end

local function ReadLifebloomTiming(unit)
    local aura = FindReadableLifebloom(unit);
    if not aura then return end

    local duration = aura.duration;
    local expirationTime = aura.expirationTime;
    local timeMod = aura.timeMod or 1;
    if addon.IsSecretValue(duration)
        or addon.IsSecretValue(expirationTime)
        or addon.IsSecretValue(timeMod)
        or ( type(duration) ~= "number" )
        or ( type(expirationTime) ~= "number" )
        or ( type(timeMod) ~= "number" )
        or ( duration <= 0 )
        or ( expirationTime <= 0 )
        or ( timeMod <= 0 ) then
        return;
    end

    local refreshTime = duration * playerProfile.primaryRefreshFraction;
    if playerProfile.primaryRefreshMaxSeconds then
        refreshTime = math.min(refreshTime, playerProfile.primaryRefreshMaxSeconds);
    end
    return expirationTime, refreshTime, timeMod;
end

local function SetLifebloomGlow(helper, shown)
    local anchor = helper and helper.primaryGlowAnchor;
    if ( not anchor ) then return end

    if shown then
        if ( not anchor.lifebloomGlowing ) then
            anchor:Show();
            addon.ShowOverlayGlow(anchor);
            anchor.lifebloomGlowing = true;
        end
    elseif anchor.lifebloomGlowing then
        addon.HideOverlayGlow(anchor);
        anchor:Hide();
        anchor.lifebloomGlowing = false;
    end
end

local function RefreshLifebloomTiming(frame, helper)
    if ( not helper.primaryGlowAnchor ) or ( not helper.active ) then
        helper.lifebloomTiming = nil;
        SetLifebloomGlow(helper, false);
        return;
    end

    local unit = frame.displayedUnit or frame.unit;
    local ok, expirationTime, refreshTime, timeMod = pcall(
        ReadLifebloomTiming,
        unit
    );
    if ( not ok ) or ( not expirationTime ) then
        helper.lifebloomTiming = nil;
        SetLifebloomGlow(helper, false);
        return;
    end

    helper.lifebloomTiming = {
        expirationTime = expirationTime,
        refreshTime = refreshTime,
        timeMod = timeMod,
    };
end

local function UpdateLifebloomGlow(helper, now)
    local timing = helper.lifebloomTiming;
    if ( not timing ) then
        SetLifebloomGlow(helper, false);
        return;
    end

    local remaining = ( timing.expirationTime - now ) / timing.timeMod;
    if remaining <= 0 then
        helper.lifebloomTiming = nil;
        SetLifebloomGlow(helper, false);
    else
        SetLifebloomGlow(helper, remaining <= timing.refreshTime);
    end
end

local function RestyleButtons(frame, helper)
    ApplyLayout(frame, helper);
    if ( not CanStyleAuraButtons() ) then
        restylePending = true;
        return;
    end

    local scale = GetScale();
    for _, button in ipairs(helper.buttons) do
        local size = button.sweepyBoopBaseSize * scale;
        button:SetSize(size, size);
    end
end

local function HideHelper(frame)
    local helper = frame.healerBuffHelper;
    if ( not helper ) then return end
    helper.active = false;
    helper.lifebloomTiming = nil;
    SetLifebloomGlow(helper, false);
    helper.primary:SetEnabled(false);
    helper.primary:Hide();
    helper.row2:SetEnabled(false);
    helper.row2:Hide();
    helper.classBuff:SetEnabled(false);
    helper.classBuff:Hide();
    helper.classBuffAnchor:Hide();
end

local function IsGroupUnit(unit)
    if ( not unit ) then return false end
    return ( unit == "player" )
        or ( unit == "pet" )
        or ( string.match(unit, "^party%d+$") ~= nil )
        or ( string.match(unit, "^partypet%d+$") ~= nil )
        or ( string.match(unit, "^raid%d+$") ~= nil )
        or ( string.match(unit, "^raidpet%d+$") ~= nil );
end

local function IsPetUnit(unit)
    if ( not unit ) then return false end
    return ( unit == "pet" )
        or ( string.match(unit, "^partypet%d+$") ~= nil )
        or ( string.match(unit, "^raidpet%d+$") ~= nil );
end

local function IsFrameVisible(frame)
    local shown = frame:IsShown();
    return ( not addon.IsSecretValue(shown) ) and shown;
end

local function ShouldTrackFrameName(name)
    if ( not name ) then return false end
    return ( string.sub(name, 1, 17) == "CompactPartyFrame" )
        or ( string.sub(name, 1, 11) == "CompactRaid" );
end

local function ActivateContainer(container, unit, forceRefresh)
    local unitChanged = container:GetUnit() ~= unit;
    if unitChanged or forceRefresh then
        container:Hide();
        if forceRefresh and ( not unitChanged ) then
            container:SetUnit("none");
        end
        container:SetUnit(unit);
        container:UpdateAllAuras();
    end
    container:SetEnabled(true);
    container:Show();
end

local function UpdateFrame(frame, forceRefresh)
    if ( not frame ) or frame:IsForbidden() then return end

    local unit = frame.displayedUnit or frame.unit;
    if editModePreviewActive
        or ( not IsProfileEnabled(activeProfile) )
        or ( not IsFrameVisible(frame) )
        or ( not unit )
        or ( not UnitExists(unit) )
        or ( not IsGroupUnit(unit) ) then
        HideHelper(frame);
        return;
    end

    local canAssist = UnitCanAssist("player", unit);
    if addon.IsSecretValue(canAssist) or ( not canAssist ) then
        HideHelper(frame);
        return;
    end

    local helper = EnsureContainers(frame);
    if ( not helper ) then return end
    RestyleButtons(frame, helper);
    local needsFullRefresh = forceRefresh or ( not helper.active );
    ActivateContainer(helper.primary, unit, needsFullRefresh);
    ActivateContainer(helper.row2, unit, needsFullRefresh);

    if IsPetUnit(unit) then
        helper.classBuff:SetEnabled(false);
        helper.classBuff:Hide();
        helper.classBuffAnchor:Hide();
    else
        ActivateContainer(helper.classBuff, unit, needsFullRefresh);
        helper.classBuffAnchor:Show();
    end

    helper.active = true;
    RefreshLifebloomTiming(frame, helper);
end

local function RefreshAllFrames(forceRefresh)
    for frame in pairs(cufPool) do
        UpdateFrame(frame, forceRefresh);
    end
end

local function FlushPendingRestyle()
    if ( not restylePending ) or ( not CanStyleAuraButtons() ) then return end
    restylePending = false;
    RefreshAllFrames();
    if restyleTicker then
        restyleTicker:Cancel();
        restyleTicker = nil;
    end
end

local function StartLifebloomUpdater()
    if lifebloomUpdater or ( not playerProfile.primaryRefreshFraction ) then return end

    local scanElapsed = 0;
    local glowElapsed = 0;
    lifebloomUpdater = CreateFrame("Frame");
    lifebloomUpdater:SetScript("OnUpdate", function(_, elapsed)
        scanElapsed = scanElapsed + elapsed;
        glowElapsed = glowElapsed + elapsed;
        local shouldScan = scanElapsed >= LIFEBLOOM_SCAN_INTERVAL;
        local shouldUpdateGlow = glowElapsed >= LIFEBLOOM_GLOW_INTERVAL;
        if ( not shouldScan ) and ( not shouldUpdateGlow ) then return end

        if shouldScan then scanElapsed = 0 end
        if shouldUpdateGlow then glowElapsed = 0 end
        local now = GetTime();
        for frame in pairs(cufPool) do
            local helper = frame.healerBuffHelper;
            if helper and helper.active then
                if shouldScan then
                    RefreshLifebloomTiming(frame, helper);
                end
                if shouldUpdateGlow then
                    UpdateLifebloomGlow(helper, now);
                end
            end
        end
    end);
end

local function StartRestyleTicker()
    if restylePending and ( not restyleTicker ) then
        restyleTicker = C_Timer.NewTicker(1, FlushPendingRestyle);
    end
end

local function TrackFrame(frame)
    if ( not frame ) or frame:IsForbidden() then return end
    local name = frame:GetName();
    if ShouldTrackFrameName(name) then
        cufPool[frame] = true;
        UpdateFrame(frame);
    elseif cufPool[frame] then
        cufPool[frame] = nil;
        HideHelper(frame);
    end
end

function SweepyBoop:SetupRaidFrameAuraModule()
    if ( not addon.PROJECT_MAINLINE ) or ( not isSupportedClass ) or setupComplete then return end
    setupComplete = true;
    CheckSpec();
    StartLifebloomUpdater();

    hooksecurefunc("CompactUnitFrame_UpdateAll", TrackFrame);
    hooksecurefunc("CompactUnitFrame_SetUnit", TrackFrame);
    hooksecurefunc("CompactUnitFrame_UpdateVisible", TrackFrame);

    local eventFrame = CreateFrame("Frame");
    eventFrame:RegisterEvent(addon.GROUP_ROSTER_UPDATE);
    eventFrame:RegisterEvent(addon.PLAYER_SPECIALIZATION_CHANGED);
    eventFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
    eventFrame:RegisterEvent(addon.PLAYER_REGEN_ENABLED);
    eventFrame:RegisterEvent("AURA_DATA_PROVIDER_SWITCH");
    eventFrame:SetScript("OnEvent", function(_, event, arg1)
        if event == addon.PLAYER_SPECIALIZATION_CHANGED then
            if arg1 ~= "player" then return end
            CheckSpec();
        elseif event == "AURA_DATA_PROVIDER_SWITCH" then
            editModePreviewActive = arg1 ~= true;
        elseif event == addon.PLAYER_REGEN_ENABLED then
            FlushPendingRestyle();
        end

        if event == addon.GROUP_ROSTER_UPDATE then
            C_Timer.After(0, function()
                RefreshAllFrames(true);
            end);
        elseif event == addon.PLAYER_ENTERING_WORLD then
            C_Timer.After(0, function()
                CheckSpec();
                RefreshAllFrames(true);
            end);
        else
            RefreshAllFrames();
        end
    end);
end

function SweepyBoop:RefreshHealerBuffHelper()
    CheckSpec();
    RefreshAllFrames();
    StartRestyleTicker();
end
