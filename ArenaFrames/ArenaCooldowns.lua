local _, addon = ...;

local spellData = addon.SpellData;
local spellResets = addon.SpellResets;
local GetSpellPowerCost = C_Spell.GetSpellPowerCost;

local npcToSpellID = {
    [101398] = 211522, -- Psyfiend
    [62982] = 200174, -- Mindbender
    [196111] = 387578, -- Gul'dan's Ambition (Pit Lord)
};

local resetByPower = {
    137639, -- Storm, Earth, and Fire
    152173, -- Serenity
    1719, -- Recklessness
    262161, -- Warbreaker
    167105, -- Colossus Smash
};

local resetByCrit = {
    190319, -- Combustion
};

local premadeIcons = {};
local iconGroups = {}; -- One group per arena opponent
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
        local size = config.arenaTrackerIconSize;
        if spellData[spellID].category == addon.SPELLCATEGORY.BURST then
            premadeIcons[unitId][spellID] = addon.CreateBurstIcon(unitId, spellID, size, true);
        else
            premadeIcons[unitId][spellID] = addon.CreateCooldownTrackingIcon(unitId, spellID, size, true);
        end

        addon.SetHideCountdownNumbers(premadeIcons[unitId][spellID], config.hideCountDownNumbers);
        -- size is set on creation but can be updated if lastModified falls behind
        premadeIcons[unitId][spellID].lastModified = config.lastModified;
    end

    -- Size was not set on creation, need to set scale and show/hide countdown numbers
    if ( premadeIcons[unitId][spellID].lastModified ~= config.lastModified ) then
        premadeIcons[unitId][spellID]:SetScale(config.arenaTrackerIconSize / addon.DEFAULT_ICON_SIZE);
        addon.SetHideCountdownNumbers(premadeIcons[unitId][spellID], config.hideCountDownNumbers);

        premadeIcons[unitId][spellID].lastModified = config.lastModified;
    end
end

local function EnsureIcons()
    if addon.TEST_MODE then
        local unitId = "player";
        premadeIcons[unitId] = premadeIcons[unitId] or {};
        for spellID, spell in pairs(spellData) do
            EnsureIcon(unitId, spellID);
        end
    else
        for i = 1, addon.MAX_ARENA_SIZE do
            local unitId = "arena"..i;
            premadeIcons[unitId] = premadeIcons[unitId] or {};
            for spellID, spell in pairs(spellData) do
                EnsureIcon(unitId, spellID);
            end
        end
    end
end

local function GetSpecOverrides(spell, spec)
    local overrides = {};

    overrides.spec = spec;

    if type(spell.cooldown) == "table" then
        overrides.cooldown = spell.cooldown[spec] or spell.cooldown.default;
    else
        overrides.cooldown = spell.cooldown;
    end

    if type(spell.charges) == "table" then
        overrides.charges = spell.charges[spec];
    else
        overrides.charges = spell.charges;
    end

    return overrides;
end

local function SetupIconGroup(group, unit, testIcons)
    -- Clear previous icons
    addon.IconGroup_Wipe(group);

    -- For external "Toggle Test Mode" icons, no filtering is needed
    if testIcons then
        for spellID, spell in pairs(spellData) do
            testIcons[unit][spellID].info = { cooldown = spell.cooldown };
            addon.IconGroup_PopulateIcon(group, testIcons[unit][spellID], spellID);
        end

        return;
    end

    -- In arena prep phase, UnitExists returns false since enemies are not visible, but we can check spec and populate icons
    local class = addon.GetClassForPlayerOrArena(unit);
    if ( not class ) then return end

    -- Pre-populate icons
    for spellID, spell in pairs(spellData) do
        -- A spell without class specified should always be populated, e.g., Power Infusion can be applied to any class
        if ( not spell.class ) or ( spell.class == class ) then
            local enabled = true;
            -- Does this spell filter by spec?
            if spell.spec then
                local specEnabled = false;
                local spec = addon.GetSpecForPlayerOrArena(unit);

                if ( not spec ) then
                    specEnabled = true;
                else
                    for i = 1, #(spell.spec) do
                        if ( spec == spell.spec[i] ) then
                            specEnabled = true;
                            break;
                        end
                    end
                end

                enabled = specEnabled;
            end

            if enabled then
                -- Reset dynamic info before populating to group
                premadeIcons[unit][spellID].info = GetSpecOverrides(spell);
                addon.IconGroup_PopulateIcon(group, premadeIcons[unit][spellID], spellID);
                --print("Populated", unit, spell.class, spellID)
            end
        end
    end
end

local function ValidateUnit(self)
    -- If unit is specified, this is a group to track a single unit, return unitGUID
    if self.unit then
        -- Update icon group guid
        if ( not self.unitGUID ) then
            self.unitGUID = UnitGUID(self.unit);
        end

        -- If unit does not exist, will return nil
        return self.unitGUID;
    else
        self.unitGUIDs = self.unitGUIDs or {};
        for i = 1, addon.MAX_ARENA_SIZE do
            local unitId = "arena" .. i;
            -- We only need to cache GUIDs here, info such as specs are taken into account when populating icons
            if ( not self.unitGUIDs[unitId] ) then
                self.unitGUIDs[unitId] = UnitGUID(unitId);
            end
        end

        return self.unitGUIDs;
    end
end

local function ResetCooldown(icon, amount, internalCooldown)
    if icon.template == addon.ICON_TEMPLATE.GLOW then
        addon.ResetIconCooldown(icon, amount);

        -- Duration has more than 1s left, hide cooldown
        -- Duration frame's finish event handler will show the cooldown
        if icon.duration and icon.duration.finish and ( GetTime() < icon.duration.finish - 1 ) then
            icon.cooldown:Hide();
        end
    elseif icon.template == addon.ICON_TEMPLATE.FLASH then
        addon.ResetCooldownTrackingCooldown(icon, amount, internalCooldown);
    end
end

local function StartIcon(icon)
    if icon.template == addon.ICON_TEMPLATE.GLOW then
        print("StartBurstIcon");
        addon.StartBurstIcon(icon);
    elseif icon.template == addon.ICON_TEMPLATE.FLASH then
        print("StartCooldownTrackingIcon");
        addon.StartCooldownTrackingIcon(icon);
    end
end

local function ProcessCombatLogEvent(self, subEvent, sourceGUID, destGUID, spellId, spellName, critical)
    local guid = ValidateUnit(self);
    if ( not guid ) then return end

    -- Check resets by spell cast
    if ( subEvent == addon.SPELL_CAST_SUCCESS ) and ( sourceGUID == guid ) then
        -- Check reset by power
        for i = 1, #resetByPower do
            local reset = resetByPower[i];
            if self.activeMap[reset] then
                local cost = GetSpellPowerCost(spellId);
                if cost and cost[1] and ( cost[1].type == spellData[reset].reduce_power_type ) then
                    local amount = spellData[reset].reduce_amount * cost[1].cost;
                    ResetCooldown(self.activeMap[reset], amount);
                end
            end
        end

        -- Check regular resets
        if spellResets[spellId] then
            for resetSpellID, amount in pairs(spellResets[spellId]) do
                if self.activeMap[resetSpellID] then
                    ResetCooldown(self.activeMap[resetSpellID], amount);
                end
            end
        end
    end

    -- Check resets by crit damage (e.g., combustion)
    if ( subEvent == addon.SPELL_DAMAGE ) and critical and ( sourceGUID == guid ) then
        for i = 1, #resetByCrit do
            local reset = resetByCrit[i];
            if self.activeMap[reset] then
                local spells = spellData[reset].critResets;
                for i = 1, #spells do
                    if ( spellId == spells[i] ) or ( spellName == spells[i] ) then
                        --print(spellName, spellId, spellData[reset].critResetAmount);
                        ResetCooldown(self.activeMap[reset], spellData[reset].critResetAmount);
                    end
                end
                return;
            end
        end
    end

    -- Check reset by interrupts, Counterspell, solar Beam
    -- Solar Beam only reduces 15s when interrupting main target, how do we detect it? Cache last reduce time?
    if ( subEvent == addon.SPELL_INTERRUPT ) and ( sourceGUID == guid ) then
        local icon = self.activeMap[spellId];
        local amount = icon and icon.spellInfo.reduce_on_interrupt;
        if icon and amount then
            ResetCooldown(icon, amount, amount);
        end
    end

    -- Check summon / dead
    if addon.EVENTS_PET_DISMISS[subEvent] then
        -- Might have already been dismissed by SPELL_AURA_REMOVED, e.g., Psyfiend
        local summonSpellId = self.npcMap[destGUID];
        if summonSpellId and self.activeMap[summonSpellId] then
            addon.ResetBurstDuration(self.activeMap[summonSpellId]);
        end
        return;
    elseif ( subEvent == addon.SPELL_SUMMON ) and ( guid == sourceGUID ) then
        -- We don't actually show the icon from SPELL_SUMMON, just create the mapping of mob GUID -> spellID
        local npcId = addon.GetNpcIdFromGuid(destGUID);
        local summonSpellId = npcToSpellID[npcId];
        self.npcMap[destGUID] = summonSpellId;

        -- If not added yet, add by this (e.g., Guldan's Ambition: Pit Lord)
        if summonSpellId and self.icons[summonSpellId] and ( not self.activeMap[summonSpellId] ) and SweepyBoop.db.profile.arenaFrames.spellList[tostring(summonSpellId)]  then
            StartIcon(self.icons[summonSpellId]);
        end
        return;
    end

    -- Validate spell
    if ( not spellData[spellId] ) then return end
    local spell = spellData[spellId];

    -- Validate unit
    local spellGUID = ( spell.trackDest and destGUID ) or sourceGUID;
    if ( spellGUID ~= guid ) then return end

    -- Check spell dismiss (check by sourceGUID unless trackDest is specified)
    if ( subEvent == addon.SPELL_AURA_REMOVED ) then
        if self.activeMap[spellId] and ( self.activeMap[spellId].template == addon.ICON_TEMPLATE.GLOW ) then
            addon.ResetBurstDuration(self.activeMap[spellId]);
            return;
        end
    end

    -- Validate subEvent
    local validateSubEvent;
    if spell.trackEvent then
        validateSubEvent = ( subEvent == spell.trackEvent );
    else
        validateSubEvent = ( subEvent == addon.SPELL_CAST_SUCCESS );
    end
    if ( not validateSubEvent ) then return end

    -- Find the icon to use
    if self.icons[spellId] and SweepyBoop.db.profile.arenaFrames.spellList[tostring(spellId)] then
        StartIcon(self.icons[spellId]);
    end
end

local function ProcessUnitSpellCast(self, event, ...)
    local guid = ValidateUnit(self);
    if ( not guid ) then return end

    local unitTarget, _, spellID = ...;
    if ( unitTarget == self.unit ) then
        local spell = spellData[spellID];
        if ( not spell ) or ( spell.trackEvent ~= addon.UNIT_SPELLCAST_SUCCEEDED ) then return end
        if self.icons[spellID] and SweepyBoop.db.profile.arenaFrames.spellList[tostring(spellID)] then
            addon.StartBurstIcon(self.icons[spellID]);
        end
    end
end

local function ProcessUnitAura(self, event, ...)
    local guid = ValidateUnit(self);
    if ( not guid ) then return end

    local unitTarget, updateAuras = ...;
    -- Only use UNIT_AURA to extend aura
    if ( unitTarget == self.unit ) and updateAuras and updateAuras.updatedAuraInstanceIDs then
        for _, instanceID in ipairs(updateAuras.updatedAuraInstanceIDs) do
            local spellInfo = C_UnitAuras.GetAuraDataByAuraInstanceID(unitTarget, instanceID);
            if spellInfo then
                local spellID = spellInfo.spellId
                local spell = spellData[spellID]
                if ( not spell ) or ( not spell.extend ) or ( not self.activeMap[spellID] ) then return end
                addon.RefreshBurstDuration(self.activeMap[spellID]);
            end
        end
    end
end

local function ProcessUnitEvent(group, event, ...)
    if ( event == addon.UNIT_SPELLCAST_SUCCEEDED ) then
        ProcessUnitSpellCast(group, event, ...);
    elseif ( event == addon.UNIT_AURA ) then
        ProcessUnitAura(group, event, ...);
    end
end

local framePrefix = ( GladiusEx and "GladiusExButtonFramearena" ) or ( Gladius and "GladiusButtonFramearena" ) or ( sArena and "sArenaEnemyFrame" ) or "CompactArenaFrameMember";
local largeColumn = 100; -- Don't break line for arena tracker
local growOptions = {
    [addon.ARENA_COOLDOWN_GROW_DIRECTION.RIGHT_DOWN] = {
        direction = "RIGHT",
        anchor = "LEFT",
        margin = 3,
        columns = largeColumn,
        growUpward = false,
    },
    [addon.ARENA_COOLDOWN_GROW_DIRECTION.RIGHT_UP] = {
        direction = "RIGHT",
        anchor = "LEFT",
        margin = 3,
        columns = largeColumn,
        growUpward = true,
    },
    [addon.ARENA_COOLDOWN_GROW_DIRECTION.LEFT_DOWN] = {
        direction = "LEFT",
        anchor = "RIGHT",
        margin = 3,
        columns = largeColumn,
        growUpward = false,
    },
    [addon.ARENA_COOLDOWN_GROW_DIRECTION.LEFT_UP] = {
        direction = "LEFT",
        anchor = "RIGHT",
        margin = 3,
        columns = largeColumn,
        growUpward = true,
    },
}

local function GetSetPointOptions(index)
    local offsetY = SweepyBoop.db.profile.arenaFrames.arenaCooldownOffsetY;
    local adjustedIndex = ( index == 0 and 1) or index;
    local setPointOptions = {
        point = "LEFT",
        relativeTo = framePrefix .. adjustedIndex,
        relativePoint = "RIGHT",
        offsetY = offsetY;
    };
    return setPointOptions;
end

local function EnsureIconGroup(index)
    local config = SweepyBoop.db.profile.arenaFrames;
    if ( not iconGroups[index] ) then
        local unitId = ( index == 0 and "player" ) or ( "arena" .. index );
        local setPointOptions = GetSetPointOptions(index);
        setPointOptions.offsetX = config.arenaCooldownOffsetX;
        iconGroups[index] = addon.CreateIconGroup(setPointOptions, growOptions[config.arenaCooldownGrowDirection], unitId);
        -- SetPointOptions is set but can be updated if lastModified falls behind
        iconGroups[index].lastModified = SweepyBoop.db.profile.arenaFrames.lastModified;
    end

    if ( iconGroups[index].lastModified ~= SweepyBoop.db.profile.arenaFrames.lastModified ) then
        local setPointOptions = GetSetPointOptions(index);
        setPointOptions.offsetX = config.arenaCooldownOffsetX;
        addon.UpdateIconGroupSetPointOptions(iconGroups[index], setPointOptions, growOptions[config.arenaCooldownGrowDirection]);
        iconGroups[index].lastModified = SweepyBoop.db.profile.arenaFrames.lastModified;
    end
end

local function EnsureIconGroups()
    if addon.TEST_MODE then
        EnsureIconGroup(0);
        SetupIconGroup(iconGroups[0], "player");
    else
        for i = 1, addon.MAX_ARENA_SIZE do
            EnsureIconGroup(i);
            SetupIconGroup(iconGroups[i], "arena" .. i);
        end
    end

    -- Refresh icon groups when zone changes, or during test mode when player switches spec
    if ( not eventFrame ) then
        eventFrame = CreateFrame("Frame");
        eventFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
        eventFrame:RegisterEvent(addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS);
        eventFrame:RegisterEvent(addon.PLAYER_SPECIALIZATION_CHANGED);
        eventFrame:RegisterEvent(addon.COMBAT_LOG_EVENT_UNFILTERED);
        eventFrame:RegisterEvent(addon.UNIT_AURA);
        eventFrame:RegisterEvent(addon.UNIT_SPELLCAST_SUCCEEDED);
        eventFrame:SetScript("OnEvent", function (frame, event, ...)
            if ( not SweepyBoop.db.profile.arenaFrames.arenaCooldownTrackerEnabled ) then
                return;
            end

            if ( event == addon.PLAYER_ENTERING_WORLD ) or ( event == addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS ) or ( event == addon.PLAYER_SPECIALIZATION_CHANGED and addon.TEST_MODE ) then
                -- Hide the external "Toggle Test Mode" group
                SweepyBoop:HideTestArenaCooldownTracker();

                -- This will simply update
                EnsureIcons();
                EnsureIconGroups();
            elseif ( event == addon.COMBAT_LOG_EVENT_UNFILTERED ) then
                if ( not IsActiveBattlefieldArena() ) and ( not addon.TEST_MODE ) then return end
                local _, subEvent, _, sourceGUID, _, _, _, destGUID, _, _, _, spellId, spellName, _, _, _, _, _, _, _, critical = CombatLogGetCurrentEventInfo();
                for i = 0, addon.MAX_ARENA_SIZE do
                    if iconGroups[i] then
                        ProcessCombatLogEvent(iconGroups[i], subEvent, sourceGUID, destGUID, spellId, spellName, critical);
                    end
                end
            elseif ( event == addon.UNIT_AURA ) or ( event == addon.UNIT_SPELLCAST_SUCCEEDED ) then
                if ( not IsActiveBattlefieldArena() ) and ( not addon.TEST_MODE ) then return end
                for i = 0, addon.MAX_ARENA_SIZE do
                    if iconGroups[i] then
                        ProcessUnitEvent(iconGroups[i], event, ...);
                    end
                end
            end
        end)
    end
end

local externalTestIcons = {}; -- Premake icons for "Toggle Test Mode"
local externalTestGroup; -- Icon group for "Toggle Test Mode"

local function RefreshTestMode()
    addon.IconGroup_Wipe(externalTestGroup);

    local config = SweepyBoop.db.profile.arenaFrames;
    local scale = config.arenaCooldownTrackerIconSize / addon.DEFAULT_ICON_SIZE;
    local unitId = "player";
    if externalTestIcons[unitId] then
        for _, icon in pairs(externalTestIcons[unitId]) do
            icon:SetScale(scale);
            addon.SetHideCountdownNumbers(icon, config.hideCountDownNumbers);
        end
    else
        externalTestIcons[unitId] = {};
        local iconSize = config.arenaCooldownTrackerIconSize;
        for spellID, spell in pairs(spellData) do
            local size = config.arenaTrackerIconSize;
            if spellData[spellID].category == addon.SPELLCATEGORY.BURST then
                externalTestIcons[unitId][spellID] = addon.CreateBurstIcon(unitId, spellID, size, true);
            else
                externalTestIcons[unitId][spellID] = addon.CreateCooldownTrackingIcon(unitId, spellID, size, true);
            end
            addon.SetHideCountdownNumbers(externalTestIcons[unitId][spellID], config.hideCountDownNumbers);
        end
    end

    local grow = growOptions[config.arenaCooldownGrowDirection];
    local setPointOptions = GetSetPointOptions(1);
    setPointOptions.offsetX = config.arenaCooldownOffsetX;
    if externalTestGroup then
        addon.UpdateIconGroupSetPointOptions(externalTestGroup, setPointOptions, grow);
    else
        externalTestGroup = addon.CreateIconGroup(setPointOptions, grow, unitId);
    end

    SetupIconGroup(externalTestGroup, unitId, externalTestIcons);
end

function SweepyBoop:SetupArenaCooldownTracker()
    EnsureIcons();
    EnsureIconGroups();
end

function SweepyBoop:TestArenaCooldownTracker()
    RefreshTestMode(); -- Wipe the previous test frames first

    local subEvent = addon.SPELL_CAST_SUCCESS;
    local sourceGUID = UnitGUID("player");
    local destGUID = UnitGUID("player");
    local spellId = 10060; -- Power Infusion
    ProcessCombatLogEvent(externalTestGroup, subEvent, sourceGUID, destGUID, spellId);

    spellId = 190319; -- Combustion
    ProcessCombatLogEvent(externalTestGroup, subEvent, sourceGUID, destGUID, spellId);

    spellId = 45438; -- Ice Block
    ProcessCombatLogEvent(externalTestGroup, subEvent, sourceGUID, destGUID, spellId);

    externalTestGroup:Show();
end

function SweepyBoop:HideTestArenaCooldownTracker()
    addon.IconGroup_Wipe(externalTestGroup);
    if externalTestGroup then
        externalTestGroup:Hide();
    end
end