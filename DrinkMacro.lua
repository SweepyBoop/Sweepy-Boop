-- Create a macro for drinks
local frameDrinkMacro = CreateFrame("Frame");
local inWorld = false;
local bestDrink = nil;
frameDrinkMacro:RegisterEvent("BAG_UPDATE");
frameDrinkMacro:RegisterEvent("PLAYER_ENTERING_WORLD");
frameDrinkMacro:RegisterEvent("PLAYER_REGEN_ENABLED");

local drinks = {
    -- itemID, name / mana gain
    113509, -- Conjured Mana Bun
    80618, -- Conjured Mana Fritter
    80610, -- Conjured Mana Pudding
    65499, -- Conjured Mana Cake
    43523, -- Conjured Mana Strudel
    43518, -- Conjured Mana Pie
    65517, -- Conjured Mana Lollipop
    65516, -- Conjured Mana Cupcake
    65515, -- Conjured Mana Brownie
    65500, -- Conjured Mana Cookie
    173859, -- Ethereal Pomegranate
    174283, -- Stygian Stew
    174284, -- Empyrean Fruit Salad
    177040, -- Ambroria Dew
    178545, -- Bone Apple Tea
    178217, -- Azurebloom Tea
    179992, -- Shadespring Water
    178539, -- Lukewarm Tauralus Milk
    178535, -- Suspicious Slime Shot
    186704, -- 40000
    172047, -- 40000
    174284, -- 40000
    177042, -- 40000
    177041, -- 40000
    13724, -- 33405
    19301, -- 25050
    173762, -- 20000
    174281, -- 20000
    178542, -- 20000
    184201, -- 20000
    178538, -- 20000
    179993, -- 20000
    178534, -- 20000
    169952, -- 9600
    169954, -- 9600
    169949, -- 9600
    163692, -- 9600
    163786, -- 9600
    163784, -- 9600
    162570, -- 9600
    163785, -- 9600
    159867, -- 9600
    169948, -- 6600
    169120, -- 6600
    162547, -- 6600
    169119, -- 6600
    159868, -- 6600
    163101, -- 6600
    163104, -- 6600
    163102, -- 6600
    163783, -- 6600
    162569, -- 6600
    138292, -- 5500
    140272, -- 5500
    138986, -- 5500
    140265, -- 5500
    140298, -- 5500
    139347, -- 5500
    140629, -- 5500
    141215, -- 5500
    138982, -- 5500
    128850, -- 5500
    138983, -- 5500
    140204, -- 5500
    140266, -- 5500
    140269, -- 5500
    152717, -- 5500
    140203, -- 5500
    140628, -- 5500
    138975, -- 5500
    128853, -- 5500
    138981, -- 5500
    139346, -- 5500
    133586, -- 5500
    58257, -- 5250
    74822, -- 5250
    63251, -- 5250
    158926, -- 4800
    115351, -- 4500
    117452, -- 4500
    117475, -- 4500
    128385, -- 4500
    59029, -- 4272
    59230, -- 4272
    58256, -- 4272
    32453, -- 4254
    58274, -- 4254
    29395, -- 4254
    59229, -- 4254
    33445, -- 4254
    41731, -- 4254
    29401, -- 4254
    32668, -- 4254
    35954, -- 4254
    42777, -- 4254
    37253, -- 4254
    40357, -- 4254
    38431, -- 4254
    34780, -- 4254
    27860, -- 4254
    32722, -- 3780
    38698, -- 3780
    38430, -- 3780
    43086, -- 3780
    29454, -- 3780
    44941, -- 3780
    33444, -- 3780
    28399, -- 3780
    81923, -- 3500
    74636, -- 3500
    105711, -- 3500
    104348, -- 3500
    81406, -- 3500
    140340, -- 2332
    32455, -- 2160
    38429, -- 900
    8766, -- 900
    1645, -- 588
    19300, -- 588
    1179, -- 504
    49602, -- 504
    17404, -- 504
    90659, -- 504
    49601, -- 504
    1708, -- 324
    155909, -- 288
    1205, -- 288
    19299, -- 288
    90660, -- 288
    159, -- 180
}

local function SetBestDrink()
    lvl = UnitLevel("player");
    for _, drink in pairs(drinks) do
        item = GetItemInfo(drink);
        itemLvl = select(5, GetItemInfo(drink));
        itemCount = GetItemCount(drink);
        if (item ~= nil and itemCount ~= nil and itemLvl ~= nil) then
            if (itemCount > 0) and (itemLvl <= lvl) then 
                bestDrink = item;
                return;
            end
        end
    end
end

local function MakeDrinkMacro()
    local oldBest = bestDrink; -- Avoids unecessary edits
    SetBestDrink();
    local iMacro = GetMacroIndexByName("DrinkMacro");
    if (iMacro == 0 and bestDrink ~= nil) then
        CreateMacro("DrinkMacro", "INV_MISC_QUESTIONMARK", "#showtooltip\n/use "..bestDrink.."\n/cast !Prowl");
    elseif (oldBest ~= bestDrink) then
        EditMacro(iMacro, "DrinkMacro", "INV_MISC_QUESTIONMARK", "#showtooltip\n/use "..bestDrink.."\n/cast !Prowl");
    end
end

local function eventHandler(self, event, ...)
    if (InCombatLockdown()) then
        return
    end
    -- If not in combat, make a macro or edit existing one
    if (event == "PLAYER_ENTERING_WORLD") then
        inWorld = true;
        MakeDrinkMacro();
    end
    if (event == "BAG_UPDATE" and inWorld) then
        MakeDrinkMacro();
    end
    if (event == "PLAYER_REGEN_ENABLED" and inWorld) then -- Exiting combat
        MakeDrinkMacro();
    end
end

frameDrinkMacro:SetScript("OnEvent", eventHandler);