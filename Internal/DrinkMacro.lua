local _, addon = ...;

local GetItemInfo = C_Item.GetItemInfo;
local GetItemCount = C_Item.GetItemCount;
local GetPlayerAuraBySpellID = C_UnitAuras.GetPlayerAuraBySpellID;

-- https://github.com/DavidPHH/Drink-Macro-Creator

-- Create a macro for drinks
local frameDrinkMacro = CreateFrame("Frame");
local inWorld = false;
local bestDrink = nil;
frameDrinkMacro:RegisterEvent(addon.BAG_UPDATE);
frameDrinkMacro:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
frameDrinkMacro:RegisterEvent(addon.PLAYER_REGEN_ENABLED);

local drinks = {
    113509, -- Conjured Mana Bun ................................................................ (100% MP/HP) [Mage Food]
    80618,  -- Conjured Mana Fritter ............................................................ (100% MP/HP) [Mage Food]
    80610,  -- Conjured Mana Pudding ............................................................ (100% MP/HP) [Mage Food]
    65499,  -- Conjured Mana Cake ............................................................... (100% MP/HP) [Mage Food]
    43523,  -- Conjured Mana Strudel ............................................................ (100% MP/HP) [Mage Food]
    43518,  -- Conjured Mana Pie ................................................................ (100% MP/HP) [Mage Food]
    65517,  -- Conjured Mana Lollipop ........................................................... (100% MP/HP) [Mage Food]
    65516,  -- Conjured Mana Cupcake ............................................................ (100% MP/HP) [Mage Food]
    65515,  -- Conjured Mana Brownie ............................................................ (100% MP/HP) [Mage Food]
    65500,  -- Conjured Mana Cookie ............................................................. (100% MP/HP) [Mage Food]
    227328, -- Wax Fondue ....................................................................... (3780k MP, 4500k HP) [189012.0]
    227336, -- Sugar Slurry ..................................................................... (3780k MP, 4500k HP) [189012.0]
    227325, -- Stone Soup ....................................................................... (3780k MP, 4500k HP) [189012.0]
    227329, -- Still-Twitching Gumbo ............................................................ (3780k MP, 4500k HP) [189012.0]
    227332, -- Sipping Aether ................................................................... (3780k MP, 4500k HP) [189012.0]
    227331, -- Saints' Delight .................................................................. (3780k MP, 4500k HP) [189012.0]
    227327, -- Rocky Road ....................................................................... (3780k MP, 4500k HP) [189012.0]
    227334, -- Mole Mole ........................................................................ (3780k MP, 4500k HP) [189012.0]
    227330, -- Grottochunk Stew ................................................................. (3780k MP, 4500k HP) [189012.0]
    227333, -- Glimmering Delicacy .............................................................. (3780k MP, 4500k HP) [189012.0]
    227326, -- Chalcocite Lava Cake ............................................................. (3780k MP, 4500k HP) [189012.0]
    227335, -- Borer Blood Pudding .............................................................. (3780k MP, 4500k HP) [189012.0]
    226811, -- Marinated Maggots ................................................................ (2842k MP, 710k HP) [142105.2]
    227309, -- Titanshake ....................................................................... (1135k MP, 0 HP) [56756.8]
    227315, -- Tarragon Soda .................................................................... (1135k MP, 0 HP) [56756.8]
    227313, -- Starfruit Puree .................................................................. (1135k MP, 0 HP) [56756.8]
    227310, -- Magmalaid ........................................................................ (1135k MP, 0 HP) [56756.8]
    227316, -- Eggnog ........................................................................... (1135k MP, 0 HP) [56756.8]
    227311, -- Digspresso ....................................................................... (1135k MP, 0 HP) [56756.8]
    224762, -- Delver's Waterskin ............................................................... (1135k MP, 0 HP) [56756.8]
    227314, -- Coffee, Light Ice ................................................................ (1135k MP, 0 HP) [56756.8]
    227312, -- Afterglow ........................................................................ (1135k MP, 0 HP) [56756.8]
    197770, -- Zesty Water ...................................................................... (540k MP, 0 HP) [27000.0]
    197762, -- Sweet and Sour Clam Chowder ...................................................... (428k MP, 321k HP) [21428.6]
    197763, -- Breakfast of Draconic Champions .................................................. (428k MP, 321k HP) [21428.6]
    197771, -- Delicious Dragon Spittle ......................................................... (428k MP, 0 HP) [21428.6]
    195464, -- Sweetened Broadhoof Milk ......................................................... (375k MP, 0 HP) [18750.0]
    201721, -- Life Fire Latte .................................................................. (375k MP, 0 HP) [18750.0]
    202315, -- Frozen Solid Tea ................................................................. (375k MP, 0 HP) [18750.0]
    204729, -- Freshly Squeezed Mosswater ....................................................... (375k MP, 0 HP) [18750.0]
    201725, -- Flappuccino ...................................................................... (375k MP, 0 HP) [18750.0]
    201046, -- Dreamwarding Dripbrew ............................................................ (375k MP, 0 HP) [18750.0]
    194685, -- Dragonspring Water ............................................................... (375k MP, 0 HP) [18750.0]
    197856, -- Cup o' Wakeup .................................................................... (375k MP, 0 HP) [18750.0]
    201697, -- Coldarra Coldbrew ................................................................ (375k MP, 0 HP) [18750.0]
    194683, -- Buttermilk ....................................................................... (375k MP, 0 HP) [18750.0]
    201698, -- Black Dragon Red Eye ............................................................. (375k MP, 0 HP) [18750.0]
    205794, -- Beetle Juice ..................................................................... (375k MP, 0 HP) [18750.0]
    194684, -- Azure Leywine .................................................................... (375k MP, 0 HP) [18750.0]
    191053, -- 10.0 Food/Drink Template - Drink Only - Level 70 - Required Level 65 ............. (375k MP, 0 HP) [18750.0]
    198441, -- Thunderspine Tenders ............................................................. (240k MP, 180k HP) [12000.0]
    207956, -- Thunderspine Nest ................................................................ (240k MP, 180k HP) [12000.0]
    196582, -- Syrup-Drenched Toast ............................................................. (240k MP, 180k HP) [12000.0]
    194681, -- Sugarwing Cupcake ................................................................ (240k MP, 180k HP) [12000.0]
    204790, -- Strong Sniffin' Soup for Niffen .................................................. (240k MP, 180k HP) [12000.0]
    195465, -- Stormwing Egg Breakfast .......................................................... (240k MP, 180k HP) [12000.0]
    205692, -- Stellaviatori Soup ............................................................... (240k MP, 180k HP) [12000.0]
    200871, -- Steamed Scarab Steak ............................................................. (240k MP, 180k HP) [12000.0]
    201820, -- Silithus Swiss ................................................................... (240k MP, 180k HP) [12000.0]
    194682, -- Mother's Gift .................................................................... (240k MP, 180k HP) [12000.0]
    204235, -- Kaldorei Fruitcake ............................................................... (240k MP, 180k HP) [12000.0]
    194680, -- Jerky Surprise ................................................................... (240k MP, 180k HP) [12000.0]
    198356, -- Honey Snack ...................................................................... (240k MP, 180k HP) [12000.0]
    197848, -- Hearty Squash Stew ............................................................... (240k MP, 180k HP) [12000.0]
    21215,  -- Graccu's Mince Meat Fruitcake .................................................... (240k MP, 180k HP) [12000.0]
    197847, -- Gorloc Fin Soup .................................................................. (240k MP, 180k HP) [12000.0]
    201420, -- Gnolan's House Special ........................................................... (240k MP, 180k HP) [12000.0]
    195466, -- Frenzy and Chips ................................................................. (240k MP, 180k HP) [12000.0]
    201413, -- Eternity-Infused Burrata ......................................................... (240k MP, 180k HP) [12000.0]
    197854, -- Enchanted Argali Tenderloin ...................................................... (240k MP, 180k HP) [12000.0]
    201469, -- Emerald Green Apple .............................................................. (240k MP, 180k HP) [12000.0]
    205690, -- Barter-B-Q ....................................................................... (240k MP, 180k HP) [12000.0]
    201047, -- Arcanostabilized Provisions ...................................................... (240k MP, 180k HP) [12000.0]
    201419, -- Apexis Asiago .................................................................... (240k MP, 180k HP) [12000.0]
    191056, -- 10.0 Food/Drink Template - Both Health and Mana - Level 70 - Required Level 65 ... (240k MP, 180k HP) [12000.0]
    75028,  -- Stormwind Surprise ............................................................... (240k MP, 0 HP) [12000.0]
    197857, -- Swog Slurp ....................................................................... (225k MP, 0 HP) [11250.0]
    201813, -- Spoiled Firewine ................................................................. (225k MP, 0 HP) [11250.0]
    194690, -- Horn o' Mead ..................................................................... (225k MP, 0 HP) [11250.0]
    195460, -- Fermented Musken Milk ............................................................ (225k MP, 0 HP) [11250.0]
    200305, -- Dracthyr Water Rations ........................................................... (225k MP, 0 HP) [11250.0]
    194692, -- Distilled Fish Juice ............................................................. (225k MP, 0 HP) [11250.0]
    194691, -- Artisanal Berry Juice ............................................................ (225k MP, 0 HP) [11250.0]
    195459, -- Argali Milk ...................................................................... (225k MP, 0 HP) [11250.0]
    197849, -- Ancient Firewine ................................................................. (225k MP, 0 HP) [11250.0]
    196584, -- Acorn Milk ....................................................................... (225k MP, 0 HP) [11250.0]
    191052, -- 10.0 Food/Drink Template - Drink Only - Level 65 - Required Level 60 ............. (225k MP, 0 HP) [11250.0]
    227320, -- Wicker Wisps ..................................................................... (214k MP, 0 HP) [10714.2]
    227322, -- Sanctified Sasparilla ............................................................ (214k MP, 0 HP) [10714.2]
    227318, -- Quicksilver Sipper ............................................................... (214k MP, 0 HP) [10714.2]
    222745, -- Pep-In-Your-Step ................................................................. (214k MP, 0 HP) [10714.2]
    227324, -- Nerub'ar Nectar .................................................................. (214k MP, 0 HP) [10714.2]
    227323, -- Mushroom Tea ..................................................................... (214k MP, 0 HP) [10714.2]
    227317, -- Lava Cola ........................................................................ (214k MP, 0 HP) [10714.2]
    227319, -- Koboldchino ...................................................................... (214k MP, 0 HP) [10714.2]
    222744, -- Cinder Nectar .................................................................... (214k MP, 0 HP) [10714.2]
    227321, -- Blessed Brew ..................................................................... (214k MP, 0 HP) [10714.2]
    169763, -- Mardivas's Magnificent Desalinating Pouch ........................................ (96k MP, 0 HP) [9600.0]
    20516,  -- Bobbing Apple .................................................................... (180k MP, 135k HP) [7200.0]
    177041, -- Sunwarmed Xyfias ................................................................. (120k MP, 90k HP) [6000.0]
    174283, -- Stygian Stew ..................................................................... (120k MP, 90k HP) [6000.0]
    180011, -- Stale Brewfest Pretzel ........................................................... (120k MP, 90k HP) [6000.0]
    177042, -- Five-Chime Batzos ................................................................ (120k MP, 90k HP) [6000.0]
    173859, -- Ethereal Pomegranate ............................................................. (120k MP, 90k HP) [6000.0]
    174284, -- Empyrean Fruit Salad ............................................................. (120k MP, 90k HP) [6000.0]
    190881, -- Circle of Subsistence ............................................................ (120k MP, 90k HP) [6000.0]
    190880, -- Catalyzed Apple Pie .............................................................. (120k MP, 90k HP) [6000.0]
    172047, -- Candied Amberjack Cakes .......................................................... (120k MP, 90k HP) [6000.0]
    173351, -- 9.0 Template Food 130 ............................................................ (120k MP, 90k HP) [6000.0]
    186704, -- Twilight Tea ..................................................................... (120k MP, 0 HP) [6000.0]
    178535, -- Suspicious Slime Shot ............................................................ (120k MP, 0 HP) [6000.0]
    179992, -- Shadespring Water ................................................................ (120k MP, 0 HP) [6000.0]
    190936, -- Restorative Flow ................................................................. (120k MP, 0 HP) [6000.0]
    178539, -- Lukewarm Tauralus Milk ........................................................... (120k MP, 0 HP) [6000.0]
    178545, -- Bone Apple Tea ................................................................... (120k MP, 0 HP) [6000.0]
    178217, -- Azurebloom Tea ................................................................... (120k MP, 0 HP) [6000.0]
    177040, -- Ambroria Dew ..................................................................... (120k MP, 0 HP) [6000.0]
    187911, -- Sable "Soup" ..................................................................... (50k MP, 37k HP) [2500.0]
    184201, -- Slushy Water ..................................................................... (50k MP, 0 HP) [2500.0]
    174281, -- Purified Skyspring Water ......................................................... (50k MP, 0 HP) [2500.0]
    179993, -- Infused Muck Water ............................................................... (50k MP, 0 HP) [2500.0]
    173762, -- Flask of Ardendew ................................................................ (50k MP, 0 HP) [2500.0]
    178542, -- Cranial Concoction ............................................................... (50k MP, 0 HP) [2500.0]
    178534, -- Corpini Slurry ................................................................... (50k MP, 0 HP) [2500.0]
    178538, -- Beetle Juice ..................................................................... (50k MP, 0 HP) [2500.0]
    172046, -- Biscuits and Caviar .............................................................. (36k MP, 45k HP) [1800.0]
    173350, -- 9.0 Template Food 125 ............................................................ (36k MP, 45k HP) [1800.0]
    180006, -- Warm Brewfest Pretzel ............................................................ (32k MP, 10k HP) [1600.0]
    180054, -- Lunar Dumplings .................................................................. (32k MP, 10k HP) [1600.0]
    133980, -- Murky Cavewater .................................................................. (32k MP, 0 HP) [1600.0]
    154891, -- Seasoned Loins ................................................................... (24k MP, 40k HP) [1200.0]
    163692, -- Scroll of Subsistence ............................................................ (24k MP, 40k HP) [1200.0]
    169954, -- Steeped Kelp Tea ................................................................. (24k MP, 0 HP) [1200.0]
    163784, -- Seafoam Coconut Water ............................................................ (24k MP, 0 HP) [1200.0]
    169952, -- Sea Salt Java .................................................................... (24k MP, 0 HP) [1200.0]
    159867, -- Rockskip Mineral Water ........................................................... (24k MP, 0 HP) [1200.0]
    162570, -- Pricklevine Juice ................................................................ (24k MP, 0 HP) [1200.0]
    163786, -- Filtered Gloomwater .............................................................. (24k MP, 0 HP) [1200.0]
    163785, -- Canteen of Rivermarsh Rainwater .................................................. (24k MP, 0 HP) [1200.0]
    169949, -- Bioluminescent Ocean Punch ....................................................... (24k MP, 0 HP) [1200.0]
    139347, -- Underjelly ....................................................................... (20k MP, 0 HP) [1000.0]
    140272, -- Suramar Spiced Tea ............................................................... (20k MP, 0 HP) [1000.0]
    178515, -- Stitched Surprise Cake ........................................................... (20k MP, 0 HP) [1000.0]
    87253,  -- Perpetual Leftovers .............................................................. (20k MP, 0 HP) [1000.0]
    138982, -- Pail of Warm Milk ................................................................ (20k MP, 0 HP) [1000.0]
    162012, -- Magic Truffle .................................................................... (20k MP, 0 HP) [1000.0]
    138292, -- Ley-Enriched Water ............................................................... (20k MP, 0 HP) [1000.0]
    140265, -- Legendermainy Light Roast ........................................................ (20k MP, 0 HP) [1000.0]
    140266, -- Kafa Kicker ...................................................................... (20k MP, 0 HP) [1000.0]
    140269, -- Iced Highmountain Refresher ...................................................... (20k MP, 0 HP) [1000.0]
    88578,  -- Cup of Kafa ...................................................................... (20k MP, 0 HP) [1000.0]
    128850, -- Chilled Conjured Water ........................................................... (20k MP, 0 HP) [1000.0]
    140629, -- Bottled Maelstrom ................................................................ (20k MP, 0 HP) [1000.0]
    152717, -- Azuremyst Water Flask ............................................................ (20k MP, 0 HP) [1000.0]
    140204, -- 'Bottled' Ley-Enriched Water ..................................................... (20k MP, 0 HP) [1000.0]
    41731,  -- Yeti Milk ........................................................................ (28k MP, 0 HP) [944.8]
    43236,  -- Star's Sorrow .................................................................... (28k MP, 0 HP) [944.8]
    59229,  -- Murky Water ...................................................................... (28k MP, 0 HP) [944.8]
    33445,  -- Honeymint Tea .................................................................... (28k MP, 0 HP) [944.8]
    58274,  -- Fresh Water ...................................................................... (28k MP, 0 HP) [944.8]
    42777,  -- Crusader's Waterskin ............................................................. (28k MP, 0 HP) [944.8]
    162569, -- Sun-Parched Waterskin ............................................................ (18k MP, 0 HP) [900.0]
    163102, -- Starhook Special Blend ........................................................... (18k MP, 0 HP) [900.0]
    163104, -- Sailor's Choice Coffee ........................................................... (18k MP, 0 HP) [900.0]
    162547, -- Raw Nazmani Mineral Water ........................................................ (18k MP, 0 HP) [900.0]
    163783, -- Mount Mugamba Spring Water ....................................................... (18k MP, 0 HP) [900.0]
    159868, -- Free-Range Goat's Milk ........................................................... (18k MP, 0 HP) [900.0]
    169948, -- Filtered Zanj'ir Water ........................................................... (18k MP, 0 HP) [900.0]
    169120, -- Enhancement-Free Water ........................................................... (18k MP, 0 HP) [900.0]
    169119, -- Enhanced Water ................................................................... (18k MP, 0 HP) [900.0]
    163101, -- Drustvar Dark Roast .............................................................. (18k MP, 0 HP) [900.0]
    139398, -- Pant Loaf ........................................................................ (15k MP, 30k HP) [750.0]
    140355, -- Laden Apple ...................................................................... (15k MP, 30k HP) [750.0]
    138986, -- Kurdos Yogurt .................................................................... (15k MP, 30k HP) [750.0]
    138983, -- Kurd's Soft Serve ................................................................ (15k MP, 30k HP) [750.0]
    133575, -- Dried Mackerel Strips ............................................................ (15k MP, 30k HP) [750.0]
    140298, -- Mananelle's Sparkling Cider ...................................................... (15k MP, 0 HP) [750.0]
    141215, -- Arcberry Juice ................................................................... (15k MP, 0 HP) [750.0]
    154889, -- Grilled Catfish .................................................................. (12k MP, 20k HP) [600.0]
    158926, -- Fried Turtle Bits ................................................................ (12k MP, 20k HP) [600.0]
    139346, -- Thuni's Patented Drinking Fluid .................................................. (8k MP, 0 HP) [425.0]
    141527, -- Slightly Rusted Canteen .......................................................... (8k MP, 0 HP) [425.0]
    138981, -- Skinny Milk ...................................................................... (8k MP, 0 HP) [425.0]
    111455, -- Saberfish Broth .................................................................. (8k MP, 0 HP) [425.0]
    140628, -- Lavacolada ....................................................................... (8k MP, 0 HP) [425.0]
    133586, -- Illidari Waterskin ............................................................... (8k MP, 0 HP) [425.0]
    128853, -- Highmountain Spring Water ........................................................ (8k MP, 0 HP) [425.0]
    138975, -- Highmountain Runoff .............................................................. (8k MP, 0 HP) [425.0]
    117452, -- Gorgrond Mineral Water ........................................................... (8k MP, 0 HP) [425.0]
    111544, -- Frostboar Jerky .................................................................. (8k MP, 0 HP) [425.0]
    128385, -- Elemental-Distilled Water ........................................................ (8k MP, 0 HP) [425.0]
    117475, -- Clefthoof Milk ................................................................... (8k MP, 0 HP) [425.0]
    118424, -- Blind Palefish ................................................................... (8k MP, 0 HP) [425.0]
    130259, -- Ancient Bandana .................................................................. (8k MP, 0 HP) [425.0]
    140203, -- 'Natural' Highmountain Spring Water .............................................. (8k MP, 0 HP) [425.0]
    74822,  -- Sasparilla Sinker ................................................................ (8k MP, 0 HP) [275.0]
    63251,  -- Mei's Masterful Brew ............................................................. (8k MP, 0 HP) [275.0]
    68140,  -- Invigorating Pineapple Punch ..................................................... (8k MP, 0 HP) [275.0]
    58257,  -- Highland Spring Water ............................................................ (8k MP, 0 HP) [275.0]
    104348, -- Timeless Tea ..................................................................... (5k MP, 0 HP) [275.0]
    88532,  -- Lotus Water ...................................................................... (5k MP, 0 HP) [275.0]
    108920, -- Lemon Flower Pudding ............................................................. (5k MP, 0 HP) [275.0]
    112449, -- Iron Horde Rations ............................................................... (5k MP, 0 HP) [275.0]
    74636,  -- Golden Carp Consomme ............................................................. (5k MP, 0 HP) [275.0]
    105711, -- Funky Monkey Brew ................................................................ (5k MP, 0 HP) [275.0]
    81923,  -- Cobo Cola ........................................................................ (5k MP, 0 HP) [275.0]
    75038,  -- Mad Brewer's Breakfast ........................................................... (2k MP, 0 HP) [275.0]
    75037,  -- Jade Witch Brew .................................................................. (2k MP, 0 HP) [275.0]
    130192, -- Potato Axebeak Stew .............................................................. (5k MP, 11k HP) [255.0]
    116120, -- Tasty Talador Lunch .............................................................. (5k MP, 0 HP) [255.0]
    58256,  -- Sparkling Oasis Water ............................................................ (6k MP, 0 HP) [223.6]
    59029,  -- Greasy Whale Milk ................................................................ (6k MP, 0 HP) [223.6]
    59230,  -- Fungus Squeezings ................................................................ (6k MP, 0 HP) [223.6]
    98118,  -- Scorpion Crunchies ............................................................... (4k MP, 0 HP) [223.6]
    86026,  -- Perfectly Cooked Instant Noodles ................................................. (4k MP, 0 HP) [223.6]
    98111,  -- K.R.E. ........................................................................... (4k MP, 0 HP) [223.6]
    75026,  -- Ginseng Tea ...................................................................... (4k MP, 0 HP) [223.6]
    98116,  -- Freeze-Dried Hyena Jerky ......................................................... (4k MP, 0 HP) [223.6]
    85501,  -- Viseclaw Soup .................................................................... (3k MP, 0 HP) [183.4]
    81924,  -- Carbonated Water ................................................................. (3k MP, 0 HP) [183.4]
    140340, -- Bottled - Carbonated Water ....................................................... (3k MP, 0 HP) [183.4]
    29454,  -- Silverwine ....................................................................... (5k MP, 0 HP) [168.0]
    28399,  -- Filtered Draenic Water ........................................................... (5k MP, 0 HP) [168.0]
    32722,  -- Enriched Terocone Juice .......................................................... (5k MP, 0 HP) [168.0]
    38430,  -- Blackrock Mineral Water .......................................................... (5k MP, 0 HP) [168.0]
    33444,  -- Pungent Seal Whey ................................................................ (5k MP, 0 HP) [167.8]
    44941,  -- Fresh-Squeezed Limeade ........................................................... (5k MP, 0 HP) [167.8]
    43086,  -- Fresh Apple Juice ................................................................ (5k MP, 0 HP) [167.8]
    38698,  -- Bitter Plasma .................................................................... (5k MP, 0 HP) [167.8]
    45932,  -- Black Jelly ...................................................................... (8k MP, 0 HP) [142.2]
    34759,  -- Smoked Rockfin ................................................................... (4k MP, 0 HP) [142.2]
    43480,  -- Small Feast ...................................................................... (4k MP, 0 HP) [142.2]
    34761,  -- Sauteed Goby ..................................................................... (4k MP, 0 HP) [142.2]
    34760,  -- Grilled Bonescale ................................................................ (4k MP, 0 HP) [142.2]
    43478,  -- Gigantic Feast ................................................................... (4k MP, 0 HP) [142.2]
    62675,  -- Starfire Espresso ................................................................ (3k MP, 0 HP) [128.0]
    35954,  -- Sweetened Goat's Milk ............................................................ (3k MP, 0 HP) [118.0]
    32453,  -- Star's Tears ..................................................................... (3k MP, 0 HP) [118.0]
    29401,  -- Sparkling Southshore Cider ....................................................... (3k MP, 0 HP) [118.0]
    27860,  -- Purified Draenic Water ........................................................... (3k MP, 0 HP) [118.0]
    34780,  -- Naaru Ration ..................................................................... (3k MP, 0 HP) [118.0]
    44750,  -- Mountain Water ................................................................... (3k MP, 0 HP) [118.0]
    40357,  -- Grizzleberry Juice ............................................................... (3k MP, 0 HP) [118.0]
    30457,  -- Gilneas Sparkling Water .......................................................... (3k MP, 0 HP) [118.0]
    37253,  -- Frostberry Juice ................................................................. (3k MP, 0 HP) [118.0]
    29395,  -- Ethermead ........................................................................ (3k MP, 0 HP) [118.0]
    32668,  -- Dos Ogris ........................................................................ (3k MP, 0 HP) [118.0]
    38431,  -- Blackrock Fortified Water ........................................................ (3k MP, 0 HP) [118.0]
    33042,  -- Black Coffee ..................................................................... (3k MP, 0 HP) [118.0]
    61382,  -- Garr's Limeade ................................................................... (3k MP, 0 HP) [100.0]
    32455,  -- Star's Lament .................................................................... (2k MP, 0 HP) [90.0]
    18300,  -- Hyjal Nectar ..................................................................... (2k MP, 0 HP) [90.0]
    68687,  -- Scalding Murglesnout ............................................................. (1k MP, 0 HP) [60.0]
    8766,   -- Morning Glory Dew ................................................................ (1k MP, 0 HP) [45.0]
    38429,  -- Blackrock Spring Water ........................................................... (1k MP, 0 HP) [45.0]
    63023,  -- Sweet Tea ........................................................................ (630 MP, 0 HP) [21.0]
    1645,   -- Moonberry Juice .................................................................. (630 MP, 0 HP) [21.0]
    19300,  -- Bottled Winterspring Water ....................................................... (630 MP, 0 HP) [21.0]
    49601,  -- Volcanic Spring Water ............................................................ (378 MP, 0 HP) [18.0]
    63530,  -- Refreshing Pineapple Punch ....................................................... (378 MP, 0 HP) [18.0]
    90659,  -- Jasmine Tea ...................................................................... (378 MP, 0 HP) [18.0]
    1179,   -- Ice Cold Milk .................................................................... (378 MP, 0 HP) [18.0]
    49602,  -- Earl Black Tea ................................................................... (378 MP, 0 HP) [18.0]
    17404,  -- Blended Bean Brew ................................................................ (378 MP, 0 HP) [18.0]
    1708,   -- Sweet Nectar ..................................................................... (270 MP, 0 HP) [10.0]
    10841,  -- Goldthorn Tea .................................................................... (270 MP, 0 HP) [10.0]
    4791,   -- Enchanted Water .................................................................. (270 MP, 0 HP) [10.0]
    1205,   -- Melon Juice ...................................................................... (216 MP, 0 HP) [9.0]
    19299,  -- Fizzy Faire Drink ................................................................ (216 MP, 0 HP) [9.0]
    9451,   -- Bubbling Water ................................................................... (216 MP, 0 HP) [9.0]
    155909, -- Bottled Stillwater ............................................................... (216 MP, 0 HP) [9.0]
    90660,  -- Black Tea ........................................................................ (216 MP, 0 HP) [9.0]
    60269,  -- Well Water ....................................................................... (136 MP, 0 HP) [7.5]
    49254,  -- Tarp Collected Dew ............................................................... (136 MP, 0 HP) [7.5]
    159,    -- Refreshing Spring Water .......................................................... (136 MP, 0 HP) [7.5]
    62672   -- South Island Iced Tea ............................................................ (18 MP, 0 HP) [0.6]
}

local function SetBestDrink()
    local level = UnitLevel("player");
    for _, drink in pairs(drinks) do
        local item, _, _, _, itemMinLevel = GetItemInfo(drink);
        local itemCount = GetItemCount(drink);
        if ( item and itemMinLevel and itemCount ) then
            if ( itemCount > 0 ) and ( itemMinLevel <= level ) then
                bestDrink = item;
                return;
            end
        end
    end
end

local healthStone;

local classSpell = {
    [addon.DRUID] = "Frenzied Regeneration",
    [addon.PRIEST] = "Desperate Prayer",
    [addon.PALADIN] = "Divine Protection",
};

local function SetHealthStone()
    local itemCount = GetItemCount(5512);
    if itemCount > 0 then
        healthStone = "Healthstone";
    else
        -- No health stone, show tooltip of a class ability
        local class = select(2, UnitClass("player"));
        healthStone = classSpell[class] or "";
    end
end

local function MakeDrinkMacro()
    local oldBest = bestDrink; -- Avoids unecessary edits
    SetBestDrink();
    local iMacro = GetMacroIndexByName("DrinkMacro");
    if ( iMacro == 0 ) and bestDrink then
        CreateMacro("DrinkMacro", "INV_MISC_QUESTIONMARK", "#showtooltip\n/use "..bestDrink.."\n/cast !Prowl");
    elseif ( oldBest ~= bestDrink ) then
        EditMacro(iMacro, "DrinkMacro", "INV_MISC_QUESTIONMARK", "#showtooltip\n/use "..bestDrink.."\n/cast !Prowl");
    end

    -- Edit the Warlock Healthstone macro
    local oldHealthStone = healthStone;
    SetHealthStone();
    local index = GetMacroIndexByName("CandyMacro");
    if ( index == 0 ) and healthStone then
        CreateMacro("CandyMacro", "INV_MISC_QUESTIONMARK", "#showtooltip " .. healthStone .. "\n/use Healthstone");
    elseif ( oldHealthStone ~= healthStone ) then
        EditMacro(index, "CandyMacro", "INV_MISC_QUESTIONMARK", "#showtooltip " .. healthStone .. "\n/use Healthstone");
    end
end

local function eventHandler(self, event, ...)
    if InCombatLockdown() then
        return
    end
    -- If not in combat, make a macro or edit existing one
    if ( event == addon.PLAYER_ENTERING_WORLD ) then
        inWorld = true;
        MakeDrinkMacro();
    end
    if ( event == addon.BAG_UPDATE ) and inWorld then
        MakeDrinkMacro();
    end
    if ( event == addon.PLAYER_REGEN_ENABLED ) and inWorld then -- Exiting combat
        MakeDrinkMacro();
    end
end

frameDrinkMacro:SetScript("OnEvent", eventHandler);
