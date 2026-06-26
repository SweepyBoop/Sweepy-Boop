local _, addon = ...;

-- Inline a spell's in-game icon for tooltips (empty string if the texture isn't available yet).
local function SpellIcon(spellId)
    local icon = addon.GetSpellTexture(spellId);
    return icon and addon.FORMAT_TEXTURE(icon) or "";
end

addon.GetRaidFrameOptions = function(order)
    local optionGroup = {
        order = order,
        type = "group",
        name = "Raid frames",
        get = function(info) return SweepyBoop.db.profile.raidFrames[info[#info]] end,
        set = function(info, val) SweepyBoop.db.profile.raidFrames[info[#info]] = val end,
        args = {
            arenaRaidFrameSortHeader = {
                order = 1,
                type = "header",
                name = "Arena party sorting",
            },

            arenaRaidFrameSortOrder = {
                order = 2,
                type = "select",
                width = 1.4,
                name = "Sort order",
                desc = "Sort Blizzard compact party frames in arenas.",
                values = {
                    [addon.RAID_FRAME_SORT_ORDER.DISABLED] = "Disabled",
                    [addon.RAID_FRAME_SORT_ORDER.PLAYER_TOP] = "Player on top",
                    [addon.RAID_FRAME_SORT_ORDER.PLAYER_MID] = "Player in middle",
                    [addon.RAID_FRAME_SORT_ORDER.PLAYER_BOTTOM] = "Player on bottom",
                },
                set = function(info, val)
                    SweepyBoop.db.profile.raidFrames[info[#info]] = val;
                    SweepyBoop:RefreshArenaRaidFrameSort();
                end,
            },

            header1 = {
                order = 3,
                type = "header",
                name = "PvP aggro highlight",
            },

            raidFrameAggroHighlightEnabled = {
                order = 4,
                width = "full",
                type = "toggle",
                name = addon.FORMAT_ATLAS("groupfinder-icon-friend") .. " Enabled",
                desc = "Show class-colored indicators on Blizzard raid-style frames when arena players target that unit.",
                set = function(info, val)
                    SweepyBoop.db.profile.raidFrames[info[#info]] = val;
                    SweepyBoop:RefreshRaidFrameAggroHighlight();
                end,
            },

            header2 = {
                order = 5,
                type = "header",
                name = "Healer Buff Helper",
            },

            healerBuffHelperScale = {
                order = 6,
                width = "normal",
                type = "range",
                isPercent = true,
                min = 0.5,
                max = 2.5,
                step = 0.05,
                name = "Icon Scale",
                desc = "Adjust all helper icons together from 50% to 250%.",
                disabled = function ()
                    local raidFrames = SweepyBoop.db.profile.raidFrames;
                    return ( not raidFrames.druidBuffHelper ) and ( not raidFrames.evokerBuffHelper );
                end,
                set = function(info, val)
                    SweepyBoop.db.profile.raidFrames[info[#info]] = val;
                    SweepyBoop:RefreshHealerBuffHelper(); -- repaint frames so the new scale applies immediately
                end,
            },

            healerBuffHelperScaleBreak = {
                order = 7,
                type = "description",
                name = "",
                width = "full",
            },

            druidBuffHelper = {
                order = 8,
                width = "normal",
                type = "toggle",
                name = addon.FORMAT_TEXTURE(addon.ICON_PATH("spell_nature_healingtouch")) .. "Resto Druid",
                desc = function ()
                    return table.concat({
                        "Enable the helper while playing Restoration Druid.",
                        "",
                        "\226\128\162 " .. SpellIcon(1126) .. " Mark of the Wild warning.",
                        "\226\128\162 " .. SpellIcon(33763) .. " Lifebloom with refresh-window glow.",
                        "\226\128\162 Row 2: " .. SpellIcon(8936) .. " Regrowth, " .. SpellIcon(48438) .. " Wild Growth, " .. SpellIcon(774) .. " Rejuvenation, " .. SpellIcon(155777) .. " Germination.",
                        "\226\128\162 Hides ALL raid-frame buffs while active; debuffs and dispellable debuffs are unaffected.",
                    }, "\n");
                end,
                set = function(info, val)
                    SweepyBoop.db.profile.raidFrames[info[#info]] = val;
                    SweepyBoop:RefreshHealerBuffHelper(); -- re-apply the buff-hiding CVar + repaint frames
                end,
            },

            druidBuffHelperWarning = {
                order = 9,
                width = 1.4,
                type = "toggle",
                name = addon.FORMAT_TEXTURE("Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew") .. "Missing-buff warning",
                desc = "For Restoration Druid only: show the warning icon when none of the Swiftmend-consumable buffs are active.",
                disabled = function () return not SweepyBoop.db.profile.raidFrames.druidBuffHelper; end,
                set = function(info, val)
                    SweepyBoop.db.profile.raidFrames[info[#info]] = val;
                    SweepyBoop:RefreshHealerBuffHelper(); -- repaint frames so the warning icon appears/disappears immediately
                end,
            },

            druidBuffHelperBreak = {
                order = 10,
                type = "description",
                name = "",
                width = "full",
            },

            evokerBuffHelper = {
                order = 11,
                width = "full",
                type = "toggle",
                name = addon.FORMAT_TEXTURE(addon.ICON_PATH("Classicon_evoker")) .. "Preservation Evoker",
                desc = function ()
                    return table.concat({
                        "Enable the helper while playing Preservation Evoker.",
                        "",
                        "\226\128\162 " .. SpellIcon(381748) .. " Blessing of the Bronze warning.",
                        "\226\128\162 " .. SpellIcon(364343) .. " Echo without a refresh-window glow.",
                        "\226\128\162 Row 2, least-to-most important: " .. SpellIcon(366155) .. " Reversion, " .. SpellIcon(355941) .. " Dream Breath, " .. SpellIcon(373267) .. " Lifebind, " .. SpellIcon(357170) .. " Time Dilation.",
                        "\226\128\162 Hides ALL raid-frame buffs while active; debuffs and dispellable debuffs are unaffected.",
                    }, "\n");
                end,
                set = function(info, val)
                    SweepyBoop.db.profile.raidFrames[info[#info]] = val;
                    SweepyBoop:RefreshHealerBuffHelper(); -- re-apply the buff-hiding CVar + repaint frames
                end,
            },
        },
    };

    return optionGroup;
end
