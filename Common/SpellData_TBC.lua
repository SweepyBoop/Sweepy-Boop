local _, addon = ...;

local POWERTYPE = Enum.PowerType;
local specID = addon.SPECID;
local category = addon.SPELLCATEGORY;

addon.SpellData = {
    -- Priest

    [17] = { -- Power Word: Shield (Rank 1)
        class = addon.PRIEST,
        cooldown = 4,
        category = category.OTHERS,
    },
        [592] = { parent = 17 }, -- Power Word: Shield (Rank 2)
        [600] = { parent = 17 }, -- Power Word: Shield (Rank 3)
        [3747] = { parent = 17 }, -- Power Word: Shield (Rank 4)
        [6065] = { parent = 17 }, -- Power Word: Shield (Rank 5)
        [6066] = { parent = 17 }, -- Power Word: Shield (Rank 6)
        [10898] = { parent = 17 }, -- Power Word: Shield (Rank 7)
        [10899] = { parent = 17 }, -- Power Word: Shield (Rank 8)
        [10900] = { parent = 17 }, -- Power Word: Shield (Rank 9)
        [10901] = { parent = 17 }, -- Power Word: Shield (Rank 10)
        [25217] = { parent = 17 }, -- Power Word: Shield (Rank 11)
        [25218] = { parent = 17 }, -- Power Word: Shield (Rank 12)

    [586] = { -- Fade (Rank 1)
        class = addon.PRIEST,
        cooldown = 30,
        category = category.OTHERS,
    },
        [9578] = { parent = 586 }, -- Fade (Rank 2)
        [9579] = { parent = 586 }, -- Fade (Rank 3)
        [9592] = { parent = 586 }, -- Fade (Rank 4)
        [10941] = { parent = 586 }, -- Fade (Rank 5)
        [10942] = { parent = 586 }, -- Fade (Rank 6)
        [25429] = { parent = 586 }, -- Fade (Rank 7)

    [724] = { -- Lightwell (Rank 1)
        class = addon.PRIEST,
        cooldown = 360,
        category = category.OTHERS,
    },
        [27870] = { parent = 724 }, -- Lightwell (Rank 2)
        [27871] = { parent = 724 }, -- Lightwell (Rank 3)
        [28275] = { parent = 724 }, -- Lightwell (Rank 4)

    [2651] = { -- Elune's Grace
        class = addon.PRIEST,
        cooldown = 180,
        category = category.OTHERS,
    },

    [2944] = { -- Devouring Plague (Rank 1)
        class = addon.PRIEST,
        cooldown = 180,
        category = category.OTHERS,
    },
        [19276] = { parent = 2944 }, -- Devouring Plague (Rank 2)
        [19277] = { parent = 2944 }, -- Devouring Plague (Rank 3)
        [19278] = { parent = 2944 }, -- Devouring Plague (Rank 4)
        [19279] = { parent = 2944 }, -- Devouring Plague (Rank 5)
        [19280] = { parent = 2944 }, -- Devouring Plague (Rank 6)
        [25467] = { parent = 2944 }, -- Devouring Plague (Rank 7)

    [6346] = { -- Fear Ward
        class = addon.PRIEST,
        cooldown = 180,
        category = category.OTHERS,
    },

    [8092] = { -- Mind Blast (Rank 1)
        class = addon.PRIEST,
        cooldown = 8,
        category = category.OTHERS,
    },
        [8102] = { parent = 8092 }, -- Mind Blast (Rank 2)
        [8103] = { parent = 8092 }, -- Mind Blast (Rank 3)
        [8104] = { parent = 8092 }, -- Mind Blast (Rank 4)
        [8105] = { parent = 8092 }, -- Mind Blast (Rank 5)
        [8106] = { parent = 8092 }, -- Mind Blast (Rank 6)
        [10945] = { parent = 8092 }, -- Mind Blast (Rank 7)
        [10946] = { parent = 8092 }, -- Mind Blast (Rank 8)
        [10947] = { parent = 8092 }, -- Mind Blast (Rank 9)
        [25372] = { parent = 8092 }, -- Mind Blast (Rank 10)
        [25375] = { parent = 8092 }, -- Mind Blast (Rank 11)

    [8122] = { -- Psychic Scream (Rank 1)
        class = addon.PRIEST,
        cooldown = 30,
        category = category.OTHERS,
    },
        [8124] = { parent = 8122 }, -- Psychic Scream (Rank 2)
        [10888] = { parent = 8122 }, -- Psychic Scream (Rank 3)
        [10890] = { parent = 8122 }, -- Psychic Scream (Rank 4)

    [10060] = { -- Power Infusion
        class = addon.PRIEST,
        cooldown = 180,
        category = category.OTHERS,
    },

    [10797] = { -- Starshards (Rank 1)
        class = addon.PRIEST,
        cooldown = 30,
        category = category.OTHERS,
    },
        [19296] = { parent = 10797 }, -- Starshards (Rank 2)
        [19299] = { parent = 10797 }, -- Starshards (Rank 3)
        [19302] = { parent = 10797 }, -- Starshards (Rank 4)
        [19303] = { parent = 10797 }, -- Starshards (Rank 5)
        [19304] = { parent = 10797 }, -- Starshards (Rank 6)
        [19305] = { parent = 10797 }, -- Starshards (Rank 7)
        [25446] = { parent = 10797 }, -- Starshards (Rank 8)

    [13896] = { -- Feedback (Rank 1)
        class = addon.PRIEST,
        cooldown = 180,
        category = category.OTHERS,
    },
        [19271] = { parent = 13896 }, -- Feedback (Rank 2)
        [19273] = { parent = 13896 }, -- Feedback (Rank 3)
        [19274] = { parent = 13896 }, -- Feedback (Rank 4)
        [19275] = { parent = 13896 }, -- Feedback (Rank 5)
        [25441] = { parent = 13896 }, -- Feedback (Rank 6)

    [13908] = { -- Desperate Prayer (Rank 1)
        class = addon.PRIEST,
        cooldown = 600,
        category = category.OTHERS,
    },
        [19236] = { parent = 13908 }, -- Desperate Prayer (Rank 2)
        [19238] = { parent = 13908 }, -- Desperate Prayer (Rank 3)
        [19240] = { parent = 13908 }, -- Desperate Prayer (Rank 4)
        [19241] = { parent = 13908 }, -- Desperate Prayer (Rank 5)
        [19242] = { parent = 13908 }, -- Desperate Prayer (Rank 6)
        [19243] = { parent = 13908 }, -- Desperate Prayer (Rank 7)
        [25437] = { parent = 13908 }, -- Desperate Prayer (Rank 8)

    [14751] = { -- Inner Focus
        class = addon.PRIEST,
        cooldown = 180,
        category = category.OTHERS,
    },

    [15286] = { -- Vampiric Embrace
        class = addon.PRIEST,
        cooldown = 10,
        category = category.OTHERS,
    },

    [15473] = { -- Shadowform
        class = addon.PRIEST,
        cooldown = 1,
        category = category.OTHERS,
    },

    [15487] = { -- Silence
        class = addon.PRIEST,
        cooldown = 45,
        category = category.OTHERS,
    },

    [32379] = { -- Shadow Word: Death (Rank 1)
        class = addon.PRIEST,
        cooldown = 12,
        category = category.OTHERS,
    },
        [32996] = { parent = 32379 }, -- Shadow Word: Death (Rank 2)

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
    },

    [33206] = { -- Pain Suppression
        class = addon.PRIEST,
        cooldown = 120,
        category = category.OTHERS,
    },

    [34433] = { -- Shadowfiend
        class = addon.PRIEST,
        cooldown = 300,
        category = category.OTHERS,
    },

    [44041] = { -- Chastise (Rank 1)
        class = addon.PRIEST,
        cooldown = 30,
        category = category.OTHERS,
    },
        [44043] = { parent = 44041 }, -- Chastise (Rank 2)
        [44044] = { parent = 44041 }, -- Chastise (Rank 3)
        [44045] = { parent = 44041 }, -- Chastise (Rank 4)
        [44046] = { parent = 44041 }, -- Chastise (Rank 5)
        [44047] = { parent = 44041 }, -- Chastise (Rank 6)

    -- Warlock

    [603] = { -- Curse of Doom (Rank 1)
        class = addon.WARLOCK,
        cooldown = 60,
        category = category.OTHERS,
    },
        [30910] = { parent = 603 }, -- Curse of Doom (Rank 2)

    [1122] = { -- Inferno
        class = addon.WARLOCK,
        cooldown = 3600,
        category = category.OTHERS,
    },

    [5484] = { -- Howl of Terror (Rank 1)
        class = addon.WARLOCK,
        cooldown = 40,
        category = category.OTHERS,
    },
        [17928] = { parent = 5484 }, -- Howl of Terror (Rank 2)

    [6229] = { -- Shadow Ward (Rank 1)
        class = addon.WARLOCK,
        cooldown = 30,
        category = category.OTHERS,
    },
        [11739] = { parent = 6229 }, -- Shadow Ward (Rank 2)
        [11740] = { parent = 6229 }, -- Shadow Ward (Rank 3)
        [28610] = { parent = 6229 }, -- Shadow Ward (Rank 4)

    [6353] = { -- Soul Fire (Rank 1)
        class = addon.WARLOCK,
        cooldown = 60,
        category = category.OTHERS,
    },
        [17924] = { parent = 6353 }, -- Soul Fire (Rank 2)
        [27211] = { parent = 6353 }, -- Soul Fire (Rank 3)
        [30545] = { parent = 6353 }, -- Soul Fire (Rank 4)

    [6789] = { -- Death Coil (Rank 1)
        class = addon.WARLOCK,
        cooldown = 120,
        category = category.OTHERS,
    },
        [17925] = { parent = 6789 }, -- Death Coil (Rank 2)
        [17926] = { parent = 6789 }, -- Death Coil (Rank 3)
        [27223] = { parent = 6789 }, -- Death Coil (Rank 4)

    [17877] = { -- Shadowburn (Rank 1)
        class = addon.WARLOCK,
        cooldown = 15,
        category = category.OTHERS,
    },
        [18867] = { parent = 17877 }, -- Shadowburn (Rank 2)
        [18868] = { parent = 17877 }, -- Shadowburn (Rank 3)
        [18869] = { parent = 17877 }, -- Shadowburn (Rank 4)
        [18870] = { parent = 17877 }, -- Shadowburn (Rank 5)
        [18871] = { parent = 17877 }, -- Shadowburn (Rank 6)
        [27263] = { parent = 17877 }, -- Shadowburn (Rank 7)
        [30546] = { parent = 17877 }, -- Shadowburn (Rank 8)

    [17962] = { -- Conflagrate (Rank 1)
        class = addon.WARLOCK,
        cooldown = 10,
        category = category.OTHERS,
    },
        [18930] = { parent = 17962 }, -- Conflagrate (Rank 2)
        [18931] = { parent = 17962 }, -- Conflagrate (Rank 3)
        [18932] = { parent = 17962 }, -- Conflagrate (Rank 4)
        [27266] = { parent = 17962 }, -- Conflagrate (Rank 5)
        [30912] = { parent = 17962 }, -- Conflagrate (Rank 6)

    [18288] = { -- Amplify Curse
        class = addon.WARLOCK,
        cooldown = 180,
        category = category.OTHERS,
    },

    [18540] = { -- Ritual of Doom
        class = addon.WARLOCK,
        cooldown = 3600,
        category = category.OTHERS,
    },

    [18708] = { -- Fel Domination
        class = addon.WARLOCK,
        cooldown = 900,
        category = category.OTHERS,
    },

    [29858] = { -- Soulshatter
        class = addon.WARLOCK,
        cooldown = 300,
        category = category.OTHERS,
    },

    [29893] = { -- Ritual of Souls
        class = addon.WARLOCK,
        cooldown = 300,
        category = category.OTHERS,
    },

    [30283] = { -- Shadowfury (Rank 1)
        class = addon.WARLOCK,
        cooldown = 20,
        category = category.OTHERS,
    },
        [30413] = { parent = 30283 }, -- Shadowfury (Rank 2)
        [30414] = { parent = 30283 }, -- Shadowfury (Rank 3)

    -- Warlock Pets

    [3716] = { -- Torment (Rank 1)
        class = addon.WARLOCK,
        cooldown = 5,
        category = category.OTHERS,
    },
        [7809] = { parent = 3716 }, -- Torment (Rank 2)
        [7810] = { parent = 3716 }, -- Torment (Rank 3)
        [7811] = { parent = 3716 }, -- Torment (Rank 4)
        [11774] = { parent = 3716 }, -- Torment (Rank 5)
        [11775] = { parent = 3716 }, -- Torment (Rank 6)
        [27270] = { parent = 3716 }, -- Torment (Rank 7)

    [4511] = { -- Phase Shift
        class = addon.WARLOCK,
        cooldown = 10,
        category = category.OTHERS,
    },

    [6360] = { -- Soothing Kiss (Rank 1)
        class = addon.WARLOCK,
        cooldown = 4,
        category = category.OTHERS,
    },
        [7813] = { parent = 6360 }, -- Soothing Kiss (Rank 2)
        [11784] = { parent = 6360 }, -- Soothing Kiss (Rank 3)
        [11785] = { parent = 6360 }, -- Soothing Kiss (Rank 4)
        [27275] = { parent = 6360 }, -- Soothing Kiss (Rank 5)

    [7814] = { -- Lash of Pain (Rank 1)
        class = addon.WARLOCK,
        cooldown = 12,
        category = category.OTHERS,
    },
        [7815] = { parent = 7814 }, -- Lash of Pain (Rank 2)
        [7816] = { parent = 7814 }, -- Lash of Pain (Rank 3)
        [11778] = { parent = 7814 }, -- Lash of Pain (Rank 4)
        [11779] = { parent = 7814 }, -- Lash of Pain (Rank 5)
        [11780] = { parent = 7814 }, -- Lash of Pain (Rank 6)
        [27274] = { parent = 7814 }, -- Lash of Pain (Rank 7)

    [17735] = { -- Suffering (Rank 1)
        class = addon.WARLOCK,
        cooldown = 120,
        category = category.OTHERS,
    },
        [17750] = { parent = 17735 }, -- Suffering (Rank 2)
        [17751] = { parent = 17735 }, -- Suffering (Rank 3)
        [17752] = { parent = 17735 }, -- Suffering (Rank 4)
        [27271] = { parent = 17735 }, -- Suffering (Rank 5)
        [33701] = { parent = 17735 }, -- Suffering (Rank 6)

    [19244] = { -- Spell Lock (Rank 1)
        class = addon.WARLOCK,
        cooldown = 24,
        category = category.INTERRUPT,
        trackPet = true,
    },
        [19647] = { parent = 19244 }, -- Spell Lock (Rank 2)

    [19505] = { -- Devour Magic (Rank 1)
        class = addon.WARLOCK,
        cooldown = 8,
        category = category.OTHERS,
    },
        [19731] = { parent = 19505 }, -- Devour Magic (Rank 2)
        [19734] = { parent = 19505 }, -- Devour Magic (Rank 3)
        [19736] = { parent = 19505 }, -- Devour Magic (Rank 4)
        [27276] = { parent = 19505 }, -- Devour Magic (Rank 5)
        [27277] = { parent = 19505 }, -- Devour Magic (Rank 6)

    -- Shaman

    [421] = { -- Chain Lightning (Rank 1)
        class = addon.SHAMAN,
        cooldown = 6,
        category = category.OTHERS,
    },
        [930] = { parent = 421 }, -- Chain Lightning (Rank 2)
        [2860] = { parent = 421 }, -- Chain Lightning (Rank 3)
        [10605] = { parent = 421 }, -- Chain Lightning (Rank 4)
        [25439] = { parent = 421 }, -- Chain Lightning (Rank 5)
        [25442] = { parent = 421 }, -- Chain Lightning (Rank 6)

    [556] = { -- Astral Recall
        class = addon.SHAMAN,
        cooldown = 900,
        category = category.OTHERS,
    },

    [1535] = { -- Fire Nova Totem (Rank 1)
        class = addon.SHAMAN,
        cooldown = 15,
        category = category.OTHERS,
    },
        [8498] = { parent = 1535 }, -- Fire Nova Totem (Rank 2)
        [8499] = { parent = 1535 }, -- Fire Nova Totem (Rank 3)
        [11314] = { parent = 1535 }, -- Fire Nova Totem (Rank 4)
        [11315] = { parent = 1535 }, -- Fire Nova Totem (Rank 5)
        [25546] = { parent = 1535 }, -- Fire Nova Totem (Rank 6)
        [25547] = { parent = 1535 }, -- Fire Nova Totem (Rank 7)

    [2062] = { -- Earth Elemental Totem
        class = addon.SHAMAN,
        cooldown = 1200,
        category = category.OTHERS,
    },

    [2484] = { -- Earthbind Totem
        class = addon.SHAMAN,
        cooldown = 15,
        category = category.OTHERS,
    },

    [2825] = { -- Bloodlust
        class = addon.SHAMAN,
        cooldown = 600,
        category = category.OTHERS,
    },

    [2894] = { -- Fire Elemental Totem
        class = addon.SHAMAN,
        cooldown = 1200,
        category = category.OTHERS,
    },

    [5730] = { -- Stoneclaw Totem (Rank 1)
        class = addon.SHAMAN,
        cooldown = 30,
        category = category.OTHERS,
    },
        [6390] = { parent = 5730 }, -- Stoneclaw Totem (Rank 2)
        [6391] = { parent = 5730 }, -- Stoneclaw Totem (Rank 3)
        [6392] = { parent = 5730 }, -- Stoneclaw Totem (Rank 4)
        [10427] = { parent = 5730 }, -- Stoneclaw Totem (Rank 5)
        [10428] = { parent = 5730 }, -- Stoneclaw Totem (Rank 6)
        [25525] = { parent = 5730 }, -- Stoneclaw Totem (Rank 7)

    [8042] = { -- Earth Shock (Rank 1)
        class = addon.SHAMAN,
        cooldown = 5,
        category = category.INTERRUPT,
    },
        [8044] = { parent = 8042 }, -- Earth Shock (Rank 2)
        [8045] = { parent = 8042 }, -- Earth Shock (Rank 3)
        [8046] = { parent = 8042 }, -- Earth Shock (Rank 4)
        [10412] = { parent = 8042 }, -- Earth Shock (Rank 5)
        [10413] = { parent = 8042 }, -- Earth Shock (Rank 6)
        [10414] = { parent = 8042 }, -- Earth Shock (Rank 7)
        [25454] = { parent = 8042 }, -- Earth Shock (Rank 8)
        [8050] = { parent = 8042 }, -- Flame Shock (Rank 1)
        [8052] = { parent = 8042 }, -- Flame Shock (Rank 2)
        [8053] = { parent = 8042 }, -- Flame Shock (Rank 3)
        [10447] = { parent = 8042 }, -- Flame Shock (Rank 4)
        [10448] = { parent = 8042 }, -- Flame Shock (Rank 5)
        [29228] = { parent = 8042 }, -- Flame Shock (Rank 6)
        [25457] = { parent = 8042 }, -- Flame Shock (Rank 7)
        [8056] = { parent = 8042 }, -- Frost Shock (Rank 1)
        [8058] = { parent = 8042 }, -- Frost Shock (Rank 2)
        [10472] = { parent = 8042 }, -- Frost Shock (Rank 3)
        [10473] = { parent = 8042 }, -- Frost Shock (Rank 4)
        [25464] = { parent = 8042 }, -- Frost Shock (Rank 5)

    [8177] = { -- Grounding Totem
        class = addon.SHAMAN,
        cooldown = 15,
        category = category.OTHERS,
    },

    [16166] = { -- Elemental Mastery
        class = addon.SHAMAN,
        cooldown = 180,
        category = category.OTHERS,
    },

    [16188] = { -- Nature's Swiftness
        class = addon.SHAMAN,
        cooldown = 180,
        category = category.OTHERS,
    },

    [16190] = { -- Mana Tide Totem
        class = addon.SHAMAN,
        cooldown = 300,
        category = category.OTHERS,
    },

    [17364] = { -- Stormstrike
        class = addon.SHAMAN,
        cooldown = 10,
        category = category.OTHERS,
    },

    [20608] = { -- Reincarnation
        class = addon.SHAMAN,
        cooldown = 3600,
        category = category.OTHERS,
    },

    [30823] = { -- Shamanistic Rage
        class = addon.SHAMAN,
        cooldown = 120,
        category = category.OTHERS,
    },

    [32182] = { -- Heroism
        class = addon.SHAMAN,
        cooldown = 600,
        category = category.OTHERS,
    },

    -- Paladin

    [498] = { -- Divine Protection (Rank 1)
        class = addon.PALADIN,
        cooldown = 300,
        category = category.OTHERS,
    },
        [5573] = { parent = 498 }, -- Divine Protection (Rank 2)

    [633] = { -- Lay on Hands (Rank 1)
        class = addon.PALADIN,
        cooldown = 3600,
        category = category.OTHERS,
    },
        [2800] = { parent = 633 }, -- Lay on Hands (Rank 2)
        [10310] = { parent = 633 }, -- Lay on Hands (Rank 3)
        [27154] = { parent = 633 }, -- Lay on Hands (Rank 4)

    [642] = { -- Divine Shield (Rank 1)
        class = addon.PALADIN,
        cooldown = 300,
        category = category.OTHERS,
    },
        [1020] = { parent = 642 }, -- Divine Shield (Rank 2)

    [853] = { -- Hammer of Justice (Rank 1)
        class = addon.PALADIN,
        cooldown = 60,
        category = category.OTHERS,
    },
        [5588] = { parent = 853 }, -- Hammer of Justice (Rank 2)
        [5589] = { parent = 853 }, -- Hammer of Justice (Rank 3)
        [10308] = { parent = 853 }, -- Hammer of Justice (Rank 4)

    [879] = { -- Exorcism (Rank 1)
        class = addon.PALADIN,
        cooldown = 15,
        category = category.OTHERS,
    },
        [5614] = { parent = 879 }, -- Exorcism (Rank 2)
        [5615] = { parent = 879 }, -- Exorcism (Rank 3)
        [10312] = { parent = 879 }, -- Exorcism (Rank 4)
        [10313] = { parent = 879 }, -- Exorcism (Rank 5)
        [10314] = { parent = 879 }, -- Exorcism (Rank 6)
        [27138] = { parent = 879 }, -- Exorcism (Rank 7)

    [1022] = { -- Blessing of Protection (Rank 1)
        class = addon.PALADIN,
        cooldown = 300,
        category = category.OTHERS,
    },
        [5599] = { parent = 1022 }, -- Blessing of Protection (Rank 2)
        [10278] = { parent = 1022 }, -- Blessing of Protection (Rank 3)

    [1044] = { -- Blessing of Freedom
        class = addon.PALADIN,
        cooldown = 25,
        category = category.OTHERS,
    },

    [2812] = { -- Holy Wrath (Rank 1)
        class = addon.PALADIN,
        cooldown = 60,
        category = category.OTHERS,
    },
        [10318] = { parent = 2812 }, -- Holy Wrath (Rank 2)
        [27139] = { parent = 2812 }, -- Holy Wrath (Rank 3)

    [2878] = { -- Turn Undead (Rank 1)
        class = addon.PALADIN,
        cooldown = 30,
        category = category.OTHERS,
    },
        [5627] = { parent = 2878 }, -- Turn Undead (Rank 2)

    [6940] = { -- Blessing of Sacrifice (Rank 1)
        class = addon.PALADIN,
        cooldown = 30,
        category = category.OTHERS,
    },
        [20729] = { parent = 6940 }, -- Blessing of Sacrifice (Rank 2)
        [27147] = { parent = 6940 }, -- Blessing of Sacrifice (Rank 3)
        [27148] = { parent = 6940 }, -- Blessing of Sacrifice (Rank 4)

    [10326] = { -- Turn Evil
        class = addon.PALADIN,
        cooldown = 30,
        category = category.OTHERS,
    },

    [19752] = { -- Divine Intervention
        class = addon.PALADIN,
        cooldown = 3600,
        category = category.OTHERS,
    },

    [20066] = { -- Repentance
        class = addon.PALADIN,
        cooldown = 60,
        category = category.OTHERS,
    },

    [26573] = { -- Consecration (Rank 1)
        class = addon.PALADIN,
        cooldown = 8,
        category = category.OTHERS,
    },
        [20116] = { parent = 26573 }, -- Consecration (Rank 2)
        [20922] = { parent = 26573 }, -- Consecration (Rank 3)
        [20923] = { parent = 26573 }, -- Consecration (Rank 4)
        [20924] = { parent = 26573 }, -- Consecration (Rank 5)
        [27173] = { parent = 26573 }, -- Consecration (Rank 6)

    [20216] = { -- Divine Favor
        class = addon.PALADIN,
        cooldown = 120,
        category = category.OTHERS,
    },

    [20271] = { -- Judgement
        class = addon.PALADIN,
        cooldown = 10,
        category = category.OTHERS,
    },

    [20473] = { -- Holy Shock (Rank 1)
        class = addon.PALADIN,
        cooldown = 15,
        category = category.OTHERS,
    },
        [20929] = { parent = 20473 }, -- Holy Shock (Rank 2)
        [20930] = { parent = 20473 }, -- Holy Shock (Rank 3)
        [27174] = { parent = 20473 }, -- Holy Shock (Rank 4)
        [33072] = { parent = 20473 }, -- Holy Shock (Rank 5)

    [20925] = { -- Holy Shield (Rank 1)
        class = addon.PALADIN,
        cooldown = 10,
        category = category.OTHERS,
    },
        [20927] = { parent = 20925 }, -- Holy Shield (Rank 2)
        [20928] = { parent = 20925 }, -- Holy Shield (Rank 3)
        [27179] = { parent = 20925 }, -- Holy Shield (Rank 4)

    [24275] = { -- Hammer of Wrath (Rank 1)
        class = addon.PALADIN,
        cooldown = 6,
        category = category.OTHERS,
    },
        [24274] = { parent = 24275 }, -- Hammer of Wrath (Rank 2)
        [24239] = { parent = 24275 }, -- Hammer of Wrath (Rank 3)
        [27180] = { parent = 24275 }, -- Hammer of Wrath (Rank 4)

    [31789] = { -- Righteous Defense
        class = addon.PALADIN,
        cooldown = 15,
        category = category.OTHERS,
    },

    [31842] = { -- Divine Illumination
        class = addon.PALADIN,
        cooldown = 180,
        category = category.OTHERS,
    },

    [31884] = { -- Avenging Wrath
        class = addon.PALADIN,
        cooldown = 180,
        category = category.OTHERS,
    },

    [31935] = { -- Avenger's Shield (Rank 1)
        class = addon.PALADIN,
        cooldown = 30,
        category = category.OTHERS,
    },
        [32699] = { parent = 31935 }, -- Avenger's Shield (Rank 2)
        [32700] = { parent = 31935 }, -- Avenger's Shield (Rank 3)

    [35395] = { -- Crusader Strike
        class = addon.PALADIN,
        cooldown = 6,
        category = category.OTHERS,
    },

    -- Hunter

    [781] = { -- Disengage (Rank 1)
        class = addon.HUNTER,
        cooldown = 5,
        category = category.OTHERS,
    },
        [14272] = { parent = 781 }, -- Disengage (Rank 2)
        [14273] = { parent = 781 }, -- Disengage (Rank 3)
        [27015] = { parent = 781 }, -- Disengage (Rank 4)

    [1495] = { -- Mongoose Bite (Rank 1)
        class = addon.HUNTER,
        cooldown = 5,
        category = category.OTHERS,
    },
        [14269] = { parent = 1495 }, -- Mongoose Bite (Rank 2)
        [14270] = { parent = 1495 }, -- Mongoose Bite (Rank 3)
        [14271] = { parent = 1495 }, -- Mongoose Bite (Rank 4)
        [36916] = { parent = 1495 }, -- Mongoose Bite (Rank 5)

    [1499] = { -- Freezing Trap (Rank 1)
        class = addon.HUNTER,
        cooldown = 30,
        category = category.OTHERS,
    },
        [14310] = { parent = 1499 }, -- Freezing Trap (Rank 2)
        [14311] = { parent = 1499 }, -- Freezing Trap (Rank 3)

    [1510] = { -- Volley (Rank 1)
        class = addon.HUNTER,
        cooldown = 60,
        category = category.OTHERS,
    },
        [14294] = { parent = 1510 }, -- Volley (Rank 2)
        [14295] = { parent = 1510 }, -- Volley (Rank 3)
        [27022] = { parent = 1510 }, -- Volley (Rank 4)

    [1513] = { -- Scare Beast (Rank 1)
        class = addon.HUNTER,
        cooldown = 30,
        category = category.OTHERS,
    },
        [14326] = { parent = 1513 }, -- Scare Beast (Rank 2)
        [14327] = { parent = 1513 }, -- Scare Beast (Rank 3)

    [1543] = { -- Flare
        class = addon.HUNTER,
        cooldown = 20,
        category = category.OTHERS,
    },

    [2643] = { -- Multi-Shot (Rank 1)
        class = addon.HUNTER,
        cooldown = 10,
        category = category.OTHERS,
    },
        [14288] = { parent = 2643 }, -- Multi-Shot (Rank 2)
        [14289] = { parent = 2643 }, -- Multi-Shot (Rank 3)
        [14290] = { parent = 2643 }, -- Multi-Shot (Rank 4)
        [25294] = { parent = 2643 }, -- Multi-Shot (Rank 5)
        [27021] = { parent = 2643 }, -- Multi-Shot (Rank 6)

    [2973] = { -- Raptor Strike (Rank 1)
        class = addon.HUNTER,
        cooldown = 6,
        category = category.OTHERS,
    },
        [14260] = { parent = 2973 }, -- Raptor Strike (Rank 2)
        [14261] = { parent = 2973 }, -- Raptor Strike (Rank 3)
        [14262] = { parent = 2973 }, -- Raptor Strike (Rank 4)
        [14263] = { parent = 2973 }, -- Raptor Strike (Rank 5)
        [14264] = { parent = 2973 }, -- Raptor Strike (Rank 6)
        [14265] = { parent = 2973 }, -- Raptor Strike (Rank 7)
        [14266] = { parent = 2973 }, -- Raptor Strike (Rank 8)
        [27014] = { parent = 2973 }, -- Raptor Strike (Rank 9)

    [3034] = { -- Viper Sting (Rank 1)
        class = addon.HUNTER,
        cooldown = 15,
        category = category.OTHERS,
    },
        [14279] = { parent = 3034 }, -- Viper Sting (Rank 2)
        [14280] = { parent = 3034 }, -- Viper Sting (Rank 3)
        [27018] = { parent = 3034 }, -- Viper Sting (Rank 4)

    [3044] = { -- Arcane Shot (Rank 1)
        class = addon.HUNTER,
        cooldown = 6,
        category = category.OTHERS,
    },
        [14281] = { parent = 3044 }, -- Arcane Shot (Rank 2)
        [14282] = { parent = 3044 }, -- Arcane Shot (Rank 3)
        [14283] = { parent = 3044 }, -- Arcane Shot (Rank 4)
        [14284] = { parent = 3044 }, -- Arcane Shot (Rank 5)
        [14285] = { parent = 3044 }, -- Arcane Shot (Rank 6)
        [14286] = { parent = 3044 }, -- Arcane Shot (Rank 7)
        [14287] = { parent = 3044 }, -- Arcane Shot (Rank 8)
        [27019] = { parent = 3044 }, -- Arcane Shot (Rank 9)

    [3045] = { -- Rapid Fire
        class = addon.HUNTER,
        cooldown = 300,
        category = category.OTHERS,
    },

    [5116] = { -- Concussive Shot
        class = addon.HUNTER,
        cooldown = 12,
        category = category.OTHERS,
    },

    [5384] = { -- Feign Death
        class = addon.HUNTER,
        cooldown = 30,
        category = category.OTHERS,
    },

    [13795] = { -- Immolation Trap (Rank 1)
        class = addon.HUNTER,
        cooldown = 30,
        category = category.OTHERS,
    },
        [14302] = { parent = 13795 }, -- Immolation Trap (Rank 2)
        [14303] = { parent = 13795 }, -- Immolation Trap (Rank 3)
        [14304] = { parent = 13795 }, -- Immolation Trap (Rank 4)
        [14305] = { parent = 13795 }, -- Immolation Trap (Rank 5)
        [27023] = { parent = 13795 }, -- Immolation Trap (Rank 6)

    [13809] = { -- Frost Trap
        class = addon.HUNTER,
        cooldown = 30,
        category = category.OTHERS,
    },

    [13813] = { -- Explosive Trap (Rank 1)
        class = addon.HUNTER,
        cooldown = 30,
        category = category.OTHERS,
    },
        [14316] = { parent = 13813 }, -- Explosive Trap (Rank 2)
        [14317] = { parent = 13813 }, -- Explosive Trap (Rank 3)
        [27025] = { parent = 13813 }, -- Explosive Trap (Rank 4)

    [20736] = { -- Distracting Shot (Rank 1)
        class = addon.HUNTER,
        cooldown = 8,
        category = category.OTHERS,
    },
        [14274] = { parent = 20736 }, -- Distracting Shot (Rank 2)
        [15629] = { parent = 20736 }, -- Distracting Shot (Rank 3)
        [15630] = { parent = 20736 }, -- Distracting Shot (Rank 4)
        [15631] = { parent = 20736 }, -- Distracting Shot (Rank 5)
        [15632] = { parent = 20736 }, -- Distracting Shot (Rank 6)
        [27020] = { parent = 20736 }, -- Distracting Shot (Rank 7)

    [19263] = { -- Deterrence
        class = addon.HUNTER,
        cooldown = 300,
        category = category.OTHERS,
    },

    [19306] = { -- Counterattack (Rank 1)
        class = addon.HUNTER,
        cooldown = 5,
        category = category.OTHERS,
    },
        [20909] = { parent = 19306 }, -- Counterattack (Rank 2)
        [20910] = { parent = 19306 }, -- Counterattack (Rank 3)
        [27067] = { parent = 19306 }, -- Counterattack (Rank 4)

    [19386] = { -- Wyvern Sting (Rank 1)
        class = addon.HUNTER,
        cooldown = 120,
        category = category.OTHERS,
    },
        [24132] = { parent = 19386 }, -- Wyvern Sting (Rank 2)
        [24133] = { parent = 19386 }, -- Wyvern Sting (Rank 3)
        [27068] = { parent = 19386 }, -- Wyvern Sting (Rank 4)

    [19434] = { -- Aimed Shot (Rank 1)
        class = addon.HUNTER,
        cooldown = 6,
        category = category.OTHERS,
    },
        [20900] = { parent = 19434 }, -- Aimed Shot (Rank 2)
        [20901] = { parent = 19434 }, -- Aimed Shot (Rank 3)
        [20902] = { parent = 19434 }, -- Aimed Shot (Rank 4)
        [20903] = { parent = 19434 }, -- Aimed Shot (Rank 5)
        [20904] = { parent = 19434 }, -- Aimed Shot (Rank 6)
        [27065] = { parent = 19434 }, -- Aimed Shot (Rank 7)

    [19503] = { -- Scatter Shot
        class = addon.HUNTER,
        cooldown = 30,
        category = category.OTHERS,
    },

    [19574] = { -- Bestial Wrath
        class = addon.HUNTER,
        cooldown = 120,
        category = category.OTHERS,
    },

    [19577] = { -- Intimidation
        class = addon.HUNTER,
        cooldown = 60,
        category = category.OTHERS,
    },

    [19801] = { -- Tranquilizing Shot
        class = addon.HUNTER,
        cooldown = 20,
        category = category.OTHERS,
    },

    [23989] = { -- Readiness
        class = addon.HUNTER,
        cooldown = 300,
        category = category.OTHERS,
    },

    [34026] = { -- Kill Command
        class = addon.HUNTER,
        cooldown = 5,
        category = category.OTHERS,
    },

    [34477] = { -- Misdirection
        class = addon.HUNTER,
        cooldown = 120,
        category = category.OTHERS,
    },

    [34490] = { -- Silencing Shot
        class = addon.HUNTER,
        cooldown = 20,
        category = category.OTHERS,
    },

    [34600] = { -- Snake Trap
        class = addon.HUNTER,
        cooldown = 30,
        category = category.OTHERS,
    },

    -- Hunter Pets

    [1742] = { -- Cower (Rank 1)
        class = addon.HUNTER,
        cooldown = 5,
        category = category.OTHERS,
    },
        [1753] = { parent = 1742 }, -- Cower (Rank 2)
        [1754] = { parent = 1742 }, -- Cower (Rank 3)
        [1755] = { parent = 1742 }, -- Cower (Rank 4)
        [1756] = { parent = 1742 }, -- Cower (Rank 5)
        [16697] = { parent = 1742 }, -- Cower (Rank 6)
        [27048] = { parent = 1742 }, -- Cower (Rank 7)

    [2649] = { -- Growl (Rank 1)
        class = addon.HUNTER,
        cooldown = 5,
        category = category.OTHERS,
    },
        [14916] = { parent = 2649 }, -- Growl (Rank 2)
        [14917] = { parent = 2649 }, -- Growl (Rank 3)
        [14918] = { parent = 2649 }, -- Growl (Rank 4)
        [14919] = { parent = 2649 }, -- Growl (Rank 5)
        [14920] = { parent = 2649 }, -- Growl (Rank 6)
        [14921] = { parent = 2649 }, -- Growl (Rank 7)
        [27047] = { parent = 2649 }, -- Growl (Rank 8)

    [7371] = { -- Charge (Rank 1)
        class = addon.HUNTER,
        cooldown = 25,
        category = category.OTHERS,
    },
        [26177] = { parent = 7371 }, -- Charge (Rank 2)
        [26178] = { parent = 7371 }, -- Charge (Rank 3)
        [26179] = { parent = 7371 }, -- Charge (Rank 4)
        [26201] = { parent = 7371 }, -- Charge (Rank 5)
        [27685] = { parent = 7371 }, -- Charge (Rank 6)

    [17253] = { -- Bite (Rank 1)
        class = addon.HUNTER,
        cooldown = 10,
        category = category.OTHERS,
    },
        [17255] = { parent = 17253 }, -- Bite (Rank 2)
        [17256] = { parent = 17253 }, -- Bite (Rank 3)
        [17257] = { parent = 17253 }, -- Bite (Rank 4)
        [17258] = { parent = 17253 }, -- Bite (Rank 5)
        [17259] = { parent = 17253 }, -- Bite (Rank 6)
        [17260] = { parent = 17253 }, -- Bite (Rank 7)
        [17261] = { parent = 17253 }, -- Bite (Rank 8)
        [27050] = { parent = 17253 }, -- Bite (Rank 9)

    [23099] = { -- Dash (Rank 1)
        class = addon.HUNTER,
        cooldown = 30,
        category = category.OTHERS,
    },
        [23109] = { parent = 23099 }, -- Dash (Rank 2)
        [23110] = { parent = 23099 }, -- Dash (Rank 3)

    [23145] = { -- Dive (Rank 1)
        class = addon.HUNTER,
        cooldown = 30,
        category = category.OTHERS,
    },
        [23147] = { parent = 23145 }, -- Dive (Rank 2)
        [23148] = { parent = 23145 }, -- Dive (Rank 3)

    [24450] = { -- Prowl (Rank 1)
        class = addon.HUNTER,
        cooldown = 10,
        category = category.OTHERS,
    },
        [24452] = { parent = 24450 }, -- Prowl (Rank 2)
        [24453] = { parent = 24450 }, -- Prowl (Rank 3)

    [24640] = { -- Scorpid Poison (Rank 1)
        class = addon.HUNTER,
        cooldown = 4,
        category = category.OTHERS,
    },
        [24583] = { parent = 24640 }, -- Scorpid Poison (Rank 2)
        [24586] = { parent = 24640 }, -- Scorpid Poison (Rank 3)
        [24587] = { parent = 24640 }, -- Scorpid Poison (Rank 4)
        [27060] = { parent = 24640 }, -- Scorpid Poison (Rank 5)

    [24604] = { -- Furious Howl (Rank 1)
        class = addon.HUNTER,
        cooldown = 10,
        category = category.OTHERS,
    },
        [24605] = { parent = 24604 }, -- Furious Howl (Rank 2)
        [24603] = { parent = 24604 }, -- Furious Howl (Rank 3)
        [24597] = { parent = 24604 }, -- Furious Howl (Rank 4)

    [26064] = { -- Shell Shield
        class = addon.HUNTER,
        cooldown = 180,
        category = category.OTHERS,
    },

    [26090] = { -- Thunderstomp (Rank 1)
        class = addon.HUNTER,
        cooldown = 60,
        category = category.OTHERS,
    },
        [26187] = { parent = 26090 }, -- Thunderstomp (Rank 2)
        [26188] = { parent = 26090 }, -- Thunderstomp (Rank 3)
        [27063] = { parent = 26090 }, -- Thunderstomp (Rank 4)

    [34889] = { -- Fire Breath (Rank 1)
        class = addon.HUNTER,
        cooldown = 10,
        category = category.OTHERS,
    },
        [35323] = { parent = 34889 }, -- Fire Breath (Rank 2)

    [35346] = { -- Warp
        class = addon.HUNTER,
        cooldown = 15,
        category = category.OTHERS,
    },

    [35387] = { -- Poison Spit (Rank 1)
        class = addon.HUNTER,
        cooldown = 10,
        category = category.OTHERS,
    },
        [35389] = { parent = 35387 }, -- Poison Spit (Rank 2)
        [35392] = { parent = 35387 }, -- Poison Spit (Rank 3)

    -- Druid

    [740] = { -- Tranquility (Rank 1)
        class = addon.DRUID,
        cooldown = 600,
        category = category.OTHERS,
    },
        [8918] = { parent = 740 }, -- Tranquility (Rank 2)
        [9862] = { parent = 740 }, -- Tranquility (Rank 3)
        [9863] = { parent = 740 }, -- Tranquility (Rank 4)
        [26983] = { parent = 740 }, -- Tranquility (Rank 5)

    [1850] = { -- Dash (Rank 1)
        class = addon.DRUID,
        cooldown = 300,
        category = category.OTHERS,
    },
        [9821] = { parent = 1850 }, -- Dash (Rank 2)
        [33357] = { parent = 1850 }, -- Dash (Rank 3)

    [5209] = { -- Challenging Roar
        class = addon.DRUID,
        cooldown = 600,
        category = category.OTHERS,
    },

    [5211] = { -- Bash (Rank 1)
        class = addon.DRUID,
        cooldown = 60,
        category = category.OTHERS,
    },
        [6798] = { parent = 5211 }, -- Bash (Rank 2)
        [8983] = { parent = 5211 }, -- Bash (Rank 3)

    [5215] = { -- Prowl (Rank 1)
        class = addon.DRUID,
        cooldown = 10,
        category = category.OTHERS,
    },
        [6783] = { parent = 5215 }, -- Prowl (Rank 2)
        [9913] = { parent = 5215 }, -- Prowl (Rank 3)

    [5229] = { -- Enrage
        class = addon.DRUID,
        cooldown = 60,
        category = category.OTHERS,
    },

    [6795] = { -- Growl
        class = addon.DRUID,
        cooldown = 10,
        category = category.OTHERS,
    },

    [8998] = { -- Cower (Rank 1)
        class = addon.DRUID,
        cooldown = 10,
        category = category.OTHERS,
    },
        [9000] = { parent = 8998 }, -- Cower (Rank 2)
        [9892] = { parent = 8998 }, -- Cower (Rank 3)
        [31709] = { parent = 8998 }, -- Cower (Rank 4)
        [27004] = { parent = 8998 }, -- Cower (Rank 5)

    [16689] = { -- Nature's Grasp (Rank 1)
        class = addon.DRUID,
        cooldown = 60,
        category = category.OTHERS,
    },
        [16810] = { parent = 16689 }, -- Nature's Grasp (Rank 2)
        [16811] = { parent = 16689 }, -- Nature's Grasp (Rank 3)
        [16812] = { parent = 16689 }, -- Nature's Grasp (Rank 4)
        [16813] = { parent = 16689 }, -- Nature's Grasp (Rank 5)
        [17329] = { parent = 16689 }, -- Nature's Grasp (Rank 6)
        [27009] = { parent = 16689 }, -- Nature's Grasp (Rank 7)

    [16857] = { -- Faerie Fire (Feral) (Rank 1)
        class = addon.DRUID,
        cooldown = 6,
        category = category.OTHERS,
    },
        [17390] = { parent = 16857 }, -- Faerie Fire (Feral) (Rank 2)
        [17391] = { parent = 16857 }, -- Faerie Fire (Feral) (Rank 3)
        [17392] = { parent = 16857 }, -- Faerie Fire (Feral) (Rank 4)
        [27011] = { parent = 16857 }, -- Faerie Fire (Feral) (Rank 5)

    [16914] = { -- Hurricane (Rank 1)
        class = addon.DRUID,
        cooldown = 60,
        category = category.OTHERS,
    },
        [17401] = { parent = 16914 }, -- Hurricane (Rank 2)
        [17402] = { parent = 16914 }, -- Hurricane (Rank 3)
        [27012] = { parent = 16914 }, -- Hurricane (Rank 4)

    [16979] = { -- Feral Charge
        class = addon.DRUID,
        cooldown = 15,
        category = category.INTERRUPT,
    },

    [17116] = { -- Nature's Swiftness
        class = addon.DRUID,
        cooldown = 180,
        category = category.OTHERS,
    },

    [18562] = { -- Swiftmend
        class = addon.DRUID,
        cooldown = 15,
        category = category.OTHERS,
    },

    [20484] = { -- Rebirth (Rank 1)
        class = addon.DRUID,
        cooldown = 1200,
        category = category.OTHERS,
    },
        [20739] = { parent = 20484 }, -- Rebirth (Rank 2)
        [20742] = { parent = 20484 }, -- Rebirth (Rank 3)
        [20747] = { parent = 20484 }, -- Rebirth (Rank 4)
        [20748] = { parent = 20484 }, -- Rebirth (Rank 5)
        [26994] = { parent = 20484 }, -- Rebirth (Rank 6)

    [22812] = { -- Barkskin
        class = addon.DRUID,
        cooldown = 60,
        category = category.OTHERS,
    },

    [22842] = { -- Frenzied Regeneration (Rank 1)
        class = addon.DRUID,
        cooldown = 180,
        category = category.OTHERS,
    },
        [22895] = { parent = 22842 }, -- Frenzied Regeneration (Rank 2)
        [22896] = { parent = 22842 }, -- Frenzied Regeneration (Rank 3)
        [26999] = { parent = 22842 }, -- Frenzied Regeneration (Rank 4)

    [29166] = { -- Innervate
        class = addon.DRUID,
        cooldown = 360,
        category = category.OTHERS,
    },

    [33831] = { -- Force of Nature
        class = addon.DRUID,
        cooldown = 180,
        category = category.OTHERS,
    },

    [33878] = { -- Mangle (Bear) (Rank 1)
        class = addon.DRUID,
        cooldown = 6,
        category = category.OTHERS,
    },
        [33986] = { parent = 33878 }, -- Mangle (Bear) (Rank 2)
        [33987] = { parent = 33878 }, -- Mangle (Bear) (Rank 3)

    -- Mage

    [66] = { -- Invisibility
        class = addon.MAGE,
        cooldown = 300,
        category = category.OTHERS,
    },

    [120] = { -- Cone of Cold (Rank 1)
        class = addon.MAGE,
        cooldown = 10,
        category = category.OTHERS,
    },
        [8492] = { parent = 120 }, -- Cone of Cold (Rank 2)
        [10159] = { parent = 120 }, -- Cone of Cold (Rank 3)
        [10160] = { parent = 120 }, -- Cone of Cold (Rank 4)
        [10161] = { parent = 120 }, -- Cone of Cold (Rank 5)
        [27087] = { parent = 120 }, -- Cone of Cold (Rank 6)

    [122] = { -- Frost Nova (Rank 1)
        class = addon.MAGE,
        cooldown = 25,
        category = category.OTHERS,
    },
        [865] = { parent = 122 }, -- Frost Nova (Rank 2)
        [6131] = { parent = 122 }, -- Frost Nova (Rank 3)
        [10230] = { parent = 122 }, -- Frost Nova (Rank 4)
        [27088] = { parent = 122 }, -- Frost Nova (Rank 5)

    [543] = { -- Fire Ward (Rank 1)
        class = addon.MAGE,
        cooldown = 30,
        category = category.OTHERS,
    },
        [8457] = { parent = 543 }, -- Fire Ward (Rank 2)
        [8458] = { parent = 543 }, -- Fire Ward (Rank 3)
        [10223] = { parent = 543 }, -- Fire Ward (Rank 4)
        [10225] = { parent = 543 }, -- Fire Ward (Rank 5)
        [27128] = { parent = 543 }, -- Fire Ward (Rank 6)

    [1953] = { -- Blink
        class = addon.MAGE,
        cooldown = 15,
        category = category.OTHERS,
    },

    [2136] = { -- Fire Blast (Rank 1)
        class = addon.MAGE,
        cooldown = 8,
        category = category.OTHERS,
    },
        [2137] = { parent = 2136 }, -- Fire Blast (Rank 2)
        [2138] = { parent = 2136 }, -- Fire Blast (Rank 3)
        [8412] = { parent = 2136 }, -- Fire Blast (Rank 4)
        [8413] = { parent = 2136 }, -- Fire Blast (Rank 5)
        [10197] = { parent = 2136 }, -- Fire Blast (Rank 6)
        [10199] = { parent = 2136 }, -- Fire Blast (Rank 7)
        [27078] = { parent = 2136 }, -- Fire Blast (Rank 8)
        [27079] = { parent = 2136 }, -- Fire Blast (Rank 9)

    [2139] = { -- Counterspell
        class = addon.MAGE,
        cooldown = 24,
        category = category.INTERRUPT,
    },

    [6143] = { -- Frost Ward (Rank 1)
        class = addon.MAGE,
        cooldown = 30,
        category = category.OTHERS,
    },
        [8461] = { parent = 6143 }, -- Frost Ward (Rank 2)
        [8462] = { parent = 6143 }, -- Frost Ward (Rank 3)
        [10177] = { parent = 6143 }, -- Frost Ward (Rank 4)
        [28609] = { parent = 6143 }, -- Frost Ward (Rank 5)
        [32796] = { parent = 6143 }, -- Frost Ward (Rank 6)

    [11113] = { -- Blast Wave (Rank 1)
        class = addon.MAGE,
        cooldown = 30,
        category = category.OTHERS,
    },
        [13018] = { parent = 11113 }, -- Blast Wave (Rank 2)
        [13019] = { parent = 11113 }, -- Blast Wave (Rank 3)
        [13020] = { parent = 11113 }, -- Blast Wave (Rank 4)
        [13021] = { parent = 11113 }, -- Blast Wave (Rank 5)
        [27133] = { parent = 11113 }, -- Blast Wave (Rank 6)
        [33933] = { parent = 11113 }, -- Blast Wave (Rank 7)

    [11129] = { -- Combustion
        class = addon.MAGE,
        cooldown = 180,
        category = category.OTHERS,
    },

    [11426] = { -- Ice Barrier (Rank 1)
        class = addon.MAGE,
        cooldown = 30,
        category = category.OTHERS,
    },
        [13031] = { parent = 11426 }, -- Ice Barrier (Rank 2)
        [13032] = { parent = 11426 }, -- Ice Barrier (Rank 3)
        [13033] = { parent = 11426 }, -- Ice Barrier (Rank 4)
        [27134] = { parent = 11426 }, -- Ice Barrier (Rank 5)
        [33405] = { parent = 11426 }, -- Ice Barrier (Rank 6)

    [11958] = { -- Cold Snap
        class = addon.MAGE,
        cooldown = 480,
        category = category.OTHERS,
    },

    [12042] = { -- Arcane Power
        class = addon.MAGE,
        cooldown = 180,
        category = category.OTHERS,
    },

    [12043] = { -- Presence of Mind
        class = addon.MAGE,
        cooldown = 180,
        category = category.OTHERS,
    },

    [12051] = { -- Evocation
        class = addon.MAGE,
        cooldown = 480,
        category = category.OTHERS,
    },

    [12472] = { -- Icy Veins
        class = addon.MAGE,
        cooldown = 180,
        category = category.OTHERS,
    },

    [31661] = { -- Dragon's Breath (Rank 1)
        class = addon.MAGE,
        cooldown = 20,
        category = category.OTHERS,
    },
        [33041] = { parent = 31661 }, -- Dragon's Breath (Rank 2)
        [33042] = { parent = 31661 }, -- Dragon's Breath (Rank 3)
        [33043] = { parent = 31661 }, -- Dragon's Breath (Rank 4)

    [31687] = { -- Summon Water Elemental
        class = addon.MAGE,
        cooldown = 180,
        category = category.OTHERS,
    },

    [33395] = { -- Freeze (Water Elemental)
        class = addon.MAGE,
        cooldown = 25,
        category = category.OTHERS,
    },

    [43987] = { -- Ritual of Refreshment
        class = addon.MAGE,
        cooldown = 300,
        category = category.OTHERS,
    },

    [45438] = { -- Ice Block
        class = addon.MAGE,
        cooldown = 300,
        category = category.OTHERS,
    },

    -- Rogue

    [408] = { -- Kidney Shot (Rank 1)
        class = addon.ROGUE,
        cooldown = 20,
        category = category.OTHERS,
    },
        [8643] = { parent = 408 }, -- Kidney Shot (Rank 2)

    [1725] = { -- Distract
        class = addon.ROGUE,
        cooldown = 30,
        category = category.OTHERS,
    },

    [1766] = { -- Kick (Rank 1)
        class = addon.ROGUE,
        cooldown = 10,
        category = category.INTERRUPT,
    },
        [1767] = { parent = 1766 }, -- Kick (Rank 2)
        [1768] = { parent = 1766 }, -- Kick (Rank 3)
        [1769] = { parent = 1766 }, -- Kick (Rank 4)
        [38768] = { parent = 1766 }, -- Kick (Rank 5)

    [1776] = { -- Gouge (Rank 1)
        class = addon.ROGUE,
        cooldown = 10,
        category = category.OTHERS,
    },
        [1777] = { parent = 1776 }, -- Gouge (Rank 2)
        [8629] = { parent = 1776 }, -- Gouge (Rank 3)
        [11285] = { parent = 1776 }, -- Gouge (Rank 4)
        [11286] = { parent = 1776 }, -- Gouge (Rank 5)
        [38764] = { parent = 1776 }, -- Gouge (Rank 6)

    [1784] = { -- Stealth (Rank 1)
        class = addon.ROGUE,
        cooldown = 10,
        category = category.OTHERS,
    },
        [1785] = { parent = 1784 }, -- Stealth (Rank 2)
        [1786] = { parent = 1784 }, -- Stealth (Rank 3)
        [1787] = { parent = 1784 }, -- Stealth (Rank 4)

    [1856] = { -- Vanish (Rank 1)
        class = addon.ROGUE,
        cooldown = 300,
        category = category.OTHERS,
    },
        [1857] = { parent = 1856 }, -- Vanish (Rank 2)
        [26889] = { parent = 1856 }, -- Vanish (Rank 3)

    [1966] = { -- Feint (Rank 1)
        class = addon.ROGUE,
        cooldown = 10,
        category = category.OTHERS,
    },
        [6768] = { parent = 1966 }, -- Feint (Rank 2)
        [8637] = { parent = 1966 }, -- Feint (Rank 3)
        [11303] = { parent = 1966 }, -- Feint (Rank 4)
        [25302] = { parent = 1966 }, -- Feint (Rank 5)
        [27448] = { parent = 1966 }, -- Feint (Rank 6)

    [2094] = { -- Blind
        class = addon.ROGUE,
        cooldown = 180,
        category = category.OTHERS,
    },

    [2983] = { -- Sprint (Rank 1)
        class = addon.ROGUE,
        cooldown = 300,
        category = category.OTHERS,
    },
        [8696] = { parent = 2983 }, -- Sprint (Rank 2)
        [11305] = { parent = 2983 }, -- Sprint (Rank 3)

    [5277] = { -- Evasion (Rank 1)
        class = addon.ROGUE,
        cooldown = 300,
        category = category.OTHERS,
    },
        [26669] = { parent = 5277 }, -- Evasion (Rank 2)

    [13750] = { -- Adrenaline Rush
        class = addon.ROGUE,
        cooldown = 300,
        category = category.OTHERS,
    },

    [13877] = { -- Blade Flurry
        class = addon.ROGUE,
        cooldown = 120,
        category = category.OTHERS,
    },

    [14177] = { -- Cold Blood
        class = addon.ROGUE,
        cooldown = 180,
        category = category.OTHERS,
    },

    [14183] = { -- Premeditation
        class = addon.ROGUE,
        cooldown = 120,
        category = category.OTHERS,
    },

    [14185] = { -- Preparation
        class = addon.ROGUE,
        cooldown = 600,
        category = category.OTHERS,
    },

    [14251] = { -- Riposte
        class = addon.ROGUE,
        cooldown = 6,
        category = category.OTHERS,
    },

    [14278] = { -- Ghostly Strike
        class = addon.ROGUE,
        cooldown = 20,
        category = category.OTHERS,
    },

    [31224] = { -- Cloak of Shadows
        class = addon.ROGUE,
        cooldown = 60,
        category = category.OTHERS,
    },

    [36554] = { -- Shadowstep
        class = addon.ROGUE,
        cooldown = 30,
        category = category.OTHERS,
    },

    -- Warrior

    [100] = { -- Charge (Rank 1)
        class = addon.WARRIOR,
        cooldown = 15,
        category = category.OTHERS,
    },
        [6178] = { parent = 100 }, -- Charge (Rank 2)
        [11578] = { parent = 100 }, -- Charge (Rank 3)

    [355] = { -- Taunt
        class = addon.WARRIOR,
        cooldown = 10,
        category = category.OTHERS,
    },

    [676] = { -- Disarm
        class = addon.WARRIOR,
        cooldown = 60,
        category = category.OTHERS,
    },

    [694] = { -- Mocking Blow (Rank 1)
        class = addon.WARRIOR,
        cooldown = 120,
        category = category.OTHERS,
    },
        [7400] = { parent = 694 }, -- Mocking Blow (Rank 2)
        [7402] = { parent = 694 }, -- Mocking Blow (Rank 3)
        [20559] = { parent = 694 }, -- Mocking Blow (Rank 4)
        [20560] = { parent = 694 }, -- Mocking Blow (Rank 5)
        [25266] = { parent = 694 }, -- Mocking Blow (Rank 6)

    [871] = { -- Shield Wall
        class = addon.WARRIOR,
        cooldown = 1800,
        category = category.OTHERS,
    },

    [1161] = { -- Challenging Shout
        class = addon.WARRIOR,
        cooldown = 600,
        category = category.OTHERS,
    },

    [1680] = { -- Whirlwind
        class = addon.WARRIOR,
        cooldown = 10,
        category = category.OTHERS,
    },

    [1719] = { -- Recklessness
        class = addon.WARRIOR,
        cooldown = 1800,
        category = category.OTHERS,
    },

    [2565] = { -- Shield Block
        class = addon.WARRIOR,
        cooldown = 5,
        category = category.OTHERS,
    },

    [2687] = { -- Bloodrage
        class = addon.WARRIOR,
        cooldown = 60,
        category = category.OTHERS,
    },

    [3411] = { -- Intervene
        class = addon.WARRIOR,
        cooldown = 30,
        category = category.OTHERS,
    },

    [5246] = { -- Intimidating Shout
        class = addon.WARRIOR,
        cooldown = 180,
        category = category.OTHERS,
    },

    [6343] = { -- Thunder Clap (Rank 1)
        class = addon.WARRIOR,
        cooldown = 4,
        category = category.OTHERS,
    },
        [8198] = { parent = 6343 }, -- Thunder Clap (Rank 2)
        [8204] = { parent = 6343 }, -- Thunder Clap (Rank 3)
        [8205] = { parent = 6343 }, -- Thunder Clap (Rank 4)
        [11580] = { parent = 6343 }, -- Thunder Clap (Rank 5)
        [11581] = { parent = 6343 }, -- Thunder Clap (Rank 6)
        [25264] = { parent = 6343 }, -- Thunder Clap (Rank 7)

    [6552] = { -- Pummel (Rank 1)
        class = addon.WARRIOR,
        cooldown = 10,
        category = category.INTERRUPT,
    },
        [6554] = { parent = 6552 }, -- Pummel (Rank 2)
        [72] = { parent = 6552, cooldown = 12 }, -- Shield Bash (Rank 1)
        [1671] = { parent = 6552, cooldown = 12 }, -- Shield Bash (Rank 2)
        [1672] = { parent = 6552, cooldown = 12 }, -- Shield Bash (Rank 3)
        [29704] = { parent = 6552, cooldown = 12 }, -- Shield Bash (Rank 4)

    [6572] = { -- Revenge (Rank 1)
        class = addon.WARRIOR,
        cooldown = 5,
        category = category.OTHERS,
    },
        [6574] = { parent = 6572 }, -- Revenge (Rank 2)
        [7379] = { parent = 6572 }, -- Revenge (Rank 3)
        [11600] = { parent = 6572 }, -- Revenge (Rank 4)
        [11601] = { parent = 6572 }, -- Revenge (Rank 5)
        [25288] = { parent = 6572 }, -- Revenge (Rank 6)
        [25269] = { parent = 6572 }, -- Revenge (Rank 7)
        [30357] = { parent = 6572 }, -- Revenge (Rank 8)

    [7384] = { -- Overpower (Rank 1)
        class = addon.WARRIOR,
        cooldown = 5,
        category = category.OTHERS,
    },
        [7887] = { parent = 7384 }, -- Overpower (Rank 2)
        [11584] = { parent = 7384 }, -- Overpower (Rank 3)
        [11585] = { parent = 7384 }, -- Overpower (Rank 4)

    [12292] = { -- Death Wish
        class = addon.WARRIOR,
        cooldown = 180,
        category = category.OTHERS,
    },

    [12294] = { -- Mortal Strike (Rank 1)
        class = addon.WARRIOR,
        cooldown = 6,
        category = category.OTHERS,
    },
        [21551] = { parent = 12294 }, -- Mortal Strike (Rank 2)
        [21552] = { parent = 12294 }, -- Mortal Strike (Rank 3)
        [21553] = { parent = 12294 }, -- Mortal Strike (Rank 4)
        [25248] = { parent = 12294 }, -- Mortal Strike (Rank 5)
        [30330] = { parent = 12294 }, -- Mortal Strike (Rank 6)

    [12328] = { -- Sweeping Strikes
        class = addon.WARRIOR,
        cooldown = 30,
        category = category.OTHERS,
    },

    [12809] = { -- Concussion Blow
        class = addon.WARRIOR,
        cooldown = 45,
        category = category.OTHERS,
    },

    [12975] = { -- Last Stand
        class = addon.WARRIOR,
        cooldown = 480,
        category = category.OTHERS,
    },

    [18499] = { -- Berserker Rage
        class = addon.WARRIOR,
        cooldown = 30,
        category = category.OTHERS,
    },

    [20230] = { -- Retaliation
        class = addon.WARRIOR,
        cooldown = 1800,
        category = category.OTHERS,
    },

    [20252] = { -- Intercept (Rank 1)
        class = addon.WARRIOR,
        cooldown = 30,
        category = category.OTHERS,
    },
        [20616] = { parent = 20252 }, -- Intercept (Rank 2)
        [20617] = { parent = 20252 }, -- Intercept (Rank 3)
        [25272] = { parent = 20252 }, -- Intercept (Rank 4)
        [25275] = { parent = 20252 }, -- Intercept (Rank 5)

    [23881] = { -- Bloodthirst (Rank 1)
        class = addon.WARRIOR,
        cooldown = 6,
        category = category.OTHERS,
    },
        [23892] = { parent = 23881 }, -- Bloodthirst (Rank 2)
        [23893] = { parent = 23881 }, -- Bloodthirst (Rank 3)
        [23894] = { parent = 23881 }, -- Bloodthirst (Rank 4)
        [25251] = { parent = 23881 }, -- Bloodthirst (Rank 5)
        [30335] = { parent = 23881 }, -- Bloodthirst (Rank 6)

    [23920] = { -- Spell Reflection
        class = addon.WARRIOR,
        cooldown = 10,
        category = category.OTHERS,
    },

    [23922] = { -- Shield Slam (Rank 1)
        class = addon.WARRIOR,
        cooldown = 6,
        category = category.OTHERS,
    },
        [23923] = { parent = 23922 }, -- Shield Slam (Rank 2)
        [23924] = { parent = 23922 }, -- Shield Slam (Rank 3)
        [23925] = { parent = 23922 }, -- Shield Slam (Rank 4)
        [25258] = { parent = 23922 }, -- Shield Slam (Rank 5)
        [30356] = { parent = 23922 }, -- Shield Slam (Rank 6)
};

addon.SpellResets = {
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
