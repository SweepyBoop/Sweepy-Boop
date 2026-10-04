local _, addon = ...;

if ( not addon.PROJECT_MAINLINE ) then return end

local auraSoundHandles = {};
local refreshScheduled
local setupComplete = false;
local arenaUnits = { "arena1", "arena2", "arena3" };
-- Blizzard_UnitFrame/Mainline/CompactArenaFrame.lua binds each opponent CC-remover
-- widget to an arenaN token. Keep an exact allowlist so party updates never announce.
local arenaUnitSet = {
    arena1 = true,
    arena2 = true,
    arena3 = true,
};
local trinketCalloutID = "pvp-trinket";
local soundRoot = "Interface\\AddOns\\SweepyBoop\\Sounds\\ArenaImportantAuras\\enUS\\";

local function GetConfig()
    return SweepyBoop.db.profile.arenaFrames;
end

local function IsInArenaInstance()
    local inInstance, instanceType = IsInInstance();
    return inInstance and instanceType == "arena";
end

local function ClearAuraSounds()
    if ( not C_UnitAuras ) or ( not C_UnitAuras.RemoveAuraSound ) then
        for i = #auraSoundHandles, 1, -1 do
            auraSoundHandles[i] = nil;
        end
        return;
    end

    for i = #auraSoundHandles, 1, -1 do
        C_UnitAuras.RemoveAuraSound(auraSoundHandles[i]);
        auraSoundHandles[i] = nil;
    end
end

local function IsCalloutEnabled(config, calloutID)
    local callouts = config.arenaImportantAuraVoiceCallouts;
    if not callouts then return true end

    return callouts[calloutID] ~= false;
end

local function GetVoiceRoot(config)
    local voicePackID = config.arenaImportantAuraVoicePack or "alliance";
    local voicePack = addon.ARENA_IMPORTANT_AURA_VOICE_PACKS[voicePackID]
        or addon.ARENA_IMPORTANT_AURA_VOICE_PACKS.alliance;
    return soundRoot .. voicePack.directory .. "\\";
end

local function IsArenaMatchEngaged()
    return IsActiveBattlefieldArena()
        and C_PvP.GetActiveMatchState() == Enum.PvPMatchState.Engaged;
end

local function IsArenaOpponentCooldownUpdate(unitTarget)
    if unitTarget == nil then return true end
    if addon.IsSecretValue(unitTarget) then return false end

    return type(unitTarget) == "string" and arenaUnitSet[unitTarget] == true;
end

local function LogArenaCooldownUpdate(unitTarget)
    if ( not addon.internal ) or ( not IsArenaMatchEngaged() ) then return end

    local isSecret = addon.IsSecretValue(unitTarget);
    if ( not isSecret ) and unitTarget == nil then return end
    local unitType = type(unitTarget);
    local unitText = "<nil>";
    local isAcceptedUpdate = IsArenaOpponentCooldownUpdate(unitTarget);
    if isSecret then
        unitText = "<secret>";
    elseif unitType == "string" then
        unitText = unitTarget;
    elseif unitTarget ~= nil then
        unitText = tostring(unitTarget);
    end

    local config = GetConfig();
    addon.PRINT(string.format(
        "ARENA_COOLDOWNS_UPDATE unitTarget=%s type=%s secret=%s accepted=%s enabled=%s trinket=%s engaged=%s",
        unitText,
        unitType,
        tostring(isSecret),
        tostring(isAcceptedUpdate),
        tostring(config.arenaImportantAuraVoiceEnabled == true),
        tostring(IsCalloutEnabled(config, trinketCalloutID)),
        tostring(IsArenaMatchEngaged())
    ));
end

local function PlayArenaOpponentTrinketCallout(unitTarget)
    if ( not IsArenaMatchEngaged() )
        or ( not IsArenaOpponentCooldownUpdate(unitTarget) ) then

        return;
    end

    -- CompactArenaFrame.lua treats ARENA_COOLDOWNS_UPDATE as a global signal and
    -- refreshes every opponent CC-remover widget. Retail 12.1 likewise supplies no
    -- unitTarget despite the Warcraft Wiki documenting one, so nil is accepted only
    -- during an engaged arena match. A supplied token must still match arena1-3.
    -- PvpInfoDocumentation.lua marks the underlying cooldown values secret; SweepyBoop
    -- never reads, compares, or infers those protected values.
    local callout = addon.ARENA_IMPORTANT_AURA_VOICE_CALLOUT_BY_ID[trinketCalloutID];
    local config = GetConfig();
    if ( not callout )
        or callout.trigger ~= "arenaCooldownUpdate"
        or ( not config.arenaImportantAuraVoiceEnabled )
        or ( not IsCalloutEnabled(config, trinketCalloutID) ) then

        return;
    end

    PlaySoundFile(GetVoiceRoot(config) .. callout.soundFileName, "Master");
end

local function RegisterAuraSounds()
    local config = GetConfig();
    if ( not config.arenaImportantAuraVoiceEnabled )
        or ( not C_UnitAuras )
        or ( not C_UnitAuras.AddAuraSound )
        or ( not IsInArenaInstance() ) then

        return;
    end

    local voiceRoot = GetVoiceRoot(config);

    for _, callout in ipairs(addon.ARENA_IMPORTANT_AURA_VOICE_CALLOUTS) do
        if ( not callout.trigger ) and IsCalloutEnabled(config, callout.id) then
            local soundFileName = voiceRoot .. callout.soundFileName;
            local unitTokens = callout.unitTokens or arenaUnits;
            for _, unit in ipairs(unitTokens) do
                for _, spellID in ipairs(callout.spellIDs) do
                    local handle = C_UnitAuras.AddAuraSound(
                        Enum.UnitAuraSoundTrigger.Added,
                        {
                            unitToken = unit,
                            spellID = spellID,
                            soundFileName = soundFileName,
                            outputChannel = "Master",
                        }
                    );
                    if handle then
                        auraSoundHandles[#auraSoundHandles + 1] = handle;
                    end
                end
            end
        end
    end
end

function SweepyBoop:RefreshArenaImportantAuraVoiceAnnouncements()
    if InCombatLockdown() then return end

    ClearAuraSounds();
    RegisterAuraSounds();
end

local function ScheduleRefresh()
    if refreshScheduled then return end

    refreshScheduled = true;
    C_Timer.After(0, function()
        refreshScheduled = false;
        SweepyBoop:RefreshArenaImportantAuraVoiceAnnouncements();
    end);
end

function SweepyBoop:SetupArenaImportantAuraVoiceAnnouncements()
    if setupComplete then
        self:RefreshArenaImportantAuraVoiceAnnouncements();
        return;
    end
    setupComplete = true;

    local eventFrame = CreateFrame("Frame");
    eventFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
    eventFrame:RegisterEvent(addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS);
    eventFrame:RegisterEvent(addon.PLAYER_REGEN_ENABLED);
    eventFrame:RegisterEvent(addon.GROUP_ROSTER_UPDATE);
    eventFrame:RegisterEvent(addon.PVP_MATCH_STATE_CHANGED);
    -- UnitDocumentation.lua declares this as Blizzard's synchronous arena cooldown
    -- event with no payload. Warcraft Wiki documents a unitTarget parameter, but Retail
    -- 12.1 currently emits nil; retain the link in case the payload is restored:
    -- https://warcraft.wiki.gg/wiki/Event:ARENA_COOLDOWNS_UPDATE
    eventFrame:RegisterEvent("ARENA_COOLDOWNS_UPDATE");
    eventFrame:SetScript("OnEvent", function(_, event, unitTarget)
        if event == "ARENA_COOLDOWNS_UPDATE" then
            LogArenaCooldownUpdate(unitTarget);
            PlayArenaOpponentTrinketCallout(unitTarget);
            return;
        end

        if event == addon.PLAYER_REGEN_ENABLED then
            self:RefreshArenaImportantAuraVoiceAnnouncements();
            return;
        end

        ScheduleRefresh();
    end);

    self:RefreshArenaImportantAuraVoiceAnnouncements();
end
