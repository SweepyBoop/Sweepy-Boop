local addonName, addon = ...;
addon.addonTitle = C_AddOns.GetAddOnMetadata(addonName, "Title");

SweepyBoop = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0");

local SweepyBoopLDB = LibStub("LibDataBroker-1.1"):NewDataObject(addonName, {
    type = "data source",
    text = addonName,
    icon = addon.INTERFACE_SWEEPY .. "Art/Logo",
    OnTooltipShow = function(tooltip)
        tooltip:SetText(addon.addonTitle, 1, 1, 1);
        tooltip:AddLine("Click to open options");
    end,
    OnClick = function()
        LibStub("AceConfigDialog-3.0"):Open(addonName);
        if SweepyBoopDB then
            SweepyBoopDB.slashCommandInvoked = SweepyBoopDB.slashCommandInvoked or 0;
            if ( SweepyBoopDB.slashCommandInvoked <= 3 ) then
                SweepyBoopDB.slashCommandInvoked = SweepyBoopDB.slashCommandInvoked + 1;
            end
        end
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
            name = "A lightweight addon to enhance your arena & battleground experience :)"
        },
    },
};

options.args.support = {
    order = 8,
    type = "group",
    name = "Support",
    args = {
        discordLink = {
            order = 1,
            type = "input",
            width = "full",
            name = addon.FORMAT_ATLAS("UI-ChatIcon-ODIN") .. " Join Discord for PvP UI support",
            desc = "Press Ctrl+C to copy URL",
            dialogControl = "InlineLink-SweepyBoop",
            get = function ()
                return "https://discord.gg/SMRxeZzVwc";
            end
        },

        donate = {
            order = 2,
            type = "input",
            width = "full",
            name = addon.FORMAT_ATLAS("GarrisonTroops-Health") .. " If feeling generous",
            desc = "Press Ctrl+C to copy URL",
            dialogControl = "InlineLink-SweepyBoop",
            get = function ()
                return "https://www.paypal.me/sweepyboop";
            end
        },
    },
}

local defaults = {
    profile = {
        nameplatesFriendly = {
            classIconsEnabled = true,
            classIconStyle = addon.CLASS_ICON_STYLE.ICON,
            showSpecIcons = true,
            hideOutsidePvP = false,
            hideInBattlegrounds = false;
            classIconSize = 1,
            petIconSize = 0.8,
            classIconOffset = 0,
            useHealerIcon = true,
            showHealerOnly = false,
            useFlagCarrierIcon = true,
            targetHighlight = true,
            classColorBorder = true,
            showPlayerName = false,
        },
        nameplatesEnemy = {
            arenaNumbersEnabled = true,
            arenaSpecIconHealer = true,
            arenaSpecIconHealerIcon = true,
            arenaSpecIconOthers = false,
            arenaSpecIconScale = 100,
            arenaSpecIconAlignment = addon.SPEC_ICON_ALIGNMENT.TOP,
            arenaSpecIconVerticalOffset = 0,
            filterEnabled = true,
            showCritterIcons = true,
            auraFilterEnabled = false,
            showBuffsOnEnemy = false,
            highlightScale = 100,
            hideHunterSecondaryPet = true,
            filterList = {},
            debuffWhiteList = {},
            buffWhiteList = {},
        },
        arenaFrames = {
            healerIndicator = true,
            arenaCooldownTrackerEnabled = true,
            arenaCooldownSecondaryBar = false,

            arenaCooldownGrowDirection = addon.ARENA_COOLDOWN_GROW_DIRECTION.RIGHT_DOWN,
            arenaCooldownOffsetX = 0,
            arenaCooldownOffsetY = 0,

            arenaCooldownGrowDirectionSecondary = addon.ARENA_COOLDOWN_GROW_DIRECTION.RIGHT_DOWN,
            arenaCooldownOffsetXSecondary = 0,
            arenaCooldownOffsetYSecondary = -35,

            arenaCooldownTrackerIconSize = 32,
            unusedIconAlpha = 0.5,
            usedIconAlpha = 1,
            showUnusedIcons = false,
            hideCountDownNumbers = false,
            spellList = {},
            spellList2 = {},

            interruptBarEnabled = false;
            interruptBarGrowDirection = addon.INTERRUPT_GROW_DIRECTION.CENTER_UP,
            interruptBarOffsetX = 0,
            interruptBarOffsetY = -150,
            interruptBarIconSize = 40,
            interruptBarUnusedIconAlpha = 0.5,
            interruptBarUsedIconAlpha = 1,
            interruptBarShowUnused = false,
            interruptBarHideCountDownNumbers = false,
            interruptBarSpellList = {},

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
                [tostring(addon.SPELLCATEGORY.OTHERS)] = 10,
            },
        },
        raidFrames = {
            arenaRaidFrameSortOrder = addon.RAID_FRAME_SORT_ORDER.DISABLED,
            raidFrameAggroHighlightEnabled = true,
            raidFrameAggroHighlightThickness = 2,
            raidFrameAggroHighlightAlpha = 0.5,
            raidFrameAggroHighlightAnimationSpeed = 0,
            druidHoTHelper = true,
        },
        misc = {
            healerInCrowdControl = false,
            healerInCrowdControlSize = 48,
            healerInCrowdControlOffsetX = 0,
            healerInCrowdControlOffsetY = 250,
            queueReminder = true,
            combatIndicator = true,
            arenaSurrenderEnabled = true,
            skipLeaveArenaConfirmation = false,
            showDampenPercentage = true,
        },
        minimap = {
            hide = false,
        },
    }
};

if addon.internal then -- Set default for internal version
    defaults.profile.nameplatesFriendly.classIconStyle = addon.CLASS_ICON_STYLE.ICON_AND_ARROW;
    defaults.profile.nameplatesFriendly.classIconSize = 1.25;
    defaults.profile.nameplatesFriendly.petIconSize = 1;
    defaults.profile.nameplatesFriendly.showCrowdControl = true;
    defaults.profile.nameplatesEnemy.auraFilterEnabled = true;
    defaults.profile.nameplatesEnemy.showBuffsOnEnemy = true;
    defaults.profile.raidFrames.arenaRaidFrameSortOrder = addon.RAID_FRAME_SORT_ORDER.PLAYER_MID;
    defaults.profile.raidFrames.raidFrameAggroHighlightAnimationSpeed = 5;
    defaults.profile.arenaFrames.arenaCooldownTrackerIconSize = 28;
    defaults.profile.arenaFrames.arenaCooldownOffsetX = 35;
    defaults.profile.arenaFrames.arenaCooldownOffsetY = 15;
    defaults.profile.arenaFrames.arenaCooldownOffsetXSecondary = 35;
    defaults.profile.arenaFrames.arenaCooldownOffsetYSecondary = -25;
    defaults.profile.arenaFrames.showUnusedIcons = true;
    defaults.profile.arenaFrames.unusedIconAlpha = 1;
    defaults.profile.arenaFrames.usedIconAlpha = 0.5;
    defaults.profile.arenaFrames.interruptBarEnabled = true;
    defaults.profile.arenaFrames.interruptBarShowUnused = true;
    defaults.profile.arenaFrames.interruptBarUnusedIconAlpha = 1;
    defaults.profile.arenaFrames.interruptBarUsedIconAlpha = 0.5;
    defaults.profile.misc.skipLeaveArenaConfirmation = true;
    defaults.profile.misc.healerInCrowdControl = true;
end

addon.FillDefaultToNpcOptions(defaults.profile.nameplatesEnemy.filterList);
addon.FillDefaultToAuraOptions(defaults.profile.nameplatesEnemy.debuffWhiteList, addon.DebuffList);
addon.FillDefaultToAuraOptions(defaults.profile.nameplatesEnemy.buffWhiteList, addon.BuffList);

local function SetupAllSpells(profile, spellList)
    for spellID, spellEntry in pairs(spellList) do
        local category = spellEntry.category;
        -- By default only check burst and defensives
        if ( category == addon.SPELLCATEGORY.BURST ) or ( category == addon.SPELLCATEGORY.DEFENSIVE ) or ( category == addon.SPELLCATEGORY.IMMUNITY ) or ( category == addon.SPELLCATEGORY.HEAL ) then
            profile[tostring(spellID)] = true;
        else
            profile[tostring(spellID)] = false;
        end
    end
end

local function UncheckAllSpells(profile, spellList)
    for spellID, spellEntry in pairs(spellList) do
        profile[tostring(spellID)] = false;
    end
end

local function SetupInterrupts(profile, spellList)
    for spellID, spellEntry in pairs(spellList) do
        local category = spellEntry.category;
        -- By default only check interrupts
        if ( category == addon.SPELLCATEGORY.INTERRUPT ) then
            profile[tostring(spellID)] = true;
        else
            profile[tostring(spellID)] = false;
        end
    end
end

if addon.PROJECT_MAINLINE then
    SetupAllSpells(defaults.profile.arenaFrames.spellList, addon.SpellData);
    SetupInterrupts(defaults.profile.arenaFrames.interruptBarSpellList, addon.SpellData);
end

function SweepyBoop:OnInitialize()
    options.args.nameplatesFriendly = addon.GetFriendlyNameplateOptions(3);
    options.args.nameplatesEnemy = addon.GetEnemyNameplateOptions(4);

    if addon.PROJECT_MAINLINE then
        options.args.arenaFrames = addon.GetArenaFrameOptions(5);
        options.args.raidFrames = addon.GetRaidFrameOptions(6);
        options.args.misc = addon.GetMiscOptions(7, icon, SweepyBoopLDB);
    end

    local currentTime = GetTime();
    for _, category in pairs(defaults) do
        if type(category) == "table" then
            category.lastModified = currentTime;
        end
    end

    self.db = LibStub("AceDB-3.0"):New("SweepyBoopDB", defaults, true);
    options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db);
    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, options);
    LibStub("AceConfigDialog-3.0"):SetDefaultSize(addonName, 750, 640);
    self.optionsFrame, self.categoryID = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, addon.addonTitle); -- Can we open to the friendly class icons page instead of the first empty page?

    icon:Register(addonName, SweepyBoopLDB, self.db.profile.minimap);

    -- Print message on first 3 logins with the addon enabled
    if SweepyBoopDB then
        SweepyBoopDB.slashCommandInvoked = SweepyBoopDB.slashCommandInvoked or 1;
        if ( SweepyBoopDB.slashCommandInvoked <= 1 ) then
            addon.PRINT("Thank you for supporting my addon! Type /sb or click the minimap icon to bring up the options panel. Have a wonderful PvP journey :)");
        end
    end

    -- Register callback (https://www.wowace.com/projects/ace3/pages/ace-db-3-0-tutorial)
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig");

    -- Nameplate module needs optimization to eat less CPU
    -- Setup nameplate modules
    self:SetupNameplateModules();

    -- Only nameplate modules for Classic currently
    -- If only enabling nameplates, 7 ms / Sec CPU, otherwise 11 ms / Sec CPU
    if ( not addon.PROJECT_MAINLINE ) then return end

    self:SetupArenaCooldownTracker();

    self:SetupHealerIndicator();

    -- Setup raid frame modules
    self:SetupRaidFrameAggroHighlight();
    self:SetupRaidFrameAuraModule();

    self:SetupQueueReminder();

    self:SetupCombatIndicator();

    self:SetupHealerInCrowdControl();
end

function SweepyBoop:TestArena()
    if IsInInstance() then
        addon.PRINT("Test mode can only be used outside instances");
        return;
    end

    if GladiusEx then
        local frame = _G["GladiusExButtonFramearena1"];
        if ( not frame ) or ( not frame:IsShown() ) then
            GladiusEx:SetTesting(3);
        end
    elseif Gladius then
        local frame = _G["GladiusButtonFramearena1"];
        if ( not frame ) or ( not frame:IsShown() ) then
            if SlashCmdList["GLADIUS"] then
                SlashCmdList["GLADIUS"]("test 3")
            end
        end
    elseif sArena then
        local frame = _G["sArenaEnemyFrame1"];
        if ( not frame ) or ( not frame:IsShown() ) then
            sArena:Test();
        end
    else
        -- Use Blizzard arena frames
        if ( not CompactArenaFrame:IsShown() ) then
            CompactArenaFrame:Show();
            for i = 1, addon.MAX_ARENA_SIZE do
                _G["CompactArenaFrameMember" .. i]:Show();
            end
        end
    end

    self:TestArenaCooldownTracker();
end

function SweepyBoop:TestArenaInterrupt()
    if IsInInstance() then
        addon.PRINT("Test mode can only be used outside instances");
        return;
    end

    self:TestArenaInterruptBar();
end

function SweepyBoop:RefreshConfig()
    if addon.PROJECT_MAINLINE then
        self:HideTestArenaCooldownTracker();
        self:HideTestArenaInterruptBar();

        self:SetupCombatIndicator();
        self:HideTestHealerInCrowdControl();
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

function SweepyBoop:CheckDefaultArenaAbilities()
    SetupAllSpells(SweepyBoop.db.profile.arenaFrames.spellList, addon.SpellData);
end

function SweepyBoop:UncheckAllArenaAbilities()
    UncheckAllSpells(SweepyBoop.db.profile.arenaFrames.spellList2, addon.SpellData);
end

function SweepyBoop:CheckDefaultInterrupts()
    SetupInterrupts(SweepyBoop.db.profile.arenaFrames.interruptBarSpellList, addon.SpellData);
end

SLASH_SweepyBoop1 = "/sb"
SlashCmdList.SweepyBoop = function(msg)
    -- This opens the in-game options panel that is not moveable or resizable
    -- if Settings and Settings.OpenToCategory then
    --     Settings.OpenToCategory(SweepyBoop.categoryID);
    -- end
    LibStub("AceConfigDialog-3.0"):Open(addonName);
    if SweepyBoopDB then
        SweepyBoopDB.slashCommandInvoked = SweepyBoopDB.slashCommandInvoked or 0;
        if ( SweepyBoopDB.slashCommandInvoked <= 3 ) then
            SweepyBoopDB.slashCommandInvoked = SweepyBoopDB.slashCommandInvoked + 1;
        end
    end
end
