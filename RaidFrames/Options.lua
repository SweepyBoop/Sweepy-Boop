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
            header1 = {
                order = 1,
                type = "header",
                name = "PvP aggro highlight",
                hidden = function () return addon.PROJECT_MAINLINE; end,
            },

            raidFrameAggroHighlightEnabled = {
                order = 2,
                width = "full",
                type = "toggle",
                name = addon.FORMAT_ATLAS("pvptalents-warmode-swords") .. " Enabled",
                desc = "Show an animating dotted line border when a teammate is targeted by enemy players\n\n"
                    .. "The color of the border changes based on the number of enemies targeting the teammate",
                hidden = function () return addon.PROJECT_MAINLINE; end,
            },

            raidFrameAggroHighlightThickness = {
                order = 3,
                type = "range",
                min = 1,
                max = 5,
                step = 1,
                name = "Border thickness",
                hidden = function ()
                    return addon.PROJECT_MAINLINE or ( not SweepyBoop.db.profile.raidFrames.raidFrameAggroHighlightEnabled );
                end
            },

            raidFrameAggroHighlightAlpha = {
                order = 4,
                type = "range",
                isPercent = true,
                min = 0.5,
                max = 1,
                step = 0.01,
                name = "Border alpha",
                hidden = function ()
                    return addon.PROJECT_MAINLINE or ( not SweepyBoop.db.profile.raidFrames.raidFrameAggroHighlightEnabled );
                end
            },

            raidFrameAggroHighlightAnimationSpeed = {
                order = 5,
                type = "range",
                width = 1.5,
                min = 0,
                max = 25,
                step = 1,
                name = "Animation speed (0 for no animation)",
                hidden = function ()
                    return addon.PROJECT_MAINLINE or ( not SweepyBoop.db.profile.raidFrames.raidFrameAggroHighlightEnabled );
                end
            },

            header2 = {
                order = 6,
                type = "header",
                name = "Druid HoT Helper",
            },

            druidHoTHelper = {
                order = 7,
                width = "full",
                type = "toggle",
                name = addon.FORMAT_TEXTURE(addon.ICON_PATH("spell_nature_healingtouch")) .. "Enabled",
                desc = function ()
                    return table.concat({
                        "For Restoration Druids \226\128\148 replace Blizzard's raid-frame buffs with your own HoTs:",
                        "",
                        "\226\128\162 " .. SpellIcon(1126) .. " Mark of the Wild: red-glowing warning shown left of Lifebloom when missing.",
                        "\226\128\162 Scale: adjust all helper icons together from 50% to 250%.",
                        "\226\128\162 " .. SpellIcon(33763) .. " Lifebloom: its own row; glows during the refresh (pandemic) window.",
                        "\226\128\162 Second row, packed left-to-right in " .. SpellIcon(18562) .. " Swiftmend-consume order (left = consumed first): " .. SpellIcon(8936) .. " Regrowth, " .. SpellIcon(48438) .. " Wild Growth, " .. SpellIcon(774) .. " Rejuvenation, " .. SpellIcon(155777) .. " Germination.",
                        "\226\128\162 Hides ALL raid-frame buffs while active on Resto; debuffs and dispellable debuffs are unaffected.",
                    }, "\n");
                end,
                set = function(info, val)
                    SweepyBoop.db.profile.raidFrames[info[#info]] = val;
                    SweepyBoop:RefreshDruidHoTHelper(); -- re-apply the buff-hiding CVar + repaint frames
                end,
            },

            druidHoTHelperScale = {
                order = 8,
                type = "range",
                isPercent = true,
                min = 0.5,
                max = 2.5,
                step = 0.05,
                name = "Icon Scale",
                disabled = function () return not SweepyBoop.db.profile.raidFrames.druidHoTHelper; end,
                set = function(info, val)
                    SweepyBoop.db.profile.raidFrames[info[#info]] = val;
                    SweepyBoop:RefreshDruidHoTHelper(); -- repaint frames so the new scale applies immediately
                end,
            },

            druidHoTHelperWarning = {
                order = 9,
                width = "full",
                type = "toggle",
                name = addon.FORMAT_TEXTURE("Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew") .. "Show missing-HoT warning",
                desc = "Show the warning icon when none of the Swiftmend-consumable HoTs are active.",
                disabled = function () return not SweepyBoop.db.profile.raidFrames.druidHoTHelper; end,
                set = function(info, val)
                    SweepyBoop.db.profile.raidFrames[info[#info]] = val;
                    SweepyBoop:RefreshDruidHoTHelper(); -- repaint frames so the warning icon appears/disappears immediately
                end,
            },
        },
    };

    return optionGroup;
end
