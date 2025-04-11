local _, addon = ...;

local spellData = addon.SpellData;
local spellResets = addon.SpellResets;
local GetSpellPowerCost = C_Spell.GetSpellPowerCost;

local interruptToSpellID = {
    [97547] = 78675, -- Solar Beam
};

local resetByPower = {
    -- 137639, -- Storm, Earth, and Fire (rarely picked)
    1719, -- Recklessness
    262161, -- Warbreaker
    167105, -- Colossus Smash
};

local resetByCrit = {
    190319, -- Combustion
};

local ICON_SET_ID = {
    ARENA_MAIN = "Arena",
    ARENA_SECONDARY = "ArenaSecondary",

    STANDALONE_1 = "Bar 1",
    STANDALONE_2 = "Bar 2",
    STANDALONE_3 = "Bar 3",
    STANDALONE_4 = "Bar 4",
    STANDALONE_5 = "Bar 5",
    STANDALONE_6 = "Bar 6",
};

local ARENA_FRAME_BARS = {
    [ICON_SET_ID.ARENA_MAIN] = true,
    [ICON_SET_ID.ARENA_SECONDARY] = true,
};

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

    -- Should we allow entries without class specified?
end

-- iconPool[iconSetID][unitID-spellID] (this works for arena frame bars too)
-- For test icons, use "spellID-test"
local iconPool = {};

local function GetIconSize(iconSetID)
    local config = SweepyBoop.db.profile.arenaFrames;
    if ARENA_FRAME_BARS[iconSetID] then
        return config.arenaCooldownTrackerIconSize;
    else
        return config.standaloneBars[iconSetID].iconSize;
    end
end

local function GetIconHideCountDownNumbers(iconSetID)
    local config = SweepyBoop.db.profile.arenaFrames;
    if ARENA_FRAME_BARS[iconSetID] then
        return config.hideCountDownNumbers;
    else
        return config.standaloneBars[iconSetID].hideCountDownNumbers;
    end
end

local function GetIcon(iconSetID, unitID, spellID, test)
    iconPool[iconSetID] = iconPool[iconSetID] or {};
    local iconID = unitID .. "-" .. spellID;
    if test then
        iconID = spellID .. "-test";
    end

    local config = SweepyBoop.db.profile.arenaFrames;

    if ( not iconPool[iconSetID][iconID] ) then
        local size = GetIconSize(iconSetID);
        if ( spellData[spellID].category == addon.SPELLCATEGORY.BURST ) and ARENA_FRAME_BARS[iconSetID] then
            iconPool[iconSetID][iconID] = addon.CreateBurstIcon(unitID, spellID, size, true);
        else
            iconPool[iconSetID][iconID] = addon.CreateCooldownTrackingIcon(unitID, spellID, size);
        end

        local hideCountDownNumbers = GetIconHideCountDownNumbers(iconSetID);
        addon.SetHideCountdownNumbers(iconPool[iconSetID][iconID], hideCountDownNumbers);
        iconPool[iconSetID][iconID].lastModified = config.lastModified;
    end

    if ( iconPool[iconSetID][iconID].lastModified ~= config.lastModified ) then
        local size = GetIconSize(iconSetID);
        iconPool[iconSetID][iconID]:SetScale(size / addon.DEFAULT_ICON_SIZE);
        local hideCountDownNumbers = GetIconHideCountDownNumbers(iconSetID);
        addon.SetHideCountdownNumbers(iconPool[iconSetID][iconID], hideCountDownNumbers);

        local hideCountDownNumbers = GetIconHideCountDownNumbers(iconSetID);
        addon.SetHideCountdownNumbers(iconPool[iconSetID][iconID], hideCountDownNumbers);

        iconPool[iconSetID][iconID].lastModified = config.lastModified;
    end

    return iconPool[iconSetID][iconID];
end

-- iconGroups[iconSetID] if tracking all units, otherwise iconGroups[iconSetID-unitID]
-- Append "-test" if it's a test group
local iconGroups = {};

local framePrefix = ( GladiusEx and "GladiusExButtonFramearena" ) or ( Gladius and "GladiusButtonFramearena" ) or ( sArena and "sArenaEnemyFrame" ) or "CompactArenaFrameMember";
local LARGE_COLUMN = 100; -- Don't break line for arena tracker
local arenaFrameGrowOptions = {
    [addon.ARENA_COOLDOWN_GROW_DIRECTION.RIGHT_DOWN] = {
        direction = "RIGHT",
        anchor = "LEFT",
        columns = LARGE_COLUMN,
        growUpward = false,
    },
    [addon.ARENA_COOLDOWN_GROW_DIRECTION.RIGHT_UP] = {
        direction = "RIGHT",
        anchor = "LEFT",
        columns = LARGE_COLUMN,
        growUpward = true,
    },
    [addon.ARENA_COOLDOWN_GROW_DIRECTION.LEFT_DOWN] = {
        direction = "LEFT",
        anchor = "RIGHT",
        columns = LARGE_COLUMN,
        growUpward = false,
    },
    [addon.ARENA_COOLDOWN_GROW_DIRECTION.LEFT_UP] = {
        direction = "LEFT",
        anchor = "RIGHT",
        columns = LARGE_COLUMN,
        growUpward = true,
    },
};
local standaloneBarGrowOptions = {
    [addon.STANDALONE_GROW_DIRECTION.CENTER_UP] = {
        direction = "UP",
        anchor = "CENTER",
        columns = LARGE_COLUMN,
        growUpward = true,
    },
    [addon.STANDALONE_GROW_DIRECTION.CENTER_DOWN] = {
        direction = "DOWN",
        anchor = "CENTER",
        columns = LARGE_COLUMN,
        growUpward = false,
    },
};

local function GetSetPointOptions(iconSetID, unitID)
    local config = SweepyBoop.db.profile.arenaFrames;

    local offsetX;
    if iconSetID == ICON_SET_ID.ARENA_MAIN then
        offsetX = config.arenaCooldownOffsetX;
    elseif iconSetID == ICON_SET_ID.ARENA_SECONDARY then
        offsetX = config.arenaCooldownOffsetXSecondary;
    else
        offsetX = config.standaloneBars[iconSetID].offsetX;
    end

    local offsetY;
    if iconSetID == ICON_SET_ID.ARENA_MAIN then
        offsetY = config.arenaCooldownOffsetY;
    elseif iconSetID == ICON_SET_ID.ARENA_SECONDARY then
        offsetY = config.arenaCooldownOffsetYSecondary;
    else
        offsetY = config.standaloneBars[iconSetID].offsetY;
    end

    local setPointOptions;
    if ARENA_FRAME_BARS[iconSetID] then
        local unitIndex = "1";
        if unitID and unitID ~= "player" then
            unitIndex = string.sub(unitID, -1);
        end
        setPointOptions = {
            point = "LEFT",
            relativeTo = framePrefix .. unitIndex,
            relativePoint = "RIGHT",
            offsetX = offsetX,
            offsetY = offsetY;
        };
    else
        setPointOptions = {
            point = "CENTER",
            relativeTo = "UIParent",
            relativePoint = "CENTER",
            offsetX = offsetX,
            offsetY = offsetY;
        };
    end

    return setPointOptions;
end

local function GetGrowOptions(iconSetID)
    local config = SweepyBoop.db.profile.arenaFrames;
    local growOptions;

    if ( iconSetID == ICON_SET_ID.ARENA_MAIN ) then
        growOptions = arenaFrameGrowOptions[config.arenaCooldownGrowDirection];
        growOptions.margin = config.arenaCooldownTrackerIconPadding;
    elseif ( iconSetID == ICON_SET_ID.ARENA_SECONDARY ) then
        growOptions = arenaFrameGrowOptions[config.arenaCooldownGrowDirectionSecondary];
        growOptions.margin = config.arenaCooldownTrackerIconPadding;
    else
        local growDirection = config.standaloneBars[iconSetID].growDirection;
        growOptions = standaloneBarGrowOptions[growDirection];
        growOptions.margin = config.standaloneBars[iconSetID].iconPadding;
    end

    return growOptions;
end

-- Specify unitID for arena frame bars (per unit)
local function GetIconGroup(iconSetID, unitID, isTestGroup)
    local iconGroupID = iconSetID;
    if unitID then
        iconGroupID = iconSetID .. "-" .. unitID;
    end
    if isTestGroup then
        iconGroupID = iconGroupID .. "-test";
    end

    local config = SweepyBoop.db.profile.arenaFrames;
    if ( not iconGroups[iconGroupID] ) then
        local setPointOptions = GetSetPointOptions(iconSetID, unitID);
        local growOptions = GetGrowOptions(iconSetID);
        iconGroups[iconGroupID] = addon.CreateIconGroup(setPointOptions, growOptions, unitID);
        iconGroups[iconGroupID].iconSetID = iconSetID;
        iconGroups[iconGroupID].guardianSpiritSaved = {}; -- Have to cache this per group
        iconGroups[iconGroupID].lastModified = config.lastModified;
    end

    if ( iconGroups[iconGroupID].lastModified ~= config.lastModified ) then
        local setPointOptions = GetSetPointOptions(iconSetID, unitID);
        local growOptions = GetGrowOptions(iconSetID);
        addon.UpdateIconGroupSetPointOptions(iconGroups[iconGroupID], setPointOptions, growOptions);
        iconGroups[iconGroupID].lastModified = config.lastModified;
    end

    addon.IconGroup_Wipe(iconGroups[iconGroupID]);
    iconGroups[iconGroupID].guardianSpiritSaved = {};

    return iconGroups[iconGroupID];
end

local function GetSpecOverrides(spell, spec)
    local overrides = {};

    overrides.spec = spec;

    if ( type(spell.cooldown) == "table" ) and spec then
        overrides.cooldown = spell.cooldown[spec] or spell.cooldown.default;
    else
        overrides.cooldown = spell.cooldown;
    end

    if ( type(spell.charges) == "table" ) and spec then
        overrides.charges = spell.charges[spec];
    else
        overrides.charges = spell.charges;
    end

    return overrides;
end

-- spellList, showUnusedIcons, unusedIconAlpha
local function GetIconConfig(iconSetID)
    local config = SweepyBoop.db.profile.arenaFrames;
    local iconConfig = {};
    if ( iconSetID == ICON_SET_ID.ARENA_MAIN ) then
        iconConfig.spellList = config.spellList;
        iconConfig.showUnusedIcons = config.showUnusedIcons;
        iconConfig.unusedIconAlpha = config.unusedIconAlpha;
    elseif ( iconSetID == ICON_SET_ID.ARENA_SECONDARY ) then
        iconConfig.spellList = config.spellList2;
        iconConfig.showUnusedIcons = config.showUnusedIcons;
        iconConfig.unusedIconAlpha = config.unusedIconAlpha;
    else
        local standaloneConfig = config.standaloneBars[iconSetID];
        iconConfig.spellList = standaloneConfig.spellList;
        iconConfig.showUnusedIcons = standaloneConfig.showUnusedIcons;
        iconConfig.unusedIconAlpha = standaloneConfig.unusedIconAlpha;
    end
    return iconConfig;
end

local function SetupIconGroup(iconSetID, unit, isTestGroup)
    local group = GetIconGroup(iconSetID, unit, isTestGroup);
    local config = SweepyBoop.db.profile.arenaFrames;
    local iconConfig = GetIconConfig(iconSetID);

    local class = addon.GetClassForPlayerOrArena(unit);
    local spec = addon.GetSpecForPlayerOrArena(unit);
    local remainingTest = 8;
    for spellID, spell in pairs(spellData) do
        if ( not spell.use_parent_icon ) then
            local enabled = false;

            -- For arena frame bars test groups, show priest abilities
            if isTestGroup and ARENA_FRAME_BARS[iconSetID] then
                if spell.class == addon.PRIEST then
                    if ( iconSetID == ICON_SET_ID.ARENA_MAIN ) then
                        if config.arenaCooldownSecondaryBar then
                            enabled = ( spell.category ~= addon.SPELLCATEGORY.DEFENSIVE );
                        else
                            enabled = true;
                        end
                    else
                        enabled = (spell.category == addon.SPELLCATEGORY.DEFENSIVE );
                    end
                end
            elseif class and ( ( not spell.class ) or ( spell.class == class ) ) then
                -- Fill enabled abilities, but for test groups, show 8 at most
                if isTestGroup and remainingTest <= 0 then
                    -- We hit the limit of 8 icons
                else
                    -- Does this spell filter by spec?
                    if spell.spec then
                        local specEnabled = false;

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

                        -- Put all icons for the class into the group whether enabled or not
                        enabled = specEnabled;
                    end
                end
            end

            if enabled then
                local icon = GetIcon(iconSetID, unit, spellID, isTestGroup);
                icon.info = GetSpecOverrides(spell, spec);
                -- The texture might have been set by use_parent_icon icons
                icon.Icon:SetTexture(C_Spell.GetSpellTexture(spellID));
                addon.IconGroup_PopulateIcon(group, icon, unit .. "-" .. spellID);
                --print("Populated icon", iconSetID, unit, spellID);

                local configSpellID = spell.parent or spellID;
                if spell.baseline and iconConfig.showUnusedIcons and iconConfig.spellList[tostring(configSpellID)] then
                    icon:SetAlpha(iconConfig.unusedIconAlpha);
                    addon.IconGroup_Insert(group, icon);
                end
            end
        end
    end
end

local function GetIconGroupEnabled(iconSetID)
    local config = SweepyBoop.db.profile.arenaFrames;
    if ( iconSetID == ICON_SET_ID.ARENA_MAIN ) then
        return config.arenaCooldownTrackerEnabled;
    elseif ( iconSetID == ICON_SET_ID.ARENA_SECONDARY ) then
        return config.arenaCooldownSecondaryBar;
    else
        return config.standaloneBars[iconSetID].enabled;
    end
end

local function ClearAllIconGroups()
    for _, iconGroup in pairs(iconGroups) do
        addon.IconGroup_Wipe(iconGroup); -- null check is included in IconGroup_Wipe
    end
end

local function SetupAllIconGroups()
    for _, iconSetID in pairs(ICON_SET_ID) do
        if GetIconGroupEnabled(iconSetID) then
            if addon.TEST_MODE then
                SetupIconGroup(iconSetID, "player");
            else
                for unitIndex = 1, addon.MAX_ARENA_SIZE do
                    local unit = "arena" .. unitIndex;
                    SetupIconGroup(iconSetID, unit);
                end
            end
        end
    end
end

local function ValidateUnit(self)
    self.unitIdToGuid = self.unitIdToGuid or {};

    if self.unit then
        if ( not self.unitIdToGuid[self.unit] ) then
            self.unitIdToGuid[self.unit] = UnitGUID(self.unit);
        end
    else
        for i = 1, addon.MAX_ARENA_SIZE do
            local unitId = "arena" .. i;
            if ( not self.unitIdToGuid[unitId] ) then
                self.unitIdToGuid[unitId] = UnitGUID(unitId);
            end
        end
    end

    self.unitGuidToId = self.unitGuidToId or {};

    for unit, guid in pairs(self.unitIdToGuid) do
        if ( not self.unitGuidToId[guid] ) then
            self.unitGuidToId[guid] = unit;
        end
    end

    return self.unitGuidToId;
end

-- Given a pet guid, return the owner unitId
local function IsCastByPet(guid)
    if UnitGUID("pet") == guid then
        return "player";
    end

    for i = 1, addon.MAX_ARENA_SIZE do
        if UnitGUID("arenapet" .. i) == guid then
            return "arena" .. i;
        end
    end
end

local function ResetCooldown(icon, amount, internalCooldown, resetTo) -- if resetTo is set, reset duration to amount, instead of reduce by amount
    if ( not icon.started ) then return end

    if icon.template == addon.ICON_TEMPLATE.GLOW then
        addon.ResetIconCooldown(icon, amount);

        -- Duration has more than 1s left, hide cooldown
        -- Duration frame's finish event handler will show the cooldown
        if icon.duration and icon.duration.finish and ( GetTime() < icon.duration.finish - 1 ) then
            icon.cooldown:Hide();
        end
    elseif icon.template == addon.ICON_TEMPLATE.FLASH then
        addon.ResetCooldownTrackingCooldown(icon, amount, internalCooldown, resetTo);
    end
end

local function StartIcon(icon)
    if icon.template == addon.ICON_TEMPLATE.GLOW then
        addon.StartBurstIcon(icon);
    elseif icon.template == addon.ICON_TEMPLATE.FLASH then
        addon.StartCooldownTrackingIcon(icon);
    end

    icon.started = true;
end

-- Record expirationTime when buff is applied, in case we missed SPELL_AURA_REMOVED
local apotheosisUnits = {};

local function ProcessCombatLogEvent(self, subEvent, sourceGUID, destGUID, spellId, spellName, critical, isTestGroup)
    -- if addon.TEST_MODE and sourceGUID == UnitGUID("player") then
    --     print(subEvent, spellName, spellId, sourceGUID, destGUID);
    -- end

    local unitGuidToId = ValidateUnit(self);
    -- If units don't exist, unitGuidToId will be empty
    if next(unitGuidToId) == nil then return end

    -- Apotheosis
    if spellId == 200183 and ( subEvent == addon.SPELL_AURA_APPLIED or subEvent == addon.SPELL_AURA_REMOVED ) then
        local unit = unitGuidToId[sourceGUID];
        if unit then
            if subEvent == addon.SPELL_AURA_APPLIED then
                apotheosisUnits[unit] = GetTime() + 20; -- 20s duration
            else
                apotheosisUnits[unit] = nil;
            end
        end
    end

    -- Guardian Spirit saved their teammate thus should be put on a longer cooldown (+120s)
    if ( spellId == 48153 ) and ( subEvent == addon.SPELL_HEAL ) then
        local unit = unitGuidToId[sourceGUID];
        if unit then
            self.guardianSpiritSaved[unit] = true;
        end

        return;
    end
    -- Now check if we need to reduce Guardian Spirit cooldown
    -- SPELL_AURA_REMOVED is fired twice, causing GS to be reset even if the healing proc
    -- Workaround by checking timestamp now vs. last aura removed
    if ( subEvent == addon.SPELL_AURA_REMOVED ) and ( spellId == 47788 ) then
        local unit = unitGuidToId[sourceGUID];
        if unit then
            if self.guardianSpiritSaved[unit] then
                self.guardianSpiritSaved[unit] = nil;
            else
                local icon = self.activeMap[unit .. "-" .. spellId];
                if icon then
                    ResetCooldown(icon, 60, nil, true); -- reduce CD to 1 min starting from now, not reducing by a fixed amount
                end
            end
        end

        return;
    end

    -- Check resets by spell cast
    if ( subEvent == addon.SPELL_CAST_SUCCESS ) and unitGuidToId[sourceGUID] then
        local unit = unitGuidToId[sourceGUID];
        -- Check reset by power
        for i = 1, #resetByPower do
            local reset = resetByPower[i];
            local icon = self.activeMap[unit .. "-" .. reset];
            if icon then
                local cost = GetSpellPowerCost(spellId);
                if cost and cost[1] and ( cost[1].type == spellData[reset].reduce_power_type ) then
                    local amount = spellData[reset].reduce_amount * cost[1].cost;
                    ResetCooldown(icon, amount);
                end
            end
        end

        -- Check regular resets
        if spellResets[spellId] then
            for i = 1, #(spellResets[spellId]) do
                local reset = spellResets[spellId][i];

                local spellToReset;
                local amount;
                if type(reset) == "table" and reset.amount then
                    spellToReset = reset.spellID;
                    amount = reset.amount;
                else
                    if type(reset) == "table" then
                        spellToReset = reset.spellID;
                    else
                        spellToReset = reset;
                    end
                end

                if addon.SpellResetsAffectedByApotheosis[spellId] and apotheosisUnits[unit] then
                    local now = GetTime();
                    if ( now > apotheosisUnits[unit] ) then -- in case we didn't catch SPELL_AURA_REMOVED, use the expirationTime to uncheck the buff
                        apotheosisUnits[unit] = nil;
                    end
                    local modifier = ( apotheosisUnits[unit] and addon.SpellResetsAffectedByApotheosis[spellId] ) or 1;
                    amount = amount * modifier;
                end

                local icon = self.activeMap[unit .. "-" .. spellToReset];
                if icon then
                    --print("Icon cooldown before reduction:", icon.timers[1].duration);
                    ResetCooldown(icon, amount);
                    --print("Icon cooldown after reduction:", icon.timers[1].duration);
                end
            end
        end
    end

    -- Check resets by crit damage (e.g., combustion)
    if ( subEvent == addon.SPELL_DAMAGE ) and critical and unitGuidToId[sourceGUID] then
        local unit = unitGuidToId[sourceGUID];
        for i = 1, #resetByCrit do
            local reset = resetByCrit[i];
            local icon = self.activeMap[unit .. "-" .. reset];
            if icon then
                local spells = spellData[reset].critResets;
                for i = 1, #spells do
                    if ( spellId == spells[i] ) or ( spellName == spells[i] ) then
                        ResetCooldown(icon, spellData[reset].critResetAmount);
                    end
                end
                return;
            end
        end
    end

    -- Check reset by interrupts, Counterspell, solar Beam
    -- Solar Beam only reduces 15s when interrupting main target, how do we detect it? Cache last reduce time?
    if ( subEvent == addon.SPELL_INTERRUPT ) and unitGuidToId[sourceGUID] then
        local unit = unitGuidToId[sourceGUID];
        local spellIdOveride = interruptToSpellID[spellId] or spellId;
        local icon = self.activeMap[unit .. "-" .. spellIdOveride];
        local amount = icon and icon.spellInfo.reduce_on_interrupt;
        if icon and amount then
            ResetCooldown(icon, amount, amount);
        end
    end

    -- Validate spell
    if ( not spellData[spellId] ) then return end
    local spell = spellData[spellId];

    -- Validate unit
    local unit;
    local spellGUID = ( spell.trackDest and destGUID ) or sourceGUID;
    if spell.trackPet then
        unit = IsCastByPet(spellGUID) or unitGuidToId[spellGUID];
    else
        unit = unitGuidToId[spellGUID];
    end
    if ( not unit ) then return end

    -- Check spell dismiss (check by sourceGUID unless trackDest is specified)
    if ( subEvent == addon.SPELL_AURA_REMOVED ) and unitGuidToId[sourceGUID] then
        local icon = self.activeMap[unitGuidToId[sourceGUID] .. "-" .. spellId];
        if icon and ( icon.template == addon.ICON_TEMPLATE.GLOW ) then
            addon.ResetBurstDuration(icon);
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

    -- Find the icon to use (check parent too)
    -- Config only shows parent ID, so check parent if applicable
    local config = SweepyBoop.db.profile.arenaFrames;
    local spellList = GetIconConfig(self.iconSetID).spellList;
    local configSpellId = spell.parent or spellId;
    local iconSpellId = ( spell.use_parent_icon and spell.parent ) or spellId;
    local iconID = unit .. "-" .. iconSpellId;
    if self.icons[iconID] and ( isTestGroup or spellList[tostring(configSpellId)] ) then
        if ( iconSpellId ~= spellId ) then
            self.icons[iconID].Icon:SetTexture(C_Spell.GetSpellTexture(spellId));
        end

        StartIcon(self.icons[iconID]);

        if isTestGroup and self.icons[iconID].Count then
            self.icons[iconID].Count:Show();
        end
    end
end

local function ProcessUnitSpellCast(self, event, ...)
    local guids = ValidateUnit(self);
    if next(guids) == nil then return end

    local unitTarget, _, spellID = ...;
    if ( not unitTarget ) then return end
    if ( unitTarget == self.unit ) then
        local spell = spellData[spellID];
        if ( not spell ) or ( spell.trackEvent ~= addon.UNIT_SPELLCAST_SUCCEEDED ) then return end
        local iconSpellID = ( spell.use_parent_icon and spell.parent ) or spellID;
        local iconID = self.unit .. "-" .. iconSpellID;
        if self.icons[iconID] then
            local spellList = GetIconConfig(self.iconSetID).spellList;

            local configSpellID = spell.parent or spellID;
            if spellList[tostring(configSpellID)] then
                addon.StartBurstIcon(self.icons[iconID]);
            end
        end
    end
end

local function ProcessUnitAura(self, event, ...)
    local guids = ValidateUnit(self);
    if next(guids) == nil then return end

    local unitTarget, updateAuras = ...;
    if ( not unitTarget ) then return end
    -- Only use UNIT_AURA to extend aura
    if ( unitTarget == self.unit ) and updateAuras and updateAuras.updatedAuraInstanceIDs then
        for _, instanceID in ipairs(updateAuras.updatedAuraInstanceIDs) do
            local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(unitTarget, instanceID);
            if auraData then
                local spellID = auraData.spellId;
                local spell = spellData[spellID];
                if spell and spell.extend then
                    local iconSpellID = ( spell.use_parent_icon and spell.parent ) or spellID;
                    local iconID = unitTarget .. "-" .. iconSpellID;
                    if self.activeMap[iconID] then
                        addon.RefreshBurstDuration(self.activeMap[iconID], auraData.duration, auraData.expirationTime);
                    end
                end
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

function SweepyBoop:TestArenaCooldownTracker()
    local secondaryBarEnabled = SweepyBoop.db.profile.arenaFrames.arenaCooldownSecondaryBar;

    local mainBarID = ICON_SET_ID.ARENA_MAIN .. "-player-test";
    local secondaryBarID = ICON_SET_ID.ARENA_SECONDARY .. "-player-test";

    addon.IconGroup_Wipe(iconGroups[mainBarID]);
    addon.IconGroup_Wipe(iconGroups[secondaryBarID]); -- Secondary bar

    SetupIconGroup(ICON_SET_ID.ARENA_MAIN, "player", true);
    if secondaryBarEnabled then
        SetupIconGroup(ICON_SET_ID.ARENA_SECONDARY, "player", true);
    end

    local subEvent = addon.SPELL_CAST_SUCCESS;
    local sourceGUID = UnitGUID("player");
    local destGUID = UnitGUID("player");
    local spellId = 10060; -- Power Infusion
    ProcessCombatLogEvent(iconGroups[mainBarID], subEvent, sourceGUID, destGUID, spellId, nil, nil, true);

    spellId = 8122; -- Psychic Scream
    ProcessCombatLogEvent(iconGroups[mainBarID], subEvent, sourceGUID, destGUID, spellId, nil, nil, true);

    spellId = 33206; -- Pain Suppression
    ProcessCombatLogEvent(iconGroups[mainBarID], subEvent, sourceGUID, destGUID, spellId, nil, nil, true);
    if secondaryBarEnabled then
        ProcessCombatLogEvent(iconGroups[secondaryBarID], subEvent, sourceGUID, destGUID, spellId, nil, nil, true);
    end

    spellId = 62618; -- Power Word: Barrier
    ProcessCombatLogEvent(iconGroups[mainBarID], subEvent, sourceGUID, destGUID, spellId, nil, nil, true);
    if secondaryBarEnabled then
        ProcessCombatLogEvent(iconGroups[secondaryBarID], subEvent, sourceGUID, destGUID, spellId, nil, nil, true);
    end

    iconGroups[mainBarID]:Show();
    if SweepyBoop.db.profile.arenaFrames.arenaCooldownSecondaryBar then
        iconGroups[secondaryBarID]:Show();
    end
end

function SweepyBoop:HideTestArenaCooldownTracker()
    local mainBar = iconGroups[ICON_SET_ID.ARENA_MAIN .. "-player-test"];
    local secondaryBar = iconGroups[ICON_SET_ID.ARENA_SECONDARY .. "-player-test"]; -- Secondary bar

    addon.IconGroup_Wipe(mainBar);
    addon.IconGroup_Wipe(secondaryBar);
    if mainBar then
        mainBar:Hide();
    end
    if secondaryBar then
        secondaryBar:Hide();
    end
end

local function RepositionExternalTestGroup(iconGroupID, unitIndex)
    if ( not iconGroups[iconGroupID] ) or ( not iconGroups[iconGroupID]:IsShown() ) then return end

    local growOptions = GetGrowOptions(iconGroups[iconGroupID].iconSetID);
    local setPointOptions = GetSetPointOptions(iconGroups[iconGroupID].iconSetID, unitIndex);
    addon.UpdateIconGroupSetPointOptions(iconGroups[iconGroupID], setPointOptions, growOptions);
end

function SweepyBoop:RepositionArenaCooldownTracker(layoutIcons)
    RepositionExternalTestGroup(ICON_SET_ID.ARENA_MAIN .. "-player-test", 1);
    RepositionExternalTestGroup(ICON_SET_ID.ARENA_SECONDARY .. "-player-test", 1);

    if layoutIcons then
        addon.IconGroup_Position(iconGroups[ICON_SET_ID.ARENA_MAIN .. "-player-test"]);
        addon.IconGroup_Position(iconGroups[ICON_SET_ID.ARENA_SECONDARY .. "-player-test"]);
    end
end

function SweepyBoop:TestArenaStandaloneBars()
    addon.IconGroup_Wipe(iconGroups[ICON_SET_ID.INTERRUPT .. "-player-test"]);
    SetupIconGroup(ICON_SET_ID.INTERRUPT, "player", true);
    local iconGroup = iconGroups[ICON_SET_ID.INTERRUPT .. "-player-test"];

    local subEvent = addon.SPELL_CAST_SUCCESS;
    local sourceGUID = UnitGUID("player");
    local destGUID = UnitGUID("player");
    local spellId = 1766; -- Kick
    ProcessCombatLogEvent(iconGroup, subEvent, sourceGUID, destGUID, spellId, nil, nil, true);

    spellId = 57994; -- Wind Shear
    ProcessCombatLogEvent(iconGroup, subEvent, sourceGUID, destGUID, spellId, nil, nil, true);

    spellId = 204336; -- Grounding Totem
    ProcessCombatLogEvent(iconGroup, subEvent, sourceGUID, destGUID, spellId, nil, nil, true);

    spellId = 8143; -- Tremor Totem
    ProcessCombatLogEvent(iconGroup, subEvent, sourceGUID, destGUID, spellId, nil, nil, true);

    iconGroup:Show();
end

function SweepyBoop:HideTestArenaStandaloneBars()
    for i = 1, 6 do
        local iconGroup = iconGroups["Bar " .. i .. "-test"];
        if iconGroup then
            addon.IconGroup_Wipe(iconGroup);
            iconGroup:Hide();
        end
    end
end

local eventFrame;

function SweepyBoop:SetupArenaCooldownTracker()
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
            local config = SweepyBoop.db.profile.arenaFrames;
            local arenaTrackerEnabled = config.arenaCooldownTrackerEnabled;
            local interruptBarEnabled = config.interruptBarEnabled;

            if ( not arenaTrackerEnabled ) and ( not interruptBarEnabled ) then
                return;
            end

            if ( event == addon.PLAYER_ENTERING_WORLD ) or ( event == addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS ) or ( event == addon.PLAYER_SPECIALIZATION_CHANGED and addon.TEST_MODE ) then
                -- PLAYER_SPECIALIZATION_CHANGED is triggered for all players, so we only process it when TEST_MODE is on

                apotheosisUnits = {};

                -- Hide the external "Toggle Test Mode" group
                SweepyBoop:HideTestArenaCooldownTracker();
                SweepyBoop:HideTestArenaStandaloneBars();

                ClearAllIconGroups();

                local shouldSetup = false;
                if addon.TEST_MODE then
                    shouldSetup = true;
                elseif ( event == addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS ) then
                    shouldSetup = true;
                elseif ( event == addon.PLAYER_ENTERING_WORLD ) then
                    local matchState = C_PvP.GetActiveMatchState();
                    shouldSetup = ( matchState < Enum.PvPMatchState.Engaged );
                end
                if shouldSetup then
                    SetupAllIconGroups();
                end
            elseif ( event == addon.COMBAT_LOG_EVENT_UNFILTERED ) then
                if ( not IsActiveBattlefieldArena() ) and ( not addon.TEST_MODE ) then return end
                local _, subEvent, _, sourceGUID, _, _, _, destGUID, _, _, _, spellId, spellName, _, _, _, _, _, _, _, critical = CombatLogGetCurrentEventInfo();
                local secondaryBarEnabled = config.arenaCooldownSecondaryBar;
                if arenaTrackerEnabled then
                    for i = 1, addon.MAX_ARENA_SIZE do
                        if iconGroups[i] then
                            ProcessCombatLogEvent(iconGroups[i], subEvent, sourceGUID, destGUID, spellId, spellName, critical);
                        end
                        if secondaryBarEnabled and iconGroups[i + 3] then
                            ProcessCombatLogEvent(iconGroups[i + 3], subEvent, sourceGUID, destGUID, spellId, spellName, critical); -- Secondary bar
                        end
                    end
                end

                if iconGroups[100] and interruptBarEnabled then
                    ProcessCombatLogEvent(iconGroups[100], subEvent, sourceGUID, destGUID, spellId, spellName);
                end
            elseif ( event == addon.UNIT_AURA ) or ( event == addon.UNIT_SPELLCAST_SUCCEEDED ) then
                if ( not IsActiveBattlefieldArena() ) and ( not addon.TEST_MODE ) then return end
                if ( not arenaTrackerEnabled ) then return end
                local secondaryBarEnabled = config.arenaCooldownSecondaryBar;
                for i = 1, addon.MAX_ARENA_SIZE do
                    if iconGroups[i] then
                        ProcessUnitEvent(iconGroups[i], event, ...);
                    end
                    if secondaryBarEnabled and iconGroups[i + 3] then
                        ProcessUnitEvent(iconGroups[i + 3], event, ...); -- Secondary bar
                    end
                end
            end
        end)
    end
end
