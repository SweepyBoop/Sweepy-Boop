local _, addon = ...;

local SBM_MACRO_NAME_MARKER = "SBM";
local INTERNAL_FOCUS_MACRO_NAME_PREFIX = "Focus";
local TARGET_TOKEN_SUFFIX_PATTERN = "%f[^%w]";
local ARENA_TARGET_PATTERN = "@arena[1-5]" .. TARGET_TOKEN_SUFFIX_PATTERN;
local TARGET_FOCUS = "@focus";
local FOCUS_TARGET_PATTERN = TARGET_FOCUS .. TARGET_TOKEN_SUFFIX_PATTERN;
local MAX_ACCOUNT_MACRO_SLOTS = MAX_ACCOUNT_MACROS or 120;
local MAX_MACRO_SLOTS = MAX_ACCOUNT_MACRO_SLOTS + (MAX_CHARACTER_MACROS or 18);

local function IsManagedMacro(macroIndex, name)
    if name:find(SBM_MACRO_NAME_MARKER, 1, true) then
        return true;
    end

    return addon.internal
        and macroIndex > MAX_ACCOUNT_MACRO_SLOTS
        and name:find(INTERNAL_FOCUS_MACRO_NAME_PREFIX, 1, true) == 1;
end

local function ReplaceManagedTargets(body, targetUnit)
    local target = "@" .. targetUnit;

    if ( targetUnit == "focus" ) then
        return body:gsub(ARENA_TARGET_PATTERN, TARGET_FOCUS);
    end

    body = body:gsub(FOCUS_TARGET_PATTERN, target);
    return body:gsub(ARENA_TARGET_PATTERN, target);
end

local function UpdateSBMMacros(targetUnit)
    targetUnit = targetUnit or addon.GetArenaHealerUnit();

    for i = 1, MAX_MACRO_SLOTS do
        local name, icon, body = GetMacroInfo(i);
        if name and body and IsManagedMacro(i, name) then
            local newBody = ReplaceManagedTargets(body, targetUnit);
            if ( newBody ~= body ) then
                EditMacro(i, name, icon, newBody);
            end
        end
    end
end

local pendingTargetUnit;
local retryFrame = CreateFrame("Frame");
retryFrame:SetScript("OnEvent", function(self)
    self:UnregisterEvent(addon.PLAYER_REGEN_ENABLED);
    local targetUnit = pendingTargetUnit;
    pendingTargetUnit = nil;
    UpdateSBMMacros(targetUnit);
end);

function SweepyBoop:UpdateSBMMacros(targetUnit)
    if InCombatLockdown() then
        pendingTargetUnit = targetUnit or pendingTargetUnit;
        retryFrame:RegisterEvent(addon.PLAYER_REGEN_ENABLED);
        return false;
    end

    pendingTargetUnit = nil;
    UpdateSBMMacros(targetUnit);
    return true;
end

SLASH_SWEEPYBOOPMACROS1 = "/sbm";
SlashCmdList.SWEEPYBOOPMACROS = function(message)
    local argument = strtrim(message or "");
    local targetUnit = "focus";

    if argument ~= "" then
        local arenaIndex = tonumber(argument);
        if ( not arenaIndex ) or ( arenaIndex % 1 ~= 0 ) or ( arenaIndex < 1 ) or ( arenaIndex > addon.MAX_ARENA_SIZE ) then
            print(string.format("SweepyBoop: use /sbm or /sbm <1-%d>.", addon.MAX_ARENA_SIZE));
            return;
        end
        targetUnit = "arena" .. arenaIndex;
    end

    local applied = SweepyBoop:UpdateSBMMacros(targetUnit);
    local timing = applied and "now target" or "will target after combat";
    print(string.format("SweepyBoop: SBM macros %s @%s.", timing, targetUnit));
end

local frame = CreateFrame("Frame");
frame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
frame:RegisterEvent(addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS);
frame:SetScript("OnEvent", function()
    SweepyBoop:UpdateSBMMacros();
end);
