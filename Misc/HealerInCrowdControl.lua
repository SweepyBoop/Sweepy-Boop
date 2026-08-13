local _, addon = ...;

local auraFilter = "HARMFUL|CROWD_CONTROL";
local auraGroupKey = "CrowdControl";
local iconBaseSize = addon.DEFAULT_ICON_SIZE;
local borderBaseSize = iconBaseSize * 1.25;
local testDuration = 8;
local alertSound = 569006; -- spell_uni_sonarping_01
local partyUnits = { "party1", "party2" };

local visualRoot;
local testFrame;
local liveContainers = {};
local healerUnits = {};
local auraButtons = {};
local auraSoundIDs = {};
local setupComplete = false;
local restylePending = false;
local soundRefreshPending = false;

local COUNTDOWN_FONT_SIZE = 18;
local COUNTDOWN_FONT_FILE = "Fonts\\2002.TTF";
local countdownFont = CreateFont("SweepyBoopHealerCCCountdownFont");
countdownFont:SetFont(COUNTDOWN_FONT_FILE, COUNTDOWN_FONT_SIZE, "OUTLINE");

local function GetConfig()
    return SweepyBoop.db.profile.misc;
end

local function GetMillisecondsThreshold()
    local threshold = tonumber(GetConfig().healerInCrowdControlMillisecondsThreshold) or 5;
    if ( threshold < 1 ) then return 1 end
    if ( threshold > 6 ) then return 6 end
    return threshold;
end

local function CanStyleAuraButtons()
    return ( not C_Secrets )
        or ( not C_Secrets.ShouldAurasBeSecret )
        or ( not C_Secrets.ShouldAurasBeSecret() );
end

local function StyleCountdownText(cooldown)
    if cooldown.SetCountdownFont then
        cooldown:SetCountdownFont(countdownFont:GetName());
    end
    if cooldown.SetCountdownMillisecondsThreshold then
        cooldown:SetCountdownMillisecondsThreshold(GetMillisecondsThreshold());
    end
    if cooldown.GetCountdownFontString then
        local text = cooldown:GetCountdownFontString();
        if text then
            text:ClearAllPoints();
            text:SetPoint("TOP", cooldown:GetParent().border, "BOTTOM", 0, -1);
        end
    end
end

local function CreateVisual(frame)
    frame:SetSize(iconBaseSize, iconBaseSize);

    frame.icon = frame:CreateTexture(nil, "BORDER");
    frame.icon:SetAllPoints(frame);

    frame.mask = frame:CreateMaskTexture();
    frame.mask:SetTexture("Interface/Masks/CircleMaskScalable");
    frame.mask:SetAllPoints(frame.icon);
    frame.icon:AddMaskTexture(frame.mask);

    frame.border = frame:CreateTexture(nil, "OVERLAY");
    frame.border:SetAtlas("talents-warmode-ring");
    frame.border:SetSize(borderBaseSize, borderBaseSize);
    frame.border:SetPoint("CENTER", frame);

    frame.cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate");
    frame.cooldown:SetAllPoints(frame);
    frame.cooldown:SetDrawEdge(true);
    frame.cooldown:SetEdgeTexture("Interface\\Cooldown\\UI-HUD-ActionBar-LoC");
    frame.cooldown:SetUseCircularEdge(true);
    frame.cooldown:SetReverse(true);
    frame.cooldown:SetSwipeTexture("Interface/Masks/CircleMaskScalable");
    frame.cooldown:SetSwipeColor(0, 0, 0, 0.5);
    frame.cooldown:SetHideCountdownNumbers(false);
    StyleCountdownText(frame.cooldown);
end

local function EnsureVisualRoot()
    if visualRoot then return visualRoot end

    visualRoot = CreateFrame("Frame", nil, UIParent);
    visualRoot:SetFrameStrata("HIGH");
    visualRoot:SetSize(1, 1);
    return visualRoot;
end

local function ApplyVisualRootLayout()
    local root = EnsureVisualRoot();
    local config = GetConfig();
    local shownSize = tonumber(config.healerInCrowdControlSize) or 48;
    if ( shownSize <= 0 ) then shownSize = 48 end
    local scale = shownSize / iconBaseSize;

    root:ClearAllPoints();
    root:SetPoint(
        "CENTER",
        UIParent,
        "CENTER",
        ( config.healerInCrowdControlOffsetX or 0 ) / scale,
        ( config.healerInCrowdControlOffsetY or 0 ) / scale
    );
    root:SetScale(scale);
    root:Show();
end

local function InitializeAuraButton(button)
    auraButtons[#auraButtons + 1] = button;
    button:SetMouseMotionEnabled(false);
    CreateVisual(button);
    button:SetIcon(button.icon);
    button:SetDurationCooldown(button.cooldown);
end

local function EnsureLiveContainer(unit)
    local container = liveContainers[unit];
    if container then return container end

    local root = EnsureVisualRoot();
    container = CreateFrame(
        "AuraContainer",
        nil,
        root,
        "CustomAuraContainerTemplate"
    );
    -- CustomAuraContainerTemplate starts enabled. Blizzard_AuraContainer.lua uses
    -- visibility to gate dynamic events, and OnShow requests a full aura refresh.
    container:Hide();
    container:SetPoint("CENTER", root, "CENTER");
    container:SetFlowLayoutAxis(AnchorUtil.FlowLayoutAxis.Horizontal);
    container:SetFlowLayoutAnchorPoint("CENTER");
    container:SetFlowLayoutGrowthDirection(
        AnchorUtil.FlowDirection.Right,
        AnchorUtil.FlowDirection.Down
    );
    container:SetUnit(unit);
    container:SetAuraProcessingPolicy(
        CustomAuraContainerAuraProcessingPolicy.ProcessAura,
        {
            displayOnlyDispellableDebuffs = false,
            ignoreBuffs = true,
            ignoreDebuffs = false,
            ignoreDispelDebuffs = false,
        }
    );
    container:AddAuraGroup(auraGroupKey, auraFilter, {
        maxFrameCount = 1,
        sortMethod = AuraContainerSortMethod.UnitFrameDebuff,
        sortDirection = AuraContainerSortDirection.Normal,
        initializeFrame = InitializeAuraButton,
        layout = {
            elementSpacing = 0,
            lineSpacing = 0,
            elementWidth = iconBaseSize,
            elementHeight = iconBaseSize,
        },
    });

    liveContainers[unit] = container;
    return container;
end

local function HideLiveContainer(container)
    container:Hide();
end

local function ActivateLiveContainer(container, unit, forceRefresh)
    if container:GetUnit() ~= unit then
        -- Blizzard_AuraContainer.lua: AuraContainerSharedMixin:SetUnit refreshes on token changes.
        container:SetUnit(unit);
    elseif forceRefresh then
        -- The same mixin exposes UpdateAllAuras for external same-token occupant changes.
        container:UpdateAllAuras();
    end
    container:Show();
end

local function UnitExistsReadable(unit)
    local exists = UnitExists(unit);
    return ( not addon.IsSecretValue(exists) ) and exists;
end

local function UpdateHealerAssignments(resetUnreadable)
    for _, unit in ipairs(partyUnits) do
        if UnitExistsReadable(unit) then
            local role = UnitGroupRolesAssigned(unit);
            if addon.IsSecretValue(role) then
                if resetUnreadable then
                    healerUnits[unit] = nil;
                end
            else
                healerUnits[unit] = role == "HEALER";
            end
        else
            healerUnits[unit] = nil;
        end
    end
end

local function ClearAuraSounds()
    for i = #auraSoundIDs, 1, -1 do
        C_UnitAuras.RemoveAuraSound(auraSoundIDs[i]);
        auraSoundIDs[i] = nil;
    end
end

local function RegisterAuraSounds(unit)
    if ( not GetConfig().healerInCrowdControlSound )
        or ( not C_UnitAuras.AddAuraSound ) then

        return;
    end

    for spellID in pairs(addon.DRList) do
        local isCrowdControl = C_Spell.IsSpellCrowdControl(spellID);
        if ( not addon.IsSecretValue(isCrowdControl) ) and isCrowdControl then
            local soundID = C_UnitAuras.AddAuraSound(
                Enum.UnitAuraSoundTrigger.Added,
                {
                    unitToken = unit,
                    spellID = spellID,
                    soundFileID = alertSound,
                    outputChannel = "Master",
                }
            );
            if soundID then
                auraSoundIDs[#auraSoundIDs + 1] = soundID;
            end
        end
    end
end

local function IsInArenaInstance()
    local inInstance, instanceType = IsInInstance();
    return inInstance and instanceType == "arena";
end

local function RefreshLiveContainers(forceRefresh, resetUnreadableRoles)
    ApplyVisualRootLayout();
    UpdateHealerAssignments(resetUnreadableRoles);
    local refreshSounds = forceRefresh and ( not InCombatLockdown() );
    if forceRefresh then
        ClearAuraSounds();
        soundRefreshPending = not refreshSounds
            and GetConfig().healerInCrowdControlSound;
    end

    -- Blizzard's fake AuraContainer provider is Edit Mode preview data, not live unit state.
    local enabled = GetConfig().healerInCrowdControl
        and IsInArenaInstance()
        and addon.IsUsingRealAuraData();

    for _, unit in ipairs(partyUnits) do
        local container = EnsureLiveContainer(unit);
        local trackUnit = enabled
            and UnitExistsReadable(unit)
            and healerUnits[unit];

        if trackUnit then
            ActivateLiveContainer(container, unit, forceRefresh);
            if refreshSounds then
                RegisterAuraSounds(unit);
            end
        else
            HideLiveContainer(container);
        end
    end
end

local function ReconcilePendingRestyle()
    -- A restricted style request remains dirty until the shared Blizzard
    -- restriction transition callback wakes this event-driven retry.
    if ( not restylePending ) or ( not CanStyleAuraButtons() ) then return end

    restylePending = false;
    for _, button in ipairs(auraButtons) do
        StyleCountdownText(button.cooldown);
    end
end

local function RestyleAuraButtons()
    if ( not CanStyleAuraButtons() ) then
        restylePending = true;
        return;
    end

    restylePending = false;
    for _, button in ipairs(auraButtons) do
        StyleCountdownText(button.cooldown);
    end
end

local function EnsureTestFrame()
    if testFrame then return testFrame end

    testFrame = CreateFrame("Frame", nil, EnsureVisualRoot());
    testFrame:SetPoint("CENTER", visualRoot, "CENTER");
    testFrame:SetMouseClickEnabled(false);
    CreateVisual(testFrame);
    testFrame.cooldown:SetScript("OnCooldownDone", function()
        testFrame:Hide();
    end);
    testFrame:Hide();
    return testFrame;
end

local class = addon.GetUnitClass("player");
local testIcons = {
    [addon.DRUID] = 51514, -- Hex
    [addon.EVOKER] = 51514, -- Hex
    [addon.HUNTER] = 605, -- Mind Control
    [addon.MAGE] = 51514, -- Hex
    [addon.MONK] = 356727, -- Spider Venom
    [addon.PALADIN] = 356727, -- Spider Venom
    [addon.PRIEST] = 605, -- Mind Control
    [addon.SHAMAN] = 8122, -- Psychic Scream
};
local testSpellID = testIcons[class] or 118; -- Polymorph

function SweepyBoop:TestHealerInCrowdControl()
    if IsInInstance() then
        addon.PRINT("Cannot run test mode inside an instance");
        return;
    end

    ApplyVisualRootLayout();
    local frame = EnsureTestFrame();
    frame.icon:SetTexture(addon.GetSpellTexture(testSpellID));
    StyleCountdownText(frame.cooldown);
    frame.cooldown:SetCooldown(GetTime(), testDuration);
    frame.cooldown:Show();
    frame:Show();

    if GetConfig().healerInCrowdControlSound then
        PlaySoundFile(alertSound, "Master");
    end
end

function SweepyBoop:HideTestHealerInCrowdControl()
    if testFrame then
        testFrame.cooldown:Clear();
        testFrame:Hide();
    end
end

function SweepyBoop:UpdateHealerInCrowdControl()
    ApplyVisualRootLayout();
    RestyleAuraButtons();
    if testFrame then
        StyleCountdownText(testFrame.cooldown);
    end
end

function SweepyBoop:SetupHealerInCrowdControl()
    if ( not addon.PROJECT_MAINLINE ) then return end

    ApplyVisualRootLayout();
    for _, unit in ipairs(partyUnits) do
        EnsureLiveContainer(unit);
    end

    if setupComplete then
        RefreshLiveContainers(true);
        return;
    end
    setupComplete = true;

    local eventFrame = CreateFrame("Frame");
    eventFrame:RegisterEvent(addon.GROUP_ROSTER_UPDATE);
    eventFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
    eventFrame:RegisterEvent(addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS);
    eventFrame:RegisterEvent(addon.PLAYER_REGEN_ENABLED);
    eventFrame:RegisterEvent("PLAYER_ROLES_ASSIGNED");
    eventFrame:SetScript("OnEvent", function(_, event)
        if event == addon.PLAYER_REGEN_ENABLED
            or event == addon.PLAYER_ENTERING_WORLD then

            ReconcilePendingRestyle();
        end

        if event == addon.PLAYER_REGEN_ENABLED then
            if soundRefreshPending then
                RefreshLiveContainers(true);
            end
            return;
        end

        if event == addon.GROUP_ROSTER_UPDATE
            or event == addon.PLAYER_ENTERING_WORLD
            or event == addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS
            or event == "PLAYER_ROLES_ASSIGNED" then

            C_Timer.After(0, function()
                RefreshLiveContainers(true, true);
            end);
        else
            RefreshLiveContainers();
        end
    end);

    addon.RegisterAuraDataProviderListener("HealerInCrowdControl", function()
        RefreshLiveContainers();
    end);
    addon.RegisterAuraRestrictionListener("HealerInCrowdControl", ReconcilePendingRestyle);

    RefreshLiveContainers(true);
end
