local _, addon = ...;

local classAbilities = {};
local macroPrefixes = {};

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
};
macroPrefixes["Rake"] = "#showtooltip no\n/cast [stance:0/3/4/5] Wild Growth\n/cast [stance:1] Ironfur\n/cast [stance:2, @";
macroPrefixes["Wild Charge"] = "#showtooltip Wild Charge\n/cast [stance:3,@player] Ursol's Vortex\n/cast [@";

classAbilities[addon.PRIEST] = {
    "Shadow Word: Pain",
    "Mind Control",
    "Mindgames",
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
    local isArena = IsActiveBattlefieldArena();

    if isArena then
        local roles = {};

        for i = 1, addon.MAX_ARENA_SIZE do
            local spec = GetArenaOpponentSpec(i);
            if spec then
                roles[i] = select(5, GetSpecializationInfoByID(spec));
            end
            if ( roles[i] == "HEALER" ) then
                -- Early return if healer is found
                return "arena" .. i;
            end
        end

        -- Healer is not found, find a tank
        for i = 1, addon.MAX_ARENA_SIZE do
            if roles[i] and ( roles[i] ~= "DAMAGER" ) then
                return "arena" .. i;
            end
        end
    end

    -- Fallback in case no healer/tank found
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
        local prefix = macroPrefixes[ability] or commonPrefix;
        local macroContent = prefix .. focusName .. commonSuffix .. ability;
        local iMacro = GetMacroIndexByName(macroName);
        if ( iMacro == 0 ) then
            CreateMacro(macroName, "INV_MISC_QUESTIONMARK", macroContent, true);
        else
            EditMacro(iMacro, macroName, "INV_MISC_QUESTIONMARK", macroContent);
        end
    end
end

local function UpdateHighlightBorder(frame, show)
    if ( not frame.HighlightBorder ) then
        local highlightBorder = CreateFrame("Frame", nil, frame, "BackdropTemplate");
        --highlightBorder:SetFrameStrata("HIGH");
        local width, healthBarHeight = frame.HealthBar:GetSize();
        local _, powerBarHeight = frame.PowerBar:GetSize();
        highlightBorder:SetSize(width + 5, (healthBarHeight + powerBarHeight) * 2.25); -- For Blizz Target 100% scale with system default scale
        highlightBorder:SetPoint("BOTTOM", frame.PowerBar, "BOTTOM");
        highlightBorder:SetBackdrop( { bgFile="Interface\\ChatFrame\\ChatFrameBackground", tileSize=16, tile=true, edgeFile="Interface\\ChatFrame\\ChatFrameBackground", edgeSize=1 } );
        highlightBorder:SetBackdropColor(0, 0, 0, 0); -- transparent main area
        highlightBorder:SetBackdropBorderColor(255, 0, 0); -- red border

        highlightBorder:Hide();
        frame.HighlightBorder = highlightBorder;
    end

    if show then
        frame.HighlightBorder:Show();
    else
        frame.HighlightBorder:Hide();
    end
end

local function UpdateArenaFrame(frame, show)
    UpdateHighlightBorder(frame, show);
end

local function updateArenaHighlight(focusName)
    local frameIndex = nil;

    if ( focusName == "focus" ) then
        if addon.TEST_MODE then
            frameIndex = 1;
        end
    else
        frameIndex = tonumber(string.sub(focusName, -1, -1));
    end

    for i = 1, 3 do
        local sArenaFrame = _G["sArenaEnemyFrame" .. i];
        if sArenaFrame then
            UpdateArenaFrame( sArenaFrame, (i == frameIndex) );
        end
    end
end

local function TryUpdateMacros()
    if (InCombatLockdown()) then
        -- Combat locked, wait for 6s to drop combat
        C_Timer.After(3, TryUpdateMacros);
    else
        local focusName = GetFocusName();
        updateMacros(focusName);
        updateArenaHighlight(focusName);
    end
end

local frame = CreateFrame("Frame");
frame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
frame:RegisterEvent(addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS);
frame:SetScript("OnEvent", function ()
    TryUpdateMacros();
end)
