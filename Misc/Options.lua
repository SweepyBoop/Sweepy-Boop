local addonName, addon = ...;

addon.GetMiscOptions = function (order, icon, SweepyBoopLDB)
    local optionGroup = {
        order = order,
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
                set = function (info, val)
                    SweepyBoop.db.profile.misc[info[#info]] = val;
                    SweepyBoop.db.profile.misc.lastModified = GetTime();
                    SweepyBoop:SetupHealerInCrowdControl();
                end
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
                set = function (info, val)
                    SweepyBoop.db.profile.misc[info[#info]] = val;
                    SweepyBoop.db.profile.misc.lastModified = GetTime();
                    SweepyBoop:UpdateHealerInCrowdControl();
                end,
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
                set = function (info, val)
                    SweepyBoop.db.profile.misc[info[#info]] = val;
                    SweepyBoop.db.profile.misc.lastModified = GetTime();
                    SweepyBoop:UpdateHealerInCrowdControl();
                end,
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
                set = function (info, val)
                    SweepyBoop.db.profile.misc[info[#info]] = val;
                    SweepyBoop.db.profile.misc.lastModified = GetTime();
                    SweepyBoop:UpdateHealerInCrowdControl();
                end,
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
                name = "",
            },
            combatIndicator = {
                order = 13,
                type = "toggle",
                width = "full",
                name = addon.FORMAT_ATLAS("countdown-swords") .. " Show combat indicator on unit frames",
                desc = "Show combat indicator icons on Player / Target / Focus frames",
                set = function(info, val)
                    SweepyBoop.db.profile.misc[info[#info]] = val;
                    SweepyBoop.db.profile.misc.lastModified = GetTime();
                    SweepyBoop:SetupCombatIndicator();
                end,
            },

            header4 = {
                order = 14,
                type = "header",
                name = "Type /afk to surrender arena",
            },
            arenaSurrenderEnabled = {
                order = 15,
                width = "full",
                type = "toggle",
                name = addon.FORMAT_TEXTURE(addon.ICON_PATH("inv_pet_exitbattle")) .. " Enabled",
                desc = "If unable to surrender, by default a confirmation dialog will pop up to confirm leaving arena",
            },
            skipLeaveArenaConfirmation = {
                order = 16,
                width = "full",
                type = "toggle",
                name = addon.FORMAT_TEXTURE(addon.ICON_PATH("ability_druid_cower")) .. " Leave arena directly if unable to surrender (skip confirmation dialog)",
                desc = addon.EXCLAMATION .. " Leaving arena before entering combat might result in deserter status",
                descStyle = "inline",
                hidden = function()
                    return ( not SweepyBoop.db.profile.misc.arenaSurrenderEnabled );
                end,
            },

            header5 = {
                order = 17,
                type = "header",
                name = "",
            },
            showDampenPercentage = {
                order = 18,
                width = "full",
                type = "toggle",
                name = addon.FORMAT_TEXTURE(addon.ICON_PATH("achievement_bg_winsoa_underxminutes")) .. " Show dampen percentage on the arena widget",
            },

            header6 = {
                order = 19,
                type = "header",
                name = "",
            },

            showMinimapIcon = {
                order = 20,
                type = "toggle",
                width = "full",
                name = addon.FORMAT_TEXTURE(addon.INTERFACE_SWEEPY .. "Art/Logo") .. " Show minimap icon for invoking options UI",
                set = function(info, val)
                    SweepyBoop.db.profile.minimap.hide = ( not val );
                    if val then
                        icon:Show(addonName);
                    else
                        icon:Hide(addonName);
                    end
                end,
                get = function (info)
                    return ( not SweepyBoop.db.profile.minimap.hide );
                end
            }
        },
    };

    return optionGroup;
end
