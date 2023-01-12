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

local function getFocusName()
    local isArena = IsActiveBattlefieldArena()

    if isArena then
        local roles = {}

        for i = 1, NS.MAX_ARENA_SIZE do
            local spec = GetArenaOpponentSpec(i)
            if spec then
                roles[i] = select(5, GetSpecializationInfoByID(spec))
            end
            if ( roles[i] == "HEALER" ) then
                -- Early return if healer is found
                return "arena" .. i
            end
        end

        -- Healer is not found, find a tank
        for i = 1, NS.MAX_ARENA_SIZE do
            if roles[i] and ( roles[i] ~= "DAMAGER" ) then
                return "arena" .. i
            end
        end
    end

    -- Fallback in case no healer/tank found
    return "focus"
end

BoopUtilsGetFocusName = getFocusName

-- e.g., #showtooltip\n/cast [@focus] Cyclone
local commonPrefix = "#showtooltip\n/cast [@"
local commonSuffix = "] "

local function updateMacros()
    local focusName = getFocusName()
    local class = select(3, UnitClass("player"))
    local abilities = classAbilities[class]
    if ( not abilities ) then return end

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

    C_Timer.After(10, function() print("Setting focus to @" .. focusName) end)
end

local frame = CreateFrame("Frame")
frame:RegisterEvent(NS.PLAYER_ENTERING_WORLD)
frame:RegisterEvent(NS.ARENA_PREP_OPPONENT_SPECIALIZATIONS)
frame:SetScript("OnEvent", function ()
    if (InCombatLockdown()) then
        print("Combat Lockdown, skip updating focus macros...")
        return
    end

    updateMacros()
end)
