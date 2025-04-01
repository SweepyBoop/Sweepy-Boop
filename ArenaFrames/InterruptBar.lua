local _, addon = ...;

local spellData = addon.SpellData;
local spellResets = addon.SpellResets;

local premadeIcons = {};
local iconGroup = {};
local eventFrame;

for spellID, spell in pairs(spellData) do
    -- Fill default priority
    spell.priority = spell.index or addon.SPELLPRIORITY.DEFAULT;

    if ( not spell.class ) or ( not C_Spell.GetSpellName(spellID) ) then
        print("Invalid spellID:", spellID);
    end

    -- Class should be a string of capital letters
    if spell.class and ( type(spell.class) ~= "string" ) then
        print("Invalid class for spellID:", spellID);
    end
end

local function EnsureIcon(unitId, spellID)
    local config = SweepyBoop.db.profile.arenaFrames;

    if ( not premadeIcons[unitId][spellID] ) then
        premadeIcons[unitId][spellID] = addon.CreateCooldownTrackingIcon(unitId, spellID, config.interruptBarIconSize, true);
        addon.SetHideCountdownNumbers(premadeIcons[unitId][spellID], config.interruptBarHideCountDownNumbers);
        -- size is set on creation but can be updated if lastModified falls behind
        premadeIcons[unitId][spellID].lastModified = config.lastModified;
    end

    -- Size was not set on creation, need to set scale and show/hide countdown numbers
    if ( premadeIcons[unitId][spellID].lastModified ~= config.lastModified ) then
        premadeIcons[unitId][spellID]:SetScale(config.interruptBarIconSize / addon.DEFAULT_ICON_SIZE);
        addon.SetHideCountdownNumbers(premadeIcons[unitId][spellID], config.interruptBarHideCountDownNumbers);

        premadeIcons[unitId][spellID].lastModified = config.lastModified;
    end
end

local function EnsureIcons()
    if addon.TEST_MODE then
        local unitId = "player";
        premadeIcons[unitId] = premadeIcons[unitId] or {};
        for spellID, spell in pairs(spellData) do
            if ( not spell.use_parent_icon ) then
                EnsureIcon(unitId, spellID);
            end
        end
    else
        for i = 1, addon.MAX_ARENA_SIZE do
            local unitId = "arena"..i;
            premadeIcons[unitId] = premadeIcons[unitId] or {};
            for spellID, spell in pairs(spellData) do
                if ( not spell.use_parent_icon ) then
                    EnsureIcon(unitId, spellID);
                end
            end
        end
    end
end