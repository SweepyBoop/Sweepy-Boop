local _, NS = ...;
NS.exclamation = "|TInterface\\OptionsFrame\\UI-OptionsFrame-NewFeatureIcon:0:0:0:-1|t";

SweepyBoop = LibStub("AceAddon-3.0"):NewAddon("SweepyBoop's Arena Helper", "AceConsole-3.0");
local AC = LibStub("AceConfig-3.0")
local ACD = LibStub("AceConfigDialog-3.0")

local options = {
    name = "SweepyBoop's Arena Helper",
    handler = SweepyBoop,
    type = "group",
    args = {
        classIcons = {
            order = 1,
            width = "full",
            type = "toggle",
            name = "Class and Pet Icons",
            desc = "Show class and pet icons on friendly players and pets",
            get = "GetClassIconsEnabled",
            set = "SetClassIconsEnabled",
        },
        arenaEnemyOffensives = {
            order = 3,
            width = "full",
            type = "toggle",
            name = "Arena Enemy Offensive Cooldowns",
            desc = "Show arena enemy offensive cooldowns next to the arena frames",
            get = "GetArenaEnemyOffensivesEnabled",
            set = "SetArenaEnemyOffensivesEnabled",
        },
        arenaEnemyDefensives = {
            order = 4,
            width = "full",
            type = "toggle",
            name = "Arena Enemy Defensive Cooldowns",
            desc = "Show arena enemy defensive cooldowns next to the arena frames",
            get = "GetArenaEnemyDefensivesEnabled",
            set = "SetArenaEnemyDefensivesEnabled",
        },
        arenaNumbers = {
            order = 2,
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
        break2 = {
			order = 6,
			type = "header",
			name = ""
		},
        reloadNotice = {
			order = 7,
			type = "description",
			fontSize = "medium",
			name = NS.exclamation .. "UI must be reloaded for most changes to take effect.",
		},
        break3 = {
			order = 8,
			type = "header",
			name = ""
		},
        reloadButton = {
			order = 9,
			type = "execute",
			name = "Reload UI",
			func = ReloadUI,
			width = 0.6,
		},
    },
};

local defaults = {
    profile = {
        classIconsEnabled = true,
        arenaEnemyOffensivesEnabled = true,
        arenaEnemyDefensivesEnabled = true,
        arenaNumbersEnabled = true,
        nameplateFilterEnabled = true,
    }
};

function SweepyBoop:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("SweepyBoopDB", defaults, true)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("SweepyBoop's Arena Helper", options);
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("SweepyBoop's Arena Helper", "SweepyBoop's Arena Helper");

    local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	AC:RegisterOptionsTable("SweepyBoop_Profiles", profiles)
	ACD:AddToBlizOptions("SweepyBoop_Profiles", "Profiles", "SweepyBoop's Arena Helper")

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