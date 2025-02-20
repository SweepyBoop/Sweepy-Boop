local _, addon = ...;

-- https://github.com/wardz/DRList-1.0/blob/master/DRList-1.0/Spells.lua
if addon.PROJECT_MAINLINE then
    addon.DRList = {
        -- *** Disorient Effects ***
        [207167]  = "disorient", -- Blinding Sleet
        [207685]  = "disorient", -- Sigil of Misery
        [33786]   = "disorient", -- Cyclone
        [360806]  = "disorient", -- Sleep Walk
        [1513]    = "disorient", -- Scare Beast
        [31661]   = "disorient", -- Dragon's Breath
        [198909]  = "disorient", -- Song of Chi-ji
        [202274]  = "disorient", -- Hot Trub
        [105421]  = "disorient", -- Blinding Light
        [10326]   = "disorient", -- Turn Evil
        [205364]  = "disorient", -- Dominate Mind
        [605]     = "disorient", -- Mind Control
        [8122]    = "disorient", -- Psychic Scream
        [2094]    = "disorient", -- Blind
        [118699]  = "disorient", -- Fear
        [130616]  = "disorient", -- Fear (Horrify)
        [5484]    = "disorient", -- Howl of Terror
        [261589]  = "disorient", -- Seduction (Grimoire of Sacrifice)
        [6358]    = "disorient", -- Seduction (Succubus)
        [5246]    = "disorient", -- Intimidating Shout
        [316593]  = "disorient", -- Intimidating Shout (Menace Main Target)
        [316595]  = "disorient", -- Intimidating Shout (Menace Other Targets)
        [331866]  = "disorient", -- Agent of Chaos (Venthyr Covenant)
        [324263]  = "disorient", -- Sulfuric Emission (Soulbind Ability)

        -- *** Incapacitate Effects ***
        [217832]  = "incapacitate", -- Imprison
        [221527]  = "incapacitate", -- Imprison (Honor talent)
        [2637]    = "incapacitate", -- Hibernate
        [99]      = "incapacitate", -- Incapacitating Roar
        [378441]  = "incapacitate", -- Time Stop
        [3355]    = "incapacitate", -- Freezing Trap
        [203337]  = "incapacitate", -- Freezing Trap (Honor talent)
        [213691]  = "incapacitate", -- Scatter Shot
        [383121]  = "incapacitate", -- Mass Polymorph
        [118]     = "incapacitate", -- Polymorph
        [28271]   = "incapacitate", -- Polymorph (Turtle)
        [28272]   = "incapacitate", -- Polymorph (Pig)
        [61025]   = "incapacitate", -- Polymorph (Snake)
        [61305]   = "incapacitate", -- Polymorph (Black Cat)
        [61780]   = "incapacitate", -- Polymorph (Turkey)
        [61721]   = "incapacitate", -- Polymorph (Rabbit)
        [126819]  = "incapacitate", -- Polymorph (Porcupine)
        [161353]  = "incapacitate", -- Polymorph (Polar Bear Cub)
        [161354]  = "incapacitate", -- Polymorph (Monkey)
        [161355]  = "incapacitate", -- Polymorph (Penguin)
        [161372]  = "incapacitate", -- Polymorph (Peacock)
        [277787]  = "incapacitate", -- Polymorph (Baby Direhorn)
        [277792]  = "incapacitate", -- Polymorph (Bumblebee)
        [321395]  = "incapacitate", -- Polymorph (Mawrat)
        [391622]  = "incapacitate", -- Polymorph (Duck)
        [460396]  = "incapacitate", -- Polymorph (Mosswool)
        [461489]  = "incapacitate", -- Polymorph (Mosswool) 2
        [82691]   = "incapacitate", -- Ring of Frost
        [115078]  = "incapacitate", -- Paralysis
        [357768]  = "incapacitate", -- Paralysis 2 (Perpetual Paralysis?)
        [20066]   = "incapacitate", -- Repentance
        [9484]    = "incapacitate", -- Shackle Undead
        [200196]  = "incapacitate", -- Holy Word: Chastise
        [1776]    = "incapacitate", -- Gouge
        [6770]    = "incapacitate", -- Sap
        [51514]   = "incapacitate", -- Hex
        [196942]  = "incapacitate", -- Hex (Voodoo Totem)
        [210873]  = "incapacitate", -- Hex (Raptor)
        [211004]  = "incapacitate", -- Hex (Spider)
        [211010]  = "incapacitate", -- Hex (Snake)
        [211015]  = "incapacitate", -- Hex (Cockroach)
        [269352]  = "incapacitate", -- Hex (Skeletal Hatchling)
        [309328]  = "incapacitate", -- Hex (Living Honey)
        [277778]  = "incapacitate", -- Hex (Zandalari Tendonripper)
        [277784]  = "incapacitate", -- Hex (Wicker Mongrel)
        [197214]  = "incapacitate", -- Sundering
        [710]     = "incapacitate", -- Banish
        [6789]    = "incapacitate", -- Mortal Coil
        [107079]  = "incapacitate", -- Quaking Palm (Racial, Pandaren)

        -- *** Controlled Stun Effects ***
        [210141]  = "stun", -- Zombie Explosion
        [377048]  = "stun", -- Absolute Zero (Breath of Sindragosa)
        [108194]  = "stun", -- Asphyxiate (Unholy)
        [221562]  = "stun", -- Asphyxiate (Blood)
        [91800]   = "stun", -- Gnaw (Ghoul)
        [91797]   = "stun", -- Monstrous Blow (Mutated Ghoul)
        [287254]  = "stun", -- Dead of Winter
        [179057]  = "stun", -- Chaos Nova
        [205630]  = "stun", -- Illidan's Grasp (Primary effect)
        [208618]  = "stun", -- Illidan's Grasp (Secondary effect)
        [211881]  = "stun", -- Fel Eruption
        [200166]  = "stun", -- Metamorphosis (PvE stun effect)
        [203123]  = "stun", -- Maim
        [163505]  = "stun", -- Rake (Prowl)
        [5211]    = "stun", -- Mighty Bash
        [202244]  = "stun", -- Overrun
        [325321]  = "stun", -- Wild Hunt's Charge
        [372245]  = "stun", -- Terror of the Skies
        [408544]  = "stun", -- Seismic Slam
        [117526]  = "stun", -- Binding Shot
        [357021]  = "stun", -- Consecutive Concussion
        [24394]   = "stun", -- Intimidation
        [389831]  = "stun", -- Snowdrift
        [119381]  = "stun", -- Leg Sweep
        [458605]  = "stun", -- Leg Sweep 2
        [202346]  = "stun", -- Double Barrel
        [853]     = "stun", -- Hammer of Justice
        [255941]  = "stun", -- Wake of Ashes
        [64044]   = "stun", -- Psychic Horror
        [200200]  = "stun", -- Holy Word: Chastise Censure
        [1833]    = "stun", -- Cheap Shot
        [408]     = "stun", -- Kidney Shot
        [118905]  = "stun", -- Static Charge (Capacitor Totem)
        [118345]  = "stun", -- Pulverize (Primal Earth Elemental)
        [305485]  = "stun", -- Lightning Lasso
        [89766]   = "stun", -- Axe Toss
        [171017]  = "stun", -- Meteor Strike (Infernal)
        [171018]  = "stun", -- Meteor Strike (Abyssal)
        [30283]   = "stun", -- Shadowfury
        [385954]  = "stun", -- Shield Charge
        [46968]   = "stun", -- Shockwave
        [132168]  = "stun", -- Shockwave (Protection)
        [145047]  = "stun", -- Shockwave (Proving Grounds PvE)
        [132169]  = "stun", -- Storm Bolt
        [199085]  = "stun", -- Warpath
        [20549]   = "stun", -- War Stomp (Racial, Tauren)
        [255723]  = "stun", -- Bull Rush (Racial, Highmountain Tauren)
        [287712]  = { "stun", "knockback" }, -- Haymaker (Racial, Kul Tiran)
        [332423]  = "stun", -- Sparkling Driftglobe Core (Kyrian Covenant)

        -- *** Controlled Root Effects ***
        -- Note: roots with duration <= 2s has no DR and are commented out
        [204085]  = "root", -- Deathchill (Chains of Ice)
        [233395]  = "root", -- Deathchill (Remorseless Winter)
        [454787]  = "root", -- Ice Prison
        [339]     = "root", -- Entangling Roots
        [235963]  = "root", -- Entangling Roots (Earthen Grasp)
        [170855]  = "root", -- Entangling Roots (Nature's Grasp)
        --[16979]   = "root", -- Wild Charge (has no DR)
        [102359]  = "root", -- Mass Entanglement
        [355689]  = "root", -- Landslide
        [393456]  = "root", -- Entrapment (Tar Trap)
        [162480]  = "root", -- Steel Trap
        --      [190927]  = "root", -- Harpoon (has no DR)
        [212638]  = "root", -- Tracker's Net
        [201158]  = "root", -- Super Sticky Tar
        [122]     = "root", -- Frost Nova
        [33395]   = "root", -- Freeze
        [386770]  = "root", -- Freezing Cold
        [378760]  = "root", -- Frostbite
        --[199786]  = "root", -- Glacial Spike (has no DR)
        [114404]  = "root", -- Void Tendril's Grasp
        [342375]  = "root", -- Tormenting Backlash (Torghast PvE)
        [116706]  = "root", -- Disable
        [324382]  = "root", -- Clash
        [64695]   = "root", -- Earthgrab (Totem effect)
        --[356738]  = "root", -- Earth Unleashed
        [285515]  = "root", -- Surge of Power
        [199042]  = "root", -- Thunderstruck (Protection PvP Talent)
        --[356356]  = "root", -- Warbringer
        [39965]   = "root", -- Frost Grenade (Item)
        [75148]   = "root", -- Embersilk Net (Item)
        [55536]   = "root", -- Frostweave Net (Item)
        [268966]  = "root", -- Hooked Deep Sea Net (Item)

        -- *** Silence Effects ***
        [47476]   = "silence", -- Strangulate
        [374776]  = "silence", -- Tightening Grasp
        [204490]  = "silence", -- Sigil of Silence
        --      [78675]   = "silence", -- Solar Beam (has no DR)
        [410065]  = "silence", -- Reactive Resin
        [202933]  = "silence", -- Spider Sting
        [356727]  = "silence", -- Spider Venom
        [354831]  = "silence", -- Wailing Arrow 1
        [355596]  = "silence", -- Wailing Arrow 2
        [217824]  = "silence", -- Shield of Virtue
        [15487]   = "silence", -- Silence
        [1330]    = "silence", -- Garrote
        [196364]  = "silence", -- Unstable Affliction Silence Effect

        -- *** Disarm Weapon Effects ***
        [209749]  = "disarm", -- Faerie Swarm (Balance Honor Talent)
        [407032]  = "disarm", -- Sticky Tar Bomb 1
        [407031]  = "disarm", -- Sticky Tar Bomb 2
        [207777]  = "disarm", -- Dismantle
        [233759]  = "disarm", -- Grapple Weapon
        [236077]  = "disarm", -- Disarm

        -- *** Force Taunt Effects ***
        [56222]   = "taunt", -- Dark Command
        [51399]   = "taunt", -- Death Grip (Taunt Effect)
        [185245]  = "taunt", -- Torment
        [6795]    = "taunt", -- Growl (Druid)
        [2649]    = "taunt", -- Growl (Hunter Pet)
        [20736]   = "taunt", -- Distracting Shot
        [116189]  = "taunt", -- Provoke
        [118635]  = "taunt", -- Provoke (Black Ox Statue)
        [196727]  = "taunt", -- Provoke (Niuzao)
        [204079]  = "taunt", -- Final Stand
        [62124]   = "taunt", -- Hand of Reckoning
        [17735]   = "taunt", -- Suffering (Voidwalker)
        [1161]    = "taunt", -- Challenging Shout
        [355]     = "taunt", -- Taunt

        -- *** Controlled Knockback Effects ***
        -- Note: not every knockback has an aura.
        [108199]  = "knockback", -- Gorefiend's Grasp
        [202249]  = "knockback", -- Overrun
        [61391]   = "knockback", -- Typhoon
        [102793]  = "knockback", -- Ursol's Vortex
        [431620]  = "knockback", -- Upheaval
        [186387]  = "knockback", -- Bursting Shot
        [236776]  = "knockback", -- Hi-Explosive Trap
        [236777]  = "knockback", -- Hi-Explosive Trap 2
        [462031]  = "knockback", -- Implosive Trap
        [157981]  = "knockback", -- Blast Wave
        [51490]   = "knockback", -- Thunderstorm
        [368970]  = "knockback", -- Tail Swipe (Racial, Dracthyr)
        [357214]  = "knockback", -- Wing Buffet (Racial, Dracthyr)
    };
else
    addon.DRList = {
        -- *** Incapacitate Effects ***
        [49203] = "incapacitate", -- Hungering Cold
        [2637]  = "incapacitate", -- Hibernate
        [3355]  = "incapacitate", -- Freezing Trap Effect
        [19386] = "incapacitate", -- Wyvern Sting
        [118]   = "incapacitate", -- Polymorph
        [28271] = "incapacitate", -- Polymorph: Turtle
        [28272] = "incapacitate", -- Polymorph: Pig
        [61025] = "incapacitate", -- Polymorph: Serpent
        [61721] = "incapacitate", -- Polymorph: Rabbit
        [61780] = "incapacitate", -- Polymorph: Turkey
        [61305] = "incapacitate", -- Polymorph: Black Cat
        [82691] = { "incapacitate", "deep_freeze_rof" }, -- Ring of Frost (Also shares DR with Deep Freeze)
        [20066] = "incapacitate", -- Repentance
        [1776]  = "incapacitate", -- Gouge
        [6770]  = "incapacitate", -- Sap
        [710]   = "incapacitate", -- Banish
        [9484]  = "incapacitate", -- Shackle Undead
        [51514] = "incapacitate", -- Hex
        [13327] = "incapacitate", -- Reckless Charge (Item)
        [4064]  = "incapacitate", -- Rough Copper Bomb (Item)
        [4065]  = "incapacitate", -- Large Copper Bomb (Item)
        [4066]  = "incapacitate", -- Small Bronze Bomb (Item)
        [4067]  = "incapacitate", -- Big Bronze Bomb (Item)
        [4068]  = "incapacitate", -- Iron Grenade (Item)
        [12421] = "incapacitate", -- Mithril Frag Bomb (Item)
        [4069]  = "incapacitate", -- Big Iron Bomb (Item)
        [12562] = "incapacitate", -- The Big One (Item)
        [12543] = "incapacitate", -- Hi-Explosive Bomb (Item)
        [19769] = "incapacitate", -- Thorium Grenade (Item)
        [19784] = "incapacitate", -- Dark Iron Bomb (Item)
        [30216] = "incapacitate", -- Fel Iron Bomb (Item)
        [30461] = "incapacitate", -- The Bigger One (Item)
        [30217] = "incapacitate", -- Adamantite Grenade (Item)
        [67769] = "incapacitate", -- Cobalt Frag Bomb (Item)
        [67890] = "incapacitate", -- Cobalt Frag Bomb (Item, Frag Belt)
        [54466] = "incapacitate", -- Saronite Grenade (Item)

        -- *** Controlled Stun Effects ***
        [47481] = "stun", -- Gnaw (Ghoul Pet)
        [91797] = "stun", -- Monstrous Blow (Dark Transformation)
        [5211]  = "stun", -- Bash
        [9005]  = "stun", -- Pounce
        [22570] = "stun", -- Maim
        [90337] = "stun", -- Bad Manner (Monkey)
        [93433] = "stun", -- Burrow Attack (Worm)
        [24394] = "stun", -- Intimidation
        [56626] = "stun", -- Sting (Wasp)
        [50519] = "stun", -- Sonic Blast
        [44572] = { "stun", "deep_freeze_rof" }, -- Deep Freeze (Also shares DR with Ring of Frost)
        [83046] = "stun", -- Improved Polymorph (Rank 1)
        [83047] = "stun", -- Improved Polymorph (Rank 2)
        [853]   = "stun", -- Hammer of Justice
        [2812]  = "stun", -- Holy Wrath
        --[88625] = "stun", -- Holy Word: Chastise
        [408]   = "stun", -- Kidney Shot
        [1833]  = "stun", -- Cheap Shot
        [58861] = "stun", -- Bash (Spirit Wolves)
        [39796] = "stun", -- Stoneclaw Stun
        [93986] = "stun", -- Aura of Foreboding
        [89766] = "stun", -- Axe Toss (Felguard)
        [54786] = "stun", -- Demon Leap
        [22703] = "stun", -- Inferno Effect
        [30283] = "stun", -- Shadowfury
        [12809] = "stun", -- Concussion Blow
        [46968] = "stun", -- Shockwave
        [85388] = "stun", -- Throwdown
        [20549] = "stun", -- War Stomp (Racial)

        -- *** Non-controlled Stun Effects ***
        [12355] = "random_stun", -- Impact
        [85387] = "random_stun", -- Aftermath
        [15283] = "random_stun", -- Stunning Blow (Weapon Proc)
        [56]    = "random_stun", -- Stun (Weapon Proc)
        [34510] = "random_stun", -- Stormherald/Deep Thunder (Weapon Proc)

        -- *** Fear Effects ***
        [1513]  = "fear", -- Scare Beast
        [10326] = "fear", -- Turn Evil
        [8122]  = "fear", -- Psychic Scream
        [2094]  = "fear", -- Blind
        [5782]  = "fear", -- Fear
        [6358]  = "fear", -- Seduction (Succubus)
        [5484]  = "fear", -- Howl of Terror
        [5246]  = "fear", -- Intimidating Shout
        [20511] = "fear", -- Intimidating Shout (secondary targets)
        [5134]  = "fear", -- Flash Bomb Fear (Item)

        -- *** Controlled Root Effects ***
        [96293] = "root", -- Chains of Ice (Chilblains Rank 1)
        [96294] = "root", -- Chains of Ice (Chilblains Rank 2)
        [339]   = "root", -- Entangling Roots
        [19975] = "root", -- Nature's Grasp
        [90327] = "root", -- Lock Jaw (Dog)
        [54706] = "root", -- Venom Web Spray (Silithid)
        [50245] = "root", -- Pin (Crab)
        [4167]  = "root", -- Web (Spider)
        [33395] = "root", -- Freeze (Water Elemental)
        [122]   = "root", -- Frost Nova
        [87193] = "root", -- Paralysis
        [64695] = "root", -- Earthgrab
        [63685] = "root", -- Freeze (Frost Shock)
        [39965] = "root", -- Frost Grenade (Item)
        [55536] = "root", -- Frostweave Net (Item)

        -- *** Non-controlled Root Effects ***
        [19185] = "random_root", -- Entrapment (Rank 1)
        [64803] = "random_root", -- Entrapment (Rank 2)
        [47168] = "random_root", -- Improved Wing Clip
        [83301] = "random_root", -- Improved Cone of Cold (Rank 1)
        [83302] = "random_root", -- Improved Cone of Cold (Rank 2)
        [55080] = "random_root", -- Shattered Barrier (Rank 1)
        [83073] = "random_root", -- Shattered Barrier (Rank 2)
        [23694] = "random_root", -- Improved Hamstring

        -- *** Disarm Weapon Effects ***
        [50541] = "disarm", -- Clench (Scorpid)
        [91644] = "disarm", -- Snatch (Bird of Prey)
        [64058] = "disarm", -- Psychic Horror Disarm Effect
        [51722] = "disarm", -- Dismantle
        [676]   = "disarm", -- Disarm

        -- *** Silence Effects ***
        [47476] = "silence", -- Strangulate
        [50479] = "silence", -- Nether Shock (Nether Ray)
        [34490] = "silence", -- Silencing Shot
        [18469] = "silence", -- Silenced - Improved Counterspell (Rank 1)
        [55021] = "silence", -- Silenced - Improved Counterspell (Rank 2)
        [31935] = "silence", -- Avenger's Shield
        [15487] = "silence", -- Silence
        [1330]  = "silence", -- Garrote - Silence
        [18425] = "silence", -- Silenced - Improved Kick
        [86759] = "silence", -- Silenced - Improved Kick (Rank 2)
        [24259] = "silence", -- Spell Lock
        [18498] = "silence", -- Silenced - Gag Order
        [50613] = "silence", -- Arcane Torrent (Racial, Runic Power)
        [28730] = "silence", -- Arcane Torrent (Racial, Mana)
        [25046] = "silence", -- Arcane Torrent (Racial, Energy)
        [69179] = "silence", -- Arcane Torrent (Rage version)
        [80483] = "silence", -- Arcane Torrent (Focus version)

        -- *** Horror Effects ***
        [64044] = "horror", -- Psychic Horror
        [6789]  = "horror", -- Death Coil

        -- *** Mind Control Effects ***
        [605]   = "mind_control", -- Mind Control
        [13181] = "mind_control", -- Gnomish Mind Control Cap (Item)
        [67799] = "mind_control", -- Mind Amplification Dish (Item)

        -- *** Force Taunt Effects ***
        [56222]   = "taunt", -- Dark Command
        [51399]   = "taunt", -- Death Grip (Taunt Effect)
        [6795]    = "taunt", -- Growl (Druid)
        [20736]   = "taunt", -- Distracting Shot
        [62124]   = "taunt", -- Hand of Reckoning
        [355]     = "taunt", -- Taunt

        -- TODO: knockbacks?

        -- *** Spells that DRs with itself only ***
        [19503] = "scatter", -- Scatter Shot
        [31661] = "scatter", -- Dragon's Breath
        [33786] = "cyclone", -- Cyclone
        [19306] = "counterattack", -- Counterattack
        [76780] = "bind_elemental", -- Bind Elemental
    };
end

-- Reference the list from BigDebuffs
addon.DRList[81261]   = "silence"; -- Solar Beam

addon.CrowdControlAuras = {};
for spellId, drType in pairs(addon.DRList) do
    if ( type(drType) == "table" ) or ( drType ~= "taunt" and drType ~= "knockback" ) then
        addon.CrowdControlAuras[spellId] = true;
    end
end
