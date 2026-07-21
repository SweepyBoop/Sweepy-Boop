local _, addon = ...;

addon.GetMacroOptions = function(order)
    local optionGroup = {
        order = order,
        type = "group",
        name = "Smart healer macros",
        args = {
            title = {
                order = 1,
                type = "header",
                name = "Focus arena macros",
            },
            overview = {
                order = 2,
                type = "description",
                fontSize = "medium",
                name = "Add SBM to a macro name to let SweepyBoop retarget its @focus casts to the enemy healer in arena.\n\nWhen a healer is detected, @focus becomes @arena1, @arena2, or @arena3. Outside arena, or if no healer is found, it changes back to @focus.",
            },
            healerIndicator = {
                order = 3,
                type = "toggle",
                width = "full",
                name = addon.FORMAT_ATLAS("Icon-Healer") .. " Show healer icon on arena frames",
                desc = "Marks the detected enemy healer on supported arena frames so it is easier to match Smart macro targeting to the frame.",
                disabled = function()
                    return ( not ( GladiusEx or Gladius or sArena or ArenaLiveUnitFrames or SlashCmdList.GLADDY ) );
                end,
                get = function()
                    return SweepyBoop.db.profile.misc.healerIndicator;
                end,
                set = function(_, val)
                    SweepyBoop.db.profile.misc.healerIndicator = val;
                    SweepyBoop.db.profile.misc.lastModified = GetTime();
                    SweepyBoop:RefreshHealerIndicator();
                end,
            },
            howItWorksHeader = {
                order = 4,
                type = "header",
                name = "How it works",
            },
            howItWorks = {
                order = 5,
                type = "description",
                fontSize = "medium",
                name = "Only macro names containing case-sensitive SBM are edited.\n\nSweepyBoop only changes explicit target tokens: @focus and @arena1 through @arena5. All other macro text is left unchanged.\n\nIf combat blocks macro edits, the update is applied after combat ends.",
            },
            exampleHeader = {
                order = 6,
                type = "header",
                name = "Example",
            },
            example = {
                order = 7,
                type = "description",
                fontSize = "medium",
                name = "Name:\nSBM Cyclone\n\nBefore arena:\n#showtooltip\n/cast [@focus] Cyclone\n\nIf the healer is arena2:\n#showtooltip\n/cast [@arena2] Cyclone\n\nAfter arena, it returns to @focus.",
            },
            limitationsHeader = {
                order = 8,
                type = "header",
                name = "Important details",
            },
            limitations = {
                order = 9,
                type = "description",
                fontSize = "medium",
                name = "Create the macro yourself and use @focus as the default target.\n\nAdd SBM only to macros SweepyBoop should manage. Leave it out of macros that must keep a fixed arena target.",
            },
        },
    };

    return addon.LocalizeOptions(optionGroup);
end
