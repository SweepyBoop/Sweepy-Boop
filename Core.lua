local addonName, NS = ...;
NS.addonTitle = GetAddOnMetadata(addonName, "Title");
NS.exclamation = "|TInterface\\OptionsFrame\\UI-OptionsFrame-NewFeatureIcon:0:0:0:-1|t";

SweepyBoop = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0");
local AC = LibStub("AceConfig-3.0")
local ACD = LibStub("AceConfigDialog-3.0")

local options = {
    name = NS.addonTitle,
    handler = SweepyBoop,
    type = "group",
    args = {
        description = {
			order = 1,
			type ="description",
			fontSize = "large",
            image = "Interface\\Addons\\SweepyBoop\\ClassIcons\\flat\\PET0",
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
    order = 5,
    type = "group",
    name = "Nameplates",
    handler = SweepyBoop,
    args = {
        classIcons = {
            order = 1,
            width = "full",
            type = "toggle",
            name = "Class & Pet Icons",
            desc = "Show class/pet icons on friendly players/pets",
            get = "GetClassIconsEnabled",
            set = "SetClassIconsEnabled",
        },
        description = {
            order = 2,
            width = "full",
            type = "description",
            name = NS.exclamation ..  "Need to enable \"Friendly Player Nameplates\" & \"Minions\" in Interface - Nameplates",
        },
        break1 = {
			order = 3,
			type = "header",
			name = ""
		},
        arenaNumbers = {
            order = 4,
            width = "full",
            type = "toggle",
            name = "Show Arena Numbers",
            desc = "Show arena numbers on top of enemy nameplates",
            get = "GetArenaNumbersEnabled",
            set = "SetArenaNumbersEnabled",
        },
        nameplateFilter = {
            order = 5,
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
    order = 6,
    type = "group",
    name = "Arena Frames",
    handler = SweepyBoop,
    args = {
        arenaEnemyOffensives = {
            order = 1,
            width = 1.5,
            type = "toggle",
            name = "Arena Enemy Offensive Cooldowns",
            desc = "Show arena enemy offensive cooldowns next to the arena frames",
            get = "GetArenaEnemyOffensivesEnabled",
            set = "SetArenaEnemyOffensivesEnabled",
        },
        arenaEnemyOffensiveIconSizeSlider = {
            order = 2,
            type = "range",
            min = 16,
            max = 64,
            name = "Icon size",
            desc = "Size of arena offensive cooldown icons",
            get = "GetArenaEnemyOffensiveIconSize",
            set = "SetArenaEnemyOffensiveIconSize",
        },
        arenaEnemyDefensives = {
            order = 3,
            width = 1.5,
            type = "toggle",
            name = "Arena Enemy Defensive Cooldowns",
            desc = "Show arena enemy defensive cooldowns next to the arena frames",
            get = "GetArenaEnemyDefensivesEnabled",
            set = "SetArenaEnemyDefensivesEnabled",
        },
        arenaEnemyDefensiveIconSizeSlider = {
            order = 4,
            type = "range",
            min = 16,
            max = 64,
            name = "Icon size",
            desc = "Size of arena defensive cooldown icons",
            get = "GetArenaEnemyDefensiveIconSize",
            set = "SetArenaEnemyDefensiveIconSize",
        },
        arenaCooldownOffsetXSlider = {
            order = 5,
            type = "range",
            width = 1.5,
            min = 0,
            max = 100,
            name = "Horizontal offset",
            desc = "Horizontal offset of the arena cooldown icon group relative to the right edge of the arena frame",
            get = "GetArenaCooldownOffsetX",
            set = "SetArenaCooldownOffsetX",
        },
    },
};

options.args.RaidFrame = {
    order = 7,
    type = "group",
    name = "Raid Frames",
    handler = SweepyBoop,
    args = {
        raidFrameAggroHighlight = {
            order = 1,
            width = "full",
            type = "toggle",
            name = "PvP Aggro Highlight",
            desc = "Show aggro highlight on raid frames when targeted by enemy players in arena",
            get = "GetRaidFrameAggroHighlightEnabled",
            set = "SetRaidFrameAggroHighlightEnabled",
        },
        description = {
            order = 2,
            width = "full",
            type = "description",
            name = NS.exclamation .. "Need to uncheck \"Display Aggro Highlight\" in Interface - Raid Frames",
        },
    },
};

local defaults = {
    profile = {
        classIconsEnabled = true,
        arenaCooldownOffsetX = 5,
        arenaEnemyOffensivesEnabled = true,
        arenaEnemyOffensiveIconSize = 32,
        arenaEnemyDefensivesEnabled = true,
        arenaEnemyDefensiveIconSize = 22,
        arenaNumbersEnabled = true,
        nameplateFilterEnabled = true,
        raidFrameAggroHighlightEnabled = true,
    }
};

function SweepyBoop:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("SweepyBoopDB", defaults, true);
    options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db);
    AC:RegisterOptionsTable(addonName, options);
    self.optionsFrame = ACD:AddToBlizOptions(addonName, NS.addonTitle);

    -- Setup nameplate modules
    self:SetupNameplateModules();

    -- Setup arena enemy cooldown icons
    self:PremakeOffensiveIcons();
    self:PopulateOffensiveIcons();
    self:PremakeCooldownTrackingIcons();
    self:PopulateCooldownTrackingIcons();

    -- Setup raid frame aggro highlight
    self:SetupRaidFrameAggroHighlight();

    self:RegisterChatCommand("sb", "SlashCommand");
end

function SweepyBoop:SlashCommand(msg)
    if not msg or msg:trim() == "" then
        InterfaceOptionsFrame_OpenToCategory(self.optionsFrame);
    end
end

function SweepyBoop:GetClassIconsEnabled(info)
    return self.db.profile.classIconsEnabled;
end

function SweepyBoop:SetClassIconsEnabled(info, value)
    self.db.profile.classIconsEnabled = value;
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
