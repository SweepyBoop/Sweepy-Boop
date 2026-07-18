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
                name = "SweepyBoop can keep selected focus macros pointed at the enemy healer in arenas. To opt in, add the letters SBM anywhere in the macro name, for example \"SBM Cyclone\" or \"Focus Kick SBM\".\n\nWhen arena specializations are available, the addon finds the enemy healer and rewrites managed target tokens in those macros from @focus to @arena1, @arena2, or @arena3. Outside arenas, or when no healer can be detected, the addon rewrites those same managed targets back to @focus.",
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
                name = "Only macros with SBM in the macro name are edited. The marker is case-sensitive, so \"SBM\" works and \"sbm\" is ignored.\n\nInside those macros, SweepyBoop only changes explicit unit target tokens: @focus and @arena1 through @arena5. Other macro text is left untouched.\n\nMacro editing is blocked during combat by the game client, so updates are applied after combat ends if an arena event occurs while you are in combat.",
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
                name = "Macro name:\nSBM Cyclone\n\nMacro body before entering arena:\n#showtooltip\n/cast [@focus] Cyclone\n\nIf the healer is arena2, SweepyBoop changes it to:\n#showtooltip\n/cast [@arena2] Cyclone\n\nAfter leaving arena, the same macro is restored to @focus.",
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
                name = "Use this for macros you want SweepyBoop to manage. Do not put SBM in macro names that should keep a fixed arena target.\n\nThe addon does not create macros for this feature. Create your own macro, include SBM in the macro name, and write it using @focus as the default target.",
            },
        },
    };

    return addon.LocalizeOptions(optionGroup);
end
