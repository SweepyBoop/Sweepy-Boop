local addonName, addon = ...;
addon.addonTitle = C_AddOns.GetAddOnMetadata(addonName, "Title");

SweepyBoop = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0");

local pvpCursor = "interface/cursor/pvp";

local options = {
    name = addon.addonTitle,
    type = "group",
    args = {
        description = {
            order = 1,
            type ="description",
            fontSize = "large",
            image = addon.INTERFACE_SWEEPY .. "Art/Logo",
            imageWidth = 36,
            imageHeight = 36,
            name = "A lightweight addon to enhance your arena & battleground experience :)"
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
            name = addon.FORMAT_TEXTURE(addon.INTERFACE_SWEEPY .. "Art/Druid") .. " Enabled",
            desc = "Show class/pet icons on friendly players/pets",
        },
        description = {
            order = 2,
            width = "full",
            type = "description",
            name = addon.EXCLAMATION ..  " Enable \"Friendly Player Nameplates\" & \"Minions\" in Interface - Nameplates\n\n"
                   .. addon.EXCLAMATION ..  " If icons don't refresh right after changing options, change current target to force an update",
        },
        classIconStyle = {
            order = 3,
            type = "select",
            values = {
                [addon.CLASS_ICON_STYLE.ICON] = addon.FORMAT_TEXTURE(addon.INTERFACE_SWEEPY .. "Art/Druid") .. " WoW class icons",
                [addon.CLASS_ICON_STYLE.ARROW] = addon.FORMAT_TEXTURE(addon.INTERFACE_SWEEPY .. "Art/ClassArrow") .. " Class color arrows",
            },
            name = "Icon style",
            hidden = function()
                return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled );
            end
        },
        newline = {
            order = 4,
            type = "description",
            name = "",
            hidden = function()
                return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled );
            end
        },
        hideOutsidePvP = {
            order = 5,
            width = "full",
            type = "toggle",
            name = addon.FORMAT_TEXTURE(pvpCursor) .. " Hide class icons outside arenas & battlegrounds",
            hidden = function()
                return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled );
            end
        },
        breaker = {
            order = 6,
            type = "header",
            name = "",
            hidden = function()
                return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled );
            end
        },
        useHealerIcon = {
            order = 7,
            width = "full",
            type = "toggle",
            name = addon.HELAER_LOGO .. " Show healer icon instead of class icon for healers",
            hidden = function()
                return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled );
            end
        },
        showHealerOnly = {
            order = 8,
            width = "full",
            type = "toggle",
            name = addon.HELAER_LOGO .. " Show healers only",
            desc = "Hide class icons of non-healer players\nFlag carrier icons will still show if the option is enabled",
            hidden = function ()
                local config = SweepyBoop.db.profile.nameplatesFriendly;
                local dependencyEnabled = config.classIconsEnabled and config.useHealerIcon;
                return ( not dependencyEnabled );
            end
        },
        useFlagCarrierIcon = {
            order = 9,
            width = "full",
            type = "toggle",
            name = addon.FORMAT_TEXTURE(addon.FLAG_CARRIER_ALLIANCE_LOGO) .. " Show flag carrier icons in battlegrounds",
            desc = "Use special icons for friendly flag carriers\nThis overwrites the healer icon",
            hidden = function()
                return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled );
            end
        },
        classIconScale = {
            order = 10,
            type = "range",
            min = 50,
            max = 200,
            step = 1,
            name = "Icon scale (%)",
            hidden = function()
                return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled );
            end
        },
        classIconOffset = {
            order = 11,
            type = "range",
            min = 0,
            max = 150,
            step = 1,
            name = "Icon offset",
            hidden = function()
                return ( not SweepyBoop.db.profile.nameplatesFriendly.classIconsEnabled );
            end
        },
    }
};

local beastMasteryHunterIcon = C_Spell.GetSpellTexture(267116);
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
            name = addon.EXCLAMATION ..  " If nameplates don't refresh right after changing options, change current target to force an update",
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
            name = addon.FORMAT_TEXTURE(addon.ICON_PATH("inv_misc_number_1")) .. " Arena enemy player nameplate numbers",
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
            name = addon.FORMAT_TEXTURE(addon.SPEC_ICON_HEALER_LOGO) ..  " Show spec icon for healers",
            desc = "Show spec icons on top of the nameplates of enemy healers inside arenas",
        },
        arenaSpecIconHealerIcon = {
            order = 6,
            width = "full",
            type = "toggle",
            name = addon.HELAER_LOGO .. " Show healer icon instead of spec icon for healers",
            hidden = function ()
                return ( not SweepyBoop.db.profile.nameplatesEnemy.arenaSpecIconHealer );
            end
        },
        arenaSpecIconOthers = {
            order = 7,
            width = "full",
            type = "toggle",
            name = addon.FORMAT_TEXTURE(addon.SPEC_ICON_OTHERS_LOGO) .. " Show spec icon for non-healers",
            desc = "Show a spec icon on top of the nameplate for enemy players that are not healers inside arenas",
        },
        arenaSpecIconAlignment = {
            order = 8,
            type = "select",
            width = 0.85,
            name = "Alignment",
            values = {
                [addon.SPEC_ICON_ALIGNMENT.TOP] = "Top",
                [addon.SPEC_ICON_ALIGNMENT.LEFT] = "Left",
                [addon.SPEC_ICON_ALIGNMENT.RIGHT] = "Right",
            },
        },
        arenaSpecIconVerticalOffset = {
            order = 9,
            min = -150,
            max = 150,
            step = 1,
            type = "range",
            width = 0.85,
            name = "Vertical offset",
            hidden = function ()
                return ( SweepyBoop.db.profile.nameplatesEnemy.arenaSpecIconAlignment ~= addon.SPEC_ICON_ALIGNMENT.TOP );
            end
        },
        arenaSpecIconScale = {
            order = 10,
            min = 50,
            max = 300,
            step = 1,
            type = "range",
            width = 0.85,
            name = "Scale (%)",
        },

        breaker3 = {
            order = 11,
            type = "header",
            name = "Nameplate Filters & Highlights",
        },

        filterSettings = {
            order = 12,
            type = "group",
            name = "General",
            args = {
                hideHunterSecondaryPet = {
                    order = 1,
                    type = "toggle",
                    width = "full",
                    name = addon.FORMAT_TEXTURE(beastMasteryHunterIcon) .. " Hide beast mastery hunter secondary pets in arena",
                    desc = "Hide the extra pet from talents\nThis feature is not available in battlegrounds due to WoW API limitations",
                },
                filterEnabled = {
                    order = 2,
                    type = "toggle",
                    width = "full",
                    name = addon.FORMAT_TEXTURE(pvpCursor) .. " Filter which hostile non-player units to hide / show / highlight",
                    desc = "Each unit's nameplate can be hidden, shown, or shown with an animating icon on top\nThis works in arenas and battlegrounds",
                },
                highlightScale = {
                    order = 3,
                    type = "range",
                    name = "Highlight icon scale (%)",
                    min = 50,
                    max = 300,
                    step = 1,
                    hidden = function()
                        return ( not SweepyBoop.db.profile.nameplatesEnemy.filterEnabled );
                    end,
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
            hidden = function()
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
    set = function(info, val) 
        SweepyBoop.db.profile.arenaFrames[info[#info]] = val;
        SweepyBoop.db.profile.arenaFrames.lastModified = GetTime();
    end,
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
        reloadUI = {
            order = 3,
            type = "execute",
            width = 0.625,
            name = "Reload UI",
            func = ReloadUI,
        },
        desc = {
            order = 4,
            type = "description",
            width = "full",
            name = addon.EXCLAMATION .. " Changes made during an arena session require a reload to take effect",
        },
        breaker1 = {
            order = 5,
            type = "header",
            name = "",
        },

        arenaEnemyOffensivesEnabled = {
            order = 6,
            width = 1.75,
            type = "toggle",
            name = addon.FORMAT_TEXTURE(addon.ICON_PATH("spell_fire_sealoffire")) .. " Arena Enemy Offensive Cooldowns",
            desc = "Show arena enemy offensive cooldowns next to the arena frames",
        },
        arenaEnemyOffensiveIconSize = {
            order = 7,
            type = "range",
            min = 16,
            max = 64,
            step = 1,
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
            name = addon.FORMAT_TEXTURE(addon.ICON_PATH("spell_holy_divineshield")) .. " Arena Enemy Defensive Cooldowns",
            desc = "Show arena enemy defensive cooldowns next to the arena frames",
        },
        arenaEnemyDefensiveIconSize = {
            order = 10,
            type = "range",
            min = 16,
            max = 64,
            step = 1,
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
            min = -300,
            max = 300,
            step = 1,
            name = "Horizontal offset",
            desc = "Horizontal offset of the arena cooldown icon group relative to the right edge of the arena frame",
        },
        arenaCooldownOffsetY = {
            order = 13,
            type = "range",
            min = -150,
            max = 150,
            step = 1,
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
for _, classID in ipairs(addon.CLASSORDER) do
    local classInfo = C_CreatureInfo.GetClassInfo(classID);
    options.args.arenaFrames.args.spellList.args[classInfo.classFile] = {
        order = groupIndex,
        type = "group",
        icon = addon.ICON_ID_CLASSES,
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
                name = addon.FORMAT_TEXTURE(icon) .. " " .. name,
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
    get = function(info) return SweepyBoop.db.profile.raidFrames[info[#info]] end,
    set = function(info, val) SweepyBoop.db.profile.raidFrames[info[#info]] = val end,
    args = {
        arenaRaidFrameSortOrder = {
            order = 1,
            type = "select",
            values = {
                [addon.RAID_FRAME_SORT_ORDER.DISABLED] = "Disabled",
                [addon.RAID_FRAME_SORT_ORDER.PLAYER_TOP] = "Player on top",
                [addon.RAID_FRAME_SORT_ORDER.PLAYER_BOTTOM] = "Player at bottom",
                [addon.RAID_FRAME_SORT_ORDER.PLAYER_MID] = "Player in the middle",
            },
            name = addon.FORMAT_TEXTURE(addon.ICON_PATH("achievement_guildperk_everybodysfriend")) .. " Sort raid frames in arena",
            style = "radio",
        },

        raidFrameAggroHighlightEnabled = {
            order = 2,
            width = "full",
            type = "toggle",
            name = addon.FORMAT_TEXTURE(addon.ICON_PATH("spell_nature_reincarnation")) .. " Show PvP aggro highlight in arena",
            desc = addon.EXCLAMATION .. " Uncheck \"Display Aggro Highlight\" in Interface - Raid Frames to disable PvE aggro",
            descStyle = "inline",
        },
    },
};

options.args.misc = {
    order = 6,
    type = "group",
    name = "Misc",
    get = function(info) return SweepyBoop.db.profile.misc[info[#info]] end,
    set = function(info, val)
        SweepyBoop.db.profile.misc[info[#info]] = val;
        SweepyBoop.db.profile.misc.lastModified = GetTime();
    end,
    handler = SweepyBoop,
    args = {
        header1 = {
            order = 1,
            type = "header",
            name = "Healer in crowd control reminder in arena",
        },
        healerInCrowdControl = {
            order = 2,
            type = "toggle",
            width = "full",
            name = addon.FORMAT_TEXTURE(addon.ICON_PATH("spell_nature_polymorph")) .. " Enabled",
        },
        healerInCrowdControlTest = {
            order = 3,
            type = "execute",
            width = "half",
            name = "Test",
            func = "TestHealerInCrowdControl",
            hidden = function ()
                return ( not SweepyBoop.db.profile.misc.healerInCrowdControl );
            end
        },
        healerInCrowdControlHide = {
            order = 4,
            type = "execute",
            width = "half",
            name = "Hide",
            func = "HideTestHealerInCrowdControl",
            hidden = function ()
                return ( not SweepyBoop.db.profile.misc.healerInCrowdControl );
            end
        },
        newline = {
            order = 5,
            type = "description",
            width = "full",
            name = "",
            hidden = function ()
                return ( not SweepyBoop.db.profile.misc.healerInCrowdControl );
            end
        },
        healerInCrowdControlSize = {
            order = 6,
            type = "range",
            min = 30,
            max = 200,
            step = 1,
            name = "Icon size",
            hidden = function ()
                return ( not SweepyBoop.db.profile.misc.healerInCrowdControl );
            end
        },
        healerInCrowdControlOffsetX = {
            order = 7,
            type = "range",
            min = -500,
            max = 500,
            step = 1,
            name = "Horizontal offset",
            hidden = function ()
                return ( not SweepyBoop.db.profile.misc.healerInCrowdControl );
            end
        },
        healerInCrowdControlOffsetY = {
            order = 8,
            type = "range",
            min = -500,
            max = 500,
            step = 1,
            name = "Vertical offset",
            hidden = function ()
                return ( not SweepyBoop.db.profile.misc.healerInCrowdControl );
            end
        },

        header2 = {
            order = 10,
            type = "header",
            name = "",
        },
        queueReminder = {
            order = 11,
            type = "toggle",
            width = "full",
            name = addon.FORMAT_TEXTURE(addon.ICON_PATH("ability_racial_timeismoney")) .. " PvP Queue Timer",
            desc = "Shows a timer on arena / battlefield queue pop, and plays an alert when it's about to expire",
            set = function (info, val)
                SweepyBoop.db.profile.misc[info[#info]] = val;
                SweepyBoop:SetupQueueReminder();
            end
        },

        header3 = {
            order = 12,
            type = "header",
            name = "Type /afk to surrender arena",
        },
        arenaSurrenderEnabled = {
            order = 13,
            width = "full",
            type = "toggle",
            name = addon.FORMAT_TEXTURE(addon.ICON_PATH("inv_pet_exitbattle")) .. " Enabled",
            desc = "If unable to surrender, by default a confirmation dialog will pop up to confirm leaving arena",
        },
        skipLeaveArenaConfirmation = {
            order = 14,
            width = "full",
            type = "toggle",
            name = addon.FORMAT_TEXTURE(addon.ICON_PATH("ability_druid_cower")) .. " Leave arena directly if unable to surrender (skip confirmation dialog)",
            desc = addon.EXCLAMATION .. " Leaving arena before entering combat might result in deserter status",
            descStyle = "inline",
            hidden = function()
                return ( not SweepyBoop.db.profile.misc.arenaSurrenderEnabled );
            end,
        },

        header4 = {
            order = 15,
            type = "header",
            name = "",
        },
        showDampenPercentage = {
            order = 16,
            width = "full",
            type = "toggle",
            name = addon.FORMAT_TEXTURE(addon.ICON_PATH("achievement_bg_winsoa_underxminutes")) .. " Show dampen percentage on the arena widget",
        },
    },
};

local defaults = {
    profile = {
        nameplatesFriendly = {
            classIconsEnabled = true,
            classIconStyle = addon.CLASS_ICON_STYLE.ICON,
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
            arenaSpecIconAlignment = addon.SPEC_ICON_ALIGNMENT.TOP,
            arenaSpecIconVerticalOffset = 0,
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
        raidFrames = {
            arenaRaidFrameSortOrder = addon.RAID_FRAME_SORT_ORDER.DISABLED,
            raidFrameAggroHighlightEnabled = true,
        },
        misc = {
            healerInCrowdControl = false,
            healerInCrowdControlSize = 48,
            healerInCrowdControlOffsetX = 0,
            healerInCrowdControlOffsetY = 250,
            queueReminder = true,
            arenaSurrenderEnabled = true,
            skipLeaveArenaConfirmation = false,
            showDampenPercentage = true,
        },
    }
};

if addon.internal then -- Set default for internal version
    defaults.profile.raidFrames.arenaRaidFrameSortOrder = addon.RAID_FRAME_SORT_ORDER.PLAYER_MID;
    defaults.profile.arenaFrames.arenaCooldownOffsetY = 7.5;
    defaults.profile.misc.skipLeaveArenaConfirmation = true;
    defaults.profile.misc.healerInCrowdControl = true;
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
    local currentTime = GetTime();
    for _, category in pairs(defaults) do
        if type(category) == "table" then
            category.lastModified = currentTime;
        end
    end

    self.db = LibStub("AceDB-3.0"):New("SweepyBoopDB", defaults, true);
    options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db);
    local appName = LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, options);
    LibStub("AceConfigDialog-3.0"):SetDefaultSize(addonName, 750, 600);
    self.optionsFrame, self.categoryID = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, addon.addonTitle); -- Can we open to the friendly class icons page instead of the first empty page?

    -- Print message on first 3 logins with the addon enabled
    if SweepyBoopDB then
        SweepyBoopDB.loginCount = SweepyBoopDB.loginCount or 1;
        if ( SweepyBoopDB.loginCount <= 3 ) then
            addon.PRINT("Thank you for supporting my addon! Type /sb to bring up the options panel. Hope you have a great PvP experience :)");
            SweepyBoopDB.loginCount = SweepyBoopDB.loginCount + 1;
        end
    end

    -- Register callback (https://www.wowace.com/projects/ace3/pages/ace-db-3-0-tutorial)
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig");

    -- Setup nameplate modules
    self:SetupNameplateModules();

    -- Setup arena enemy cooldown icons
    self:SetupOffensiveIcons();
    self:SetupCooldownTrackingIcons();

    -- Setup raid frame aggro highlight
    self:SetupRaidFrameAggroHighlight();

    self:SetupQueueReminder();
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

    local currentTime = GetTime();
    for _, category in pairs(self.db.profile) do
        if type(category) == "table" then
            category.lastModified = currentTime;
        end
    end
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
