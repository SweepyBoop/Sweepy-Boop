local addonName, NS = ...;
NS.addonTitle = C_AddOns.GetAddOnMetadata(addonName, "Title");
NS.exclamation = "|TInterface\\OptionsFrame\\UI-OptionsFrame-NewFeatureIcon:0:0:0:-1|t";

SweepyBoop = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0");

local options = {
    name = NS.addonTitle,
    handler = SweepyBoop,
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
			name = NS.exclamation .. "UI must be reloaded for most changes to take effect.",
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
    handler = SweepyBoop,
    args = {
        header = {
            order = 1,
            type = "header",
            name = "Class & Pet Icons",
        },
        classIcons = {
            order = 2,
            width = "full",
            type = "toggle",
            name = "Enable",
            desc = "Show class/pet icons on friendly players/pets",
            get = "GetClassIconsEnabled",
            set = "SetClassIconsEnabled",
        },
        description = {
            order = 3,
            width = "full",
            type = "description",
            name = NS.exclamation ..  "Need to enable \"Friendly Player Nameplates\" & \"Minions\" in Interface - Nameplates",
        },
        selectClass = {
            order = 4,
            type = "select",
            name = "Class Icon Style",
            style = "dropdown",
            get = "GetClassIconStyle",
            set = "SetClassIconStyle",
            values = {
                [NS.CLASSICONSTYLE.ROUND] = "Round",
                [NS.CLASSICONSTYLE.FLAT] = "Flat",
            },
            disabled = function()
                return ( not SweepyBoop:GetClassIconsEnabled() );
            end
        },
        selectPet = {
            order = 5,
            type = "select",
            name = "Pet Icon Style",
            style = "dropdown",
            get = "GetPetIconStyle",
            set = "SetPetIconStyle",
            values = {
                [NS.PETICONSTYLE.CATS] = "Cat memes",
                [NS.PETICONSTYLE.MENDPET] = "Mend pet icon",
            },
            disabled = function()
                return ( not SweepyBoop:GetClassIconsEnabled() );
            end
        },
        borderStyle = {
            order = 6,
            type = "select",
            name = "Selection highlight border style",
            style = "dropdown",
            get = "GetSelectionBorderStyle",
            set = "SetSelectionBorderStyle",
            values = {
                [NS.SELECTIONBORDERSTYLE.FIRE] = "Fire",
                [NS.SELECTIONBORDERSTYLE.ARCANE] = "Arcane",
                [NS.SELECTIONBORDERSTYLE.AIR] = "Air",
                [NS.SELECTIONBORDERSTYLE.MECHANICAL] = "Mechanical",
            },
            disabled = function()
                return ( not SweepyBoop:GetClassIconsEnabled() );
            end
        },
        healerIcon = {
            order = 6,
            width = "full",
            type = "toggle",
            name = "Use dedicated healer icon",
            desc = "Use a dedicated icon for party healers",
            get = "GetHealerIconEnabled",
            set = "SetHealerIconEnabled",
            disabled = function()
                return ( not SweepyBoop:GetClassIconsEnabled() );
            end
        },
        iconScale = {
            order = 7,
            --width = "full",
            type = "range",
            min = 50,
            max = 200,
            name = "Icon scale (%)",
            get = "GetClassIconScale",
            set = "SetClassIconScale",
            disabled = function()
                return ( not SweepyBoop:GetClassIconsEnabled() );
            end
        },
        iconOffset = {
            order = 8,
            type = "range",
            min = 0,
            max = 150,
            name = "Icon offset",
            get = "GetClassIconOffset",
            set = "SetClassIconOffset",
            disabled = function()
                return ( not SweepyBoop:GetClassIconsEnabled() );
            end
        },
        break1 = {
			order = 9,
			type = "header",
			name = ""
		},
        arenaNumbers = {
            order = 10,
            width = "full",
            type = "toggle",
            name = "Show Arena Numbers",
            desc = "Show arena numbers on top of enemy nameplates",
            get = "GetArenaNumbersEnabled",
            set = "SetArenaNumbersEnabled",
        },
        nameplateFilter = {
            order = 11,
            width = "full",
            type = "toggle",
            name = "Only Show Important Nameplates in Arena",
            desc = "Only show nameplates of enemy players and important non-player units while inside arena",
            get = "GetNameplateFilterEnabled",
            set = "SetNameplateFilterEnabled",
        },
    },
};

options.args.ArenaFrames = {
    order = 7,
    type = "group",
    name = "Arena Frames",
    handler = SweepyBoop,
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
            name = NS.exclamation .. "UI Reload is required if Gladius / sArena settings are changed",
        },
        breaker1 = {
            order = 3,
            type = "header",
            name = "",
        },

        arenaEnemyOffensives = {
            order = 4,
            width = 1.5,
            type = "toggle",
            name = "Arena Enemy Offensive Cooldowns",
            desc = "Show arena enemy offensive cooldowns next to the arena frames",
            get = "GetArenaEnemyOffensivesEnabled",
            set = "SetArenaEnemyOffensivesEnabled",
        },
        arenaEnemyOffensiveIconSizeSlider = {
            order = 5,
            type = "range",
            min = 16,
            max = 64,
            name = "Icon size",
            desc = "Size of arena offensive cooldown icons",
            get = "GetArenaEnemyOffensiveIconSize",
            set = "SetArenaEnemyOffensiveIconSize",
        },
        arenaEnemyDefensives = {
            order = 6,
            width = 1.5,
            type = "toggle",
            name = "Arena Enemy Defensive Cooldowns",
            desc = "Show arena enemy defensive cooldowns next to the arena frames",
            get = "GetArenaEnemyDefensivesEnabled",
            set = "SetArenaEnemyDefensivesEnabled",
        },
        arenaEnemyDefensiveIconSizeSlider = {
            order = 7,
            type = "range",
            min = 16,
            max = 64,
            name = "Icon size",
            desc = "Size of arena defensive cooldown icons",
            get = "GetArenaEnemyDefensiveIconSize",
            set = "SetArenaEnemyDefensiveIconSize",
        },
        arenaCooldownOffsetXSlider = {
            order = 8,
            type = "range",
            min = -750,
            max = 750,
            name = "Horizontal offset",
            desc = "Horizontal offset of the arena cooldown icon group relative to the right edge of the arena frame",
            get = "GetArenaCooldownOffsetX",
            set = "SetArenaCooldownOffsetX",
        },
        arenaCooldownOffsetYSlider = {
            order = 9,
            type = "range",
            min = -150,
            max = 150,
            name = "Vertical offset",
            desc = "Vertical offset of the arena cooldown icon group relative to the right edge of the arena frame",
            get = "GetArenaCooldownOffsetY",
            set = "SetArenaCooldownOffsetY",
        },
    },
};

options.args.RaidFrame = {
    order = 8,
    type = "group",
    name = "Raid Frames",
    handler = SweepyBoop,
    args = {
        sortGroup = {
            order = 1,
            type = "select",
            values = {
                [NS.RaidFrameSortOrder.Disabled] = "Disabled",
                [NS.RaidFrameSortOrder.PlayerTop] = "Player on top",
                [NS.RaidFrameSortOrder.PlayerBottom] = "Player at bottom",
                [NS.RaidFrameSortOrder.PlayerMiddle] = "Player in the middle",
            },
            name = "Sort raid frames inside arena",
            desc = "Customize the sort order of raid frames inside arena",
            descStyle = "inline",
            get = "GetRaidFrameSortOrder",
            set = "SetRaidFrameSortOrder",
            style = "radio",
        },

        breaker1 = {
            order = 2,
            type = "header",
            name = "",
        },

        raidFrameAggroHighlight = {
            order = 3,
            width = "full",
            type = "toggle",
            name = "PvP Aggro Highlight",
            desc = "Show aggro highlight on raid frames when targeted by enemy players in arena",
            get = "GetRaidFrameAggroHighlightEnabled",
            set = "SetRaidFrameAggroHighlightEnabled",
        },
        description = {
            order = 4,
            width = "full",
            type = "description",
            name = NS.exclamation .. "Need to uncheck \"Display Aggro Highlight\" in Interface - Raid Frames",
        },
    },
};

options.args.Misc = {
    order = 9,
    type = "group",
    name = "Misc",
    handler = SweepyBoop,
    args = {
        header = {
            order = 1,
            type = "header",
            name = "Type /afk to surrender arena",
        },
        surrender = {
            order = 2,
            width = "full",
            type = "toggle",
            name = "Enable",
            get = "GetArenaSurrenderEnabled",
            set = "SetArenaSurrenderEnabled",
        },
        skipConfirm = {
            order = 3,
            width = "full",
            type = "toggle",
            name = "Leave directly if unable to surrender (skip confirmation dialog)",
            get = "GetSkipLeaveArenaConfirmationEnabled",
            set = "SetSkipLeaveArenaConfirmationEnabled",
            disabled = function()
                return ( not SweepyBoop:GetArenaSurrenderEnabled() );
            end,
        },
        description = {
            order = 4,
            width = "full",
            type = "description",
            name = NS.exclamation .. NS.exclamation .. NS.exclamation ..  "Leaving arena without entering combat results in deserter status",
        },
    },
};

local defaults = {
    profile = {
        classIconsEnabled = true,
        classIconStyle = NS.CLASSICONSTYLE.ROUND,
        petIconStyle = NS.PETICONSTYLE.CATS,
        classIconSelectionBorderStyle = NS.SELECTIONBORDERSTYLE.FIRE,
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
        nameplateFilterEnabled = true,
        arenaRaidFrameSortOrder = NS.RaidFrameSortOrder.Disabled,
        raidFrameAggroHighlightEnabled = true,
        arenaSurrenderEnabled = true,
        skipLeaveArenaConfirmation = false,
    }
};

function SweepyBoop:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("SweepyBoopDB", defaults, true);
    options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db);
    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, options);
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, NS.addonTitle);

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

function SweepyBoop:GetClassIconsEnabled(info)
    return self.db.profile.classIconsEnabled;
end

function SweepyBoop:SetClassIconsEnabled(info, value)
    self.db.profile.classIconsEnabled = value;
end

function SweepyBoop:GetClassIconStyle(info)
    return self.db.profile.classIconStyle;
end

function SweepyBoop:SetClassIconStyle(info, value)
    self.db.profile.classIconStyle = value;
end

function SweepyBoop:GetPetIconStyle(info)
    return self.db.profile.petIconStyle;
end

function SweepyBoop:SetPetIconStyle(info, value)
    self.db.profile.petIconStyle = value;
end

function SweepyBoop:GetSelectionBorderStyle(info)
    return self.db.profile.classIconSelectionBorderStyle;
end

function SweepyBoop:SetSelectionBorderStyle(info, value)
    self.db.profile.classIconSelectionBorderStyle = value;
end

function SweepyBoop:GetHealerIconEnabled(info)
    return self.db.profile.useHealerIcon;
end

function SweepyBoop:SetHealerIconEnabled(info, value)
    self.db.profile.useHealerIcon = value;
end

function SweepyBoop:GetClassIconScale(info)
    return self.db.profile.classIconScale;
end

function SweepyBoop:SetClassIconScale(info, value)
    self.db.profile.classIconScale = value;
end

function SweepyBoop:GetClassIconOffset(info)
    return self.db.profile.classIconOffset;
end

function SweepyBoop:SetClassIconOffset(info, value)
    self.db.profile.classIconOffset = value;
end

function SweepyBoop:GetArenaEnemyOffensivesEnabled(info)
    return self.db.profile.arenaEnemyOffensivesEnabled;
end

function SweepyBoop:SetArenaEnemyOffensivesEnabled(info, value)
    self.db.profile.arenaEnemyOffensivesEnabled = value;
end

function SweepyBoop:GetArenaEnemyDefensivesEnabled(info)
    return self.db.profile.arenaEnemyDefensivesEnabled;
end

function SweepyBoop:SetArenaEnemyDefensivesEnabled(info, value)
    self.db.profile.arenaEnemyDefensivesEnabled = value;
end

function SweepyBoop:GetArenaNumbersEnabled(info)
    return self.db.profile.arenaNumbersEnabled;
end

function SweepyBoop:SetArenaNumbersEnabled(info, value)
    self.db.profile.arenaNumbersEnabled = value;
end

function SweepyBoop:GetNameplateFilterEnabled(info)
    return self.db.profile.nameplateFilterEnabled;
end

function SweepyBoop:SetNameplateFilterEnabled(info, value)
    self.db.profile.nameplateFilterEnabled = value;
end

function SweepyBoop:GetRaidFrameSortOrder(info)
    return self.db.profile.arenaRaidFrameSortOrder;
end

function SweepyBoop:SetRaidFrameSortOrder(info, value)
    self.db.profile.arenaRaidFrameSortOrder = value;
end

function SweepyBoop:GetRaidFrameAggroHighlightEnabled(info)
    return self.db.profile.raidFrameAggroHighlightEnabled;
end

function SweepyBoop:SetRaidFrameAggroHighlightEnabled(info, value)
    self.db.profile.raidFrameAggroHighlightEnabled = value;
end

function SweepyBoop:GetArenaCooldownOffsetX(info)
    return self.db.profile.arenaCooldownOffsetX;
end

function SweepyBoop:SetArenaCooldownOffsetX(info, value)
    self.db.profile.arenaCooldownOffsetX = value;
end

function SweepyBoop:GetArenaCooldownOffsetY(info)
    return self.db.profile.arenaCooldownOffsetY;
end

function SweepyBoop:SetArenaCooldownOffsetY(info, value)
    self.db.profile.arenaCooldownOffsetY = value;
end

function SweepyBoop:GetArenaEnemyOffensiveIconSize(info)
    return self.db.profile.arenaEnemyOffensiveIconSize;
end

function SweepyBoop:SetArenaEnemyOffensiveIconSize(info, value)
    self.db.profile.arenaEnemyOffensiveIconSize = value;
end

function SweepyBoop:GetArenaEnemyDefensiveIconSize(info)
    return self.db.profile.arenaEnemyDefensiveIconSize;
end

function SweepyBoop:SetArenaEnemyDefensiveIconSize(info, value)
    self.db.profile.arenaEnemyDefensiveIconSize = value;
end

function SweepyBoop:GetArenaSurrenderEnabled(info)
    return self.db.profile.arenaSurrenderEnabled;
end

function SweepyBoop:SetArenaSurrenderEnabled(info, value)
    self.db.profile.arenaSurrenderEnabled = value;
end

function SweepyBoop:GetSkipLeaveArenaConfirmationEnabled(info)
    return self.db.profile.skipLeaveArenaConfirmation;
end

function SweepyBoop:SetSkipLeaveArenaConfirmationEnabled(info, value)
    self.db.profile.skipLeaveArenaConfirmation = value;
end

function SweepyBoop:RefreshConfig()
    self:HideTestArenaEnemyBurst();
    self:HideTestCooldownTracking();
end

SLASH_SweepyBoop1 = "/sb"
SlashCmdList.SweepyBoop = function(msg)
    LibStub("AceConfigDialog-3.0"):Open(addonName)
end
