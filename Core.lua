local addonName, addon = ...;
addon.L = LibStub("AceLocale-3.0"):GetLocale(addonName);
local L = addon.L;
addon.addonTitle = C_AddOns.GetAddOnMetadata(addonName, "Title");

SweepyBoop = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceSerializer-3.0");

local SweepyBoopLDB = LibStub("LibDataBroker-1.1"):NewDataObject(addonName, {
    type = "data source",
    text = addonName,
    icon = addon.INTERFACE_SWEEPY .. "Art/Logo",
    OnTooltipShow = function(tooltip)
        tooltip:SetText(addon.addonTitle, 1, 1, 1);
        tooltip:AddLine(L["Click to open options"]);
    end,
    OnClick = function()
        LibStub("AceConfigDialog-3.0"):Open(addonName);
    end,
})
local icon = LibStub("LibDBIcon-1.0");

local options = {
    name = addon.addonTitle,
    type = "group",
    args = {
        description = {
            order = 1,
            type = "description",
            fontSize = "large",
            image = addon.INTERFACE_SWEEPY .. "Art/Logo",
            imageWidth = 36,
            imageHeight = 36,
            name = L["A lightweight addon to enhance your arena & battleground experience :)"]
        },
    },
};

options.args.support = {
    order = 8,
    type = "group",
    name = L["Support"],
    args = {
        discordLink = {
            order = 1,
            type = "input",
            width = "full",
            name = addon.FORMAT_ATLAS("UI-ChatIcon-ODIN") .. " " .. L["Join Discord for PvP UI support"],
            desc = L["Press Ctrl+C to copy URL"],
            dialogControl = "InlineLink-SweepyBoop",
            get = function ()
                return "https://discord.gg/SMRxeZzVwc";
            end
        },

        donate = {
            order = 2,
            type = "input",
            width = "full",
            name = addon.FORMAT_ATLAS("GarrisonTroops-Health") .. " " .. L["If feeling generous"],
            desc = L["Press Ctrl+C to copy URL"],
            dialogControl = "InlineLink-SweepyBoop",
            get = function ()
                return "https://www.paypal.me/sweepyboop";
            end
        },
    },
};

local defaults = {
    profile = {
        nameplatesFriendly = {
            classIconsEnabled = true,
            classIconStyle = addon.CLASS_ICON_STYLE.CLASS_ICON,
            classIconMarkerStyle = addon.CLASS_ICON_MARKER_STYLE.DOUBLE_ARROW,
            classIconMarkerVisibility = addon.CLASS_ICON_MARKER_VISIBILITY.ALWAYS_SHOW,
            showSpecIcons = true,
            hideOutsidePvP = false,
            hideInBattlegrounds = false;
            classIconSize = 1,
            healerIconSize = 1.25,
            flagCarrierIconSize = 1.5,
            petIconSize = 0.8,
            classIconHorizontalOffset = 0,
            classIconOffset = 0,
            classIconBorderStyle = addon.CLASS_ICON_BORDER_STYLE.CLASS_COLORED,
            useHealerIcon = true,
            showHealerOnly = false,
            useFlagCarrierIcon = true,
            targetHighlightStyle = addon.TARGET_HIGHLIGHT_STYLE.ANIMATED,
            showPlayerName = false,
            showCrowdControl = addon.CLASS_ICON_CROWD_CONTROL_DISPLAY.FULL,
        },
        nameplatesEnemy = {
            arenaNumbersEnabled = true,
            arenaSpecIconHealer = true,
            arenaSpecIconHealerIcon = true,
            arenaSpecIconOthers = false,
            arenaSpecIconScale = 100,
            arenaSpecIconAlignment = addon.SPEC_ICON_ALIGNMENT.TOP,
            arenaSpecIconHorizontalOffset = 0,
            arenaSpecIconVerticalOffset = 0,
            filterEnabled = true,
            showCritterIcons = true,
            auraFilterEnabled = false,
            showBuffsOnEnemy = false,
            bigDebuffsEnabled = addon.BIG_DEBUFFS_DEFAULTS.ENABLED,
            bigDebuffsShowCrowdControl = addon.BIG_DEBUFFS_DEFAULTS.SHOW_CROWD_CONTROL,
            bigDebuffsShowDefensives = addon.BIG_DEBUFFS_DEFAULTS.SHOW_DEFENSIVES,
            bigDebuffsShowImportantBuffs = addon.BIG_DEBUFFS_DEFAULTS.SHOW_IMPORTANT_BUFFS,
            bigDebuffsShowCountdown = addon.BIG_DEBUFFS_DEFAULTS.SHOW_COUNTDOWN,
            bigDebuffsIconStyle = addon.BIG_DEBUFFS_DEFAULTS.ICON_STYLE,
            bigDebuffsIconSize = addon.BIG_DEBUFFS_DEFAULTS.ICON_SIZE,
            bigDebuffsMaxIcons = addon.BIG_DEBUFFS_DEFAULTS.MAX_ICONS,
            bigDebuffsSpacing = addon.BIG_DEBUFFS_DEFAULTS.SPACING,
            bigDebuffsOffsetX = addon.BIG_DEBUFFS_DEFAULTS.OFFSET_X,
            bigDebuffsOffsetY = addon.BIG_DEBUFFS_DEFAULTS.OFFSET_Y,
            npcHighlightScale = 1,
            npcHighlightHorizontalOffset = 0,
            npcHighlightOffset = 0,
            hideHunterSecondaryPet = true,
            filterList = {},
            debuffWhiteList = {},
            buffWhiteList = {},
        },
        arenaFrames = {
            arenaCooldownTrackerEnabled = true,
            arenaCooldownSecondaryBar = false,

            arenaCooldownGrowDirection = addon.ARENA_COOLDOWN_GROW_DIRECTION.RIGHT,
            arenaCooldownOffsetX = 0,
            arenaCooldownOffsetY = 0,

            arenaCooldownGrowDirectionSecondary = addon.ARENA_COOLDOWN_GROW_DIRECTION.RIGHT,
            arenaCooldownOffsetXSecondary = 0,
            arenaCooldownOffsetYSecondary = -35,

            arenaCooldownTrackerIconSize = 32,
            arenaCooldownTrackerIconSizeSecondary = 32,
            arenaCooldownTrackerIconPadding = 2,
            arenaCooldownTrackerIconPaddingSecondary = 2,
            arenaCooldownTrackerGlow = true,
            arenaCooldownTrackerGlowSecondary = true,

            arenaOffensiveIconsEnabled = false,
            arenaOffensiveIconSize = addon.ARENA_OFFENSIVE_ICON_STYLE.DEFAULT_DISPLAY_SIZE,
            arenaOffensiveIconOffsetX = 0,
            arenaOffensiveIconOffsetY = 0,

            unusedIconAlpha = 0.5,
            usedIconAlpha = 1,
            showUnusedIcons = false,
            hideCountDownNumbers = false,
            spellList = {},
            spellList2 = {},

            spellCatPriority = {
                [tostring(addon.SPELLCATEGORY.IMMUNITY)] = 100,
                [tostring(addon.SPELLCATEGORY.DEFENSIVE)] = 90,
                [tostring(addon.SPELLCATEGORY.DISPEL)] = 50,
                [tostring(addon.SPELLCATEGORY.MASS_DISPEL)] = 55,
                [tostring(addon.SPELLCATEGORY.INTERRUPT)] = 50,
                [tostring(addon.SPELLCATEGORY.STUN)] = 90,
                [tostring(addon.SPELLCATEGORY.SILENCE)] = 80,
                [tostring(addon.SPELLCATEGORY.KNOCKBACK)] = 30,
                [tostring(addon.SPELLCATEGORY.CROWDCONTROL)] = 70,
                [tostring(addon.SPELLCATEGORY.BURST)] = 90,
                [tostring(addon.SPELLCATEGORY.HEAL)] = 80,
                [tostring(addon.SPELLCATEGORY.MOBILITY)] = 70,
                [tostring(addon.SPELLCATEGORY.OTHERS)] = 10,
            },
        },
        raidFrames = {
            raidFrameAggroHighlightRaidFramesShape = "Circle",
            raidFrameAggroHighlightRaidFramesAnchor = "TOPRIGHT",
            raidFrameAggroHighlightRaidFramesRelativePoint = "TOPRIGHT",
            raidFrameAggroHighlightRaidFramesGrowDirection = "LEFT",
            raidFrameAggroHighlightRaidFramesOffsetX = -1,
            raidFrameAggroHighlightRaidFramesOffsetY = -1,
            raidFrameAggroHighlightRaidFramesSpacing = 1,
            raidFrameAggroHighlightRaidFramesSize = 16,
            raidFrameAggroHighlightRaidFramesBorderThickness = 1,
            raidFrameAggroHighlightArenaFramesShape = "Circle",
            raidFrameAggroHighlightArenaFramesAnchor = "TOPRIGHT",
            raidFrameAggroHighlightArenaFramesRelativePoint = "TOPRIGHT",
            raidFrameAggroHighlightArenaFramesGrowDirection = "LEFT",
            raidFrameAggroHighlightArenaFramesOffsetX = -1,
            raidFrameAggroHighlightArenaFramesOffsetY = -1,
            raidFrameAggroHighlightArenaFramesSpacing = 1,
            raidFrameAggroHighlightArenaFramesSize = 16,
            raidFrameAggroHighlightArenaFramesBorderThickness = 1,
            druidBuffHelper = true,
            healerBuffHelperScale = 1,
            healerBuffHelperOffsetX = 0,
            healerBuffHelperOffsetY = 0,
            druidBuffHelperWarning = false,
            evokerBuffHelper = true,
            raidFrameDebuffIconsEnabled = false,
            raidFrameDebuffIconCount = 2,
            raidFrameDebuffIconScale = 0.5,
            raidFrameDebuffIconDispellableScale = 0.5,
            raidFrameDebuffIconShowCountdown = true,
            raidFrameDebuffIconMillisecondsThreshold = 3,
            raidFrameDebuffIconOffsetX = 2,
            raidFrameDebuffIconOffsetY = 0,
        },
        misc = {
            healerInCrowdControl = false,
            healerInCrowdControlSize = 48,
            healerInCrowdControlMillisecondsThreshold = 3,
            healerInCrowdControlOffsetX = 0,
            healerInCrowdControlOffsetY = 250,
            healerIndicator = true,
            queueReminder = true,
            precognitionTracker = true,
            precognitionTrackerSize = 36,
            precognitionTrackerOffsetX = 0,
            precognitionTrackerOffsetY = -75,
            personalDR = false,
            personalDRSize = 32,
            personalDRShowCleanStun = true,
            personalDRAnchorPoint = "CENTER",
            personalDRRelativePoint = "CENTER",
            personalDRGrowDirection = "CENTER",
            personalDROffsetX = 0,
            personalDROffsetY = -50,
            personalDRTrackStun = true,
            personalDRTrackIncapacitate = true,
            personalDRTrackDisorient = true,
            personalDRTrackRoot = false,
            personalDRTrackSilence = false,
            personalDRTrackDisarm = false,
            honorReminder = false,
            honorReminderThreshold = 10000,
            honorReminderFontSize = 16,
            honorReminderIconSize = 16,
            honorReminderAnchorPoint = "BOTTOMRIGHT",
            honorReminderOffsetX = 0,
            honorReminderOffsetY = 75,
            combatIndicator = true,
            classColorUnitFrames = true,
            alwaysShowDruidComboPoints = true,
            hideBlizzArenaFrames = true,
            showDampenPercentage = true,

            rangeCheckerSize = 32,
            rangeCheckerOffsetX = 0,
            rangeCheckerOffsetY = 0,

            rangeCheckerSpells = {
                [addon.DEATHKNIGHT] = 49576, -- Death Grip
                [addon.DEMONHUNTER] = 217832, -- Imprison
                [addon.DRUID] = 33786, -- Cyclone
                [addon.EVOKER] = 360806, -- Sleep Walk
                [addon.HUNTER] = 213691, -- Scatter Shot
                [addon.MAGE] = 118, -- Polymorph
                [addon.MONK] = 115078, -- Paralysis
                [addon.PALADIN] = 20066, -- Repentance
                [addon.PRIEST] = 605, -- Mind Control
                [addon.ROGUE] = 36554, -- Shadowstep
                [addon.SHAMAN] = 51514, -- Hex
                [addon.WARLOCK] = 5782, -- Fear
                [addon.WARRIOR] = 107570, -- Storm Bolt
            },
        },
        mouseCursor = {
            enabled = true,
            showBaseline = true,
            showTrail = true,
            showGCD = true,
            ringSize = 48,
            gcdRingSize = 60,
            scale = 1,
            opacity = 0.85,
            trailDuration = 0.35,
            trailDensity = 0.018,
            trailSize = 9,
            trailMinMovement = 2,
            baselineColorR = 1,
            baselineColorG = 1,
            baselineColorB = 1,
            trailColorR = 1,
            trailColorG = 1,
            trailColorB = 1,
            gcdColorR = 0.1,
            gcdColorG = 1,
            gcdColorB = 0.25,
        },
        minimap = {
            hide = false,
        },
    }
};

if addon.internal then -- Set default for internal version
    defaults.profile.nameplatesFriendly.classIconStyle = addon.CLASS_ICON_STYLE.CLASS_ICON_AND_MARKER;
    defaults.profile.nameplatesFriendly.classIconMarkerVisibility = addon.CLASS_ICON_MARKER_VISIBILITY.PARTY_MEMBERS_ONLY;
    defaults.profile.nameplatesFriendly.classIconSize = 1.5;
    defaults.profile.nameplatesFriendly.healerIconSize = 1.5;
    defaults.profile.nameplatesFriendly.flagCarrierIconSize = 1.5;
    defaults.profile.nameplatesFriendly.petIconSize = 1.5;
    defaults.profile.nameplatesEnemy.arenaSpecIconOthers = true;
    defaults.profile.nameplatesEnemy.auraFilterEnabled = true;
    defaults.profile.nameplatesEnemy.showBuffsOnEnemy = true;
    defaults.profile.nameplatesEnemy.bigDebuffsEnabled = true;
    defaults.profile.raidFrames.raidFrameDebuffIconsEnabled = true;
    defaults.profile.arenaFrames.arenaCooldownSecondaryBar = true;
    defaults.profile.arenaFrames.arenaCooldownTrackerIconSize = 28;
    defaults.profile.arenaFrames.arenaCooldownTrackerIconSizeSecondary = 28;
    defaults.profile.arenaFrames.arenaCooldownOffsetX = 35;
    defaults.profile.arenaFrames.arenaCooldownOffsetY = 15;
    defaults.profile.arenaFrames.arenaCooldownOffsetXSecondary = 35;
    defaults.profile.arenaFrames.arenaCooldownOffsetYSecondary = -25;
    defaults.profile.arenaFrames.arenaOffensiveIconsEnabled = true;
    defaults.profile.arenaFrames.showUnusedIcons = true;
    defaults.profile.arenaFrames.unusedIconAlpha = 1;
    defaults.profile.arenaFrames.usedIconAlpha = 0.5;
    defaults.profile.misc.healerInCrowdControl = true;
    defaults.profile.misc.honorReminder = true;
    defaults.profile.misc.personalDR = true;
    defaults.profile.misc.personalDRTrackIncapacitate = false;
    defaults.profile.misc.personalDRTrackDisorient = false;
    defaults.profile.misc.personalDROffsetY = 100;
    defaults.profile.misc.rangeCheckerEnabled = true;
end

local function FillDefaults()
    addon.FillDefaultToNpcOptions(defaults.profile.nameplatesEnemy.filterList);
    addon.FillDefaultToAuraOptions(defaults.profile.nameplatesEnemy.debuffWhiteList, addon.DebuffList);
    addon.FillDefaultToAuraOptions(defaults.profile.nameplatesEnemy.buffWhiteList, addon.BuffList);

    defaults.profile.arenaFrames.standaloneBars = {};
    for i = 1, 6 do
        local groupName = "Bar ".. i;
        defaults.profile.arenaFrames.standaloneBars[groupName] = {
            name = groupName,
            enabled = false,

            growDirection = addon.STANDALONE_GROW_DIRECTION.CENTER,
            columns = 8,
            growUpward = true,
            offsetX = 0,
            offsetY = 0,

            iconSize = 32,
            iconPadding = 2,
            unusedIconAlpha = 0.5,
            usedIconAlpha = 1,
            showUnusedIcons = false,
            hideCountDownNumbers = false,
            spellList = {},
        };
    end

    addon.SetupAllSpells(defaults.profile.arenaFrames.spellList, addon.SpellData);
    addon.SetupInterrupts(defaults.profile.arenaFrames.standaloneBars["Bar 1"].spellList, addon.SpellData);
end

function SweepyBoop:SetupBlizzardOptions()
    local interfaceOptionPanel = CreateFrame("Frame", nil, UIParent);
    interfaceOptionPanel.name = addon.addonTitle;
    interfaceOptionPanel:Hide();

    interfaceOptionPanel:SetScript("OnShow", function(self)
        local title = self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
        title:SetPoint("TOPLEFT", 16, -16);
        title:SetText(addon.addonTitle);

        local context = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
        context:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8);
        context:SetText(L["\124cFF00FF00Type /sb\124r or click the minimap icon to open the option panel."]);

        local open = CreateFrame("Button", nil, self, "UIPanelButtonTemplate");
        open:SetText(L["Open Option Panel"]);
        open:SetWidth(177);
        open:SetHeight(24);
        open:SetPoint("TOPLEFT", context, "BOTTOMLEFT", 0, -30);
        open.tooltipText = "";
        open:SetScript("OnClick", function()
            LibStub("AceConfigDialog-3.0"):Open(addonName);
        end)

        self:SetScript("OnShow", nil);
    end)

    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(interfaceOptionPanel, addon.addonTitle);
        Settings.RegisterAddOnCategory(category);
    else
        InterfaceOptions_AddCategory(interfaceOptionPanel);
    end

    SLASH_SweepyBoop1 = "/sb";
    SlashCmdList.SweepyBoop = function(msg)
        -- This opens the in-game options panel that is not moveable or resizable
        -- if Settings and Settings.OpenToCategory then
        --     Settings.OpenToCategory(SweepyBoop.categoryID);
        -- end
        LibStub("AceConfigDialog-3.0"):Open(addonName);
    end
end

function SweepyBoop:OnInitialize()
    FillDefaults();
    local currentTime = GetTime();
    for _, category in pairs(defaults) do
        if type(category) == "table" then
            category.lastModified = currentTime;
        end
    end
    self.db = LibStub("AceDB-3.0"):New("SweepyBoopDB", defaults, true);
    for _, profile in pairs(self.db.profiles) do
        addon.RemoveObsoleteProfileSettings(profile);
    end

    options.args.nameplatesFriendly = addon.GetFriendlyNameplateOptions(3);
    options.args.nameplatesEnemy = addon.GetEnemyNameplateOptions(4);

    if addon.PROJECT_MAINLINE then
        options.args.arenaFrames = addon.GetMainlineArenaFrameOptions(5);
        options.args.raidFrames = addon.GetRaidFrameOptions(6);
        options.args.macros = addon.GetMacroOptions(7.5);
        if addon.MAINLINE_CORE_FEATURES_ONLY then
            local miscOptions = addon.GetMiscOptions(7, icon, SweepyBoopLDB);
            options.args.misc =
                addon.GetHealerInCrowdControlOptions(7);
            options.args.misc.args.general.args.showMinimapIcon =
                miscOptions.args.general.args.showMinimapIcon;
            options.args.misc.args.general.args.combatIndicator =
                miscOptions.args.general.args.combatIndicator;
            options.args.misc.args.general.args.classColorUnitFrames =
                miscOptions.args.general.args.classColorUnitFrames;
            options.args.misc.args.honorReminder = miscOptions.args.honorReminder;
            options.args.misc.args.personalDR = miscOptions.args.personalDR;
            options.args.misc.args.gismo = miscOptions.args.gismo;
        else
            options.args.misc = addon.GetMiscOptions(7, icon, SweepyBoopLDB);
        end
    else
        options.args.arenaFrames = addon.GetArenaFrameOptions(5);
    end
    options.args.mouseCursor = addon.GetMouseCursorOptions(7.25);

    addon.importDialogs = addon.importDialogs or {};
    addon.importDialogs[""] = addon.CreateImportDialog("");
    addon.exportDialog = addon.exportDialog or addon.CreateExportDialog(); -- One shared dialog for exporting
    options.args.profileSharing = {
        order = 9,
        type = "group",
        name = L["Profile sharing"],
        args = {
            import = {
                order = 1,
                type = "execute",
                name = L["Import Profile"],
                desc = L["Import a profile from another user."],
                func = function()
                    SweepyBoop:ShowImport("");
                end,
            },
            export = {
                order = 2,
                type = "execute",
                name = L["Export Profile"],
                desc = L["Export your profile to share with others."],
                func = function()
                    SweepyBoop:ShowExport();
                end,
            },
        },
    };

    options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db);
    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, options);
    LibStub("AceConfigDialog-3.0"):SetDefaultSize(addonName, 760, 660);

    -- We don't add settings UI to game Options as it freezes after we modify settings then try to invoke options
    -- OmniBar has the same issue
    --self.optionsFrame, self.categoryID = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, addon.addonTitle); -- Can we open to the friendly class icons page instead of the first empty page?

    self:SetupBlizzardOptions();

    icon:Register(addonName, SweepyBoopLDB, self.db.profile.minimap);

    -- Register callback (https://www.wowace.com/projects/ace3/pages/ace-db-3-0-tutorial)
    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig");
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig");
    self:SetupNameplateModules();

    if ( not addon.PROJECT_MAINLINE ) then
        self:SetupArenaCooldownTracker();
        self:SetupMouseCursor();
    end

    if ( not addon.PROJECT_MAINLINE ) then return end

    -- Recovered modules run independently of the temporary Mainline gate.
    self:SetupRaidFrameAuraModule();
    self:SetupRaidFrameDebuffIcons();
    self:SetupArenaOffensiveIcons();

    self:SetupRaidFrameAggroHighlight();
    self:SetupHealerInCrowdControl();
    self:SetupHonorReminder();
    self:SetupAlwaysShowDruidComboPoints();
    self:SetupDampenDisplay();
    self:SetupQueueReminder();
    self:SetupPrecognitionTracker();
    self:SetupPersonalDR();
    self:SetupHealerIndicator();
    self:SetupRangeChecker();

    self:SetupCombatIndicator();
    self:SetupClassColorUnitFrames();

    if addon.MAINLINE_CORE_FEATURES_ONLY then
        self:SetupMouseCursor();
        return;
    end

    self:SetupHideBlizzArenaFrames();
    self:SetupMouseCursor();
    self:UpdateSBMMacros();
end

function SweepyBoop:RefreshConfig()
    if ( not addon.PROJECT_MAINLINE ) then
        self:HideTestArenaCooldownTracker();
        self:HideTestArenaStandaloneBars();
    end

    self:RefreshMouseCursor();

    if addon.PROJECT_MAINLINE then
        self:RefreshHealerBuffHelper();
        self:RefreshRaidFrameDebuffIcons();
        self:UpdateArenaOffensiveIcons();
        self:RefreshRaidFrameAggroHighlight();
        self:HideTestHealerInCrowdControl();
        self:SetupHealerInCrowdControl();
        self:UpdateHealerInCrowdControl();
        self:RefreshHonorReminder();
        self:SetupAlwaysShowDruidComboPoints();
        self:SetupDampenDisplay();
        self:SetupPrecognitionTracker();
        self:SetupPersonalDR();
        self:SetupRangeChecker();
    end

    if addon.PROJECT_MAINLINE then
        self:SetupCombatIndicator();
        self:SetupClassColorUnitFrames();
    end

    local currentTime = GetTime();
    for _, category in pairs(self.db.profile) do
        if type(category) == "table" then
            category.lastModified = currentTime;
        end
    end

    self:RefreshAllNamePlates(true);

    if self.db.profile.minimap.hide then
        icon:Hide(addonName);
    else
        icon:Show(addonName);
    end
end
