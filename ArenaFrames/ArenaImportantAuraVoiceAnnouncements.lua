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

local function PlayArenaOpponentTrinketCallout(unitTarget)
    if type(unitTarget) ~= "string" or not arenaUnitSet[unitTarget] then return end

    -- CompactArenaFrame.lua handles ARENA_COOLDOWNS_UPDATE by querying
    -- C_PvP.GetArenaCrowdControlInfo for its arena unit. PvpInfoDocumentation.lua
    -- marks those raw cooldown values secret when loss-of-control data is restricted.
    -- Voice playback therefore uses only the event's unit token and never reads,
    -- compares, or infers any protected cooldown value.
    local callout = addon.ARENA_IMPORTANT_AURA_VOICE_CALLOUT_BY_ID[trinketCalloutID];
    local config = GetConfig();
    if ( not callout )
        or callout.trigger ~= "arenaCooldownUpdate"
        or ( not config.arenaImportantAuraVoiceEnabled )
        or ( not IsCalloutEnabled(config, trinketCalloutID) )
        or ( not IsInArenaInstance() ) then

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
    -- event, but the generated 12.1 metadata snapshot omits its runtime payload.
    -- Warcraft Wiki documents the affected unitTarget token explicitly:
    -- https://warcraft.wiki.gg/wiki/Event:ARENA_COOLDOWNS_UPDATE
    eventFrame:RegisterEvent("ARENA_COOLDOWNS_UPDATE");
    eventFrame:SetScript("OnEvent", function(_, event, unitTarget)
        if event == "ARENA_COOLDOWNS_UPDATE" then
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
