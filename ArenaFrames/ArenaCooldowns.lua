local _, addon = ...;

local spellData = addon.SpellData;
local spellResets = addon.SpellResets;
local GetSpellPowerCost = C_Spell.GetSpellPowerCost;

local npcToSpellID = {
    [101398] = 211522, -- Psyfiend
    [62982] = 200174, -- Mindbender
    --[196111] = 387578, -- Gul'dan's Ambition (Pit Lord)
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

local premadeIcons = {};
local iconGroups = {}; -- One group per arena opponent for 1~3, 100 is for interrupt bar
local premadeIconsInterrupt = {};
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

local function EnsureIcon(unitId, spellID, isInterruptBar)
    local config = SweepyBoop.db.profile.arenaFrames;

    local iconSet = isInterruptBar and premadeIconsInterrupt or premadeIcons;

    if ( not iconSet[unitId][spellID] ) then
        local size = isInterruptBar and config.interruptBarIconSize or config.arenaCooldownTrackerIconSize;
        if spellData[spellID].category == addon.SPELLCATEGORY.BURST then
            iconSet[unitId][spellID] = addon.CreateBurstIcon(unitId, spellID, size, true);
        else
            iconSet[unitId][spellID] = addon.CreateCooldownTrackingIcon(unitId, spellID, size, true);
        end

        local hideCountDownNumbers = isInterruptBar and config.interruptBarHideCountDownNumbers or config.hideCountDownNumbers;
        addon.SetHideCountdownNumbers(iconSet[unitId][spellID], hideCountDownNumbers);
        -- size is set on creation but can be updated if lastModified falls behind
        iconSet[unitId][spellID].lastModified = config.lastModified;
    end

    -- Size was not set on creation, need to set scale and show/hide countdown numbers
    if ( iconSet[unitId][spellID].lastModified ~= config.lastModified ) then
        local size = isInterruptBar and config.interruptBarIconSize or config.arenaCooldownTrackerIconSize;
        iconSet[unitId][spellID]:SetScale(size / addon.DEFAULT_ICON_SIZE);
        local hideCountDownNumbers = isInterruptBar and config.interruptBarHideCountDownNumbers or config.hideCountDownNumbers;
        addon.SetHideCountdownNumbers(iconSet[unitId][spellID], hideCountDownNumbers);

        iconSet[unitId][spellID].lastModified = config.lastModified;
    end
end

local function EnsureIcons()
    if addon.TEST_MODE then
        local unitId = "player";
        premadeIcons[unitId] = premadeIcons[unitId] or {};
        premadeIconsInterrupt[unitId] = premadeIconsInterrupt[unitId] or {};
        for spellID, spell in pairs(spellData) do
            if ( not spell.use_parent_icon ) then
                if ( spell.category == addon.SPELLCATEGORY.INTERRUPT ) then
                    EnsureIcon(unitId, spellID, true);
                else
                    EnsureIcon(unitId, spellID);
                end
            end
        end
    else
        for i = 1, addon.MAX_ARENA_SIZE do
            local unitId = "arena"..i;
            premadeIcons[unitId] = premadeIcons[unitId] or {};
            premadeIconsInterrupt[unitId] = premadeIconsInterrupt[unitId] or {};
            for spellID, spell in pairs(spellData) do
                if ( not spell.use_parent_icon ) then
                    if ( spell.category == addon.SPELLCATEGORY.INTERRUPT ) then
                        EnsureIcon(unitId, spellID, true);
                    else
                        EnsureIcon(unitId, spellID);
                    end
                end
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
    local isInterruptBar = group.isInterruptBar;
    -- For external "Toggle Test Mode" icons, no filtering is needed
    if testIcons then
        local config = SweepyBoop.db.profile.arenaFrames;
        for spellID, spell in pairs(spellData) do
            if testIcons[unit][spellID] then
                testIcons[unit][spellID].info = { cooldown = spell.cooldown };
                -- The texture might have been set by use_parent_icon icons
                testIcons[unit][spellID].Icon:SetTexture(C_Spell.GetSpellTexture(spellID));
                addon.IconGroup_PopulateIcon(group, testIcons[unit][spellID], spellID);

                local showUnusedIcons = isInterruptBar and config.showUnusedInterruptIcons or config.showUnusedIcons;
                local unusedIconAlpha = isInterruptBar and config.interruptBarUnusedIconAlpha or config.unusedIconAlpha;
                if spell.baseline and showUnusedIcons then
                    testIcons[unit][spellID]:SetAlpha(unusedIconAlpha);
                    addon.IconGroup_Insert(group, testIcons[unit][spellID]);
                end
            end
        end

        return;
    end

    -- In arena prep phase, UnitExists returns false since enemies are not visible, but we can check spec and populate icons
    local class = addon.GetClassForPlayerOrArena(unit);
    if ( not class ) then return end

    local config = SweepyBoop.db.profile.arenaFrames;
    local iconSet = isInterruptBar and premadeIconsInterrupt or premadeIcons;

    -- Pre-populate icons
    for spellID, spell in pairs(spellData) do
        if iconSet[unit][spellID] then
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
                    iconSet[unit][spellID].info = GetSpecOverrides(spell);
                    -- The texture might have been set by use_parent_icon icons
                    iconSet[unit][spellID].Icon:SetTexture(C_Spell.GetSpellTexture(spellID));
                    addon.IconGroup_PopulateIcon(group, iconSet[unit][spellID], spellID);
                    --print("Populated", unit, spell.class, spellID)

                    local showUnusedIcons = isInterruptBar and config.showUnusedInterruptIcons or config.showUnusedIcons;
                    local unusedIconAlpha = isInterruptBar and config.interruptBarUnusedIconAlpha or config.unusedIconAlpha;
                    local spellList = isInterruptBar and config.interruptBarSpellList or config.spellList;
                    if spell.baseline and showUnusedIcons and spellList[tostring(spellID)] then
                        iconSet[unit][spellID]:SetAlpha(unusedIconAlpha);
                        addon.IconGroup_Insert(group, iconSet[unit][spellID]);
                    end
                end
            end
        end
    end
end

local function ValidateUnit(self)
    if ( not self.unitGuidToId ) then
        self.unitGuidToId = {};
        if self.unit then
            local unitGuid = UnitGUID(self.unit);
            if unitGuid then
                self.unitGuidToId[unitGuid] = self.unit;
            end
        else
            for i = 1, addon.MAX_ARENA_SIZE do
                local unitId = "arena" .. i;
                local unitGuid = UnitGUID(unitId);
                if unitGuid then
                    self.unitGuidToId[unitGuid] = unitId;
                end
            end
        end
    end

    return self.unitGuidToId;
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
    icon:SetAlpha(1);
    if icon.template == addon.ICON_TEMPLATE.GLOW then
        addon.StartBurstIcon(icon);
    elseif icon.template == addon.ICON_TEMPLATE.FLASH then
        addon.StartCooldownTrackingIcon(icon);
    end
end

local function ProcessCombatLogEvent(self, subEvent, sourceGUID, destGUID, spellId, spellName, critical, isTestGroup)
    local unitGuidToId = ValidateUnit(self);
    -- If self.unit doesn't exist, unitGuidToId will be empty
    if next(unitGuidToId) == nil then return end

    -- if addon.TEST_MODE and sourceGUID == UnitGUID("player") then
    --     print(subEvent, spellName, spellId);
    -- end

    -- Check resets by spell cast
    if ( subEvent == addon.SPELL_CAST_SUCCESS ) and ( unitGuidToId[sourceGUID] ) then
        -- Check reset by power
        for i = 1, #resetByPower do
            local reset = resetByPower[i];
            local icon = self.activeMap[self.unit .. "-" .. reset];
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

                --print(spellToReset, amount, self.activeMap[self.unit .. "-" .. spellToReset]);
                local icon = self.activeMap[self.unit .. "-" .. spellToReset];
                if icon then
                    ResetCooldown(icon, amount);
                end
            end
        end
    end

    -- Check resets by crit damage (e.g., combustion)
    if ( subEvent == addon.SPELL_DAMAGE ) and critical and ( unitGuidToId[sourceGUID] ) then
        for i = 1, #resetByCrit do
            local reset = resetByCrit[i];
            local icon = self.activeMap[self.unit .. "-" .. reset];
            if icon then
                local spells = spellData[reset].critResets;
                for i = 1, #spells do
                    if ( spellId == spells[i] ) or ( spellName == spells[i] ) then
                        --print(spellName, spellId, spellData[reset].critResetAmount);
                        ResetCooldown(icon, spellData[reset].critResetAmount);
                    end
                end
                return;
            end
        end
    end

    -- Check reset by interrupts, Counterspell, solar Beam
    -- Solar Beam only reduces 15s when interrupting main target, how do we detect it? Cache last reduce time?
    if ( subEvent == addon.SPELL_INTERRUPT ) and ( unitGuidToId[sourceGUID] ) then
        local icon = self.activeMap[self.unit .. "-" .. spellId];
        local amount = icon and icon.spellInfo.reduce_on_interrupt;
        if icon and amount then
            ResetCooldown(icon, amount, amount);
        end
    end

    -- Check summon / dead
    if addon.EVENTS_PET_DISMISS[subEvent] then
        -- Might have already been dismissed by SPELL_AURA_REMOVED, e.g., Psyfiend
        local summonSpellId = self.npcMap[destGUID];
        if summonSpellId and self.activeMap[self.unit .. "-" .. summonSpellId] then
            addon.ResetBurstDuration(self.activeMap[self.unit .. "-" .. summonSpellId]);
        end
        return;
    elseif ( subEvent == addon.SPELL_SUMMON ) and ( unitGuidToId[sourceGUID] ) then
        -- We don't actually show the icon from SPELL_SUMMON, just create the mapping of mob GUID -> spellID
        local npcId = addon.GetNpcIdFromGuid(destGUID);
        local summonSpellId = npcToSpellID[npcId];
        self.npcMap[destGUID] = summonSpellId;

        -- If not added yet, add by this (e.g., Guldan's Ambition: Pit Lord)
        -- if summonSpellId and self.icons[summonSpellId] and ( not self.activeMap[self.unit .. "-" .. summonSpellId] ) and SweepyBoop.db.profile.arenaFrames.spellList[tostring(summonSpellId)]  then
        --     StartIcon(self.icons[self.unit .. "-" .. summonSpellId]);
        -- end
        return;
    end

    -- Validate spell
    if ( not spellData[spellId] ) then return end
    local spell = spellData[spellId];

    -- Validate unit
    local spellGUID = ( spell.trackDest and destGUID ) or sourceGUID;
    if ( not unitGuidToId[spellGUID] ) then return end

    -- Check spell dismiss (check by sourceGUID unless trackDest is specified)
    if ( subEvent == addon.SPELL_AURA_REMOVED ) then
        local icon = self.activeMap[self.unit .. "-" .. spellId];
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
    local spellList = self.isInterruptBar and config.interruptBarSpellList or config.spellList;
    local configSpellId = spell.parent or spellId;
    local iconID = ( spell.use_parent_icon and spell.parent ) or spellId;
    if self.icons[iconID] and ( isTestGroup or spellList[tostring(configSpellId)] ) then
        if ( iconID ~= spellId ) then
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
    if ( unitTarget == self.unit ) then
        local spell = spellData[spellID];
        if ( not spell ) or ( spell.trackEvent ~= addon.UNIT_SPELLCAST_SUCCEEDED ) then return end
        if self.icons[spellID] then
            local config = SweepyBoop.db.profile.arenaFrames;
            local spellList = self.isInterruptBar and config.interruptBarSpellList or config.spellList;
            if spellList[tostring(spellID)] then
                addon.StartBurstIcon(self.icons[spellID]);
            end
        end
    end
end

local function ProcessUnitAura(self, event, ...)
    local guids = ValidateUnit(self);
    if next(guids) == nil then return end

    local unitTarget, updateAuras = ...;
    -- Only use UNIT_AURA to extend aura
    if ( unitTarget == self.unit ) and updateAuras and updateAuras.updatedAuraInstanceIDs then
        for _, instanceID in ipairs(updateAuras.updatedAuraInstanceIDs) do
            local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(unitTarget, instanceID);
            if auraData then
                local spellID = auraData.spellId;
                local spell = spellData[spellID];
                if spell and spell.extend and self.activeMap[self.unit .. "-" .. spellID] then
                    addon.RefreshBurstDuration(self.activeMap[self.unit .. "-" .. spellID], auraData.duration, auraData.expirationTime);
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

local framePrefix = ( GladiusEx and "GladiusExButtonFramearena" ) or ( Gladius and "GladiusButtonFramearena" ) or ( sArena and "sArenaEnemyFrame" ) or "CompactArenaFrameMember";
local largeColumn = 100; -- Don't break line for arena tracker
local arenaFrameGrowOptions = {
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
};

local interruptBarGrowOptions = {
    [addon.INTERRUPT_GROW_DIRECTION.CENTER_UP] = {
        direction = "CENTER",
        anchor = "CENTER",
        margin = 3,
        columns = 8,
        growUpward = true,
    },
    [addon.INTERRUPT_GROW_DIRECTION.CENTER_DOWN] = {
        direction = "CENTER",
        anchor = "CENTER",
        margin = 3,
        columns = 8,
        growUpward = false,
    },
}

local function GetSetPointOptions(index, isInterruptBar)
    local config = SweepyBoop.db.profile.arenaFrames;
    local offsetX = isInterruptBar and config.interruptBarOffsetX or config.arenaCooldownOffsetX;
    local offsetY = isInterruptBar and config.interruptBarOffsetY or config.arenaCooldownOffsetY;
    local setPointOptions;
    if isInterruptBar then
        setPointOptions = {
            point = "CENTER",
            relativeTo = "UIParent",
            relativePoint = "CENTER",
            offsetX = offsetX,
            offsetY = offsetY;
        };
    else
        local adjustedIndex = ( index == 0 and 1 ) or index;
        setPointOptions = {
            point = "LEFT",
            relativeTo = framePrefix .. adjustedIndex,
            relativePoint = "RIGHT",
            offsetX = offsetX,
            offsetY = offsetY;
        };
    end
    return setPointOptions;
end

local function EnsureIconGroup(index, unitId, isInterruptBar)
    local config = SweepyBoop.db.profile.arenaFrames;

    if ( not iconGroups[index] ) then
        local setPointOptions = GetSetPointOptions(index, isInterruptBar);
        local growOptions = isInterruptBar and interruptBarGrowOptions[config.interruptBarGrowDirection] or arenaFrameGrowOptions[config.arenaCooldownGrowDirection];
        iconGroups[index] = addon.CreateIconGroup(setPointOptions, growOptions, unitId);
        iconGroups[index].isInterruptBar = isInterruptBar;
        -- SetPointOptions is set but can be updated if lastModified falls behind
        iconGroups[index].lastModified = SweepyBoop.db.profile.arenaFrames.lastModified;
    end

    if ( iconGroups[index].lastModified ~= SweepyBoop.db.profile.arenaFrames.lastModified ) then
        local setPointOptions = GetSetPointOptions(index, isInterruptBar);
        local growOptions = isInterruptBar and interruptBarGrowOptions[config.interruptBarGrowDirection] or arenaFrameGrowOptions[config.arenaCooldownGrowDirection];
        addon.UpdateIconGroupSetPointOptions(iconGroups[index], setPointOptions, growOptions);
        iconGroups[index].lastModified = SweepyBoop.db.profile.arenaFrames.lastModified;
    end

    -- Clear previous icons
    --print("Clear previous icons");
    addon.IconGroup_Wipe(iconGroups[index]);
end

local function EnsureIconGroups()
    if addon.TEST_MODE then
        EnsureIconGroup(0, "player");
        EnsureIconGroup(100, "player", true); -- Interrupt bar
    else
        for i = 1, addon.MAX_ARENA_SIZE do
            EnsureIconGroup(i, "arena" .. i);
        end
        EnsureIconGroup(100, nil, true); -- Interrupt bar
    end
end

local function SetupIconGroups()
    if addon.TEST_MODE then
        SetupIconGroup(iconGroups[0], "player");
        SetupIconGroup(iconGroups[100], "player", nil);
    else
        for i = 1, addon.MAX_ARENA_SIZE do
            SetupIconGroup(iconGroups[i], "arena" .. i);
            SetupIconGroup(iconGroups[100], nil, nil);
        end
    end
end

local externalTestIcons = {}; -- Premake icons for "Toggle Test Mode"
local externalTestIconsInterrupt = {}; -- Premake icons for "Toggle Test Mode" interrupt bar
local externalTestGroup = {}; -- 1 for "Arena frames", 2 for "Interrupt bar". LUA only passes table by reference

local function RefreshTestMode(index, testIcons, isInterruptBar)
    addon.IconGroup_Wipe(externalTestGroup[index]);

    local config = SweepyBoop.db.profile.arenaFrames;
    local iconSize = isInterruptBar and config.interruptBarIconSize or config.arenaCooldownTrackerIconSize;
    local iconScale = iconSize / addon.DEFAULT_ICON_SIZE;
    local hideCountDownNumbers = isInterruptBar and config.interruptBarHideCountDownNumbers or config.hideCountDownNumbers;
    local unitId = "player";
    if testIcons[unitId] then
        for _, icon in pairs(testIcons[unitId]) do
            icon:SetScale(iconScale);
            addon.SetHideCountdownNumbers(icon, hideCountDownNumbers);
        end
    else
        testIcons[unitId] = {};
        for spellID, spell in pairs(spellData) do
            local isEnabled = false;
            if isInterruptBar then
                isEnabled = ( spell.category == addon.SPELLCATEGORY.INTERRUPT );
            elseif spell.class == addon.PRIEST then
                if spell.use_parent_icons then
                    -- Don't create if using parent icon
                elseif ( not spell.spec ) then
                    isEnabled = true;
                else
                    for i = 1, #(spell.spec) do
                        if ( spell.spec[i] == addon.SPECID.DISCIPLINE ) then
                            isEnabled = true;
                            break;
                        end
                    end
                end
            end
            if isEnabled then
                if spellData[spellID].category == addon.SPELLCATEGORY.BURST then
                    testIcons[unitId][spellID] = addon.CreateBurstIcon(unitId, spellID, iconSize, true);
                else
                    testIcons[unitId][spellID] = addon.CreateCooldownTrackingIcon(unitId, spellID, iconSize, true);
                end
                addon.SetHideCountdownNumbers(testIcons[unitId][spellID], hideCountDownNumbers);
            end
        end
    end

    local growOptions = isInterruptBar and interruptBarGrowOptions[config.interruptBarGrowDirection] or arenaFrameGrowOptions[config.arenaCooldownGrowDirection];
    local setPointOptions = GetSetPointOptions(1, isInterruptBar);
    if externalTestGroup[index] then
        addon.UpdateIconGroupSetPointOptions(externalTestGroup[index], setPointOptions, growOptions);
    else
        externalTestGroup[index] = addon.CreateIconGroup(setPointOptions, growOptions, unitId);
        externalTestGroup[index].isInterruptBar = isInterruptBar;
    end

    SetupIconGroup(externalTestGroup[index], unitId, testIcons);
end

function SweepyBoop:TestArenaCooldownTracker()
    RefreshTestMode(1, externalTestIcons); -- Wipe the previous test frames first

    local subEvent = addon.SPELL_CAST_SUCCESS;
    local sourceGUID = UnitGUID("player");
    local destGUID = UnitGUID("player");
    local spellId = 10060; -- Power Infusion
    ProcessCombatLogEvent(externalTestGroup[1], subEvent, sourceGUID, destGUID, spellId, nil, nil, true);

    spellId = 8122; -- Psychic Scream
    ProcessCombatLogEvent(externalTestGroup[1], subEvent, sourceGUID, destGUID, spellId, nil, nil, true);

    spellId = 33206; -- Pain Suppression
    ProcessCombatLogEvent(externalTestGroup[1], subEvent, sourceGUID, destGUID, spellId, nil, nil, true);

    spellId = 62618; -- Power Word: Barrier
    ProcessCombatLogEvent(externalTestGroup[1], subEvent, sourceGUID, destGUID, spellId, nil, nil, true);

    externalTestGroup[1]:Show();
end

function SweepyBoop:HideTestArenaCooldownTracker()
    addon.IconGroup_Wipe(externalTestGroup[1]);
    if externalTestGroup[1] then
        externalTestGroup[1]:Hide();
    end
end

function SweepyBoop:RepositionArenaCooldownTracker()
    if ( not externalTestGroup[1] ) or ( not externalTestGroup[1]:IsShown() ) then return end

    local config = SweepyBoop.db.profile.arenaFrames;
    local grow = arenaFrameGrowOptions[config.arenaCooldownGrowDirection];
    local setPointOptions = GetSetPointOptions(1);
    setPointOptions.offsetX = config.arenaCooldownOffsetX;
    addon.UpdateIconGroupSetPointOptions(externalTestGroup[1], setPointOptions, grow);
end

function SweepyBoop:TestArenaInterruptBar()
    RefreshTestMode(2, externalTestIconsInterrupt, true); -- Wipe the previous test frames first

    local subEvent = addon.SPELL_CAST_SUCCESS;
    local sourceGUID = UnitGUID("player");
    local destGUID = UnitGUID("player");
    local spellId = 1766; -- Kick
    ProcessCombatLogEvent(externalTestGroup[2], subEvent, sourceGUID, destGUID, spellId, nil, nil, true);

    spellId = 2139; -- Counterspell
    ProcessCombatLogEvent(externalTestGroup[2], subEvent, sourceGUID, destGUID, spellId, nil, nil, true);

    spellId = 147362; -- Counter Shot
    ProcessCombatLogEvent(externalTestGroup[2], subEvent, sourceGUID, destGUID, spellId, nil, nil, true);

    externalTestGroup[2]:Show();
end

function SweepyBoop:HideTestArenaInterruptBar()
    addon.IconGroup_Wipe(externalTestGroup[2]);
    if externalTestGroup[2] then
        externalTestGroup[2]:Hide();
    end
end

function SweepyBoop:RepositionArenaInterruptBar()
    if ( not externalTestGroup[2] ) or ( not externalTestGroup[2]:IsShown() ) then return end

    local config = SweepyBoop.db.profile.arenaFrames;
    local grow = arenaFrameGrowOptions[config.arenaCooldownGrowDirection];
    local setPointOptions = GetSetPointOptions(1, true);
    setPointOptions.offsetX = config.arenaCooldownOffsetX;
    addon.UpdateIconGroupSetPointOptions(externalTestGroup[2], setPointOptions, grow);
end

function SweepyBoop:SetupArenaCooldownTracker()
    EnsureIcons();
    EnsureIconGroups();

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
                -- PLAYER_SPECIALIZATION_CHANGED is triggered for all players, so we only process it when TEST_MODE is on

                -- Hide the external "Toggle Test Mode" group
                SweepyBoop:HideTestArenaCooldownTracker();

                -- This will simply update
                EnsureIcons();
                EnsureIconGroups();

                local shouldSetup = false;
                if addon.TEST_MODE then
                    shouldSetup = true;
                else
                    shouldSetup = ( event == addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS );
                end
                if shouldSetup then
                    --print("SetupIconGroups");
                    SetupIconGroups();
                end
            elseif ( event == addon.COMBAT_LOG_EVENT_UNFILTERED ) then
                if ( not IsActiveBattlefieldArena() ) and ( not addon.TEST_MODE ) then return end
                local _, subEvent, _, sourceGUID, _, _, _, destGUID, _, _, _, spellId, spellName, _, _, _, _, _, _, _, critical = CombatLogGetCurrentEventInfo();
                for i = 0, addon.MAX_ARENA_SIZE do
                    if iconGroups[i] then
                        ProcessCombatLogEvent(iconGroups[i], subEvent, sourceGUID, destGUID, spellId, spellName, critical);
                    end
                end
                if iconGroups[100] then
                    ProcessCombatLogEvent(iconGroups[100], subEvent, sourceGUID, destGUID, spellId, spellName);
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
