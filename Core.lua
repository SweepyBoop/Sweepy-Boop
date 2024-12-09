local addonName, addon = ...;
addon.addonTitle = C_AddOns.GetAddOnMetadata(addonName, "Title");
addon.exclamation = "|TInterface\\OptionsFrame\\UI-OptionsFrame-NewFeatureIcon:0:0:0:-1|t";

SweepyBoop = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0");

local options = {
    name = addon.addonTitle,
    type = "group",
    args = {
        description = {
            order = 1,
            type ="description",
            fontSize = "large",
            image = "Interface\\Addons\\SweepyBoop\\ClassIcons\\pet\\PET0",
            imageWidth = 36,
            imageHeight = 36,
            name = "A lightweight addon to make your arena gameplay smoother :)"
        },
        break1 = {
            order = 2,
            type = "header",
            name = ""
        },
        reloadNotice = {
            order = 3,
            type = "description",
            fontSize = "medium",
            name = addon.exclamation .. "UI must be reloaded for most changes to take effect.",
        },
        reloadButton = {
            order = 4,
            type = "execute",
            name = "Reload UI",
            func = ReloadUI,
            width = 0.6,
        },
        break2 = {
            order = 5,
            type = "header",
            name = ""
        },
    },
};

options.args.NamePlates = {
    order = 6,
    type = "group",
    name = "Nameplates",
    get = function(info) return SweepyBoop.db.profile[info[#info]] end,
    set = function(info, val) SweepyBoop.db.profile[info[#info]] = val end,
    args = {
        header = {
            order = 1,
            type = "header",
            name = "Class & Pet Icons",
        },
        classIconsEnabled = {
            order = 2,
            width = "full",
            type = "toggle",
            name = "Enabled",
            desc = "Show class/pet icons on friendly players/pets",
        },
        description = {
            order = 3,
            width = "full",
            type = "description",
            name = addon.exclamation ..  "Need to enable \"Friendly Player Nameplates\" & \"Minions\" in Interface - Nameplates",
        },
        classIconStyle = {
            order = 4,
            type = "select",
            name = "Class Icon Style",
            style = "dropdown",
            values = {
                [addon.CLASSICONSTYLE.ROUND] = "Round",
                [addon.CLASSICONSTYLE.FLAT] = "Flat",
            },
            disabled = function()
                return ( not SweepyBoop.db.profile.classIconsEnabled );
            end
        },
        petIconStyle = {
            order = 5,
            type = "select",
            name = "Pet Icon Style",
            style = "dropdown",
            values = {
                [addon.PETICONSTYLE.CATS] = "Cat memes",
                [addon.PETICONSTYLE.MENDPET] = "Mend pet icon",
            },
            disabled = function()
                return ( not SweepyBoop.db.profile.classIconsEnabled );
            end
        },
        classIconSelectionBorderStyle = {
            order = 6,
            type = "select",
            name = "Selection highlight border style",
            style = "dropdown",
            values = {
                [addon.SELECTIONBORDERSTYLE.FIRE] = "Fire",
                [addon.SELECTIONBORDERSTYLE.ARCANE] = "Arcane",
                [addon.SELECTIONBORDERSTYLE.AIR] = "Air",
                [addon.SELECTIONBORDERSTYLE.MECHANICAL] = "Mechanical",
                [addon.SELECTIONBORDERSTYLE.PLAIN] = "Plain",
            },
            disabled = function()
                return ( not SweepyBoop.db.profile.classIconsEnabled );
            end
        },
        useHealerIcon = {
            order = 6,
            width = "full",
            type = "toggle",
            name = "Use dedicated healer icon",
            desc = "Use a dedicated icon for party healers",
            disabled = function()
                return ( not SweepyBoop.db.profile.classIconsEnabled );
            end
        },
        classIconScale = {
            order = 7,
            type = "range",
            min = 50,
            max = 200,
            name = "Icon scale (%)",
            disabled = function()
                return ( not SweepyBoop.db.profile.classIconsEnabled );
            end
        },
        classIconOffset = {
            order = 8,
            type = "range",
            min = 0,
            max = 150,
            name = "Icon offset",
            disabled = function()
                return ( not SweepyBoop.db.profile.classIconsEnabled );
            end
        },
        break1 = {
            order = 9,
            type = "header",
            name = ""
        },
        arenaNumbersEnabled = {
            order = 10,
            width = "full",
            type = "toggle",
            name = "Show Arena Numbers",
            desc = "Show arena numbers on top of enemy nameplates",
        },

        nameplateFilter = {
            order = 11,
            type = "group",
            name = "Filter & Highlight",
            get = function(info) return SweepyBoop.db.profile.nameplateFilter[info[#info]] end,
            set = function(info, val) SweepyBoop.db.profile.nameplateFilter[info[#info]] = val end,
            args = {
                enabled = {
                    order = 1,
                    type = "toggle",
                    name = "Enabled",
                },
                header = {
                    order = 2,
                    type = "header",
                    name = "Unit list",
                },
            },
        },
    },
};

options.args.ArenaFrames = {
    order = 7,
    type = "group",
    name = "Arena Frames",
    handler = SweepyBoop, -- for running SweepyBoop:TestArena()
    get = function(info) return SweepyBoop.db.profile[info[#info]] end,
    set = function(info, val) SweepyBoop.db.profile[info[#info]] = val end,
    args = {
        testmode = {
            order = 1,
            type = "execute",
            name = "Toggle Test Mode",
            func = "TestArena",
        },
        description1 = {
            order = 2,
            width = "full",
            type = "description",
            name = addon.exclamation .. "UI Reload is required if Gladius / sArena settings are changed",
        },
        breaker1 = {
            order = 3,
            type = "header",
            name = "",
        },

        arenaEnemyOffensivesEnabled = {
            order = 4,
            width = 1.5,
            type = "toggle",
            name = "Arena Enemy Offensive Cooldowns",
            desc = "Show arena enemy offensive cooldowns next to the arena frames",
        },
        arenaEnemyOffensiveIconSize = {
            order = 5,
            type = "range",
            min = 16,
            max = 64,
            name = "Icon size",
            desc = "Size of arena offensive cooldown icons",
        },
        arenaEnemyDefensivesEnabled = {
            order = 6,
            width = 1.5,
            type = "toggle",
            name = "Arena Enemy Defensive Cooldowns",
            desc = "Show arena enemy defensive cooldowns next to the arena frames",
        },
        arenaEnemyDefensiveIconSize = {
            order = 7,
            type = "range",
            min = 16,
            max = 64,
            name = "Icon size",
            desc = "Size of arena defensive cooldown icons",
        },
        arenaCooldownOffsetX = {
            order = 8,
            type = "range",
            min = -750,
            max = 750,
            name = "Horizontal offset",
            desc = "Horizontal offset of the arena cooldown icon group relative to the right edge of the arena frame",
        },
        arenaCooldownOffsetY = {
            order = 9,
            type = "range",
            min = -150,
            max = 150,
            name = "Vertical offset",
            desc = "Vertical offset of the arena cooldown icon group relative to the right edge of the arena frame",
        },
    },
};

options.args.RaidFrame = {
    order = 8,
    type = "group",
    name = "Raid Frames",
    get = function(info) return SweepyBoop.db.profile[info[#info]] end,
    set = function(info, val) SweepyBoop.db.profile[info[#info]] = val end,
    args = {
        arenaRaidFrameSortOrder = {
            order = 1,
            type = "select",
            values = {
                [addon.RaidFrameSortOrder.Disabled] = "Disabled",
                [addon.RaidFrameSortOrder.PlayerTop] = "Player on top",
                [addon.RaidFrameSortOrder.PlayerBottom] = "Player at bottom",
                [addon.RaidFrameSortOrder.PlayerMiddle] = "Player in the middle",
            },
            name = "Sort raid frames inside arena",
            desc = "Customize the sort order of raid frames inside arena",
            descStyle = "inline",
            style = "radio",
        },

        breaker1 = {
            order = 2,
            type = "header",
            name = "",
        },

        raidFrameAggroHighlightEnabled = {
            order = 3,
            width = "full",
            type = "toggle",
            name = "PvP Aggro Highlight",
            desc = "Show aggro highlight on raid frames when targeted by enemy players in arena",
        },
        description = {
            order = 4,
            width = "full",
            type = "description",
            name = addon.exclamation .. "Need to uncheck \"Display Aggro Highlight\" in Interface - Raid Frames",
        },
    },
};

options.args.Misc = {
    order = 9,
    type = "group",
    name = "Misc",
    get = function(info) return SweepyBoop.db.profile[info[#info]] end,
    set = function(info, val) SweepyBoop.db.profile[info[#info]] = val end,
    args = {
        header1 = {
            order = 1,
            type = "header",
            name = "Type /afk to surrender arena",
        },
        arenaSurrenderEnabled = {
            order = 2,
            width = "full",
            type = "toggle",
            name = "Enabled",
        },
        skipLeaveArenaConfirmation = {
            order = 3,
            width = "full",
            type = "toggle",
            name = "Leave directly if unable to surrender (skip confirmation dialog)",
            disabled = function()
                return ( not SweepyBoop.db.profile.arenaSurrenderEnabled );
            end,
        },
        description = {
            order = 4,
            width = "full",
            type = "description",
            name = addon.exclamation .. addon.exclamation .. addon.exclamation ..  "Leaving arena without entering combat results in deserter status",
        },

        header2 = {
            order = 5,
            type = "header",
            name = "",
        },
        showDampenPercentage = {
            order = 6,
            width = "full",
            type = "toggle",
            name = "Show dampen percentage on the arena widget",
        },
    },
};

local defaults = {
    profile = {
        classIconsEnabled = true,
        classIconStyle = addon.CLASSICONSTYLE.ROUND,
        petIconStyle = addon.PETICONSTYLE.CATS,
        classIconSelectionBorderStyle = addon.SELECTIONBORDERSTYLE.FIRE,
        classIconScale = 100,
        classIconOffset = 0,
        useHealerIcon = true,
        arenaCooldownOffsetX = 5,
        arenaCooldownOffsetY = 0,
        arenaEnemyOffensivesEnabled = true,
        arenaEnemyOffensiveIconSize = 32,
        arenaEnemyDefensivesEnabled = true,
        arenaEnemyDefensiveIconSize = 25,
        arenaNumbersEnabled = true,
        nameplateFilter = {
            enabled = true,
        },
        arenaRaidFrameSortOrder = addon.RaidFrameSortOrder.Disabled,
        raidFrameAggroHighlightEnabled = true,
        arenaSurrenderEnabled = true,
        skipLeaveArenaConfirmation = false,
        showDampenPercentage = true,
    }
};

function SweepyBoop:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("SweepyBoopDB", defaults, true);
    options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db);
    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, options);
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, addon.addonTitle);

    -- Register callback (https://www.wowace.com/projects/ace3/pages/ace-db-3-0-tutorial)
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig");

    -- Setup nameplate modules
    self:SetupNameplateModules();

    -- Setup arena enemy cooldown icons
    self:PremakeOffensiveIcons();
    self:PopulateOffensiveIcons();
    self:PremakeCooldownTrackingIcons();
    self:PopulateCooldownTrackingIcons();

    -- Setup raid frame aggro highlight
    self:SetupRaidFrameAggroHighlight();
end

function SweepyBoop:TestArena()
    if IsInInstance() then
        print("Test mode can only be used outside instances");
        return;
    end

    if Gladius then
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
        print("No Gladius / sArena detected");
        return;
    end

    self:TestArenaEnemyBurst();
    self:TestCooldownTracking();
end

function SweepyBoop:RefreshConfig()
    self:HideTestArenaEnemyBurst();
    self:HideTestCooldownTracking();
end

SLASH_SweepyBoop1 = "/sb"
SlashCmdList.SweepyBoop = function(msg)
    LibStub("AceConfigDialog-3.0"):Open(addonName);
end
