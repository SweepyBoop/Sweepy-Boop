local _, addon = ...;

local spellData = addon.SpellData;
local spellResets = addon.SpellResets;

local premadeIcons = {};
local iconGroup = {};
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
        premadeIcons[unitId][spellID] = addon.CreateCooldownTrackingIcon(unitId, spellID, config.interruptBarIconSize, true);
        addon.SetHideCountdownNumbers(premadeIcons[unitId][spellID], config.interruptBarHideCountDownNumbers);
        -- size is set on creation but can be updated if lastModified falls behind
        premadeIcons[unitId][spellID].lastModified = config.lastModified;
    end

    -- Size was not set on creation, need to set scale and show/hide countdown numbers
    if ( premadeIcons[unitId][spellID].lastModified ~= config.lastModified ) then
        premadeIcons[unitId][spellID]:SetScale(config.interruptBarIconSize / addon.DEFAULT_ICON_SIZE);
        addon.SetHideCountdownNumbers(premadeIcons[unitId][spellID], config.interruptBarHideCountDownNumbers);

        premadeIcons[unitId][spellID].lastModified = config.lastModified;
    end
end

local function EnsureIcons()
    if addon.TEST_MODE then
        local unitId = "player";
        premadeIcons[unitId] = premadeIcons[unitId] or {};
        for spellID, spell in pairs(spellData) do
            if ( not spell.use_parent_icon ) then
                EnsureIcon(unitId, spellID);
            end
        end
    else
        for i = 1, addon.MAX_ARENA_SIZE do
            local unitId = "arena"..i;
            premadeIcons[unitId] = premadeIcons[unitId] or {};
            for spellID, spell in pairs(spellData) do
                if ( not spell.use_parent_icon ) then
                    EnsureIcon(unitId, spellID);
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
    -- For external "Toggle Test Mode" icons, no filtering is needed
    if testIcons then
        local config = SweepyBoop.db.profile.arenaFrames;
        for spellID, spell in pairs(spellData) do
            if testIcons[unit][spellID] then
                testIcons[unit][spellID].info = { cooldown = spell.cooldown };
                -- The texture might have been set by use_parent_icon icons
                testIcons[unit][spellID].Icon:SetTexture(C_Spell.GetSpellTexture(spellID));
                addon.IconGroup_PopulateIcon(group, testIcons[unit][spellID], spellID);

                if spell.baseline and config.showUnusedIcons then
                    testIcons[unit][spellID]:SetAlpha(config.unusedIconAlpha);
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

    -- Pre-populate icons
    for spellID, spell in pairs(spellData) do
        if premadeIcons[unit][spellID] then
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
                    -- The texture might have been set by use_parent_icon icons
                    premadeIcons[unit][spellID].Icon:SetTexture(C_Spell.GetSpellTexture(spellID));
                    addon.IconGroup_PopulateIcon(group, premadeIcons[unit][spellID], spellID);
                    --print("Populated", unit, spell.class, spellID)

                    if spell.baseline and config.showUnusedIcons and config.spellList[tostring(spellID)] then
                        premadeIcons[unit][spellID]:SetAlpha(config.unusedIconAlpha);
                        addon.IconGroup_Insert(group, premadeIcons[unit][spellID]);
                    end
                end
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