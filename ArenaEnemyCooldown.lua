local _, NS = ...;

local test = true;

local spellData = NS.spellData;
local spellResets = NS.spellResets;

local npcToSpellID = {
    [101398] = 211522,
    [62982] = 200174,
};

local resetByPower = {
    137639, -- Storm, Earth, and Fire
    152173, -- Serenity
    1719, -- Recklessness
};

local resetByCrit = {
    190319, -- Combustion
    1459, -- Arcane Intellect (test)
};

for _, spell in pairs(spellData) do
    spell.priority = spell.index;
    if ( not spell.priority ) then
        spell.priority = 100;
    end
end

local growOptions = {
    direction = "RIGHT",
    anchor = "LEFT",
    margin = 5,
};

local setPointOptions = {};
for i = 1, NS.MAX_ARENA_SIZE do
    setPointOptions[i] = {
        point = "LEFT",
        relativeTo = _G["sArenaEnemyFrame" .. i],
        relativePoint = "RIGHT",
        offsetX = 37.5,
        offsetY = 0,
    };
end

local function ValidateUnit(self)
     -- Update icon group guid
     if ( not self.unitGUID ) then
        self.unitGUID = UnitGUID(self.unit);
    end

    -- If unit does not exist, will return nil
    return self.unitGUID;
end

local function ProcessCombatLogEvent(self, event, ...)
    local guid = ValidateUnit(self);
    if ( not guid ) then
        return;
    end

    local _, subEvent, _, sourceGUID, _, _, _, destGUID, _, _, _, spellId, spellName, spellSchool, _, _, _, _, _, _, critical = CombatLogGetCurrentEventInfo();

    -- Check resets by spell cast
    if ( subEvent == "SPELL_CAST_SUCCESS" ) and ( sourceGUID == guid ) then
        -- Check reset by power
        for i = 1, #resetByPower do
            local reset = resetByPower[i];
            if self.activeMap[reset] then
                local cost = GetSpellPowerCost(spellId);
                if cost and cost[1] and ( cost[1].type == spellData[reset].reduce_power_type ) then
                    local amount = spellData[reset].reduce_amount * cost[1].cost;
                    NS.ResetWeakAuraCooldown(self.activeMap[reset], amount);
                end
            end
        end

        -- Check regular resets
        if spellResets[spellId] then
            for resetSpellID, amount in pairs(spellResets[spellId]) do
                if self.activeMap[resetSpellID] then
                    NS.ResetWeakAuraCooldown(self.activeMap[resetSpellID], amount);
                end
            end
        end
    end

    -- Check resets by crit damage (e.g., combustion)
    if ( subEvent == "SPELL_DAMAGE" ) and critical and ( sourceGUID == guid ) then
        for i = 1, #resetByCrit do
            local reset = resetByCrit[i];
            if self.activeMap[reset] then
                local spells = spellData[reset].critResets;
                for i = 1, #spells do
                    if ( spellId == spells[i] ) or ( spellName == spells[i] ) then
                        NS.ResetWeakAuraCooldown(self.activeMap[reset], spellData[reset].critResetAmount);
                    end
                end
                return;
            end
        end
    end

    -- Check summon / dead
    if ( subEvent == "UNIT_DIED" ) then
        -- Might have already been dismissed by SPELL_AURA_REMOVED, e.g., Psyfiend
        local summonSpellId = self.npcMap[destGUID];
        if summonSpellId and self.activeMap[summonSpellId] then
            NS.ResetWeakAuraDuration(self.activeMap[summonSpellId]);
        end
        return;
    elseif ( subEvent == "SPELL_SUMMON" ) and ( guid == sourceGUID ) then
        -- We don't actually show the icon from SPELL_SUMMON, just create the mapping of mob GUID -> spellID
        local npcId = NS.GetNpcIdFromGuid(destGUID);
        local summonSpellId = npcToSpellID[npcId];
        self.npcMap[destGUID] = summonSpellId;
        return;
    end
        
    -- Validate spell
    if ( not spellData[spellId] ) then return end
    local spell = spellData[spellId];

    -- Validate unit
    local spellGUID = ( spell.trackDest and destGUID ) or sourceGUID;
    if ( spellGUID ~= guid ) then return end

    -- Check spell dismiss
    if ( subEvent == "SPELL_AURA_REMOVED" ) then
        if self.activeMap[spellId] then
            NS.ResetWeakAuraDuration(self.activeMap[spellId]);
            return;
        end
    end

    -- Validate subEvent
    if spell.trackEvent and ( subEvent ~= spell.trackEvent ) then return end
    if ( not spell.trackEvent ) and ( subEvent ~= "SPELL_CAST_SUCCESS" ) then return end

    -- Find the icon to use
    if self.icons[spellId] then
        NS.StartWeakAuraIcon(self.icons[spellId]);
    end
end

local function ArenaEventHandler(self, event, ...)
    if ( event == "COMBAT_LOG_EVENT_UNFILTERED" ) then
        ProcessCombatLogEvent(self, event, ...);
    elseif ( event == "UNIT_SPELLCAST_SUCCEEDED" ) then
        --ProcessUnitSpellCast(self, event, ...);
    elseif ( event == "UNIT_AURA" ) then
        --ProcessUnitAura(self, event, ...);
    end
end

local function SetupAuraGroup(group, unit)
    -- Clear previous icons
    NS.IconGroup_Wipe(group);

    local class = select(3, UnitClass(unit));
    -- Pre-populate icons
    for spellID, spell in pairs(spellData) do
        if ( spell.class == class ) then
            NS.IconGroup_CreateIcon(group, NS.CreateWeakAuraIcon(unit, spellID, 32, true), spellID);
        end
    end

    -- Register events
    group:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
    group:RegisterEvent("UNIT_AURA");
    group:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");
    group:SetScript("OnEvent", ArenaEventHandler);
end

if test then
    local testGroup = NS.CreateIconGroup(setPointOptions[1], growOptions, "player");
    SetupAuraGroup(testGroup, "player");
else

end