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

local manuallySelectedTargetUnit;
addon.GetManagedMacroTargetUnit = function()
    return manuallySelectedTargetUnit or addon.GetArenaHealerUnit();
end

local function UpdateSBMMacros(targetUnit)
    targetUnit = targetUnit or addon.GetManagedMacroTargetUnit();

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

local function SetManagedMacroTarget(targetUnit)
    manuallySelectedTargetUnit = targetUnit;
    local applied = SweepyBoop:UpdateSBMMacros(targetUnit);
    local timing = applied and "now target" or "will target after combat";
    print(string.format("SweepyBoop: SBM macros %s @%s.", timing, targetUnit));
end

if addon.PROJECT_MAINLINE then
    local preMatchClickOverlays = {};

    local function SetPreMatchOverlaysEnabled(enabled)
        if InCombatLockdown() then return end

        for _, overlay in pairs(preMatchClickOverlays) do
            overlay:SetMouseClickEnabled(enabled);
        end
    end

    local function SetupPreMatchClickOverlays()
        if InCombatLockdown() then return end

        local preMatchFrames = CompactArenaFrame
            and CompactArenaFrame.PreMatchFramesContainer
            and CompactArenaFrame.PreMatchFramesContainer.preMatchUnitFrames;
        if ( not preMatchFrames ) then return end

        for arenaIndex = 1, addon.MAX_ARENA_SIZE do
            local preMatchFrame = preMatchFrames[arenaIndex];
            if preMatchFrame and ( not preMatchClickOverlays[arenaIndex] ) then
                local targetUnit = "arena" .. arenaIndex;
                local overlay = CreateFrame("Button", nil, preMatchFrame);
                overlay:SetAllPoints(preMatchFrame);
                overlay:RegisterForClicks("RightButtonUp");
                overlay:SetMouseClickEnabled(IsShiftKeyDown());
                overlay:SetScript("OnClick", function()
                    if ( not InCombatLockdown() )
                        and IsShiftKeyDown()
                        and C_PvP.IsMatchConsideredArena() then
                        SetManagedMacroTarget(targetUnit);
                    end
                end);
                preMatchClickOverlays[arenaIndex] = overlay;
            end
        end
    end

    local overlayEventFrame = CreateFrame("Frame");
    overlayEventFrame:RegisterEvent("MODIFIER_STATE_CHANGED");
    overlayEventFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
    overlayEventFrame:RegisterEvent(addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS);
    overlayEventFrame:SetScript("OnEvent", function(_, event)
        if event ~= "MODIFIER_STATE_CHANGED" then
            SetupPreMatchClickOverlays();
        end
        SetPreMatchOverlaysEnabled(IsShiftKeyDown());
    end);

    if CompactArenaFrame_Generate then
        hooksecurefunc("CompactArenaFrame_Generate", SetupPreMatchClickOverlays);
    end
    SetupPreMatchClickOverlays();
end

local frame = CreateFrame("Frame");
frame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
frame:RegisterEvent(addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS);
frame:RegisterEvent(addon.PVP_MATCH_STATE_CHANGED);
frame:SetScript("OnEvent", function(_, event)
    if event == addon.PLAYER_ENTERING_WORLD then
        manuallySelectedTargetUnit = nil;
    elseif event == addon.PVP_MATCH_STATE_CHANGED then
        local state = C_PvP.GetActiveMatchState();
        if state == Enum.PvPMatchState.PostRound
            or state == Enum.PvPMatchState.Complete
            or state == Enum.PvPMatchState.Inactive then
            manuallySelectedTargetUnit = nil;
        end
        return;
    end

    SweepyBoop:UpdateSBMMacros();
end);
