local _, addon = ...;

addon.GetMacroOptions = function(order)
    local optionGroup = {
        order = order,
        type = "group",
        name = "Smart macros",
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
            howItWorksHeader = {
                order = 3,
                type = "header",
                name = "How it works",
            },
            howItWorks = {
                order = 4,
                type = "description",
                fontSize = "medium",
                name = "Only macro names containing case-sensitive SBM are edited.\n\nSweepyBoop only changes explicit target tokens: @focus and @arena1 through @arena5. All other macro text is left unchanged.\n\nIf combat blocks macro edits, the update is applied after combat ends.",
            },
            exampleHeader = {
                order = 5,
                type = "header",
                name = "Example",
            },
            example = {
                order = 6,
                type = "description",
                fontSize = "medium",
                name = "Name:\nSBM Cyclone\n\nBefore arena:\n#showtooltip\n/cast [@focus] Cyclone\n\nIf the healer is arena2:\n#showtooltip\n/cast [@arena2] Cyclone\n\nAfter arena, it returns to @focus.",
            },
            limitationsHeader = {
                order = 7,
                type = "header",
                name = "Important details",
            },
            limitations = {
                order = 8,
                type = "description",
                fontSize = "medium",
                name = "Create the macro yourself and use @focus as the default target.\n\nAdd SBM only to macros SweepyBoop should manage. Leave it out of macros that must keep a fixed arena target.",
            },
        },
    };

    return addon.LocalizeOptions(optionGroup);
end
