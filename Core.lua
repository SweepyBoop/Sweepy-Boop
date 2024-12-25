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
            image = "Interface\\Addons\\SweepyBoop\\Art\\Logo",
            imageWidth = 36,
            imageHeight = 36,
            name = "A lightweight addon to improve your arena & battleground experience :)"
        },
    },
};

options.args.nameplatesFriendly = {
    order = 2,
    type = "group",
    name = "Friendly class icons",
    get = function(info) return SweepyBoop.db.profile.nameplatesFriendly[info[#info]] end,
    set = function(info, val)
        SweepyBoop.db.profile.nameplatesFriendly[info[#info]] = val;
        -- Can we force all nameplates to call CompactUnitFrame_UpdateName
        SweepyBoop.db.profile.nameplatesFriendly.lastModified = GetTime();
    end,
    args = {
        classIconsEnabled = {
            order = 1,
            width = "full",
            type = "toggle",
            name = format("|T%s:20|t %s", "interface\\addons\\SweepyBoop\\Art\\Druid", "Enabled"),
            desc = "Show class/pet icons on friendly players/pets",
        },
        description = {
            order = 2,
            width = "full",
            type = "description",
            name = addon.exclamation ..  "Need to enable \"Friendly Player Nameplates\" & \"Minions\" in Interface - Nameplates\n\n"
                   .. addon.exclamation ..  "If icons don't refresh right after changing options, change current target to force an update",
        },
        hideOutsidePvP = {
            order = 3,
            width = "full",
            type = "toggle",
            name = format("|T%s:20|t %s", "interface\\cursor\\pvp", "Hide class icons outside arenas & battlegrounds"),
            disabled = function()
                return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled );
            end
        },
        breaker = {
            order = 4,
            type = "header",
            name = "",
        },
        useHealerIcon = {
            order = 5,
            width = "full",
            type = "toggle",
            name = format("|T%s:20|t %s", "interface\\addons\\SweepyBoop\\Art\\healer", "Use dedicated healer icon"),
            desc = "Use a dedicated icon for party healers in arenas and battlegrounds",
            disabled = function()
                return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled );
            end
        },
        showHealerOnly = {
            order = 6,
            width = "full",
            type = "toggle",
            name = format("|T%s:20|t %s", "interface\\addons\\SweepyBoop\\Art\\healer", "Show healers only"),
            disabled = function ()
                return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled );
            end
        },
        useFlagCarrierIcon = {
            order = 7,
            width = "full",
            type = "toggle",
            name = format("|T%s:20|t|T%s:20|t %s", addon.flagCarrierHordeLogo, addon.flagCarrierAllianceLogo, "Use flag carrier icons in battlegrounds"),
            desc = "Use dedicated icons for friendly flag carriers\nThis overwrites the healer icon",
            disabled = function()
                return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled );
            end
        },
        classIconScale = {
            order = 8,
            type = "range",
            min = 50,
            max = 200,
            name = "Icon scale (%)",
            disabled = function()
                return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled );
            end
        },
        classIconOffset = {
            order = 9,
            type = "range",
            min = 0,
            max = 150,
            name = "Icon offset",
            disabled = function()
                return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled );
            end
        },
    }
};

options.args.nameplatesEnemy = {
    order = 3,
    type = "group",
    childGroups = "tab",
    name = "Enemy nameplates",
    get = function(info) return SweepyBoop.db.profile.nameplatesEnemy[info[#info]] end,
    set = function(info, val) 
        SweepyBoop.db.profile.nameplatesEnemy[info[#info]] = val;
        -- Can we force all nameplates to call CompactUnitFrame_UpdateName
        SweepyBoop.db.profile.nameplatesEnemy.lastModified = GetTime();
    end,
    args = {
        tip = {
            order = 1,
            width = "full",
            type = "description",
            name = addon.exclamation ..  "If nameplates don't refresh right after changing options, change current target to force an update",
        },
        breaker1 = {
            order = 2,
            type = "header",
            name = "",
        },

        arenaNumbersEnabled = {
            order = 3,
            width = "full",
            type = "toggle",
            name = format("|T%s:20|t|T%s:20|t|T%s:20|t %s", "interface/icons/inv_misc_number_1", "interface/icons/inv_misc_number_2", "interface/icons/inv_misc_number_3", "Arena enemy player nameplate numbers"),
            desc = "Places arena numbers over enemy players' nameplates, e.g., 1 for arena1, and so on",
        },

        breaker2 = {
            order = 4,
            type = "header",
            name = "Arena enemy spec icons",
        },
        arenaSpecIconHealer = {
            order = 5,
            width = "full",
            type = "toggle",
            name = format("|T%s:20|t %s", addon.specIconHealerLogo, "Show spec icon for healers"),
            desc = "Show a spec icon on top of the nameplate for enemy healers inside arenas",
        },
        arenaSpecIconHealerIcon = {
            order = 6,
            width = "full",
            type = "toggle",
            name = format("|T%s:20|t %s", "Interface\\Addons\\SweepyBoop\\art\\healer", "Show healer icon instead of spec icon for healers"),
            disabled = function ()
                return ( not SweepyBoop.db.profile.nameplatesEnemy.arenaSpecIconHealer );
            end
        },
        arenaSpecIconOthers = {
            order = 7,
            width = "full",
            type = "toggle",
            name = format("|T%s:20|t %s", addon.specIconOthersLogo, "Show spec icon for non-healers"),
            desc = "Show a spec icon on top of the nameplate for enemy players that are not healers inside arenas",
        },
        arenaSpecIconScale = {
            order = 8,
            min = 50,
            max = 300,
            type = "range",
            name = "Spec icon scale (%)",
        },
        arenaSpecIconOffset = {
            order = 9,
            min = -150,
            max = 150,
            type = "range",
            name = "Spec icon offset",
        },

        breaker3 = {
            order = 10,
            type = "header",
            name = "Nameplate Filters & Highlights",
        },

        filterEnabled = {
            order = 11,
            type = "toggle",
            width = "full",
            name = format("|T%s:20|t %s", "interface\\cursor\\pvp", "Enabled"),
            desc = "Filter which hostile non-player units to show nameplates in arenas and battlegrounds",
        },
        filterSettings = {
            order = 12,
            type = "group",
            name = "General",
            disabled = function()
                return ( not SweepyBoop.db.profile.nameplatesEnemy.filterEnabled );
            end,
            args = {
                highlightScale = {
                    order = 1,
                    type = "range",
                    name = "Highlight icon scale (%)",
                    min = 50,
                    max = 300,
                },
                hideHunterSecondaryPet = {
                    order = 2,
                    type = "toggle",
                    width = "full",
                    name = format("|T%s:20|t %s", C_Spell.GetSpellTexture(267116), "Hide beast mastery hunter secondary pets in arena"),
                    desc = "Hide the extra pet from talents\nThis feature is not available in battlegrounds due to WoW API limitations",
                },
            },
        },
        filterList = {
            order = 13,
            type = "group",
            name = "Filter whitelist",
            get = function(info) return SweepyBoop.db.profile.nameplatesEnemy.filterList[info[#info]] end,
            set = function(info, val) SweepyBoop.db.profile.nameplatesEnemy.filterList[info[#info]] = val end,
            args = {},
            disabled = function()
                return ( not SweepyBoop.db.profile.nameplatesEnemy.filterEnabled );
            end
        }
    },
};

addon.AppendNpcOptionsToGroup(options.args.nameplatesEnemy.args.filterList);

options.args.arenaFrames = {
    order = 4,
    type = "group",
    childGroups = "tab",
    name = "Arena Frames",
    handler = SweepyBoop, -- for running SweepyBoop:TestArena()
    get = function(info) return SweepyBoop.db.profile.arenaFrames[info[#info]] end,
    set = function(info, val) SweepyBoop.db.profile.arenaFrames[info[#info]] = val end,
    args = {
        testmode = {
            order = 1,
            type = "execute",
            name = "Test",
            func = "TestArena",
            width = "half",
        },
        hidetest = {
            order = 2,
            type = "execute",
            name = "Hide",
            func = "HideTestArena",
            width = "half",
        },
        -- Reload UI shouldn't be needed anymore, but keep them here in case
        -- reloadButton = {
        --     order = 3,
        --     type = "execute",
        --     name = "Reload UI",
        --     func = ReloadUI,
        --     desc = addon.exclamation .. "Some changes might require a UI reload to take full effect",
        -- },
        -- description1 = {
        --     order = 4,
        --     width = "full",
        --     type = "description",
        --     name = addon.exclamation .. "Reload UI might be required if Gladius / sArena settings are changed significantly",
        -- },
        breaker1 = {
            order = 5,
            type = "header",
            name = "",
        },

        arenaEnemyOffensivesEnabled = {
            order = 6,
            width = 1.75,
            type = "toggle",
            name = format("|T%s:20|t %s", "interface/icons/spell_fire_sealoffire", "Arena Enemy Offensive Cooldowns"),
            desc = "Show arena enemy offensive cooldowns next to the arena frames",
        },
        arenaEnemyOffensiveIconSize = {
            order = 7,
            type = "range",
            min = 16,
            max = 64,
            name = "Icon size",
            desc = "Size of arena offensive cooldown icons",
        },
        newline1 = {
            order = 8,
            type = "description",
            width = "full",
            name = "",
        },
        arenaEnemyDefensivesEnabled = {
            order = 9,
            width = 1.75,
            type = "toggle",
            name = format("|T%s:20|t %s", "interface/icons/spell_holy_divineshield", "Arena Enemy Defensive Cooldowns"),
            desc = "Show arena enemy defensive cooldowns next to the arena frames",
        },
        arenaEnemyDefensiveIconSize = {
            order = 10,
            type = "range",
            min = 16,
            max = 64,
            name = "Icon size",
            desc = "Size of arena defensive cooldown icons",
        },

        newline2 = {
            order = 11,
            type = "description",
            width = "full",
            name = "",
        },
        arenaCooldownOffsetX = {
            order = 12,
            type = "range",
            min = -750,
            max = 750,
            name = "Horizontal offset",
            desc = "Horizontal offset of the arena cooldown icon group relative to the right edge of the arena frame",
        },
        arenaCooldownOffsetY = {
            order = 13,
            type = "range",
            min = -150,
            max = 150,
            name = "Vertical offset",
            desc = "Vertical offset of the arena cooldown icon group relative to the right edge of the arena frame",
        },

        spellList = {
            order = 14,
            type = "group",
            name = "Spells",
            desc = "Select which abilities to track cooldown inside arenas",
            get = function(info) return SweepyBoop.db.profile.arenaFrames.spellList[info[#info]] end,
            set = function(info, val) SweepyBoop.db.profile.arenaFrames.spellList[info[#info]] = val end,
            args = {
                checkAll = {
                    order = 1,
                    type = "execute",
                    name = "Check All",
                    func = function ()
                        SweepyBoop:CheckAllSpells(true);
                    end
                },
                uncheckAll = {
                    order = 2,
                    type = "execute",
                    name = "Uncheck All",
                    func = function ()
                        SweepyBoop:CheckAllSpells(false);
                    end
                },
            },
        }
    },
};

local indexInClassGroup = {};
local groupIndex = 3;
-- Ensure one group for each class, in order
for _, classID in ipairs(addon.classOrder) do
    local classInfo = C_CreatureInfo.GetClassInfo(classID);
    options.args.arenaFrames.args.spellList.args[classInfo.classFile] = {
        order = groupIndex,
        type = "group",
        icon = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes",
        iconCoords = CLASS_ICON_TCOORDS[classInfo.classFile],
        name = classInfo.className,
        args = {},
    };

    indexInClassGroup[classInfo.classFile] = 1;
    groupIndex = groupIndex + 1;
end
local function AppendSpellOptions(group, spellList, category)
    for spellID, spellInfo in pairs(spellList) do
        if ( not category ) or ( spellInfo.category == category ) then
            local classFile = spellInfo.class;
            local classGroup = group.args[classFile];
            local icon, name = C_Spell.GetSpellTexture(spellID), C_Spell.GetSpellName(spellID);
            -- https://warcraft.wiki.gg/wiki/SpellMixin
            local description;
            local spell = Spell:CreateFromSpellID(spellID);
            spell:ContinueOnSpellLoad(function()
                description = spell:GetSpellDescription();
            end)
            classGroup.args[tostring(spellID)] = {
                order = indexInClassGroup[classFile],
                type = "toggle",
                width = "full", -- otherwise the icon might look strange vertically
                name = format("|T%s:20|t %s", icon, name),
                desc = description,
            };
            
            indexInClassGroup[classFile] = indexInClassGroup[classFile] + 1;
        end
    end
end

AppendSpellOptions(options.args.arenaFrames.args.spellList, addon.burstSpells);
AppendSpellOptions(options.args.arenaFrames.args.spellList, addon.utilitySpells, addon.SPELLCATEGORY.DEFENSIVE);

options.args.raidFrames = {
    order = 5,
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

options.args.misc = {
    order = 6,
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
            name = addon.exclamation .. "Leaving arena without entering combat might result in deserter status",
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
        nameplatesFriendly = {
            classIconsEnabled = true,
            hideOutsidePvP = false,
            classIconScale = 100,
            classIconOffset = 0,
            useHealerIcon = true,
            showHealerOnly = false,
            useFlagCarrierIcon = true,
        },
        nameplatesEnemy = {
            arenaNumbersEnabled = true,
            arenaSpecIconHealer = true,
            arenaSpecIconHealerIcon = true,
            arenaSpecIconOthers = false,
            arenaSpecIconScale = 100,
            arenaSpecIconOffset = 0,
            filterEnabled = true,
            highlightScale = 100,
            hideHunterSecondaryPet = true,
            filterList = {},
        },
        arenaFrames = {
            arenaCooldownOffsetX = 0,
            arenaCooldownOffsetY = 0,
            arenaEnemyOffensivesEnabled = true,
            arenaEnemyOffensiveIconSize = 32,
            arenaEnemyDefensivesEnabled = true,
            arenaEnemyDefensiveIconSize = 25,
            spellList = {},
        },
        arenaRaidFrameSortOrder = addon.RaidFrameSortOrder.Disabled,
        raidFrameAggroHighlightEnabled = true,
        arenaSurrenderEnabled = true,
        skipLeaveArenaConfirmation = false,
        showDampenPercentage = true,
    }
};

if addon.internal then -- Set default for internal version
    defaults.profile.arenaRaidFrameSortOrder = addon.RaidFrameSortOrder.PlayerMiddle;
    defaults.profile.arenaFrames.arenaCooldownOffsetX = 5;
end

addon.FillDefaultToNpcOptions(defaults.profile.nameplatesEnemy.filterList);

local function SetupAllSpells(profile, spellList, value)
    for spellID, spellEntry in pairs(spellList) do
        profile[tostring(spellID)] = value;
    end
end

SetupAllSpells(defaults.profile.arenaFrames.spellList, addon.burstSpells, true);
SetupAllSpells(defaults.profile.arenaFrames.spellList, addon.utilitySpells, true);

function SweepyBoop:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("SweepyBoopDB", defaults, true);
    options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db);
    local appName = LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, options);
    LibStub("AceConfigDialog-3.0"):SetDefaultSize(addonName, 750, 600);
    self.optionsFrame, self.categoryID = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, addon.addonTitle); -- Can we open to the friendly class icons page instead of the first empty page?
    

    -- Register callback (https://www.wowace.com/projects/ace3/pages/ace-db-3-0-tutorial)
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig");

    -- Setup nameplate modules
    self:SetupNameplateModules();

    -- Setup arena enemy cooldown icons
    self:SetupOffensiveIcons();
    self:SetupCooldownTrackingIcons();

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
        -- Use Blizzard arena frames
        if ( not CompactArenaFrame:IsShown() ) then
            CompactArenaFrame:Show();
            for i = 1, addon.MAX_ARENA_SIZE do
                _G["CompactArenaFrameMember" .. i]:Show();
            end
        end
    end

    self:TestArenaEnemyBurst();
    self:TestCooldownTracking();
end

function SweepyBoop:HideTestArena()
    self:HideTestArenaEnemyBurst();
    self:HideTestCooldownTracking();
end

function SweepyBoop:RefreshConfig()
    self:HideTestArenaEnemyBurst();
    self:HideTestCooldownTracking();

    local time = GetTime();
    self.db.profile.nameplatesFriendly.lastModified = time;
    self.db.profile.nameplatesEnemy.lastModified = time;
end

function SweepyBoop:CheckAllSpells(value)
    SetupAllSpells(SweepyBoop.db.profile.arenaFrames.spellList, addon.burstSpells, value);
    SetupAllSpells(SweepyBoop.db.profile.arenaFrames.spellList, addon.utilitySpells, value);
end

SLASH_SweepyBoop1 = "/sb"
SlashCmdList.SweepyBoop = function(msg)
    -- This opens the in-game options panel that is not moveable or resizable
    -- if Settings and Settings.OpenToCategory then
    --     Settings.OpenToCategory(SweepyBoop.categoryID);
    -- end
    LibStub("AceConfigDialog-3.0"):Open(addonName);
end
