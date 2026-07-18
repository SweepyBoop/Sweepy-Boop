local _, addon = ...;

local classAbilities = {};
local macroPrefixes = {};
local macroContentGenerators = {};

if addon.PROJECT_MAINLINE then
    classAbilities[addon.DRUID] = {
        "Cyclone",
        "Entangling Roots",
        "Hibernate",
        "Maim",
        "Mass Entanglement",
        "Mighty Bash",
        "Moonfire",
        "Rake",
        "Skull Bash",
        "Wild Charge",
        "Heart of the Wild",
    };
    macroPrefixes["Rake"] = "#showtooltip\n/cast [stance:0/3/4/5, help] [stance:0/3/4/5, @player] Wild Growth\n/cast [stance:1] Ironfur\n/cast [stance:2, @";
    macroPrefixes["Wild Charge"] = "#showtooltip Wild Charge\n/cast [stance:3,@player] Ursol's Vortex\n/cast [@";
    macroContentGenerators["Heart of the Wild"] = function (focusName)
        return "#showtooltip Ironbark\n/use [nostance][stance:1/3/4/5] !Cat Form(Shapeshift)\n/cast [stance:2, @" .. focusName .. "] Wild Charge\n/cast [stance:2, @" .. focusName .. "] Heart of the Wild";
    end
else
    classAbilities[addon.DRUID] = {
        "Cyclone",
        "Entangling Roots",
        "Hibernate",
        "Maim",
        "Bash",
        "Moonfire",
        "Pounce",
        "Skull Bash(Bear Form)",
        "Skull Bash(Cat Form)",
        "Faerie Fire",
        "Faerie Fire (Feral)",
    };
    macroPrefixes["Pounce"] = "#showtooltip\n/cast [stance:0/2/4/5/6] Wild Growth\n/cast [stance:1] Enrage\n/cast [stance:3, @";
end

classAbilities[addon.PRIEST] = {
    "Shadow Word: Pain",
    "Mind Control",
    "Dispel Magic",
};

classAbilities[addon.PALADIN] = {
    "Hammer of Justice",
    "Repentance",
    "Hand of Reckoning",
    "Judgment",
    "Rebuke",
};

local function GetFocusName()
    if IsActiveBattlefieldArena() then
        for i = 1, addon.MAX_ARENA_SIZE do
            local spec = GetArenaOpponentSpec(i);
            if spec then
                local role = select(5, GetSpecializationInfoByID(spec));
                if ( role == "HEALER" ) then
                    return "arena" .. i;
                end
            end
        end
    end

    -- Fallback in case no healer found
    return "focus";
end

-- e.g., #showtooltip\n/cast [@focus] Cyclone
local commonPrefix = "#showtooltip\n/cast [@";
local commonSuffix = "] ";

local function updateMacros(focusName)
    local class = select(2, UnitClass("player"));
    local abilities = classAbilities[class];
    if ( not abilities ) then return end

    for i = 1, #(abilities) do
        local ability = abilities[i];
        local macroName = "Focus " .. ability;
        local macroContentGenerator = macroContentGenerators[ability];
        local prefix = macroPrefixes[ability] or commonPrefix;
        local macroContent = macroContentGenerator and macroContentGenerator(focusName) or prefix .. focusName .. commonSuffix .. ability;
        local iMacro = GetMacroIndexByName(macroName);
        if ( iMacro == 0 ) then
            CreateMacro(macroName, "INV_MISC_QUESTIONMARK", macroContent, true);
        else
            EditMacro(iMacro, macroName, "INV_MISC_QUESTIONMARK", macroContent);
        end
    end

    --print("Focus macros set to " .. focusName);
end

local function TryUpdateMacros()
    if (InCombatLockdown()) then
        -- Combat locked, wait for 6s to drop combat
        C_Timer.After(3, TryUpdateMacros);
    else
        local focusName = GetFocusName();
        updateMacros(focusName);
    end
end

local frame = CreateFrame("Frame");
frame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
if addon.PROJECT_MAINLINE then
    frame:RegisterEvent(addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS);
else
    frame:RegisterEvent("ARENA_OPPONENT_UPDATE");
end
frame:SetScript("OnEvent", function ()
    TryUpdateMacros();
end)
