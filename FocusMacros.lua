local _, NS = ...

local classAbilities = {}
local macroPrefixes = {}

classAbilities[NS.classId.Druid] = {
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
}
macroPrefixes["Rake"] = "#showtooltip\n/cast [stance:0/3/4/5] Wild Growth\n/cast [stance:1] Ironfur\n/cast [stance:2,stealth, @"
macroPrefixes["Wild Charge"] = "#showtooltip Wild Charge\n/cast [stance:3,@player] Ursol's Vortex\n/cast [@"

local function getFocusName(isArena)
    if isArena then
        print("Updating Focus Macros for Arena...")
        local roles = {}

        for i = 1, NS.MAX_ARENA_SIZE do
            local spec = GetArenaOpponentSpec(i)
            roles[i] = select(5, GetSpecializationInfoByID(specID))
            if ( roles[i] == "HEALER" ) then
                -- Early return if healer is found
                return "arena" .. i
            end
        end

        -- Healer is not found, find a tank
        for i = 1, NS.MAX_ARENA_SIZE do
            if ( roles[i] ~= "DAMAGER" ) then
                return "arena" .. i
            end
        end
    else
        return "focus"
    end
end

-- e.g., #showtooltip\n/cast [@focus] Cyclone
local commonPrefix = "#showtooltip\n/cast [@"
local commonSuffix = "] "

local function updateMacros(isArena)
    local focusName = getFocusName(isArena)
    local class = select(3, UnitClass("player"))
    local abilities = classAbilities[class]

    for i = 1, #(abilities) do
        local ability = abilities[i]
        local macroName = "Focus " .. ability
        local prefix = macroPrefixes[ability] or commonPrefix
        local macroContent = prefix .. focusName .. commonSuffix .. ability
        local iMacro = GetMacroIndexByName(macroName)
        if ( iMacro == 0 ) then
            CreateMacro(macroName, "INV_MISC_QUESTIONMARK", macroContent, true)
        else
            EditMacro(iMacro, macroName, "INV_MISC_QUESTIONMARK", macroContent)
        end
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent(NS.PLAYER_ENTERING_WORLD)
frame:RegisterEvent(NS.ARENA_PREP_OPPONENT_SPECIALIZATIONS)
frame:SetScript("OnEvent", function ()
    local isArena = IsActiveBattlefieldArena()
    updateMacros(isArena)
end)

