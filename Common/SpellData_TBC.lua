local _, addon = ...;

local POWERTYPE = Enum.PowerType;
local specID = addon.SPECID;
local category = addon.SPELLCATEGORY;

addon.SpellData = {
    -- Priest

    [586] = { -- Fade (Rank 1)
        class = addon.PRIEST,
        cooldown = 30,
        category = category.OTHERS,
        baseline = true,
    },
        [9578] = { parent = 586, use_parent_icon = true }, -- Fade (Rank 2)
        [9579] = { parent = 586, use_parent_icon = true }, -- Fade (Rank 3)
        [9592] = { parent = 586, use_parent_icon = true }, -- Fade (Rank 4)
        [10941] = { parent = 586, use_parent_icon = true }, -- Fade (Rank 5)
        [10942] = { parent = 586, use_parent_icon = true }, -- Fade (Rank 6)
        [25429] = { parent = 586, use_parent_icon = true }, -- Fade (Rank 7)

    [724] = { -- Lightwell (Rank 1)
        class = addon.PRIEST,
        cooldown = 360,
        category = category.OTHERS,
        spec = { specID.HOLY_PRIEST },
        baseline = true,
    },
        [27870] = { parent = 724, use_parent_icon = true }, -- Lightwell (Rank 2)
        [27871] = { parent = 724, use_parent_icon = true }, -- Lightwell (Rank 3)
        [28275] = { parent = 724, use_parent_icon = true }, -- Lightwell (Rank 4)

    [2651] = { -- Elune's Grace
        class = addon.PRIEST,
        cooldown = 180,
        category = category.OTHERS,
    },

    [2944] = { -- Devouring Plague (Rank 1)
        class = addon.PRIEST,
        cooldown = 180,
        duration = 24,
        category = category.BURST,
    },
        [19276] = { parent = 2944, use_parent_icon = true }, -- Devouring Plague (Rank 2)
        [19277] = { parent = 2944, use_parent_icon = true }, -- Devouring Plague (Rank 3)
        [19278] = { parent = 2944, use_parent_icon = true }, -- Devouring Plague (Rank 4)
        [19279] = { parent = 2944, use_parent_icon = true }, -- Devouring Plague (Rank 5)
        [19280] = { parent = 2944, use_parent_icon = true }, -- Devouring Plague (Rank 6)
        [25467] = { parent = 2944, use_parent_icon = true }, -- Devouring Plague (Rank 7)

    [6346] = { -- Fear Ward
        class = addon.PRIEST,
        cooldown = 180,
        category = category.OTHERS,
        baseline = true,
    },

    [8092] = { -- Mind Blast (Rank 1)
        class = addon.PRIEST,
        cooldown = 8,
        category = category.OTHERS,
        baseline = true,
    },
        [8102] = { parent = 8092, use_parent_icon = true }, -- Mind Blast (Rank 2)
        [8103] = { parent = 8092, use_parent_icon = true }, -- Mind Blast (Rank 3)
        [8104] = { parent = 8092, use_parent_icon = true }, -- Mind Blast (Rank 4)
        [8105] = { parent = 8092, use_parent_icon = true }, -- Mind Blast (Rank 5)
        [8106] = { parent = 8092, use_parent_icon = true }, -- Mind Blast (Rank 6)
        [10945] = { parent = 8092, use_parent_icon = true }, -- Mind Blast (Rank 7)
        [10946] = { parent = 8092, use_parent_icon = true }, -- Mind Blast (Rank 8)
        [10947] = { parent = 8092, use_parent_icon = true }, -- Mind Blast (Rank 9)
        [25372] = { parent = 8092, use_parent_icon = true }, -- Mind Blast (Rank 10)
        [25375] = { parent = 8092, use_parent_icon = true }, -- Mind Blast (Rank 11)

    [8122] = { -- Psychic Scream (Rank 1)
        class = addon.PRIEST,
        cooldown = 30,
        category = category.OTHERS,
        baseline = true,
    },
        [8124] = { parent = 8122, use_parent_icon = true }, -- Psychic Scream (Rank 2)
        [10888] = { parent = 8122, use_parent_icon = true }, -- Psychic Scream (Rank 3)
        [10890] = { parent = 8122, use_parent_icon = true }, -- Psychic Scream (Rank 4)

    [10060] = { -- Power Infusion
        class = addon.PRIEST,
        cooldown = 180,
        duration = 15,
        category = category.BURST,
        spec = { specID.DISCIPLINE },
        baseline = true,
    },

    [10797] = { -- Starshards (Rank 1)
        class = addon.PRIEST,
        cooldown = 30,
        category = category.OTHERS,
    },
        [19296] = { parent = 10797, use_parent_icon = true }, -- Starshards (Rank 2)
        [19299] = { parent = 10797, use_parent_icon = true }, -- Starshards (Rank 3)
        [19302] = { parent = 10797, use_parent_icon = true }, -- Starshards (Rank 4)
        [19303] = { parent = 10797, use_parent_icon = true }, -- Starshards (Rank 5)
        [19304] = { parent = 10797, use_parent_icon = true }, -- Starshards (Rank 6)
        [19305] = { parent = 10797, use_parent_icon = true }, -- Starshards (Rank 7)
        [25446] = { parent = 10797, use_parent_icon = true }, -- Starshards (Rank 8)

    [13896] = { -- Feedback (Rank 1)
        class = addon.PRIEST,
        cooldown = 180,
        category = category.OTHERS,
    },
        [19271] = { parent = 13896, use_parent_icon = true }, -- Feedback (Rank 2)
        [19273] = { parent = 13896, use_parent_icon = true }, -- Feedback (Rank 3)
        [19274] = { parent = 13896, use_parent_icon = true }, -- Feedback (Rank 4)
        [19275] = { parent = 13896, use_parent_icon = true }, -- Feedback (Rank 5)
        [25441] = { parent = 13896, use_parent_icon = true }, -- Feedback (Rank 6)

    [13908] = { -- Desperate Prayer (Rank 1)
        class = addon.PRIEST,
        cooldown = 600,
        category = category.DEFENSIVE,
    },
        [19236] = { parent = 13908, use_parent_icon = true }, -- Desperate Prayer (Rank 2)
        [19238] = { parent = 13908, use_parent_icon = true }, -- Desperate Prayer (Rank 3)
        [19240] = { parent = 13908, use_parent_icon = true }, -- Desperate Prayer (Rank 4)
        [19241] = { parent = 13908, use_parent_icon = true }, -- Desperate Prayer (Rank 5)
        [19242] = { parent = 13908, use_parent_icon = true }, -- Desperate Prayer (Rank 6)
        [19243] = { parent = 13908, use_parent_icon = true }, -- Desperate Prayer (Rank 7)
        [25437] = { parent = 13908, use_parent_icon = true }, -- Desperate Prayer (Rank 8)

    [14751] = { -- Inner Focus
        class = addon.PRIEST,
        cooldown = 180,
        category = category.OTHERS,
        spec = { specID.DISCIPLINE },
        baseline = true,
    },

    [15286] = { -- Vampiric Embrace
        class = addon.PRIEST,
        cooldown = 10,
        category = category.OTHERS,
        spec = { specID.SHADOW },
        baseline = true,
    },

    [15487] = { -- Silence
        class = addon.PRIEST,
        cooldown = 45,
        category = category.OTHERS,
        spec = { specID.SHADOW },
        baseline = true,
    },

    [32379] = { -- Shadow Word: Death (Rank 1)
        class = addon.PRIEST,
        cooldown = 12,
        category = category.OTHERS,
        baseline = true,
    },
        [32996] = { parent = 32379, use_parent_icon = true }, -- Shadow Word: Death (Rank 2)

    [32548] = { -- Symbol of Hope
        class = addon.PRIEST,
        cooldown = 300,
        category = category.OTHERS,
    },

    [32676] = { -- Consume Magic
        class = addon.PRIEST,
        cooldown = 120,
        category = category.OTHERS,
    },

    [33076] = { -- Prayer of Mending
        class = addon.PRIEST,
        cooldown = 10,
        category = category.OTHERS,
        baseline = true,
    },

    [33206] = { -- Pain Suppression
        class = addon.PRIEST,
        cooldown = 120,
        category = category.DEFENSIVE,
        spec = { specID.DISCIPLINE },
        baseline = true,
    },

    [34433] = { -- Shadowfiend
        class = addon.PRIEST,
        cooldown = 300,
        category = category.BURST,
        baseline = true,
    },

    [44041] = { -- Chastise (Rank 1)
        class = addon.PRIEST,
        cooldown = 30,
        category = category.OTHERS,
    },
        [44043] = { parent = 44041, use_parent_icon = true }, -- Chastise (Rank 2)
        [44044] = { parent = 44041, use_parent_icon = true }, -- Chastise (Rank 3)
        [44045] = { parent = 44041, use_parent_icon = true }, -- Chastise (Rank 4)
        [44046] = { parent = 44041, use_parent_icon = true }, -- Chastise (Rank 5)
        [44047] = { parent = 44041, use_parent_icon = true }, -- Chastise (Rank 6)

    -- Warlock

    [603] = { -- Curse of Doom (Rank 1)
        class = addon.WARLOCK,
        cooldown = 60,
        category = category.OTHERS,
        baseline = true,
    },
        [30910] = { parent = 603, use_parent_icon = true }, -- Curse of Doom (Rank 2)

    [5484] = { -- Howl of Terror (Rank 1)
        class = addon.WARLOCK,
        cooldown = 40,
        category = category.OTHERS,
        baseline = true,
    },
        [17928] = { parent = 5484, use_parent_icon = true }, -- Howl of Terror (Rank 2)

    [6229] = { -- Shadow Ward (Rank 1)
        class = addon.WARLOCK,
        cooldown = 30,
        category = category.OTHERS,
        baseline = true,
    },
        [11739] = { parent = 6229, use_parent_icon = true }, -- Shadow Ward (Rank 2)
        [11740] = { parent = 6229, use_parent_icon = true }, -- Shadow Ward (Rank 3)
        [28610] = { parent = 6229, use_parent_icon = true }, -- Shadow Ward (Rank 4)

    [6353] = { -- Soul Fire (Rank 1)
        class = addon.WARLOCK,
        cooldown = 60,
        category = category.OTHERS,
        baseline = true,
    },
        [17924] = { parent = 6353, use_parent_icon = true }, -- Soul Fire (Rank 2)
        [27211] = { parent = 6353, use_parent_icon = true }, -- Soul Fire (Rank 3)
        [30545] = { parent = 6353, use_parent_icon = true }, -- Soul Fire (Rank 4)

    [6789] = { -- Death Coil (Rank 1)
        class = addon.WARLOCK,
        cooldown = 120,
        category = category.OTHERS,
        baseline = true,
    },
        [17925] = { parent = 6789, use_parent_icon = true }, -- Death Coil (Rank 2)
        [17926] = { parent = 6789, use_parent_icon = true }, -- Death Coil (Rank 3)
        [27223] = { parent = 6789, use_parent_icon = true }, -- Death Coil (Rank 4)

    [17877] = { -- Shadowburn (Rank 1)
        class = addon.WARLOCK,
        cooldown = 15,
        category = category.BURST,
        spec = { specID.DESTRUCTION },
        baseline = true,
    },
        [18867] = { parent = 17877, use_parent_icon = true }, -- Shadowburn (Rank 2)
        [18868] = { parent = 17877, use_parent_icon = true }, -- Shadowburn (Rank 3)
        [18869] = { parent = 17877, use_parent_icon = true }, -- Shadowburn (Rank 4)
        [18870] = { parent = 17877, use_parent_icon = true }, -- Shadowburn (Rank 5)
        [18871] = { parent = 17877, use_parent_icon = true }, -- Shadowburn (Rank 6)
        [27263] = { parent = 17877, use_parent_icon = true }, -- Shadowburn (Rank 7)
        [30546] = { parent = 17877, use_parent_icon = true }, -- Shadowburn (Rank 8)

    [17962] = { -- Conflagrate (Rank 1)
        class = addon.WARLOCK,
        cooldown = 10,
        category = category.OTHERS,
        spec = { specID.DESTRUCTION },
        baseline = true,
    },
        [18930] = { parent = 17962, use_parent_icon = true }, -- Conflagrate (Rank 2)
        [18931] = { parent = 17962, use_parent_icon = true }, -- Conflagrate (Rank 3)
        [18932] = { parent = 17962, use_parent_icon = true }, -- Conflagrate (Rank 4)
        [27266] = { parent = 17962, use_parent_icon = true }, -- Conflagrate (Rank 5)
        [30912] = { parent = 17962, use_parent_icon = true }, -- Conflagrate (Rank 6)

    [18288] = { -- Amplify Curse
        class = addon.WARLOCK,
        cooldown = 180,
        category = category.OTHERS,
        spec = { specID.AFFLICTION },
        baseline = true,
    },

    [18540] = { -- Ritual of Doom
        class = addon.WARLOCK,
        cooldown = 3600,
        category = category.OTHERS,
        baseline = true,
    },

    [18708] = { -- Fel Domination
        class = addon.WARLOCK,
        cooldown = 900,
        category = category.OTHERS,
        spec = { specID.DEMONOLOGY },
        baseline = true,
    },

    [29858] = { -- Soulshatter
        class = addon.WARLOCK,
        cooldown = 300,
        category = category.OTHERS,
        baseline = true,
    },

    [29893] = { -- Ritual of Souls
        class = addon.WARLOCK,
        cooldown = 300,
        category = category.OTHERS,
        baseline = true,
    },

    [30283] = { -- Shadowfury (Rank 1)
        class = addon.WARLOCK,
        cooldown = 20,
        category = category.OTHERS,
        spec = { specID.DESTRUCTION },
        baseline = true,
    },
        [30413] = { parent = 30283, use_parent_icon = true }, -- Shadowfury (Rank 2)
        [30414] = { parent = 30283, use_parent_icon = true }, -- Shadowfury (Rank 3)

    -- Warlock Pets

    [4511] = { -- Phase Shift
        class = addon.WARLOCK,
        cooldown = 10,
        category = category.OTHERS,
        baseline = true,
    },

    [7814] = { -- Lash of Pain (Rank 1)
        class = addon.WARLOCK,
        cooldown = 12,
        category = category.OTHERS,
        baseline = true,
    },
        [7815] = { parent = 7814, use_parent_icon = true }, -- Lash of Pain (Rank 2)
        [7816] = { parent = 7814, use_parent_icon = true }, -- Lash of Pain (Rank 3)
        [11778] = { parent = 7814, use_parent_icon = true }, -- Lash of Pain (Rank 4)
        [11779] = { parent = 7814, use_parent_icon = true }, -- Lash of Pain (Rank 5)
        [11780] = { parent = 7814, use_parent_icon = true }, -- Lash of Pain (Rank 6)
        [27274] = { parent = 7814, use_parent_icon = true }, -- Lash of Pain (Rank 7)

    [17735] = { -- Suffering (Rank 1)
        class = addon.WARLOCK,
        cooldown = 120,
        category = category.OTHERS,
        baseline = true,
    },
        [17750] = { parent = 17735, use_parent_icon = true }, -- Suffering (Rank 2)
        [17751] = { parent = 17735, use_parent_icon = true }, -- Suffering (Rank 3)
        [17752] = { parent = 17735, use_parent_icon = true }, -- Suffering (Rank 4)
        [27271] = { parent = 17735, use_parent_icon = true }, -- Suffering (Rank 5)
        [33701] = { parent = 17735, use_parent_icon = true }, -- Suffering (Rank 6)

    [19244] = { -- Spell Lock (Rank 1)
        class = addon.WARLOCK,
        cooldown = 24,
        category = category.INTERRUPT,
        trackPet = true,
        baseline = true,
    },
        [19647] = { parent = 19244, use_parent_icon = true }, -- Spell Lock (Rank 2)

    [19505] = { -- Devour Magic (Rank 1)
        class = addon.WARLOCK,
        cooldown = 8,
        category = category.OTHERS,
        trackPet = true,
        baseline = true,
    },
        [19731] = { parent = 19505, use_parent_icon = true }, -- Devour Magic (Rank 2)
        [19734] = { parent = 19505, use_parent_icon = true }, -- Devour Magic (Rank 3)
        [19736] = { parent = 19505, use_parent_icon = true }, -- Devour Magic (Rank 4)
        [27276] = { parent = 19505, use_parent_icon = true }, -- Devour Magic (Rank 5)
        [27277] = { parent = 19505, use_parent_icon = true }, -- Devour Magic (Rank 6)

    -- Shaman

    [8042] = { -- Earth Shock (Rank 1)
        cooldown = 5,
        class = addon.SHAMAN,
        category = category.INTERRUPT,
        baseline = true,
    },
        [8044] = { parent = 8042, use_parent_icon = true }, -- Earth Shock (Rank 2)
        [8045] = { parent = 8042, use_parent_icon = true }, -- Earth Shock (Rank 3)
        [8046] = { parent = 8042, use_parent_icon = true }, -- Earth Shock (Rank 4)
        [10412] = { parent = 8042, use_parent_icon = true }, -- Earth Shock (Rank 5)
        [10413] = { parent = 8042, use_parent_icon = true }, -- Earth Shock (Rank 6)
        [10414] = { parent = 8042, use_parent_icon = true }, -- Earth Shock (Rank 7)
        [25454] = { parent = 8042, use_parent_icon = true }, -- Earth Shock (Rank 8)

    [556] = { -- Astral Recall
        class = addon.SHAMAN,
        cooldown = 900,
        category = category.OTHERS,
        baseline = true,
    },

    [1535] = { -- Fire Nova Totem (Rank 1)
        class = addon.SHAMAN,
        cooldown = 15,
        category = category.OTHERS,
        baseline = true,
    },
        [8498] = { parent = 1535, use_parent_icon = true }, -- Fire Nova Totem (Rank 2)
        [8499] = { parent = 1535, use_parent_icon = true }, -- Fire Nova Totem (Rank 3)
        [11314] = { parent = 1535, use_parent_icon = true }, -- Fire Nova Totem (Rank 4)
        [11315] = { parent = 1535, use_parent_icon = true }, -- Fire Nova Totem (Rank 5)
        [25546] = { parent = 1535, use_parent_icon = true }, -- Fire Nova Totem (Rank 6)
        [25547] = { parent = 1535, use_parent_icon = true }, -- Fire Nova Totem (Rank 7)

    [2484] = { -- Earthbind Totem
        class = addon.SHAMAN,
        cooldown = 15,
        category = category.OTHERS,
        baseline = true,
    },

    [2825] = { -- Bloodlust
        class = addon.SHAMAN,
        cooldown = 600,
        duration = 40,
        category = category.BURST,
        baseline = true,
    },

    [2894] = { -- Fire Elemental Totem
        class = addon.SHAMAN,
        cooldown = 1200,
        category = category.OTHERS,
        baseline = true,
    },

    [5730] = { -- Stoneclaw Totem (Rank 1)
        class = addon.SHAMAN,
        cooldown = 30,
        category = category.OTHERS,
        baseline = true,
    },
        [6390] = { parent = 5730, use_parent_icon = true }, -- Stoneclaw Totem (Rank 2)
        [6391] = { parent = 5730, use_parent_icon = true }, -- Stoneclaw Totem (Rank 3)
        [6392] = { parent = 5730, use_parent_icon = true }, -- Stoneclaw Totem (Rank 4)
        [10427] = { parent = 5730, use_parent_icon = true }, -- Stoneclaw Totem (Rank 5)
        [10428] = { parent = 5730, use_parent_icon = true }, -- Stoneclaw Totem (Rank 6)
        [25525] = { parent = 5730, use_parent_icon = true }, -- Stoneclaw Totem (Rank 7)

    [8177] = { -- Grounding Totem
        class = addon.SHAMAN,
        cooldown = 15,
        category = category.OTHERS,
        baseline = true,
    },

    [16166] = { -- Elemental Mastery
        class = addon.SHAMAN,
        cooldown = 180,
        category = category.OTHERS,
        spec = { specID.ELEMENTAL },
        baseline = true,
    },

    [16188] = { -- Nature's Swiftness
        class = addon.SHAMAN,
        cooldown = 180,
        category = category.OTHERS,
        spec = { specID.RESTORATION_SHAMAN },
        baseline = true,
    },

    [16190] = { -- Mana Tide Totem
        class = addon.SHAMAN,
        cooldown = 300,
        category = category.OTHERS,
        spec = { specID.RESTORATION_SHAMAN },
        baseline = true,
    },

    [17364] = { -- Stormstrike
        class = addon.SHAMAN,
        cooldown = 10,
        category = category.OTHERS,
        spec = { specID.ENHANCEMENT },
        baseline = true,
    },

    [30823] = { -- Shamanistic Rage
        class = addon.SHAMAN,
        cooldown = 120,
        category = category.OTHERS,
        spec = { specID.ENHANCEMENT },
        baseline = true,
    },

    [32182] = { -- Heroism
        class = addon.SHAMAN,
        cooldown = 600,
        duration = 40,
        category = category.BURST,
        baseline = true,
    },

    -- Paladin

    [498] = { -- Divine Protection (Rank 1)
        class = addon.PALADIN,
        cooldown = 300,
        category = category.DEFENSIVE,
        baseline = true,
    },
        [5573] = { parent = 498, use_parent_icon = true }, -- Divine Protection (Rank 2)

    [633] = { -- Lay on Hands (Rank 1)
        class = addon.PALADIN,
        cooldown = 3600,
        category = category.DEFENSIVE,
        baseline = true,
    },
        [2800] = { parent = 633, use_parent_icon = true }, -- Lay on Hands (Rank 2)
        [10310] = { parent = 633, use_parent_icon = true }, -- Lay on Hands (Rank 3)
        [27154] = { parent = 633, use_parent_icon = true }, -- Lay on Hands (Rank 4)

    [642] = { -- Divine Shield (Rank 1)
        class = addon.PALADIN,
        cooldown = 300,
        category = category.DEFENSIVE,
        baseline = true,
    },
        [1020] = { parent = 642, use_parent_icon = true }, -- Divine Shield (Rank 2)

    [853] = { -- Hammer of Justice (Rank 1)
        class = addon.PALADIN,
        cooldown = 45,
        category = category.OTHERS,
        baseline = true,
    },
        [5588] = { parent = 853, use_parent_icon = true }, -- Hammer of Justice (Rank 2)
        [5589] = { parent = 853, use_parent_icon = true }, -- Hammer of Justice (Rank 3)
        [10308] = { parent = 853, use_parent_icon = true }, -- Hammer of Justice (Rank 4)

    [879] = { -- Exorcism (Rank 1)
        class = addon.PALADIN,
        cooldown = 15,
        category = category.OTHERS,
        baseline = true,
    },
        [5614] = { parent = 879, use_parent_icon = true }, -- Exorcism (Rank 2)
        [5615] = { parent = 879, use_parent_icon = true }, -- Exorcism (Rank 3)
        [10312] = { parent = 879, use_parent_icon = true }, -- Exorcism (Rank 4)
        [10313] = { parent = 879, use_parent_icon = true }, -- Exorcism (Rank 5)
        [10314] = { parent = 879, use_parent_icon = true }, -- Exorcism (Rank 6)
        [27138] = { parent = 879, use_parent_icon = true }, -- Exorcism (Rank 7)

    [1022] = { -- Blessing of Protection (Rank 1)
        class = addon.PALADIN,
        cooldown = 300,
        category = category.DEFENSIVE,
        baseline = true,
    },
        [5599] = { parent = 1022, use_parent_icon = true }, -- Blessing of Protection (Rank 2)
        [10278] = { parent = 1022, use_parent_icon = true }, -- Blessing of Protection (Rank 3)

    [1044] = { -- Blessing of Freedom
        class = addon.PALADIN,
        cooldown = 25,
        category = category.OTHERS,
        baseline = true,
    },

    [2812] = { -- Holy Wrath (Rank 1)
        class = addon.PALADIN,
        cooldown = 60,
        category = category.OTHERS,
        baseline = true,
    },
        [10318] = { parent = 2812, use_parent_icon = true }, -- Holy Wrath (Rank 2)
        [27139] = { parent = 2812, use_parent_icon = true }, -- Holy Wrath (Rank 3)

    [2878] = { -- Turn Undead (Rank 1)
        class = addon.PALADIN,
        cooldown = 30,
        category = category.OTHERS,
        baseline = true,
    },
        [5627] = { parent = 2878, use_parent_icon = true }, -- Turn Undead (Rank 2)

    [6940] = { -- Blessing of Sacrifice (Rank 1)
        class = addon.PALADIN,
        cooldown = 30,
        category = category.DEFENSIVE,
        baseline = true,
    },
        [20729] = { parent = 6940, use_parent_icon = true }, -- Blessing of Sacrifice (Rank 2)
        [27147] = { parent = 6940, use_parent_icon = true }, -- Blessing of Sacrifice (Rank 3)
        [27148] = { parent = 6940, use_parent_icon = true }, -- Blessing of Sacrifice (Rank 4)

    [10326] = { -- Turn Evil
        class = addon.PALADIN,
        cooldown = 30,
        category = category.OTHERS,
        baseline = true,
    },

    [19752] = { -- Divine Intervention
        class = addon.PALADIN,
        cooldown = 3600,
        category = category.OTHERS,
        baseline = true,
    },

    [20066] = { -- Repentance
        class = addon.PALADIN,
        cooldown = 60,
        category = category.OTHERS,
        spec = { specID.RETRIBUTION },
        baseline = true,
    },

    [26573] = { -- Consecration (Rank 1)
        class = addon.PALADIN,
        cooldown = 8,
        category = category.OTHERS,
        baseline = true,
    },
        [20116] = { parent = 26573, use_parent_icon = true }, -- Consecration (Rank 2)
        [20922] = { parent = 26573, use_parent_icon = true }, -- Consecration (Rank 3)
        [20923] = { parent = 26573, use_parent_icon = true }, -- Consecration (Rank 4)
        [20924] = { parent = 26573, use_parent_icon = true }, -- Consecration (Rank 5)
        [27173] = { parent = 26573, use_parent_icon = true }, -- Consecration (Rank 6)

    [20216] = { -- Divine Favor
        class = addon.PALADIN,
        cooldown = 120,
        category = category.OTHERS,
        spec = { specID.HOLY_PALADIN },
        baseline = true,
    },

    [20271] = { -- Judgement
        class = addon.PALADIN,
        cooldown = 10,
        category = category.OTHERS,
        baseline = true,
    },

    [20473] = { -- Holy Shock (Rank 1)
        class = addon.PALADIN,
        cooldown = 15,
        category = category.OTHERS,
        spec = { specID.HOLY_PALADIN },
        baseline = true,
    },
        [20929] = { parent = 20473, use_parent_icon = true }, -- Holy Shock (Rank 2)
        [20930] = { parent = 20473, use_parent_icon = true }, -- Holy Shock (Rank 3)
        [27174] = { parent = 20473, use_parent_icon = true }, -- Holy Shock (Rank 4)
        [33072] = { parent = 20473, use_parent_icon = true }, -- Holy Shock (Rank 5)

    [20925] = { -- Holy Shield (Rank 1)
        class = addon.PALADIN,
        cooldown = 10,
        category = category.OTHERS,
        spec = { specID.PROTECTION_PALADIN },
        baseline = true,
    },
        [20927] = { parent = 20925, use_parent_icon = true }, -- Holy Shield (Rank 2)
        [20928] = { parent = 20925, use_parent_icon = true }, -- Holy Shield (Rank 3)
        [27179] = { parent = 20925, use_parent_icon = true }, -- Holy Shield (Rank 4)

    [31789] = { -- Righteous Defense
        class = addon.PALADIN,
        cooldown = 15,
        category = category.OTHERS,
        baseline = true,
    },

    [31842] = { -- Divine Illumination
        class = addon.PALADIN,
        cooldown = 180,
        category = category.OTHERS,
        spec = { specID.HOLY_PALADIN },
        baseline = true,
    },

    [31884] = { -- Avenging Wrath
        class = addon.PALADIN,
        cooldown = 180,
        duration = 20,
        category = category.BURST,
        baseline = true,
    },

    [31935] = { -- Avenger's Shield (Rank 1)
        class = addon.PALADIN,
        cooldown = 30,
        category = category.OTHERS,
        spec = { specID.PROTECTION_PALADIN },
        baseline = true,
    },
        [32699] = { parent = 31935, use_parent_icon = true }, -- Avenger's Shield (Rank 2)
        [32700] = { parent = 31935, use_parent_icon = true }, -- Avenger's Shield (Rank 3)

    -- Hunter

    [1499] = { -- Freezing Trap (Rank 1)
        class = addon.HUNTER,
        cooldown = 30,
        category = category.OTHERS,
        baseline = true,
    },
        [14310] = { parent = 1499, use_parent_icon = true }, -- Freezing Trap (Rank 2)
        [14311] = { parent = 1499, use_parent_icon = true }, -- Freezing Trap (Rank 3)

    [1510] = { -- Volley (Rank 1)
        class = addon.HUNTER,
        cooldown = 60,
        duration = 6,
        category = category.BURST,
        baseline = true,
    },
        [14294] = { parent = 1510, use_parent_icon = true }, -- Volley (Rank 2)
        [14295] = { parent = 1510, use_parent_icon = true }, -- Volley (Rank 3)
        [27022] = { parent = 1510, use_parent_icon = true }, -- Volley (Rank 4)

    [1513] = { -- Scare Beast (Rank 1)
        class = addon.HUNTER,
        cooldown = 30,
        category = category.OTHERS,
        baseline = true,
    },
        [14326] = { parent = 1513, use_parent_icon = true }, -- Scare Beast (Rank 2)
        [14327] = { parent = 1513, use_parent_icon = true }, -- Scare Beast (Rank 3)

    [1543] = { -- Flare
        class = addon.HUNTER,
        cooldown = 20,
        category = category.OTHERS,
        baseline = true,
    },

    [2643] = { -- Multi-Shot (Rank 1)
        class = addon.HUNTER,
        cooldown = 10,
        category = category.OTHERS,
        baseline = true,
    },
        [14288] = { parent = 2643, use_parent_icon = true }, -- Multi-Shot (Rank 2)
        [14289] = { parent = 2643, use_parent_icon = true }, -- Multi-Shot (Rank 3)
        [14290] = { parent = 2643, use_parent_icon = true }, -- Multi-Shot (Rank 4)
        [25294] = { parent = 2643, use_parent_icon = true }, -- Multi-Shot (Rank 5)
        [27021] = { parent = 2643, use_parent_icon = true }, -- Multi-Shot (Rank 6)

    [3034] = { -- Viper Sting (Rank 1)
        class = addon.HUNTER,
        cooldown = 15,
        category = category.OTHERS,
        baseline = true,
    },
        [14279] = { parent = 3034, use_parent_icon = true }, -- Viper Sting (Rank 2)
        [14280] = { parent = 3034, use_parent_icon = true }, -- Viper Sting (Rank 3)
        [27018] = { parent = 3034, use_parent_icon = true }, -- Viper Sting (Rank 4)

    [3045] = { -- Rapid Fire
        class = addon.HUNTER,
        cooldown = 300,
        duration = 15,
        category = category.BURST,
        baseline = true,
    },

    [5116] = { -- Concussive Shot
        class = addon.HUNTER,
        cooldown = 12,
        category = category.OTHERS,
        baseline = true,
    },

    [5384] = { -- Feign Death
        class = addon.HUNTER,
        cooldown = 30,
        category = category.OTHERS,
        baseline = true,
    },

    [13795] = { -- Immolation Trap (Rank 1)
        class = addon.HUNTER,
        cooldown = 30,
        category = category.OTHERS,
        baseline = true,
    },
        [14302] = { parent = 13795, use_parent_icon = true }, -- Immolation Trap (Rank 2)
        [14303] = { parent = 13795, use_parent_icon = true }, -- Immolation Trap (Rank 3)
        [14304] = { parent = 13795, use_parent_icon = true }, -- Immolation Trap (Rank 4)
        [14305] = { parent = 13795, use_parent_icon = true }, -- Immolation Trap (Rank 5)
        [27023] = { parent = 13795, use_parent_icon = true }, -- Immolation Trap (Rank 6)

    [13809] = { -- Frost Trap
        class = addon.HUNTER,
        cooldown = 30,
        category = category.OTHERS,
        baseline = true,
    },

    [13813] = { -- Explosive Trap (Rank 1)
        class = addon.HUNTER,
        cooldown = 30,
        category = category.OTHERS,
        baseline = true,
    },
        [14316] = { parent = 13813, use_parent_icon = true }, -- Explosive Trap (Rank 2)
        [14317] = { parent = 13813, use_parent_icon = true }, -- Explosive Trap (Rank 3)
        [27025] = { parent = 13813, use_parent_icon = true }, -- Explosive Trap (Rank 4)

    [20736] = { -- Distracting Shot (Rank 1)
        class = addon.HUNTER,
        cooldown = 8,
        category = category.OTHERS,
        baseline = true,
    },
        [14274] = { parent = 20736, use_parent_icon = true }, -- Distracting Shot (Rank 2)
        [15629] = { parent = 20736, use_parent_icon = true }, -- Distracting Shot (Rank 3)
        [15630] = { parent = 20736, use_parent_icon = true }, -- Distracting Shot (Rank 4)
        [15631] = { parent = 20736, use_parent_icon = true }, -- Distracting Shot (Rank 5)
        [15632] = { parent = 20736, use_parent_icon = true }, -- Distracting Shot (Rank 6)
        [27020] = { parent = 20736, use_parent_icon = true }, -- Distracting Shot (Rank 7)

    [19263] = { -- Deterrence
        class = addon.HUNTER,
        cooldown = 300,
        category = category.DEFENSIVE,
        baseline = true,
    },

    [19386] = { -- Wyvern Sting (Rank 1)
        class = addon.HUNTER,
        cooldown = 120,
        category = category.OTHERS,
        spec = { specID.SURVIVAL },
        baseline = true,
    },
        [24132] = { parent = 19386, use_parent_icon = true }, -- Wyvern Sting (Rank 2)
        [24133] = { parent = 19386, use_parent_icon = true }, -- Wyvern Sting (Rank 3)
        [27068] = { parent = 19386, use_parent_icon = true }, -- Wyvern Sting (Rank 4)

    [19503] = { -- Scatter Shot
        class = addon.HUNTER,
        cooldown = 30,
        category = category.OTHERS,
        spec = { specID.SURVIVAL },
        baseline = true,
    },

    [19574] = { -- Bestial Wrath
        class = addon.HUNTER,
        cooldown = 120,
        duration = 18,
        category = category.BURST,
        spec = { specID.BEASTMASTERY },
        baseline = true,
    },

    [19577] = { -- Intimidation
        class = addon.HUNTER,
        cooldown = 60,
        category = category.OTHERS,
        spec = { specID.BEASTMASTERY },
        baseline = true,
    },

    [19801] = { -- Tranquilizing Shot
        class = addon.HUNTER,
        cooldown = 20,
        category = category.OTHERS,
        baseline = true,
    },

    [23989] = { -- Readiness
        class = addon.HUNTER,
        cooldown = 300,
        category = category.OTHERS,
        spec = { specID.MARKSMANSHIP },
        baseline = true,
    },

    [34477] = { -- Misdirection
        class = addon.HUNTER,
        cooldown = 120,
        category = category.OTHERS,
        baseline = true,
    },

    [34490] = { -- Silencing Shot
        class = addon.HUNTER,
        cooldown = 20,
        category = category.OTHERS,
        spec = { specID.MARKSMANSHIP },
        baseline = true,
    },

    [34600] = { -- Snake Trap
        class = addon.HUNTER,
        cooldown = 30,
        category = category.OTHERS,
        baseline = true,
    },

    -- Hunter Pets

    [7371] = { -- Charge (Rank 1)
        class = addon.HUNTER,
        cooldown = 25,
        category = category.OTHERS,
        baseline = true,
    },
        [26177] = { parent = 7371, use_parent_icon = true }, -- Charge (Rank 2)
        [26178] = { parent = 7371, use_parent_icon = true }, -- Charge (Rank 3)
        [26179] = { parent = 7371, use_parent_icon = true }, -- Charge (Rank 4)
        [26201] = { parent = 7371, use_parent_icon = true }, -- Charge (Rank 5)
        [27685] = { parent = 7371, use_parent_icon = true }, -- Charge (Rank 6)

    [17253] = { -- Bite (Rank 1)
        class = addon.HUNTER,
        cooldown = 10,
        category = category.OTHERS,
        baseline = true,
    },
        [17255] = { parent = 17253, use_parent_icon = true }, -- Bite (Rank 2)
        [17256] = { parent = 17253, use_parent_icon = true }, -- Bite (Rank 3)
        [17257] = { parent = 17253, use_parent_icon = true }, -- Bite (Rank 4)
        [17258] = { parent = 17253, use_parent_icon = true }, -- Bite (Rank 5)
        [17259] = { parent = 17253, use_parent_icon = true }, -- Bite (Rank 6)
        [17260] = { parent = 17253, use_parent_icon = true }, -- Bite (Rank 7)
        [17261] = { parent = 17253, use_parent_icon = true }, -- Bite (Rank 8)
        [27050] = { parent = 17253, use_parent_icon = true }, -- Bite (Rank 9)

    [23099] = { -- Dash (Rank 1)
        class = addon.HUNTER,
        cooldown = 30,
        category = category.OTHERS,
        baseline = true,
    },
        [23109] = { parent = 23099, use_parent_icon = true }, -- Dash (Rank 2)
        [23110] = { parent = 23099, use_parent_icon = true }, -- Dash (Rank 3)

    [23145] = { -- Dive (Rank 1)
        class = addon.HUNTER,
        cooldown = 30,
        category = category.OTHERS,
        baseline = true,
    },
        [23147] = { parent = 23145, use_parent_icon = true }, -- Dive (Rank 2)
        [23148] = { parent = 23145, use_parent_icon = true }, -- Dive (Rank 3)

    [24450] = { -- Prowl (Rank 1)
        class = addon.HUNTER,
        cooldown = 10,
        category = category.OTHERS,
        baseline = true,
    },
        [24452] = { parent = 24450, use_parent_icon = true }, -- Prowl (Rank 2)
        [24453] = { parent = 24450, use_parent_icon = true }, -- Prowl (Rank 3)

    [24604] = { -- Furious Howl (Rank 1)
        class = addon.HUNTER,
        cooldown = 10,
        category = category.OTHERS,
        baseline = true,
    },
        [24605] = { parent = 24604, use_parent_icon = true }, -- Furious Howl (Rank 2)
        [24603] = { parent = 24604, use_parent_icon = true }, -- Furious Howl (Rank 3)
        [24597] = { parent = 24604, use_parent_icon = true }, -- Furious Howl (Rank 4)

    [26064] = { -- Shell Shield
        class = addon.HUNTER,
        cooldown = 180,
        category = category.OTHERS,
        baseline = true,
    },

    [26090] = { -- Thunderstomp (Rank 1)
        class = addon.HUNTER,
        cooldown = 60,
        category = category.OTHERS,
        baseline = true,
    },
        [26187] = { parent = 26090, use_parent_icon = true }, -- Thunderstomp (Rank 2)
        [26188] = { parent = 26090, use_parent_icon = true }, -- Thunderstomp (Rank 3)
        [27063] = { parent = 26090, use_parent_icon = true }, -- Thunderstomp (Rank 4)

    [34889] = { -- Fire Breath (Rank 1)
        class = addon.HUNTER,
        cooldown = 10,
        category = category.OTHERS,
        baseline = true,
    },
        [35323] = { parent = 34889, use_parent_icon = true }, -- Fire Breath (Rank 2)

    [35346] = { -- Warp
        class = addon.HUNTER,
        cooldown = 15,
        category = category.OTHERS,
        baseline = true,
    },

    [35387] = { -- Poison Spit (Rank 1)
        class = addon.HUNTER,
        cooldown = 10,
        category = category.OTHERS,
        baseline = true,
    },
        [35389] = { parent = 35387, use_parent_icon = true }, -- Poison Spit (Rank 2)
        [35392] = { parent = 35387, use_parent_icon = true }, -- Poison Spit (Rank 3)

    -- Druid

    [740] = { -- Tranquility (Rank 1)
        class = addon.DRUID,
        cooldown = 600,
        category = category.OTHERS,
        baseline = true,
    },
        [8918] = { parent = 740, use_parent_icon = true }, -- Tranquility (Rank 2)
        [9862] = { parent = 740, use_parent_icon = true }, -- Tranquility (Rank 3)
        [9863] = { parent = 740, use_parent_icon = true }, -- Tranquility (Rank 4)
        [26983] = { parent = 740, use_parent_icon = true }, -- Tranquility (Rank 5)

    [1850] = { -- Dash (Rank 1)
        class = addon.DRUID,
        cooldown = 300,
        category = category.OTHERS,
        baseline = true,
    },
        [9821] = { parent = 1850, use_parent_icon = true }, -- Dash (Rank 2)
        [33357] = { parent = 1850, use_parent_icon = true }, -- Dash (Rank 3)

    [5209] = { -- Challenging Roar
        class = addon.DRUID,
        cooldown = 600,
        category = category.OTHERS,
        baseline = true,
    },

    [5211] = { -- Bash (Rank 1)
        class = addon.DRUID,
        cooldown = 60,
        category = category.OTHERS,
        baseline = true,
    },
        [6798] = { parent = 5211, use_parent_icon = true }, -- Bash (Rank 2)
        [8983] = { parent = 5211, use_parent_icon = true }, -- Bash (Rank 3)

    [5215] = { -- Prowl (Rank 1)
        class = addon.DRUID,
        cooldown = 10,
        category = category.OTHERS,
        baseline = true,
    },
        [6783] = { parent = 5215, use_parent_icon = true }, -- Prowl (Rank 2)
        [9913] = { parent = 5215, use_parent_icon = true }, -- Prowl (Rank 3)

    [5229] = { -- Enrage
        class = addon.DRUID,
        cooldown = 60,
        category = category.OTHERS,
        baseline = true,
    },

    [6795] = { -- Growl
        class = addon.DRUID,
        cooldown = 10,
        category = category.OTHERS,
        baseline = true,
    },

    [8998] = { -- Cower (Rank 1)
        class = addon.DRUID,
        cooldown = 10,
        category = category.OTHERS,
        baseline = true,
    },
        [9000] = { parent = 8998, use_parent_icon = true }, -- Cower (Rank 2)
        [9892] = { parent = 8998, use_parent_icon = true }, -- Cower (Rank 3)
        [31709] = { parent = 8998, use_parent_icon = true }, -- Cower (Rank 4)
        [27004] = { parent = 8998, use_parent_icon = true }, -- Cower (Rank 5)

    [16689] = { -- Nature's Grasp (Rank 1)
        class = addon.DRUID,
        cooldown = 60,
        category = category.OTHERS,
        baseline = true,
    },
        [16810] = { parent = 16689, use_parent_icon = true }, -- Nature's Grasp (Rank 2)
        [16811] = { parent = 16689, use_parent_icon = true }, -- Nature's Grasp (Rank 3)
        [16812] = { parent = 16689, use_parent_icon = true }, -- Nature's Grasp (Rank 4)
        [16813] = { parent = 16689, use_parent_icon = true }, -- Nature's Grasp (Rank 5)
        [17329] = { parent = 16689, use_parent_icon = true }, -- Nature's Grasp (Rank 6)
        [27009] = { parent = 16689, use_parent_icon = true }, -- Nature's Grasp (Rank 7)

    [16914] = { -- Hurricane (Rank 1)
        class = addon.DRUID,
        cooldown = 60,
        category = category.OTHERS,
        baseline = true,
    },
        [17401] = { parent = 16914, use_parent_icon = true }, -- Hurricane (Rank 2)
        [17402] = { parent = 16914, use_parent_icon = true }, -- Hurricane (Rank 3)
        [27012] = { parent = 16914, use_parent_icon = true }, -- Hurricane (Rank 4)

    [16979] = { -- Feral Charge
        class = addon.DRUID,
        cooldown = 15,
        category = category.INTERRUPT,
        spec = { specID.FERAL },
        baseline = true,
    },

    [17116] = { -- Nature's Swiftness
        class = addon.DRUID,
        cooldown = 180,
        category = category.OTHERS,
        spec = { specID.RESTORATION_DRUID },
        baseline = true,
    },

    [18562] = { -- Swiftmend
        class = addon.DRUID,
        cooldown = 15,
        category = category.OTHERS,
        spec = { specID.RESTORATION_DRUID },
        baseline = true,
    },

    [20484] = { -- Rebirth (Rank 1)
        class = addon.DRUID,
        cooldown = 1200,
        category = category.OTHERS,
        baseline = true,
    },
        [20739] = { parent = 20484, use_parent_icon = true }, -- Rebirth (Rank 2)
        [20742] = { parent = 20484, use_parent_icon = true }, -- Rebirth (Rank 3)
        [20747] = { parent = 20484, use_parent_icon = true }, -- Rebirth (Rank 4)
        [20748] = { parent = 20484, use_parent_icon = true }, -- Rebirth (Rank 5)
        [26994] = { parent = 20484, use_parent_icon = true }, -- Rebirth (Rank 6)

    [22812] = { -- Barkskin
        class = addon.DRUID,
        cooldown = 60,
        category = category.DEFENSIVE,
        baseline = true,
    },

    [22842] = { -- Frenzied Regeneration (Rank 1)
        class = addon.DRUID,
        cooldown = 180,
        category = category.DEFENSIVE,
        baseline = true,
    },
        [22895] = { parent = 22842, use_parent_icon = true }, -- Frenzied Regeneration (Rank 2)
        [22896] = { parent = 22842, use_parent_icon = true }, -- Frenzied Regeneration (Rank 3)
        [26999] = { parent = 22842, use_parent_icon = true }, -- Frenzied Regeneration (Rank 4)

    [29166] = { -- Innervate
        class = addon.DRUID,
        cooldown = 360,
        category = category.OTHERS,
        baseline = true,
    },

    [33831] = { -- Force of Nature
        class = addon.DRUID,
        cooldown = 180,
        category = category.OTHERS,
        spec = { specID.BALANCE },
        baseline = true,
    },

    -- Mage

    [27103] = { -- Mana Gem
        class = addon.MAGE,
        cooldown = 120,
        category = category.OTHERS,
        baseline = true,
    },

    [66] = { -- Invisibility
        class = addon.MAGE,
        cooldown = 300,
        category = category.OTHERS,
        baseline = true,
    },

    [120] = { -- Cone of Cold (Rank 1)
        class = addon.MAGE,
        cooldown = 8,
        opt_lower_cooldown = 6,
        category = category.OTHERS,
        baseline = true,
    },
        [8492] = { parent = 120, use_parent_icon = true }, -- Cone of Cold (Rank 2)
        [10159] = { parent = 120, use_parent_icon = true }, -- Cone of Cold (Rank 3)
        [10160] = { parent = 120, use_parent_icon = true }, -- Cone of Cold (Rank 4)
        [10161] = { parent = 120, use_parent_icon = true }, -- Cone of Cold (Rank 5)
        [27087] = { parent = 120, use_parent_icon = true }, -- Cone of Cold (Rank 6)

    [122] = { -- Frost Nova (Rank 1)
        class = addon.MAGE,
        cooldown = 21,
        category = category.OTHERS,
        baseline = true,
    },
        [865] = { parent = 122, use_parent_icon = true }, -- Frost Nova (Rank 2)
        [6131] = { parent = 122, use_parent_icon = true }, -- Frost Nova (Rank 3)
        [10230] = { parent = 122, use_parent_icon = true }, -- Frost Nova (Rank 4)
        [27088] = { parent = 122, use_parent_icon = true }, -- Frost Nova (Rank 5)

    [543] = { -- Fire Ward (Rank 1)
        class = addon.MAGE,
        cooldown = 30,
        category = category.OTHERS,
        baseline = true,
    },
        [8457] = { parent = 543, use_parent_icon = true }, -- Fire Ward (Rank 2)
        [8458] = { parent = 543, use_parent_icon = true }, -- Fire Ward (Rank 3)
        [10223] = { parent = 543, use_parent_icon = true }, -- Fire Ward (Rank 4)
        [10225] = { parent = 543, use_parent_icon = true }, -- Fire Ward (Rank 5)
        [27128] = { parent = 543, use_parent_icon = true }, -- Fire Ward (Rank 6)

    [1953] = { -- Blink
        class = addon.MAGE,
        cooldown = 13,
        category = category.OTHERS,
        baseline = true,
    },

    [2136] = { -- Fire Blast (Rank 1)
        class = addon.MAGE,
        cooldown = 8,
        category = category.OTHERS,
        baseline = true,
    },
        [2137] = { parent = 2136, use_parent_icon = true }, -- Fire Blast (Rank 2)
        [2138] = { parent = 2136, use_parent_icon = true }, -- Fire Blast (Rank 3)
        [8412] = { parent = 2136, use_parent_icon = true }, -- Fire Blast (Rank 4)
        [8413] = { parent = 2136, use_parent_icon = true }, -- Fire Blast (Rank 5)
        [10197] = { parent = 2136, use_parent_icon = true }, -- Fire Blast (Rank 6)
        [10199] = { parent = 2136, use_parent_icon = true }, -- Fire Blast (Rank 7)
        [27078] = { parent = 2136, use_parent_icon = true }, -- Fire Blast (Rank 8)
        [27079] = { parent = 2136, use_parent_icon = true }, -- Fire Blast (Rank 9)

    [2139] = { -- Counterspell
        class = addon.MAGE,
        cooldown = 24,
        category = category.INTERRUPT,
        baseline = true,
    },

    [6143] = { -- Frost Ward (Rank 1)
        class = addon.MAGE,
        cooldown = 30,
        category = category.OTHERS,
        baseline = true,
    },
        [8461] = { parent = 6143, use_parent_icon = true }, -- Frost Ward (Rank 2)
        [8462] = { parent = 6143, use_parent_icon = true }, -- Frost Ward (Rank 3)
        [10177] = { parent = 6143, use_parent_icon = true }, -- Frost Ward (Rank 4)
        [28609] = { parent = 6143, use_parent_icon = true }, -- Frost Ward (Rank 5)
        [32796] = { parent = 6143, use_parent_icon = true }, -- Frost Ward (Rank 6)

    [11113] = { -- Blast Wave (Rank 1)
        class = addon.MAGE,
        cooldown = 30,
        category = category.OTHERS,
        spec = { specID.FIRE },
        baseline = true,
    },
        [13018] = { parent = 11113, use_parent_icon = true }, -- Blast Wave (Rank 2)
        [13019] = { parent = 11113, use_parent_icon = true }, -- Blast Wave (Rank 3)
        [13020] = { parent = 11113, use_parent_icon = true }, -- Blast Wave (Rank 4)
        [13021] = { parent = 11113, use_parent_icon = true }, -- Blast Wave (Rank 5)
        [27133] = { parent = 11113, use_parent_icon = true }, -- Blast Wave (Rank 6)
        [33933] = { parent = 11113, use_parent_icon = true }, -- Blast Wave (Rank 7)

    [11129] = { -- Combustion
        class = addon.MAGE,
        cooldown = 180,
        category = category.BURST,
        spec = { specID.FIRE },
        baseline = true,
    },

    [11426] = { -- Ice Barrier (Rank 1)
        class = addon.MAGE,
        cooldown = 30,
        opt_lower_cooldown = 24,
        category = category.DEFENSIVE,
        spec = { specID.FROST_MAGE },
        baseline = true,
    },
        [13031] = { parent = 11426, use_parent_icon = true }, -- Ice Barrier (Rank 2)
        [13032] = { parent = 11426, use_parent_icon = true }, -- Ice Barrier (Rank 3)
        [13033] = { parent = 11426, use_parent_icon = true }, -- Ice Barrier (Rank 4)
        [27134] = { parent = 11426, use_parent_icon = true }, -- Ice Barrier (Rank 5)
        [33405] = { parent = 11426, use_parent_icon = true }, -- Ice Barrier (Rank 6)

    [11958] = { -- Cold Snap
        class = addon.MAGE,
        cooldown = 480,
        opt_lower_cooldown = 384,
        category = category.OTHERS,
        spec = { specID.FROST_MAGE },
        baseline = true,
    },

    [12042] = { -- Arcane Power
        class = addon.MAGE,
        cooldown = 180,
        duration = 15,
        category = category.BURST,
        spec = { specID.ARCANE },
        baseline = true,
    },

    [12043] = { -- Presence of Mind
        class = addon.MAGE,
        cooldown = 180,
        category = category.BURST,
        spec = { specID.ARCANE },
        baseline = true,
    },

    [12051] = { -- Evocation
        class = addon.MAGE,
        cooldown = 480,
        category = category.OTHERS,
        baseline = true,
    },

    [12472] = { -- Icy Veins
        class = addon.MAGE,
        cooldown = 180,
        duration = 20,
        category = category.BURST,
        spec = { specID.FROST_MAGE },
        baseline = true,
    },

    [31661] = { -- Dragon's Breath (Rank 1)
        class = addon.MAGE,
        cooldown = 20,
        category = category.OTHERS,
        spec = { specID.FIRE },
        baseline = true,
    },
        [33041] = { parent = 31661, use_parent_icon = true }, -- Dragon's Breath (Rank 2)
        [33042] = { parent = 31661, use_parent_icon = true }, -- Dragon's Breath (Rank 3)
        [33043] = { parent = 31661, use_parent_icon = true }, -- Dragon's Breath (Rank 4)

    [31687] = { -- Summon Water Elemental
        class = addon.MAGE,
        cooldown = 180,
        category = category.OTHERS,
        spec = { specID.FROST_MAGE },
        baseline = true,
    },

    [33395] = { -- Freeze (Water Elemental)
        class = addon.MAGE,
        cooldown = 25,
        category = category.OTHERS,
        spec = { specID.FROST_MAGE },
        baseline = true,
    },

    [43987] = { -- Ritual of Refreshment
        class = addon.MAGE,
        cooldown = 300,
        category = category.OTHERS,
        baseline = true,
    },

    [45438] = { -- Ice Block
        class = addon.MAGE,
        cooldown = 300,
        opt_lower_cooldown = 240,
        category = category.DEFENSIVE,
        baseline = true,
    },

    -- Rogue

    [408] = { -- Kidney Shot (Rank 1)
        class = addon.ROGUE,
        cooldown = 20,
        category = category.OTHERS,
        baseline = true,
    },
        [8643] = { parent = 408, use_parent_icon = true }, -- Kidney Shot (Rank 2)

    [1725] = { -- Distract
        class = addon.ROGUE,
        cooldown = 30,
        category = category.OTHERS,
        baseline = true,
    },

    [1766] = { -- Kick (Rank 1)
        class = addon.ROGUE,
        cooldown = 10,
        category = category.INTERRUPT,
        baseline = true,
    },
        [1767] = { parent = 1766, use_parent_icon = true }, -- Kick (Rank 2)
        [1768] = { parent = 1766, use_parent_icon = true }, -- Kick (Rank 3)
        [1769] = { parent = 1766, use_parent_icon = true }, -- Kick (Rank 4)
        [38768] = { parent = 1766, use_parent_icon = true }, -- Kick (Rank 5)

    [1776] = { -- Gouge (Rank 1)
        class = addon.ROGUE,
        cooldown = 10,
        category = category.OTHERS,
        baseline = true,
    },
        [1777] = { parent = 1776, use_parent_icon = true }, -- Gouge (Rank 2)
        [8629] = { parent = 1776, use_parent_icon = true }, -- Gouge (Rank 3)
        [11285] = { parent = 1776, use_parent_icon = true }, -- Gouge (Rank 4)
        [11286] = { parent = 1776, use_parent_icon = true }, -- Gouge (Rank 5)
        [38764] = { parent = 1776, use_parent_icon = true }, -- Gouge (Rank 6)

    [1784] = { -- Stealth (Rank 1)
        class = addon.ROGUE,
        cooldown = 10,
        category = category.OTHERS,
        baseline = true,
    },
        [1785] = { parent = 1784, use_parent_icon = true }, -- Stealth (Rank 2)
        [1786] = { parent = 1784, use_parent_icon = true }, -- Stealth (Rank 3)
        [1787] = { parent = 1784, use_parent_icon = true }, -- Stealth (Rank 4)

    [1856] = { -- Vanish (Rank 1)
        class = addon.ROGUE,
        cooldown = 210, -- Baseline 300s, Elusiveness -90s
        category = category.OTHERS,
        baseline = true,
    },
        [1857] = { parent = 1856, use_parent_icon = true }, -- Vanish (Rank 2)
        [26889] = { parent = 1856, use_parent_icon = true }, -- Vanish (Rank 3)

    [1966] = { -- Feint (Rank 1)
        class = addon.ROGUE,
        cooldown = 10,
        category = category.OTHERS,
        baseline = true,
    },
        [6768] = { parent = 1966, use_parent_icon = true }, -- Feint (Rank 2)
        [8637] = { parent = 1966, use_parent_icon = true }, -- Feint (Rank 3)
        [11303] = { parent = 1966, use_parent_icon = true }, -- Feint (Rank 4)
        [25302] = { parent = 1966, use_parent_icon = true }, -- Feint (Rank 5)
        [27448] = { parent = 1966, use_parent_icon = true }, -- Feint (Rank 6)

    [2094] = { -- Blind
        class = addon.ROGUE,
        cooldown = 90, -- Baseline 180s, Elusiveness -90s
        category = category.OTHERS,
        baseline = true,
    },

    [2983] = { -- Sprint (Rank 1)
        class = addon.ROGUE,
        cooldown = 300,
        category = category.OTHERS,
        baseline = true,
    },
        [8696] = { parent = 2983, use_parent_icon = true }, -- Sprint (Rank 2)
        [11305] = { parent = 2983, use_parent_icon = true }, -- Sprint (Rank 3)

    [5277] = { -- Evasion (Rank 1)
        class = addon.ROGUE,
        cooldown = 300,
        category = category.DEFENSIVE,
        baseline = true,
    },
        [26669] = { parent = 5277, use_parent_icon = true }, -- Evasion (Rank 2)

    [13750] = { -- Adrenaline Rush
        class = addon.ROGUE,
        cooldown = 300,
        duration = 15,
        category = category.BURST,
        spec = { specID.OUTLAW },
        baseline = true,
    },

    [13877] = { -- Blade Flurry
        class = addon.ROGUE,
        cooldown = 120,
        duration = 15,
        category = category.BURST,
        spec = { specID.OUTLAW },
        baseline = true,
    },

    [14177] = { -- Cold Blood
        class = addon.ROGUE,
        cooldown = 180,
        category = category.BURST,
        spec = { specID.ASSASSINATION },
        baseline = true,
    },

    [14183] = { -- Premeditation
        class = addon.ROGUE,
        cooldown = 120,
        category = category.OTHERS,
        spec = { specID.SUBTLETY },
        baseline = true,
    },

    [14185] = { -- Preparation
        class = addon.ROGUE,
        cooldown = 600,
        category = category.OTHERS,
        spec = { specID.SUBTLETY },
        baseline = true,
    },

    [14278] = { -- Ghostly Strike
        class = addon.ROGUE,
        cooldown = 20,
        category = category.OTHERS,
        spec = { specID.SUBTLETY },
        baseline = true,
    },

    [31224] = { -- Cloak of Shadows
        class = addon.ROGUE,
        cooldown = 60,
        category = category.DEFENSIVE,
        baseline = true,
    },

    [36554] = { -- Shadowstep
        class = addon.ROGUE,
        cooldown = 30,
        category = category.OTHERS,
        spec = { specID.SUBTLETY },
        baseline = true,
    },

    -- Warrior

    [12294] = { -- Mortal Strike (Rank 1)
        class = addon.WARRIOR,
        cooldown = 6,
        category = category.OTHERS,
        spec = { specID.ARMS },
        baseline = true,
    },
        [21551] = { parent = 12294, use_parent_icon = true }, -- Mortal Strike (Rank 2)
        [21552] = { parent = 12294, use_parent_icon = true }, -- Mortal Strike (Rank 3)
        [21553] = { parent = 12294, use_parent_icon = true }, -- Mortal Strike (Rank 4)
        [25248] = { parent = 12294, use_parent_icon = true }, -- Mortal Strike (Rank 5)
        [30330] = { parent = 12294, use_parent_icon = true }, -- Mortal Strike (Rank 6)


    [100] = { -- Charge (Rank 1)
        class = addon.WARRIOR,
        cooldown = 15,
        category = category.OTHERS,
        baseline = true,
    },
        [6178] = { parent = 100, use_parent_icon = true }, -- Charge (Rank 2)
        [11578] = { parent = 100, use_parent_icon = true }, -- Charge (Rank 3)

    [355] = { -- Taunt
        class = addon.WARRIOR,
        cooldown = 10,
        category = category.OTHERS,
        baseline = true,
    },

    [676] = { -- Disarm
        class = addon.WARRIOR,
        cooldown = 60,
        category = category.OTHERS,
        baseline = true,
    },

    [694] = { -- Mocking Blow (Rank 1)
        class = addon.WARRIOR,
        cooldown = 120,
        category = category.OTHERS,
        baseline = true,
    },
        [7400] = { parent = 694, use_parent_icon = true }, -- Mocking Blow (Rank 2)
        [7402] = { parent = 694, use_parent_icon = true }, -- Mocking Blow (Rank 3)
        [20559] = { parent = 694, use_parent_icon = true }, -- Mocking Blow (Rank 4)
        [20560] = { parent = 694, use_parent_icon = true }, -- Mocking Blow (Rank 5)
        [25266] = { parent = 694, use_parent_icon = true }, -- Mocking Blow (Rank 6)

    [871] = { -- Shield Wall
        class = addon.WARRIOR,
        cooldown = 1800,
        category = category.DEFENSIVE,
        baseline = true,
    },

    [1161] = { -- Challenging Shout
        class = addon.WARRIOR,
        cooldown = 600,
        category = category.OTHERS,
        baseline = true,
    },

    [1680] = { -- Whirlwind
        class = addon.WARRIOR,
        cooldown = 10,
        category = category.OTHERS,
        baseline = true,
    },

    [1719] = { -- Recklessness
        class = addon.WARRIOR,
        cooldown = 1800,
        category = category.OTHERS,
        baseline = true,
    },

    [2687] = { -- Bloodrage
        class = addon.WARRIOR,
        cooldown = 60,
        category = category.OTHERS,
        baseline = true,
    },

    [3411] = { -- Intervene
        class = addon.WARRIOR,
        cooldown = 30,
        category = category.OTHERS,
        baseline = true,
    },

    [5246] = { -- Intimidating Shout
        class = addon.WARRIOR,
        cooldown = 180,
        category = category.OTHERS,
        baseline = true,
    },

    [6552] = { -- Pummel (Rank 1)
        class = addon.WARRIOR,
        cooldown = 10,
        category = category.INTERRUPT,
        baseline = true,
    },
        [6554] = { parent = 6552, use_parent_icon = true }, -- Pummel (Rank 2)
        [72] = { parent = 6552, cooldown = 12, use_parent_icon = true }, -- Shield Bash (Rank 1)
        [1671] = { parent = 6552, cooldown = 12, use_parent_icon = true }, -- Shield Bash (Rank 2)
        [1672] = { parent = 6552, cooldown = 12, use_parent_icon = true }, -- Shield Bash (Rank 3)
        [29704] = { parent = 6552, cooldown = 12, use_parent_icon = true }, -- Shield Bash (Rank 4)

    [12292] = { -- Death Wish
        class = addon.WARRIOR,
        cooldown = 180,
        category = category.OTHERS,
        spec = { specID.ARMS },
        baseline = true,
    },

    [12328] = { -- Sweeping Strikes
        class = addon.WARRIOR,
        cooldown = 30,
        category = category.OTHERS,
        spec = { specID.ARMS },
        baseline = true,
    },

    [12809] = { -- Concussion Blow
        class = addon.WARRIOR,
        cooldown = 45,
        category = category.OTHERS,
        spec = { specID.PROTECTION_WARRIOR },
        baseline = true,
    },

    [12975] = { -- Last Stand
        class = addon.WARRIOR,
        cooldown = 480,
        category = category.DEFENSIVE,
        spec = { specID.PROTECTION_WARRIOR },
        baseline = true,
    },

    [18499] = { -- Berserker Rage
        class = addon.WARRIOR,
        cooldown = 30,
        category = category.OTHERS,
        baseline = true,
    },

    [20230] = { -- Retaliation
        class = addon.WARRIOR,
        cooldown = 1800,
        category = category.OTHERS,
        baseline = true,
    },

    [20252] = { -- Intercept (Rank 1)
        class = addon.WARRIOR,
        cooldown = 15,
        category = category.OTHERS,
        baseline = true,
    },
        [20616] = { parent = 20252, use_parent_icon = true }, -- Intercept (Rank 2)
        [20617] = { parent = 20252, use_parent_icon = true }, -- Intercept (Rank 3)
        [25272] = { parent = 20252, use_parent_icon = true }, -- Intercept (Rank 4)
        [25275] = { parent = 20252, use_parent_icon = true }, -- Intercept (Rank 5)

    [23920] = { -- Spell Reflection
        class = addon.WARRIOR,
        cooldown = 10,
        category = category.DEFENSIVE,
        baseline = true,
    },

};

addon.SpellResets = {
    -- Cold Snap
    [11958] = {
        11426, -- Ice Barrier
        6143, -- Frost Ward
        122, -- Frost Nova
        45438, -- Ice Block
        12472, -- Icy Veins
        31687, -- Summon Water Elemental
    },

    -- Preparation
    [14185] = {
        5277, -- Evasion
        2983, -- Sprint
        1856, -- Vanish
        14177, -- Cold Blood
        36554, -- Shadowstep
        14183, -- Premeditation
    },

    -- Summon Felhunter
    [691] = {
        19244, -- Spell Lock
    },
};

for _, spell in pairs(addon.SpellData) do
    if spell.category == category.BURST and ( not spell.duration ) then
        spell.duration = 3;
    end
end

for _, spell in pairs(addon.SpellData) do
    if spell.parent then
        local parent = addon.SpellData[spell.parent];

        spell.cooldown = spell.cooldown or parent.cooldown;
        spell.duration = spell.duration or parent.duration;
        spell.class = spell.class or parent.class;
        spell.spec = spell.spec or parent.spec;
        spell.category = spell.category or parent.category;
        spell.trackPet = spell.trackPet or parent.trackPet;
        spell.trackEvent = spell.trackEvent or parent.trackEvent;
        spell.baseline = spell.baseline or parent.baseline;
        spell.index = spell.index or parent.index;
        spell.default = spell.default or parent.default;
    end
end

addon.SpellResetsAffectedByApotheosis = {}; -- Dummy value to not error out

-- Spec inference for TBC (the client exposes no enemy spec): a spell cast or an aura a unit
-- carries can pin down its talent build, which the arena cooldown tracker uses to pre-show
-- that unit's spec cooldowns once revealed. Two sources feed addon.SpecDetection:
--   1. The extra tells listed here -- auras/forms and rotational abilities that aren't
--      themselves tracked cooldowns.
--   2. Every single-spec cooldown from addon.SpellData, folded in by the loop below so a
--      spell that is already tracked never has to be repeated.
-- Spec IDs are addon.SPECID; the TBC "Combat" rogue tree maps to OUTLAW.
addon.SpecDetection = {};
local function AddSpecDetection(spellIDs, spec)
    for _, id in ipairs(spellIDs) do
        addon.SpecDetection[id] = spec;
    end
end

-- Druid
AddSpecDetection({16880, 16886}, specID.BALANCE); -- Nature's Grace
AddSpecDetection({24858}, specID.BALANCE); -- Moonkin Form
AddSpecDetection({17007}, specID.FERAL); -- Leader of the Pack
AddSpecDetection({33876, 33983, 33982}, specID.FERAL); -- Mangle (Cat)
AddSpecDetection({33986, 33878, 33987}, specID.FERAL); -- Mangle (Bear)
AddSpecDetection({33883, 33881, 33882}, specID.RESTORATION_DRUID); -- Natural Perfection
AddSpecDetection({33891}, specID.RESTORATION_DRUID); -- Tree of Life

-- Hunter
AddSpecDetection({34471, 34692}, specID.BEASTMASTERY); -- The Beast Within
AddSpecDetection({20895, 19578}, specID.BEASTMASTERY); -- Spirit Bond
AddSpecDetection({34460, 34455, 34459}, specID.BEASTMASTERY); -- Ferocious Inspiration
AddSpecDetection({27066}, specID.MARKSMANSHIP); -- Trueshot Aura
AddSpecDetection({34502, 34500, 34503, 34501}, specID.SURVIVAL); -- Expose Weakness
AddSpecDetection({24134, 24132, 19386, 24135, 27069, 24133, 24131, 27068}, specID.SURVIVAL); -- Wyvern Sting
AddSpecDetection({20909, 19306, 27067, 20910}, specID.SURVIVAL); -- Counterattack

-- Mage
AddSpecDetection({31589}, specID.ARCANE); -- Slow
AddSpecDetection({31570, 31569}, specID.ARCANE); -- Improved Blink

-- Paladin
AddSpecDetection({31836, 31834, 31833, 31835}, specID.HOLY_PALADIN); -- Light's Grace
AddSpecDetection({33073, 33072, 27175, 25914, 33074, 25903, 20930, 25911, 25902, 25913, 25912, 20473, 27174, 20929, 27176}, specID.HOLY_PALADIN); -- Holy Shock
AddSpecDetection({27170}, specID.RETRIBUTION); -- Seal of Command
AddSpecDetection({20049}, specID.RETRIBUTION); -- Vengeance
AddSpecDetection({20218}, specID.RETRIBUTION); -- Sanctity Aura
AddSpecDetection({26017, 26018, 67, 26016, 9452, 26021}, specID.RETRIBUTION); -- Vindication
AddSpecDetection({35395}, specID.RETRIBUTION); -- Crusader Strike

-- Priest
AddSpecDetection({33206, 44416}, specID.DISCIPLINE); -- Pain Suppression
AddSpecDetection({14818, 27841, 14819, 25312, 14752}, specID.DISCIPLINE); -- Divine Spirit
AddSpecDetection({32999, 27681}, specID.DISCIPLINE); -- Prayer of Spirit
AddSpecDetection({45241, 45244, 45237, 45243, 45242, 45234}, specID.DISCIPLINE); -- Focused Will
AddSpecDetection({27811, 27816, 27815, 27813, 27818, 27817}, specID.DISCIPLINE); -- Blessed Recovery
AddSpecDetection({14893}, specID.DISCIPLINE); -- Inspiration
AddSpecDetection({33146, 33143, 33142, 33145}, specID.HOLY_PRIEST); -- Blessed Resilience
AddSpecDetection({34865, 34861, 34866, 34863, 34864}, specID.HOLY_PRIEST); -- Circle of Healing
AddSpecDetection({15473}, specID.SHADOW); -- Shadowform
AddSpecDetection({34916, 34917, 34914, 34919}, specID.SHADOW); -- Vampiric Touch

-- Rogue
AddSpecDetection({34411, 34413, 34412, 1329}, specID.ASSASSINATION); -- Mutilate
AddSpecDetection({31240, 31237, 31238, 31241, 31233, 31236, 31242, 31235, 31239, 31234}, specID.ASSASSINATION); -- Find Weakness
AddSpecDetection({26864, 17348, 16511, 17347}, specID.SUBTLETY); -- Hemorrhage
AddSpecDetection({36554, 44373, 36563}, specID.SUBTLETY); -- Shadowstep

-- Shaman
AddSpecDetection({30708, 30706}, specID.ELEMENTAL); -- Totem of Wrath
AddSpecDetection({30809, 30805, 30802, 30808, 30807, 30810, 30804, 30811, 30806, 30803}, specID.ENHANCEMENT); -- Unleashed Rage
AddSpecDetection({16280}, specID.ENHANCEMENT); -- Flurry
AddSpecDetection({30824, 30823}, specID.ENHANCEMENT); -- Shamanistic Rage
AddSpecDetection({32176, 17364, 32175}, specID.ENHANCEMENT); -- Stormstrike
AddSpecDetection({32593, 974, 32594, 379}, specID.RESTORATION_SHAMAN); -- Earth Shield
AddSpecDetection({29205, 29206, 29202, 29203}, specID.RESTORATION_SHAMAN); -- Healing Way

-- Warlock
AddSpecDetection({30108, 31117, 30404, 30405}, specID.AFFLICTION); -- Unstable Affliction
AddSpecDetection({18220, 27265, 18937, 18938}, specID.AFFLICTION); -- Dark Pact
AddSpecDetection({19028}, specID.DEMONOLOGY); -- Soul Link
AddSpecDetection({35693, 35691, 35692}, specID.DEMONOLOGY); -- Demonic Knowledge
AddSpecDetection({23842, 23839, 35706, 23829, 23761, 23826, 23822, 35705, 23835, 23825, 23838, 23841, 23827, 35702, 23828, 35704, 23824, 35703, 23844, 23843, 23840, 23823, 23836, 23785, 23833, 23762, 23760, 23759, 23834, 23837}, specID.DEMONOLOGY); -- Master Demonologist
AddSpecDetection({30301, 30302, 30300, 30299}, specID.DESTRUCTION); -- Nether Protection
AddSpecDetection({34936, 34939, 34938, 34935}, specID.DESTRUCTION); -- Backlash

-- Warrior
AddSpecDetection({29841, 29834, 29838, 29842}, specID.ARMS); -- Second Wind
AddSpecDetection({30335, 23881, 25253, 23885, 23890, 23886, 25252, 23889, 30339, 23893, 23887, 30340, 23894, 23880, 23888, 25251, 23891, 23892}, specID.FURY); -- Bloodthirst
AddSpecDetection({20243, 30016, 30022}, specID.PROTECTION_WARRIOR); -- Devastate
AddSpecDetection({23923, 23925, 23924, 30356, 23922, 25258}, specID.PROTECTION_WARRIOR); -- Shield Slam

-- Fold in tracked spec cooldowns (and their ranks) straight from their SpellData spec tags,
-- so a spell that is already a tracked cooldown never has to be repeated above.
for id, spell in pairs(addon.SpellData) do
    if spell.spec and ( #spell.spec == 1 ) and ( addon.SpecDetection[id] == nil ) then
        addon.SpecDetection[id] = spell.spec[1];
    end
end
