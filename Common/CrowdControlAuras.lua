local _, addon = ...;

addon.CrowdControlAuras = {
    [388673] = true, -- Dragonrider's Initiative
    [454787] = true, -- Ice Prison
    [31661] = true, -- Dragon's Breath
    [200196] = true, -- Holy Word: Chastise
    [209749] = true, -- Faerie Swarm
    [6358] = true, -- Seduction
    [285515] = true, -- Surge of Power (Root)
    [385954] = true, -- Shield Charge
    [211010] = true, -- Hex (Snake)
    [391622] = true, -- Polymorph Duck
    [190925] = true, -- Harpoon
    [24394] = true, -- Intimidation
    [305252] = true, -- Gladiator's Maledict
    [324382] = true, -- Clash
    [204490] = true, -- Sigil of Silence
    [157997] = true, -- Ice Nova
    [118345] = true, -- Pulverize
    [305485] = true, -- Lightning Lasso (PvP Talent)
    [163505] = true, -- Rake
    [3355] = true, -- Freezing Trap
    [15487] = true, -- Silence
    [356567] = true, -- Shackles of Malediction
    [207167] = true, -- Blinding Sleet
    [132168] = true, -- Shockwave
    [460392] = true, -- Polymorph Mosswool
    [228600] = true, -- Glacial Spike Root
    [356727] = true, -- Spider Venom
    [277784] = true, -- Hex (Wicker Mongrel)
    [203123] = true, -- Maim
    [205630] = true, -- Illidan's Grasp - Grab
    [179057] = true, -- Chaos Nova
    [211881] = true, -- Fel Eruption
    [61305] = true, -- Polymorph Black Cat
    [126819] = true, -- Polymorph Porcupine
    [451517] = true, -- Catch Out
    [324263] = true, -- Sulfuric Emission (Necrolord - Emeni Trait)
    [91797] = true, -- Monstrous Blow
    [28272] = true, -- Polymorph Pig
    [2094] = true, -- Blind
    [213688] = true, -- Fel Cleave - Fel Lord stun (Demo PvP Talent)
    [255723] = true, -- Bull Rush
    [99] = true, -- Incapacitating Roar
    [393456] = true, -- Entrapment
    [22703] = true, -- Infernal Awakening
    [161354] = true, -- Polymorph Monkey
    [127797] = true, -- Ursol's Vortex
    [64695] = true, -- Earthgrab Totem
    [313148] = true, -- Forbidden Obsidian Claw
    [117526] = true, -- Binding Shot
    [407031] = true, -- Sticky Tar Bomb (AoE)
    [358861] = true, -- Void Volley: Horrify (Shadow PvP Talent)
    [710] = true, -- Banish
    [389831] = true, -- Snowdrift
    [107079] = true, -- Quaking Palm
    [115078] = true, -- Paralysis
    [105421] = true, -- Blinding Light
    [202244] = true, -- Overrun (Guardian PvP Talent)
    [1776] = true, -- Gouge
    [6770] = true, -- Sap
    [287254] = true, -- Dead of Winter
    [132169] = true, -- Storm Bolt
    [355689] = true, -- Landslide
    [217824] = true, -- Shield of Virtue (Protection PvP Talent) (defined as Interrupt)
    [105771] = true, -- Charge
    [20066] = true, -- Repentance
    [461489] = true, -- Polymorph Moss
    [331866] = true, -- Agent of Chaos (Venthyr - Nadjia Trait)
    [212638] = true, -- Tracker's Net
    [5484] = true, -- Howl of Terror
    [316595] = true, -- Menace (Other targets)
    [117405] = true, -- Binding Shot - aura when you're in the area
    [61780] = true, -- Polymorph Turkey
    [233759] = true, -- Grapple Weapon (MW/WW PvP Talent)
    [196364] = true, -- Unstable Affliction (Silence)
    [47476] = true, -- Strangulate
    [45334] = true, -- Immobilized (Wild Charge in Bear Form)
    [161353] = true, -- Polymorph Polar Bear Cub
    [277778] = true, -- Hex (Zandalari Tendonripper)
    [51514] = true, -- Hex
    [287712] = true, -- Haymaker
    [210141] = true, -- Zombie Explosion (Reanimation Unholy PvP Talent)
    [208618] = true, -- Illidan's Grasp - Stun
    [204085] = true, -- when applied by Chains of Ice
    [9484] = true, -- Shackle Undead
    [210873] = true, -- Hex (Compy)
    [277787] = true, -- Polymorph Direhorn
    [358259] = true, -- Gladiator's Maledict
    [407032] = true, -- Sticky Tar Bomb
    [332423] = true, -- Sparkling Driftglobe Core (Kyrian - Mikanikos Trait)
    [383121] = true, -- Mass Polymorph
    [199085] = true, -- Warpath (Prot PvP Talent)
    [213491] = true, -- Demonic Trample (short stun on targets)
    [1513] = true, -- Scare Beast
    [211004] = true, -- Hex (Spider)
    [236273] = true, -- Duel (Arms PvP Talent)
    [1098] = true, -- Subjugate Demon
    [374776] = true, -- Tightening Grasp (Silence)
    [356738] = true, -- Earth Unleashed
    [207685] = true, -- Sigil of Misery
    [385149] = true, -- Exorcism stun
    [1833] = true, -- Cheap Shot
    [221527] = true, -- Imprison (PvP Talent)
    [408] = true, -- Kidney Shot
    [199042] = true, -- Thunderstruck (Prot PvP Talent)
    [354051] = true, -- Nimble Steps
    [339] = true, -- Entangling Roots
    [114404] = true, -- Void Tendrils
    [378760] = true, -- Frostbite
    [91807] = true, -- Shambling Rush (defined as Interrupt)
    [116706] = true, -- Disable
    [212183] = true, -- Smoke Bomb (PvP Talent)
    [6789] = true, -- Mortal Coil
    [118905] = true, -- Static Charge
    [33786] = true, -- Cyclone
    [269352] = true, -- Hex (Skeletal Hatchling)
    [316593] = true, -- Menace (Main target)
    [1330] = true, -- Garrote - Silence
    [198909] = true, -- Song of Chi-Ji
    [236077] = true, -- Disarm (PvP Talent)
    [408544] = true, -- Seismic Slam
    [81261] = true, -- Solar Beam
    [33395] = true, -- Freeze
    [161372] = true, -- Polymorph Peacock
    [77505] = true, -- Earthquake (Stun)
    [102359] = true, -- Mass Entanglement
    [61721] = true, -- Polymorph Rabbit
    [211015] = true, -- Hex (Cockroach)
    [130616] = true, -- Fear (Horrify)
    [82691] = true, -- Ring of Frost
    [31935] = true, -- Avenger's Shield (defined as Interrupt)
    [255941] = true, -- Wake of Ashes stun
    [89766] = true, -- Axe Toss
    [372245] = true, -- Terror of the Skies
    [217832] = true, -- Imprison
    [2637] = true, -- Hibernate
    [213691] = true, -- Scatter Shot
    [356356] = true, -- Warbringer
    [203337] = true, -- Diamond Ice (Survival PvP Talent)
    [202274] = true, -- Incendiary Brew (Brew PvP Talent)
    [119381] = true, -- Leg Sweep
    [853] = true, -- Hammer of Justice
    [356723] = true, -- Scorpid Venom
    [360806] = true, -- Sleep Walk
    [64044] = true, -- Psychic Horror
    [207777] = true, -- Dismantle
    [5211] = true, -- Mighty Bash
    [449700] = true, -- Gravity Lapse (Wowhead labels it as a root mechanic)
    [118699] = true, -- Fear
    [30283] = true, -- Shadowfury
    [370970] = true, -- The Hunt (Root)
    [91800] = true, -- Gnaw
    [200200] = true, -- Holy Word: Chastise (Stun)
    [221562] = true, -- Asphyxiate
    [28271] = true, -- Polymorph Turtle
    [197214] = true, -- Sundering
    [277792] = true, -- Polymorph Bumblebee
    [309328] = true, -- Hex (Living Honey)
    [122] = true, -- Frost Nova
    [8122] = true, -- Psychic Scream
    [87204] = true, -- Sin and Punishment
    [233395] = true, -- when applied by Remorseless Winter
    [202346] = true, -- Double Barrel (Brew PvP Talent)
    [20549] = true, -- War Stomp
    [377048] = true, -- Absolute Zero
    [5246] = true, -- Intimidating Shout
    [605] = true, -- Mind Control
    [376080] = true, -- Champion's Spear
    [61025] = true, -- Polymorph Serpent
    [118] = true, -- Polymorph
    [10326] = true, -- Turn Evil
    [204080] = true, -- Deathchill
    [170855] = true, -- Entangling Roots (Nature's Grasp)
    [357021] = true, -- Consecutive Concussion
    [161355] = true, -- Polymorph Penguin
};

