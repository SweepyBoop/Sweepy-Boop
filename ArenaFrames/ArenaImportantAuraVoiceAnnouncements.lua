local _, addon = ...;

if ( not addon.PROJECT_MAINLINE ) then return end

local auraSoundHandles = {};
local refreshScheduled
local setupComplete = false;
local arenaUnits = { "arena1", "arena2", "arena3" };
local soundRoot = "Interface\\AddOns\\SweepyBoop\\Sounds\\ArenaImportantAuras\\enUS\\";
local trinketSoundThrottleByGUID = {};

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

local function IsArenaUnitGUID(guid)
    if not guid then return false end

    for _, unit in ipairs(arenaUnits) do
        if UnitGUID(unit) == guid then
            return true;
        end
    end
    return false;
end

local function HandleTrinketCombatLogEvent()
    local callout = addon.ARENA_IMPORTANT_AURA_TRINKET_VOICE_CALLOUT;
    if not callout then return end

    local config = GetConfig();
    if ( not config.arenaImportantAuraVoiceEnabled ) or ( not IsInArenaInstance() ) then
        return;
    end

    local _, subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellID =
        CombatLogGetCurrentEventInfo();
    if subEvent ~= addon.SPELL_CAST_SUCCESS or ( not IsArenaUnitGUID(sourceGUID) ) then
        return;
    end

    local matchesTrinket = false;
    for _, trinketSpellID in ipairs(callout.spellIDs) do
        if spellID == trinketSpellID then
            matchesTrinket = true;
            break;
        end
    end
    if not matchesTrinket then return end

    local now = GetTime();
    local lastPlayed = trinketSoundThrottleByGUID[sourceGUID];
    if lastPlayed and ( now - lastPlayed ) < 1 then return end
    trinketSoundThrottleByGUID[sourceGUID] = now;
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
        if IsCalloutEnabled(config, callout.id) then
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
    if addon.ARENA_IMPORTANT_AURA_TRINKET_VOICE_CALLOUT then
        eventFrame:RegisterEvent(addon.COMBAT_LOG_EVENT_UNFILTERED);
    end
    eventFrame:SetScript("OnEvent", function(_, event)
        if event == addon.COMBAT_LOG_EVENT_UNFILTERED then
            HandleTrinketCombatLogEvent();
            return;
        end

        if event == addon.PLAYER_REGEN_ENABLED then
            wipe(trinketSoundThrottleByGUID);
            self:RefreshArenaImportantAuraVoiceAnnouncements();
            return;
        end

        ScheduleRefresh();
    end);

    self:RefreshArenaImportantAuraVoiceAnnouncements();
end
