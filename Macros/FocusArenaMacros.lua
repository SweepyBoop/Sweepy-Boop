local _, addon = ...;

local SBM_MACRO_NAME_MARKER = "SBM";
local TARGET_TOKEN_SUFFIX_PATTERN = "%f[^%w]";
local ARENA_TARGET_PATTERN = "@arena[1-5]" .. TARGET_TOKEN_SUFFIX_PATTERN;
local TARGET_FOCUS = "@focus";
local FOCUS_TARGET_PATTERN = TARGET_FOCUS .. TARGET_TOKEN_SUFFIX_PATTERN;
local MAX_MACRO_SLOTS = (MAX_ACCOUNT_MACROS or 120) + (MAX_CHARACTER_MACROS or 18);

local function ReplaceManagedTargets(body, targetUnit)
    local target = "@" .. targetUnit;

    if ( targetUnit == "focus" ) then
        return body:gsub(ARENA_TARGET_PATTERN, TARGET_FOCUS);
    end

    body = body:gsub(FOCUS_TARGET_PATTERN, target);
    return body:gsub(ARENA_TARGET_PATTERN, target);
end

local function UpdateSBMMacros()
    local targetUnit = addon.GetArenaHealerUnit();

    for i = 1, MAX_MACRO_SLOTS do
        local name, icon, body = GetMacroInfo(i);
        if name and body and name:find(SBM_MACRO_NAME_MARKER, 1, true) then
            local newBody = ReplaceManagedTargets(body, targetUnit);
            if ( newBody ~= body ) then
                EditMacro(i, name, icon, newBody);
            end
        end
    end
end

local retryFrame = CreateFrame("Frame");
retryFrame:SetScript("OnEvent", function(self)
    self:UnregisterEvent(addon.PLAYER_REGEN_ENABLED);
    UpdateSBMMacros();
end);

function SweepyBoop:UpdateSBMMacros()
    if InCombatLockdown() then
        retryFrame:RegisterEvent(addon.PLAYER_REGEN_ENABLED);
        return;
    end

    UpdateSBMMacros();
end

local frame = CreateFrame("Frame");
frame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
frame:RegisterEvent(addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS);
frame:SetScript("OnEvent", function()
    SweepyBoop:UpdateSBMMacros();
end);
