local _, NS = ...;

local CreateFrame = CreateFrame;
local UnitLevel = UnitLevel;
local GetMacroIndexByName = GetMacroIndexByName;
local GetItemInfo = GetItemInfo;
local GetItemCount = GetItemCount;
local CreateMacro = CreateMacro;
local EditMacro = EditMacro;
local InCombatLockdown = InCombatLockdown;
local IsInInstance = IsInInstance;
local GetTime = GetTime;
local SendChatMessage = SendChatMessage;
local GetPlayerAuraBySpellID = C_UnitAuras.GetPlayerAuraBySpellID;

-- https://github.com/DavidPHH/Drink-Macro-Creator

-- Create a macro for drinks
local frameDrinkMacro = CreateFrame("Frame");
local inWorld = false;
local bestDrink = nil;
frameDrinkMacro:RegisterEvent(NS.BAG_UPDATE);
frameDrinkMacro:RegisterEvent(NS.PLAYER_ENTERING_WORLD);
frameDrinkMacro:RegisterEvent(NS.PLAYER_REGEN_ENABLED);

local drinks = {
    -- itemID, -- name ............................... (Mana / HP Gain / Buff) [Avg Mana/Second]
    113509, -- Conjured Mana Bun ..................... (100% MP, 100% HP)
    80618,  -- Conjured Mana Fritter ................. (100% MP, 100% HP)
    80610,  -- Conjured Mana Pudding ................. (100% MP, 100% HP)
    65499,  -- Conjured Mana Cake .................... (100% MP, 100% HP)
    43523,  -- Conjured Mana Strudel ................. (100% MP, 100% HP)
    43518,  -- Conjured Mana Pie ..................... (100% MP, 100% HP)
    65517,  -- Conjured Mana Lollipop ................ (100% MP, 100% HP)
    65516,  -- Conjured Mana Cupcake ................. (100% MP, 100% HP)
    65515,  -- Conjured Mana Brownie ................. (100% MP, 100% HP)
    65500,  -- Conjured Mana Cookie .................. (100% MP, 100% HP)
    194684, -- Azure Leywine ......................... (175k MP) [8750]
    194683, -- Buttermilk ............................ (175k MP) [8750]
    201698, -- Black Dragon Red Eye .................. (175k MP) [8750]
    201697, -- Coldarra Coldbrew ..................... (175k MP) [8750]
    197856, -- Cup o' Wakeup ......................... (175k MP) [8750]
    197771, -- Delicious Dragon Spittle .............. (175k MP) [8750]
    194685, -- Dragonspring Water .................... (175k MP) [8750]
    201046, -- Dreamwarding Dripbrew ................. (175k MP) [8750]
    201725, -- Flappuccino ........................... (175k MP) [8750]
    201721, -- Life Fire Latte ....................... (175k MP) [8750]
    195464, -- Sweetened Broadhoof Milk .............. (175k MP) [8750]
    -- 197772, -- Churnbelly Tea ..................... (175k MP, Well Fed: Swim Speed, Underwater Breathing) [8750]
    201419, -- Apexis Asiago ......................... (66.7k MP, 50k HP) [3333]
    197763, -- Breakfast of Draconic Champions ....... (66.7k MP, 50k HP) [3333]
    201469, -- Emerald Green Apple ................... (66.7k MP, 50k HP) [3333]
    197854, -- Enchanted Argali Tenderloin ........... (66.7k MP, 50k HP) [3333]
    201413, -- Eternity-Infused Burrata .............. (66.7k MP, 50k HP) [3333]
    195466, -- Frenzy and Chips ...................... (66.7k MP, 50k HP) [3333]
    197847, -- Gorloc Fin Soup ....................... (66.7k MP, 50k HP) [3333]
    197848, -- Hearty Squash Stew .................... (66.7k MP, 50k HP) [3333]
    198356, -- Honey Snack ........................... (66.7k MP, 50k HP) [3333]
    194680, -- Jerky Surprise ........................ (66.7k MP, 50k HP) [3333]
    201047, -- Magically Repurposed Essentials ....... (66.7k MP, 50k HP) [3333]
    194682, -- Mother's Gift ......................... (66.7k MP, 50k HP) [3333]
    200871, -- Steamed Scarab Steak .................. (66.7k MP, 50k HP) [3333]
    195465, -- Stormwing Egg Breakfast ............... (66.7k MP, 50k HP) [3333]
    194681, -- Sugarwing Cupcake ..................... (66.7k MP, 50k HP) [3333]
    197762, -- Sweet and Sour Clam Chowder ........... (66.7k MP, 50k HP) [3333]
    196582, -- Syrup-Drenched Toast .................. (66.7k MP, 50k HP) [3333]
    198441, -- Thunderspine Tenders .................. (66.7k MP, 50k HP) [3333]
    196584, -- Acorn Milk ............................ (62.5k MP) [3125]
    197849, -- Ancient Firewine ...................... (62.5k MP) [3125]
    195459, -- Argali Milk ........................... (62.5k MP) [3125]
    194691, -- Artisanal Berry Juice ................. (62.5k MP) [3125]
    194692, -- Distilled Fish Juice .................. (62.5k MP) [3125]
    200305, -- Dracthyr Water Rations ................ (62.5k MP) [3125]
    195460, -- Fermented Musken Milk ................. (62.5k MP) [3125]
    194690, -- Horn o' Mead .......................... (62.5k MP) [3125]
    197857, -- Swog Slurp ............................ (62.5k MP) [3125]
    197770, -- Zesty Water ........................... (62.5k MP) [3125]
    201820, -- Silithus Swiss ........................ (53.3k MP, 40k HP) [2667]
    201420, -- Gnolan's House Special ................ (53.3k MP) [2667]
    201813, -- Spoiled Firewine ...................... (50k MP) [2500]
    172047, -- Candied Amberjack Cakes ............... (40k MP, 30k HP) [2000]
    190880, -- Catalyzed Apple Pie ................... (40k MP, 30k HP) [2000]
    190881, -- Circle of Subsistence ................. (40k MP, 30k HP) [2000]
    174284, -- Empyrean Fruit Salad .................. (40k MP, 30k HP) [2000]
    173859, -- Ethereal Pomegranate .................. (40k MP, 30k HP) [2000]
    177042, -- Five-Chime Batzos ..................... (40k MP, 30k HP) [2000]
    174283, -- Stygian Stew .......................... (40k MP, 30k HP) [2000]
    177041, -- Sunwarmed Xyfias ...................... (40k MP, 30k HP) [2000]
    177040, -- Ambroria Dew .......................... (40k MP) [2000]
    178217, -- Azurebloom Tea ........................ (40k MP) [2000]
    178545, -- Bone Apple Tea ........................ (40k MP) [2000]
    178539, -- Lukewarm Tauralus Milk ................ (40k MP) [2000]
    190936, -- Restorative Flow ...................... (40k MP) [2000]
    179992, -- Shadespring Water ..................... (40k MP) [2000]
    178535, -- Suspicious Slime Shot ................. (40k MP) [2000]
    186704, -- Twilight Tea .......................... (40k MP) [2000]
    13724,  -- Enriched Manna Biscuit ................ (33405 MP / 30s? -- TODO: Check in-game. Wowhead says 192721 MP, 95129 HP as of 2022/10/31) 
    19301,  -- Alterac Manna Biscuit ................. (25050 MP / 30s? -- TODO: Check in-game. Wowhead says 144519 MP, 250962 HP as of 2022/10/31)
    178538, -- Beetle Juice .......................... (20k MP) [1000]
    178534, -- Corpini Slurry ........................ (20k MP) [1000]
    178542, -- Cranial Concoction .................... (20k MP) [1000]
    173762, -- Flask of Ardendew ..................... (20k MP) [1000]
    179993, -- Infused Muck Water .................... (20k MP) [1000]
    174281, -- Purified Skyspring Water .............. (20k MP) [1000]
    184201, -- Slushy Water .......................... (20k MP) [1000]
    163692, -- Scroll of Subsistence ................. (9.6k MP, 16k HP) [480]
    169949, -- Bioluminescent Ocean Punch ............ (9.6k MP) [480]
    163785, -- Canteen of Rivermarsh Rainwater ....... (9.6k MP) [480]
    163786, -- Filtered Gloomwater ................... (9.6k MP) [480]
    162570, -- Pricklevine Juice ..................... (9.6k MP) [480]
    159867, -- Rockskip Mineral Water ................ (9.6k MP) [480]
    169952, -- Sea Salt Java ......................... (9.6k MP) [480]
    163784, -- Seafoam Coconut Water ................. (9.6k MP) [480]
    169954, -- Steeped Kelp Tea ...................... (9.6k MP) [480]
    152717, -- Azuremyst Water Flask ................. (8k MP) [400]
    140629, -- Bottled Maelstrom ..................... (8k MP) [400]
    140204, -- 'Bottled' Ley-Enriched Water .......... (8k MP) [400]
    128850, -- Chilled Conjured Water ................ (8k MP) [400] [Not actually conjured.]
    140269, -- Iced Highmountain Refresher ........... (8k MP) [400]
    140266, -- Kafa Kicker ........................... (8k MP) [400]
    140265, -- Legendermainy Light Roast ............. (8k MP) [400]
    138292, -- Ley-Enriched Water .................... (8k MP) [400]
    138982, -- Pail of Warm Milk ..................... (8k MP) [400]
    140272, -- Suramar Spiced Tea .................... (8k MP) [400]
    139347, -- Underjelly ............................ (8k MP) [400]
    42777,  -- Crusader's Waterskin .................. (11.3k MP / 30s) [378]
    58274,  -- Fresh Water ........................... (11.3k MP / 30s) [378]
    33445,  -- Honeymint Tea ......................... (11.3k MP / 30s) [378]
    59229,  -- Murky Water ........................... (11.3k MP / 30s) [378]
    41731,  -- Yeti Milk ............................. (11.3k MP / 30s) [378]
    163101, -- Drustvar Dark Roast ................... (7.2k MP) [360]
    169119, -- Enhanced Water ........................ (7.2k MP) [360]
    169120, -- Enhancement-Free Water ................ (7.2k MP) [360]
    169948, -- Filtered Zanj'ir Water ................ (7.2k MP) [360]
    159868, -- Free-Range Goat's Milk ................ (7.2k MP) [360]
    163783, -- Mount Mugamba Spring Water ............ (7.2k MP) [360]
    162547, -- Raw Nazmani Mineral Water ............. (7.2k MP) [360]
    163104, -- Sailor's Choice Coffee ................ (7.2k MP) [360]
    163102, -- Starhook Special Blend ................ (7.2k MP) [360]
    162569, -- Sun-Parched Waterskin ................. (7.2k MP) [360]
    138983, -- Kurd's Soft Serve ..................... (6k MP, 12k HP) [300]
    138986, -- Kurdos Yogurt ......................... (6k MP, 12k HP) [300]
    141215, -- Arcberry Juice ........................ (6k MP) [300]
    140298, -- Mananelle's Sparkling Cider ........... (6k MP) [300]
    117475, -- Clefthoof Milk ........................ (5k MP) [250]
    128385, -- Elemental-Distilled Water ............. (5k MP) [250]
    117452, -- Gorgrond Mineral Water ................ (5k MP) [250]
    138975, -- Highmountain Runoff ................... (5k MP) [250]
    128853, -- Highmountain Spring Water ............. (5k MP) [250]
    133586, -- Illidari Waterskin .................... (5k MP) [250]
    140628, -- Lavacolada ............................ (5k MP) [250]
    140203, -- 'Natural' Highmountain Spring Water ... (5k MP) [250]
    138981, -- Skinny Milk ........................... (5k MP) [250]
    139346, -- Thuni's Patented Drinking Fluid ....... (5k MP) [250]
    158926, -- Fried Turtle Bits ..................... (4.8k MP, 8k HP) [240]
    81923,  -- Cobo Cola ............................. (4k MP) [200]
    105711, -- Funky Monkey Brew ..................... (4k MP) [200]
    74636,  -- Golden Carp Consomme .................. (4k MP) [200]
    58257,  -- Highland Spring Water ................. (6k MP / 30s) [200]
    63251,  -- Mei's Masterful Brew .................. (6k MP / 30s) [200]
    74822,  -- Sasparilla Sinker ..................... (6k MP / 30s) [200]
    104348, -- Timeless Tea .......................... (4k MP) [200]
    59230,  -- Fungus Squeezings ..................... (4.9k MP / 30s) [163]
    59029,  -- Greasy Whale Milk ..................... (4.9k MP / 30s) [163]
    58256,  -- Sparkling Oasis Water ................. (4.9k MP / 30s) [163]
    81406,  -- Roasted Barley Tea .................... (3.3k MP, 3.2k HP, Well Fed: 3 Mastery) [163]
    140340, -- Bottled - Carbonated Water ............ (2.7k MP) [133]
    32722,  -- Enriched Terocone Juice ............... (3.8k MP, 944 HP / 30s) [126]
    38698,  -- Bitter Plasma ......................... (3.8k MP / 30s) [126]
    38430,  -- Blackrock Mineral Water ............... (3.8k MP / 30s) [126]
    43086,  -- Fresh Apple Juice ..................... (3.8k MP / 30s) [126]
    44941,  -- Fresh-Squeezed Limeade ................ (3.8k MP / 30s) [126]
    28399,  -- Filtered Draenic Water ................ (3.8k MP / 30s) [126]
    33444,  -- Pungent Seal Whey ..................... (3.8k MP / 30s) [126]
    29454,  -- Silverwine ............................ (3.8k MP / 30s) [126]
    34780,  -- Naaru Ration .......................... (2.9k MP, 1.6k HP / 30s) [94]
    38431,  -- Blackrock Fortified Water ............. (2.9k MP / 30s) [94]
    32668,  -- Dos Ogris ............................. (2.9k MP / 30s) [94]
    29395,  -- Ethermead ............................. (2.9k MP / 30s) [94]
    37253,  -- Frostberry Juice ...................... (2.9k MP / 30s) [94]
    40357,  -- Grizzleberry Juice .................... (2.9k MP / 30s) [94]
    27860,  -- Purified Draenic Water ................ (2.9k MP / 30s) [94]
    29401,  -- Sparkling Southshore Cider ............ (2.9k MP / 30s) [94]
    32453,  -- Star's Tears .......................... (2.9k MP / 30s) [94]
    35954,  -- Sweetened Goat's Milk ................. (2.9k MP / 30s) [94]
    32455,  -- Star's Lament ......................... (2.2k MP / 30s) [72]
    38429,  -- Blackrock Spring Water ................ (900 MP / 30s) [30]
    8766,   -- Morning Glory Dew ..................... (900 MP / 30s) [30]
    17404,  -- Blended Bean Brew ..................... (504 MP / 21s) [24]
    49602,  -- Earl Black Tea ........................ (504 MP / 21s) [24]
    1179,   -- Ice Cold Milk ......................... (504 MP / 21s) [24]
    90659,  -- Jasmine Tea ........................... (504 MP / 21s) [24]
    49601,  -- Volcanic Spring Water ................. (504 MP / 21s) [24]
    19300,  -- Bottled Winterspring Water ............ (540 MP / 30s) [18]
    1645,   -- Moonberry Juice ....................... (540 MP / 30s) [18]
    90660,  -- Black Tea ............................. (288 MP / 24s) [12]
    155909, -- Bottled Stillwater .................... (288 MP / 24s) [12]
    19299,  -- Fizzy Faire Drink ..................... (288 MP / 24s) [12]
    1205,   -- Melon Juice ........................... (288 MP / 24s) [12]
    1708,   -- Sweet Nectar .......................... (324 MP / 27s) [12]
    159,    -- Refreshing Spring Water ............... (180 MP / 18s) [10]
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
    [NS.DRUID] = "Renewal",
    [NS.PRIEST] = "Desperate Prayer",
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
        CreateMacro("CandyMacro", "INV_MISC_QUESTIONMARK", "#showtooltip " .. healthStone .. "\n/Use Healthstone");
    elseif ( oldHealthStone ~= healthStone ) then
        EditMacro(index, "CandyMacro", "INV_MISC_QUESTIONMARK", "#showtooltip " .. healthStone .. "\n/Use Healthstone");
    end
end

local function eventHandler(self, event, ...)
    if InCombatLockdown() then
        return
    end
    -- If not in combat, make a macro or edit existing one
    if ( event == NS.PLAYER_ENTERING_WORLD ) then
        inWorld = true;
        MakeDrinkMacro();
    end
    if ( event == NS.BAG_UPDATE ) and inWorld then
        MakeDrinkMacro();
    end
    if ( event == NS.PLAYER_REGEN_ENABLED ) and inWorld then -- Exiting combat
        MakeDrinkMacro();
    end
end

frameDrinkMacro:SetScript("OnEvent", eventHandler);

-- Send chat message when drinking
local drinkBuffs = {
    167152, -- Refreshment
    369162, -- Drink
};

local lastSent = 0;
local chatMessage = CreateFrame("Frame");
chatMessage:RegisterEvent(NS.UNIT_AURA);
chatMessage:SetScript("OnEvent", function (self, event, ...)
    local unit = ...;
    if ( unit == "player" ) then
        for i = 1, #(drinkBuffs) do
            local buffName = drinkBuffs[i];
            local aura = GetPlayerAuraBySpellID(buffName);
            if aura and aura.expirationTime and IsInInstance() then
                local now = GetTime();
                if ( now > lastSent + 6 ) then
                    pcall(function() SendChatMessage("Drinking. Do not overextend!", "YELL") end)
                    lastSent = now;
                end
            end
        end
    end
end)
