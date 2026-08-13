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
        primaryPandemicGlow = true,
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

local playerClass = addon.GetUnitClass("player");
local isSupportedClass = supportedClasses[playerClass] and true or false;
local playerProfile;
local activeProfile;
local cufPool = {};
local setupComplete = false;
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

local function IsProfileEnabled(profile)
    return profile and GetConfig()[profile.enabledSetting];
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

local function InitializeAuraButton(button, size)
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

local function LayoutLifebloomPandemicBorder(button)
    local textures = button.sweepyBoopPandemicBorder;
    if not textures then return end

    local padding = PRIMARY_BUFF_SIZE
        * addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_PADDING
        / addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_BASE_SIZE;
    for _, texture in ipairs(textures) do
        texture:ClearAllPoints();
        texture:SetPoint("TOPLEFT", button, "TOPLEFT", -padding, padding);
        texture:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", padding, -padding);
    end
end

local function AddLifebloomPandemicBorder(button)
    local borderFrame = CreateFrame("Frame", nil, button);
    borderFrame:SetAllPoints(button);
    borderFrame:SetFrameStrata("HIGH");
    borderFrame:SetFixedFrameStrata(true);

    local function AddTexture(path, layer, alpha)
        local texture = borderFrame:CreateTexture(nil, layer);
        texture:SetTexture(path);
        texture:SetBlendMode("ADD");
        texture:SetVertexColor(0, 1, 0, alpha);
        button:AddPandemicRegion(texture);
        return texture;
    end

    button.sweepyBoopPandemicBorder = {
        AddTexture(
            addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_GLOW_TEXTURE,
            "BORDER",
            0.9
        ),
        AddTexture(
            addon.BIG_DEBUFFS_ICON_STYLE.HIGHLIGHT_BORDER_TEXTURE,
            "OVERLAY",
            1
        ),
    };
    LayoutLifebloomPandemicBorder(button);
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

    helper = {};
    helper.root = CreateFrame("Frame", nil, frame);
    helper.root:SetSize(1, 1);
    helper.root:SetFrameLevel(frame:GetFrameLevel() + FRAME_LEVEL_OFFSET);

    helper.primary = CreateFrame(
        "AuraContainer",
        nil,
        helper.root,
        "CustomAuraContainerTemplate"
    );
    helper.primary:SetFrameLevel(helper.root:GetFrameLevel());
    helper.primary:SetPoint(
        "TOPRIGHT",
        helper.root,
        "CENTER",
        0,
        PRIMARY_BUFF_SIZE + ( ROW_SPACING / 2 )
    );
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
            InitializeAuraButton(button, PRIMARY_BUFF_SIZE);

            if playerProfile.primaryPandemicGlow then
                AddLifebloomPandemicBorder(button);
            end
        end,
        layout = {
            elementWidth = PRIMARY_BUFF_SIZE,
            elementHeight = PRIMARY_BUFF_SIZE,
        },
    });

    helper.row2 = CreateFrame(
        "AuraContainer",
        nil,
        helper.root,
        "CustomAuraContainerTemplate"
    );
    helper.row2:SetFrameLevel(helper.root:GetFrameLevel());
    helper.row2:SetPoint(
        "TOPRIGHT",
        helper.root,
        "CENTER",
        0,
        -( ROW_SPACING / 2 )
    );
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
    helper.row2Warning:SetSize(ROW2_BUFF_SIZE, ROW2_BUFF_SIZE);
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
                InitializeAuraButton(button, ROW2_BUFF_SIZE);
            end,
            layout = {
                groupSpacing = ROW2_BUFF_SPACING,
                elementWidth = ROW2_BUFF_SIZE,
                elementHeight = ROW2_BUFF_SIZE,
            },
        });
    end

    helper.classBuffAnchor = CreateFrame("Frame", nil, helper.root);
    helper.classBuffAnchor:SetFrameLevel(helper.root:GetFrameLevel());
    helper.classBuffAnchor:SetSize(ROW2_BUFF_SIZE, ROW2_BUFF_SIZE);
    helper.classBuffAnchor:SetPoint(
        "RIGHT",
        helper.root,
        "CENTER",
        -PRIMARY_BUFF_SIZE - ROW2_BUFF_SPACING,
        ( PRIMARY_BUFF_SIZE / 2 ) + ( ROW_SPACING / 2 )
    );
    helper.classBuffAnchor:Hide();

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

    frame.healerBuffHelper = helper;
    ApplyLayout(frame, helper);
    return helper;
end

ApplyLayout = function(frame, helper)
    local config = GetConfig();
    local offsetX = -RIGHT_PAD + ( config.healerBuffHelperOffsetX or 0 );
    local offsetY = config.healerBuffHelperOffsetY or 0;

    helper.root:ClearAllPoints();
    helper.root:SetPoint("RIGHT", frame, "RIGHT", offsetX, offsetY);
    helper.root:SetScale(GetScale());

    local warningSetting = playerProfile.row2WarningSetting;
    helper.row2Warning:SetShown(
        warningSetting
            and config[warningSetting]
            and true
            or false
    );
end

local function HideHelper(frame)
    local helper = frame.healerBuffHelper;
    if ( not helper ) then return end
    helper.active = false;
    helper.primary:SetEnabled(false);
    helper.primary:Hide();
    helper.row2:SetEnabled(false);
    helper.row2:Hide();
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

local function ReadClassBuffState(unit)
    if ( not C_UnitAuras.GetUnitAuraBySpellID )
        or ( not C_Secrets )
        or ( not C_Secrets.ShouldSpellAuraBeSecret ) then
        return;
    end

    for spellID in pairs(playerProfile.classBuffAuras) do
        if C_Secrets.ShouldSpellAuraBeSecret(spellID) then return end
        if C_UnitAuras.GetUnitAuraBySpellID(unit, spellID) then
            return true;
        end
    end

    return false;
end

local function UpdateClassBuffWarning(helper, unit)
    helper.classBuffWarning:Hide();
    helper.classBuffAnchor:Hide();

    if IsPetUnit(unit) then return end

    local ok, hasClassBuff = pcall(ReadClassBuffState, unit);
    if ( not ok ) or hasClassBuff == nil then return end

    helper.classBuffAnchor:Show();
    helper.classBuffWarning:SetShown(not hasClassBuff);
end

local function ShouldTrackFrameName(name)
    if ( not name ) then return false end
    return ( string.sub(name, 1, 17) == "CompactPartyFrame" )
        or ( string.sub(name, 1, 11) == "CompactRaid" );
end

local function ActivateContainer(container, unit, forceRefresh)
    if container:GetUnit() ~= unit then
        -- Blizzard_AuraContainer.lua: AuraContainerSharedMixin:SetUnit refreshes on token changes.
        container:SetUnit(unit);
    elseif forceRefresh then
        -- The same mixin exposes UpdateAllAuras for external same-token occupant changes.
        container:UpdateAllAuras();
    end
    container:SetEnabled(true);
    container:Show();
end

local function UpdateFrame(frame, forceRefresh)
    if ( not frame ) or frame:IsForbidden() then return end

    local unit = frame.displayedUnit or frame.unit;
    -- Blizzard's fake AuraContainer provider is Edit Mode preview data, not live unit state.
    if ( not addon.IsUsingRealAuraData() )
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
    ApplyLayout(frame, helper);
    local needsFullRefresh = forceRefresh or ( not helper.active );
    ActivateContainer(helper.primary, unit, needsFullRefresh);
    ActivateContainer(helper.row2, unit, needsFullRefresh);
    UpdateClassBuffWarning(helper, unit);

    helper.active = true;
end

local function RefreshAllFrames(forceRefresh)
    for frame in pairs(cufPool) do
        UpdateFrame(frame, forceRefresh);
    end
end

local function RefreshClassBuffWarnings()
    for frame in pairs(cufPool) do
        local helper = frame.healerBuffHelper;
        if helper and helper.active then
            local unit = frame.displayedUnit or frame.unit;
            UpdateClassBuffWarning(helper, unit);
        end
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

    hooksecurefunc("CompactUnitFrame_UpdateAll", TrackFrame);
    hooksecurefunc("CompactUnitFrame_SetUnit", TrackFrame);
    hooksecurefunc("CompactUnitFrame_UpdateVisible", TrackFrame);

    local eventFrame = CreateFrame("Frame");
    eventFrame:RegisterEvent(addon.GROUP_ROSTER_UPDATE);
    eventFrame:RegisterEvent(addon.PLAYER_SPECIALIZATION_CHANGED);
    eventFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
    eventFrame:RegisterEvent(addon.UNIT_FACTION);
    eventFrame:RegisterEvent("PLAYER_CONTROL_LOST");
    eventFrame:RegisterEvent("PLAYER_CONTROL_GAINED");
    eventFrame:RegisterEvent("UNIT_AURA");
    eventFrame:SetScript("OnEvent", function(_, event, arg1)
        if event == "UNIT_AURA" then
            RefreshClassBuffWarnings();
            return;
        elseif event == addon.PLAYER_SPECIALIZATION_CHANGED then
            if arg1 ~= "player" then return end
            CheckSpec();
        end

        local isControlTransition = event == addon.UNIT_FACTION
            or event == "PLAYER_CONTROL_LOST"
            or event == "PLAYER_CONTROL_GAINED";
        if event == addon.GROUP_ROSTER_UPDATE or isControlTransition then
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

    addon.RegisterAuraDataProviderListener("RaidFrameAuraModule", function()
        RefreshAllFrames();
    end);
end

function SweepyBoop:RefreshHealerBuffHelper()
    CheckSpec();
    RefreshAllFrames();
end
