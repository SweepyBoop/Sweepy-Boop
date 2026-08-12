local _, addon = ...;
addon.TEST_MODE = false;

addon.PROJECT_MAINLINE = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE);
addon.PROJECT_TBC = (WOW_PROJECT_ID == 5);
addon.PROFILE_VERSION = 1.0; -- To validate export string

addon.SPELLCATEGORY = {
    IMMUNITY = 1,
    DEFENSIVE = 2,
    DISPEL = 3,
    MASS_DISPEL = 4,
    INTERRUPT = 5,
    STUN = 6,
    SILENCE = 7,
    KNOCKBACK = 8,
    CROWDCONTROL = 9,
    BURST = 10,
    HEAL = 11,
    MOBILITY = 12,
    OTHERS = 100,
};

addon.SPELLCATEGORY_NAME = {
    [addon.SPELLCATEGORY.IMMUNITY] = addon.L["Immunity"],
    [addon.SPELLCATEGORY.DEFENSIVE] = addon.L["Defensive"],
    [addon.SPELLCATEGORY.DISPEL] = addon.L["Dispel"],
    [addon.SPELLCATEGORY.MASS_DISPEL] = addon.L["Mass Dispel"],
    [addon.SPELLCATEGORY.INTERRUPT] = addon.L["Interrupt"],
    [addon.SPELLCATEGORY.STUN] = addon.L["Stun"],
    [addon.SPELLCATEGORY.SILENCE] = addon.L["Silence"],
    [addon.SPELLCATEGORY.KNOCKBACK] = addon.L["Knockback"],
    [addon.SPELLCATEGORY.CROWDCONTROL] = addon.L["Crowd Control"],
    [addon.SPELLCATEGORY.BURST] = addon.L["Burst"],
    [addon.SPELLCATEGORY.HEAL] = addon.L["Heal"],
    [addon.SPELLCATEGORY.MOBILITY] = addon.L["Mobility"],
    [addon.SPELLCATEGORY.OTHERS] = addon.L["Others"],
};

addon.SPELLPRIORITY = {
    DEADLY = 1,
    HIGH = 10,
    DEFAULT = 50,
    LOW = 100,
};

addon.ICON_TEMPLATE = {
    GLOW = 1, -- AWC style
    FLASH = 2, -- OmniBar style
};

addon.BIG_DEBUFFS_ICON_STYLE_ID = {
    DEBUFF_BORDER = "debuffBorder",
    HIGHLIGHT = "highlight",
    GLOW = "glow",
};

addon.BIG_DEBUFFS_AURA_KIND = {
    CROWD_CONTROL = 1,
    DEFENSIVE = 2,
    IMPORTANT_BUFF = 3,
};

local BIG_DEBUFFS_AURA_TINT = {
    [addon.BIG_DEBUFFS_AURA_KIND.CROWD_CONTROL] = { 1, 0.6471, 0 },
    [addon.BIG_DEBUFFS_AURA_KIND.DEFENSIVE] = { 0.2, 0.65, 1 },
    [addon.BIG_DEBUFFS_AURA_KIND.IMPORTANT_BUFF] = { 0, 1, 0 },
};

local BIG_DEBUFFS_STYLE_TINT = {
    [addon.BIG_DEBUFFS_ICON_STYLE_ID.HIGHLIGHT] = {
        [addon.BIG_DEBUFFS_AURA_KIND.CROWD_CONTROL] = { 1, 0.48, 0 },
    },
};

addon.BIG_DEBUFFS_DEFAULTS = {
    ENABLED = false,
    SHOW_CROWD_CONTROL = true,
    SHOW_DEFENSIVES = true,
    SHOW_IMPORTANT_BUFFS = true,
    ICON_STYLE = addon.BIG_DEBUFFS_ICON_STYLE_ID.HIGHLIGHT,
    ICON_SIZE = 32,
    MAX_ICONS = 2,
    SPACING = 6,
    OFFSET_X = 0,
    OFFSET_Y = 0,
};

addon.BIG_DEBUFFS_ICON_STYLE = {
    DEBUFF_ICON_INSET = 2,
    DEBUFF_BORDER_TEXTURE = "Interface\\Buttons\\UI-Debuff-Overlays",
    DEBUFF_BORDER_TEX_COORDS = { 0.296875, 0.5703125, 0, 0.515625 },
    HIGHLIGHT_BORDER_TEXTURE = "Interface\\AddOns\\SweepyBoop\\Art\\BigDebuffsAuraHighlightBorder",
    HIGHLIGHT_GLOW_TEXTURE = "Interface\\AddOns\\SweepyBoop\\Art\\BigDebuffsAuraHighlightGlow",
    HIGHLIGHT_BASE_SIZE = 32,
    HIGHLIGHT_PADDING = 7,
    GLOW_COOLDOWN_EDGE_TEXTURE = "Interface\\Cooldown\\UI-HUD-ActionBar-LoC",
};

addon.GetBigDebuffsIconStyle = function(config)
    if config.bigDebuffsIconStyle == "auraHighlight" then
        return addon.BIG_DEBUFFS_ICON_STYLE_ID.HIGHLIGHT;
    end

    return config.bigDebuffsIconStyle or addon.BIG_DEBUFFS_DEFAULTS.ICON_STYLE;
end

addon.GetBigDebuffsAuraTint = function(auraKind, iconStyle)
    local styleTints = BIG_DEBUFFS_STYLE_TINT[iconStyle];
    return ( styleTints and styleTints[auraKind] ) or BIG_DEBUFFS_AURA_TINT[auraKind] or BIG_DEBUFFS_AURA_TINT[addon.BIG_DEBUFFS_AURA_KIND.IMPORTANT_BUFF];
end

addon.ARENA_COOLDOWN_GROW_DIRECTION = {
    RIGHT = 1,
    LEFT = 3,

    CENTER = 4, -- Probably will never include this option
};

addon.STANDALONE_GROW_DIRECTION = {
    CENTER = 1,
    LEFT = 2,
    RIGHT = 3,
};

addon.ICON_SET_ID = {
    ARENA_MAIN = "Arena",
    ARENA_SECONDARY = "ArenaSecondary",

    STANDALONE_1 = "Bar 1",
    STANDALONE_2 = "Bar 2",
    STANDALONE_3 = "Bar 3",
    STANDALONE_4 = "Bar 4",
    STANDALONE_5 = "Bar 5",
    STANDALONE_6 = "Bar 6",
};

addon.ARENA_FRAME_BARS = {
    [addon.ICON_SET_ID.ARENA_MAIN] = true,
    [addon.ICON_SET_ID.ARENA_SECONDARY] = true,
};

addon.ARENA_FRAME_BARS_SUPPORTED = function()
    if addon.PROJECT_MAINLINE then
        return true;
    else
        return GladiusEx or Gladius or sArena or ArenaLiveUnitFrames or SlashCmdList.GLADDY;
    end
end

addon.GET_ARENA_FRAME_PREFIX = function()
    if addon.ARENA_FRAME_PREFIX == nil then
        addon.ARENA_FRAME_PREFIX =
            ( GladiusEx and "GladiusExButtonFramearena" )
            or ( Gladius and "GladiusButtonFramearena" )
            or ( sArena and "sArenaEnemyFrame" )
            or ( ArenaLiveUnitFrames and "ALUF_ArenaEnemyFramesArenaEnemyFrame" )
            or ( SlashCmdList.GLADDY and "GladdyButtonFrame" )
            or "CompactArenaFrameMember";
    end

    return addon.ARENA_FRAME_PREFIX;
end

addon.DURATION_DYNAMIC = "DURATION_DYNAMIC";

addon.SPECID = {
    BLOOD = 250,
    FROST_DK = 251,
    UNHOLY = 252,

    HAVOC = 577,
    VENGEANCE = 581,
    DEVOURER = 1480,

    BALANCE = 102,
    FERAL = 103,
    GUARDIAN = 104,
    RESTORATION_DRUID = 105,

    DEVASTATION = 1467,
    PRESERVATION = 1468,
    AUGMENTATION = 1473,

    BEASTMASTERY = 253,
    MARKSMANSHIP = 254,
    SURVIVAL = 255,

    ARCANE = 62,
    FIRE = 63,
    FROST_MAGE = 64,

    BREWMASTER = 268,
    MISTWEAVER = 270,
    WINDWALKER = 269,

    HOLY_PALADIN = 65,
    PROTECTION_PALADIN = 66,
    RETRIBUTION = 70,

    DISCIPLINE = 256,
    HOLY_PRIEST = 257,
    SHADOW = 258,

    ASSASSINATION = 259,
    OUTLAW = 260,
    SUBTLETY = 261,

    ELEMENTAL = 262,
    ENHANCEMENT = 263,
    RESTORATION_SHAMAN = 264,

    AFFLICTION = 265,
    DEMONOLOGY = 266,
    DESTRUCTION = 267,

    ARMS = 71,
    FURY = 72,
    PROTECTION_WARRIOR = 73,
};

-- Event name constants
addon.BAG_UPDATE = "BAG_UPDATE";
addon.LOSS_OF_CONTROL_ADDED = "LOSS_OF_CONTROL_ADDED";
addon.LOSS_OF_CONTROL_UPDATE = "LOSS_OF_CONTROL_UPDATE";
addon.PLAYER_ENTERING_WORLD = "PLAYER_ENTERING_WORLD";
addon.ZONE_CHANGED_NEW_AREA = "ZONE_CHANGED_NEW_AREA";
addon.PLAYER_TARGET_CHANGED = "PLAYER_TARGET_CHANGED";
addon.PLAYER_FOCUS_CHANGED = "PLAYER_FOCUS_CHANGED";
addon.PLAYER_REGEN_ENABLED = "PLAYER_REGEN_ENABLED";
addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS = "ARENA_PREP_OPPONENT_SPECIALIZATIONS";
addon.ARENA_OPPONENT_UPDATE = "ARENA_OPPONENT_UPDATE";
addon.PVP_MATCH_STATE_CHANGED = "PVP_MATCH_STATE_CHANGED";
addon.PLAYER_SPECIALIZATION_CHANGED = "PLAYER_SPECIALIZATION_CHANGED";
addon.UNIT_SPELLCAST_START = "UNIT_SPELLCAST_START";
addon.UNIT_SPELLCAST_STOP = "UNIT_SPELLCAST_STOP";
addon.UNIT_SPELLCAST_INTERRUPTED = "UNIT_SPELLCAST_INTERRUPTED";
addon.UNIT_SPELLCAST_CHANNEL_START = "UNIT_SPELLCAST_CHANNEL_START";
addon.UNIT_SPELLCAST_CHANNEL_STOP = "UNIT_SPELLCAST_CHANNEL_STOP";
addon.UNIT_SPELLCAST_SUCCEEDED = "UNIT_SPELLCAST_SUCCEEDED";
addon.UNIT_AURA = "UNIT_AURA";
addon.UNIT_TARGET = "UNIT_TARGET";
addon.UNIT_HEALTH = "UNIT_HEALTH";
addon.UNIT_MAXHEALTH = "UNIT_MAXHEALTH";
addon.UNIT_POWER_UPDATE = "UNIT_POWER_UPDATE";
addon.UNIT_POWER_FREQUENT = "UNIT_POWER_FREQUENT";
addon.UNIT_MAXPOWER = "UNIT_MAXPOWER";
addon.UNIT_PET = "UNIT_PET";
addon.UNIT_FLAGS = "UNIT_FLAGS";
addon.UPDATE_SHAPESHIFT_FORM = "UPDATE_SHAPESHIFT_FORM";
addon.COMBAT_LOG_EVENT_UNFILTERED = "COMBAT_LOG_EVENT_UNFILTERED";
addon.GROUP_ROSTER_UPDATE = "GROUP_ROSTER_UPDATE";
addon.NAME_PLATE_UNIT_ADDED = "NAME_PLATE_UNIT_ADDED";
addon.NAME_PLATE_UNIT_REMOVED = "NAME_PLATE_UNIT_REMOVED";
-- Sub event name constants
addon.SPELL_CAST_SUCCESS = "SPELL_CAST_SUCCESS";
addon.SPELL_AURA_APPLIED = "SPELL_AURA_APPLIED";
addon.SPELL_AURA_REMOVED = "SPELL_AURA_REMOVED";
addon.SPELL_DAMAGE = "SPELL_DAMAGE";
addon.SPELL_CAST_START = "SPELL_CAST_START";
addon.SPELL_SUMMON = "SPELL_SUMMON";
addon.SPELL_EMPOWER_END = "SPELL_EMPOWER_END";
addon.PARTY_KILL = "PARTY_KILL";
addon.UNIT_DIED = "UNIT_DIED";
addon.UNIT_DESTROYED = "UNIT_DESTROYED";
addon.UNIT_DISSIPATES = "UNIT_DISSIPATES";
addon.SPELL_DISPEL = "SPELL_DISPEL";
addon.SPELL_INTERRUPT = "SPELL_INTERRUPT";
addon.SPELL_HEAL = "SPELL_HEAL";
addon.UPDATE_BATTLEFIELD_SCORE = "UPDATE_BATTLEFIELD_SCORE";
addon.UNIT_FACTION = "UNIT_FACTION";

addon.EVENTS_PET_DISMISS = {
    [addon.PARTY_KILL] = true,
    [addon.UNIT_DIED] = true,
    [addon.UNIT_DESTROYED] = true,
    [addon.UNIT_DISSIPATES] = true,
};

-- classFileName constants
addon.DEATHKNIGHT = "DEATHKNIGHT";
addon.DEMONHUNTER = "DEMONHUNTER";
addon.DRUID = "DRUID";
addon.EVOKER = "EVOKER";
addon.HUNTER = "HUNTER";
addon.MAGE = "MAGE";
addon.MONK = "MONK";
addon.PALADIN = "PALADIN";
addon.PRIEST = "PRIEST";
addon.ROGUE = "ROGUE";
addon.SHAMAN = "SHAMAN";
addon.WARLOCK = "WARLOCK";
addon.WARRIOR = "WARRIOR";

-- Maps a spec ID back to its class file name. Used by TBC heuristic spec detection to
-- reject indicators that don't belong to the unit's class.
addon.SPECID_TO_CLASS = {
    [addon.SPECID.BLOOD] = addon.DEATHKNIGHT,
    [addon.SPECID.FROST_DK] = addon.DEATHKNIGHT,
    [addon.SPECID.UNHOLY] = addon.DEATHKNIGHT,

    [addon.SPECID.HAVOC] = addon.DEMONHUNTER,
    [addon.SPECID.VENGEANCE] = addon.DEMONHUNTER,

    [addon.SPECID.BALANCE] = addon.DRUID,
    [addon.SPECID.FERAL] = addon.DRUID,
    [addon.SPECID.GUARDIAN] = addon.DRUID,
    [addon.SPECID.RESTORATION_DRUID] = addon.DRUID,

    [addon.SPECID.DEVASTATION] = addon.EVOKER,
    [addon.SPECID.PRESERVATION] = addon.EVOKER,
    [addon.SPECID.AUGMENTATION] = addon.EVOKER,

    [addon.SPECID.BEASTMASTERY] = addon.HUNTER,
    [addon.SPECID.MARKSMANSHIP] = addon.HUNTER,
    [addon.SPECID.SURVIVAL] = addon.HUNTER,

    [addon.SPECID.ARCANE] = addon.MAGE,
    [addon.SPECID.FIRE] = addon.MAGE,
    [addon.SPECID.FROST_MAGE] = addon.MAGE,

    [addon.SPECID.BREWMASTER] = addon.MONK,
    [addon.SPECID.MISTWEAVER] = addon.MONK,
    [addon.SPECID.WINDWALKER] = addon.MONK,

    [addon.SPECID.HOLY_PALADIN] = addon.PALADIN,
    [addon.SPECID.PROTECTION_PALADIN] = addon.PALADIN,
    [addon.SPECID.RETRIBUTION] = addon.PALADIN,

    [addon.SPECID.DISCIPLINE] = addon.PRIEST,
    [addon.SPECID.HOLY_PRIEST] = addon.PRIEST,
    [addon.SPECID.SHADOW] = addon.PRIEST,

    [addon.SPECID.ASSASSINATION] = addon.ROGUE,
    [addon.SPECID.OUTLAW] = addon.ROGUE,
    [addon.SPECID.SUBTLETY] = addon.ROGUE,

    [addon.SPECID.ELEMENTAL] = addon.SHAMAN,
    [addon.SPECID.ENHANCEMENT] = addon.SHAMAN,
    [addon.SPECID.RESTORATION_SHAMAN] = addon.SHAMAN,

    [addon.SPECID.AFFLICTION] = addon.WARLOCK,
    [addon.SPECID.DEMONOLOGY] = addon.WARLOCK,
    [addon.SPECID.DESTRUCTION] = addon.WARLOCK,

    [addon.SPECID.ARMS] = addon.WARRIOR,
    [addon.SPECID.FURY] = addon.WARRIOR,
    [addon.SPECID.PROTECTION_WARRIOR] = addon.WARRIOR,
};

addon.CLASSID = {
    WARRIOR = 1,
    PALADIN = 2,
    HUNTER = 3,
    ROGUE = 4,
    PRIEST = 5,
    DEATHKNIGHT = 6,
    SHAMAN = 7,
    MAGE = 8,
    WARLOCK = 9,
    MONK = 10,
    DRUID = 11,
    DEMONHUNTER = 12,
    EVOKER = 13,
};

addon.CLASSORDER = {
    addon.CLASSID.DEATHKNIGHT,
    addon.CLASSID.DEMONHUNTER,
    addon.CLASSID.DRUID,
    addon.CLASSID.EVOKER,
    addon.CLASSID.HUNTER,
    addon.CLASSID.MAGE,
    addon.CLASSID.MONK,
    addon.CLASSID.PALADIN,
    addon.CLASSID.PRIEST,
    addon.CLASSID.ROGUE,
    addon.CLASSID.SHAMAN,
    addon.CLASSID.WARLOCK,
    addon.CLASSID.WARRIOR,
};

addon.DEFAULT_ICON_SIZE = 36;
addon.COUNTDOWN_FONT_SIZE_COEFFICIENT = 0.375;
addon.CHARGE_TEXTURE = "Crosshair_Recurring_32"; -- TODO: make it available for classic: https://github.com/seblindfors/WoWAtlasExtract/blob/master/README.md
addon.CHARGE_TEXTURE_SIZE = 16;

addon.RAID_FRAME_SORT_ORDER = {
    DISABLED = 0,
    PLAYER_TOP = 1,
    PLAYER_BOTTOM = 2,
    PLAYER_MID = 3,
};

addon.IsConflictingFrameSortAddonLoaded = function()
    return C_AddOns.IsAddOnLoaded("FrameSort");
end

addon.IsConflictingRaidFrameDebuffAddonLoaded = function()
    return C_AddOns.IsAddOnLoaded("MiniCC");
end

addon.IsConflictingHealerBuffHelperAddonLoaded = function()
    return C_AddOns.IsAddOnLoaded("RaidFrameAuras");
end

addon.INTERFACE_SWEEPY = "interface/addons/SweepyBoop/";

addon.FLAG_CARRIER_HORDE_LOGO = "interface/icons/inv_bannerpvp_01";
addon.FLAG_CARRIER_ALLIANCE_LOGO = "interface/icons/inv_bannerpvp_02";

addon.SPEC_ICON_HEALER_LOGO = "interface/icons/spell_nature_healingtouch";
addon.SPEC_ICON_OTHERS_LOGO = 236270;

addon.SPEC_ICON_ALIGNMENT = {
    TOP = 0,
    LEFT = 1,
    RIGHT = 2,
};

addon.FORMAT_TEXTURE = function (texture, customSize)
    local size = customSize or 20;
    return format("|T%s:" .. size .. "|t", texture);
end
addon.FORMAT_ATLAS = function (texture, customSize)
    local size = customSize or 20;
    return format("|A:%s:" .. size .. ":" .. size .. ":|a", texture);
end

addon.LocalizeText = function(text)
    if ( type(text) ~= "string" ) or ( text == "" ) or ( not addon.L ) then
        return text;
    end

    local localized = rawget(addon.L, text);
    if localized then return localized end

    local prefix, separator, suffix = text:match("^(|T.-|t)(%s*)(.+)$");
    if not prefix then
        prefix, separator, suffix = text:match("^(|A.-|a)(%s*)(.+)$");
    end

    if prefix and suffix then
        localized = rawget(addon.L, suffix);
        if localized then
            return prefix .. separator .. localized;
        end
    end

    return text;
end

addon.LocalizeOptions = function(optionGroup)
    local function LocalizeOption(option)
        if type(option) ~= "table" then return end

        if type(option.name) == "string" then
            option.name = addon.LocalizeText(option.name);
        end
        if type(option.desc) == "string" then
            option.desc = addon.LocalizeText(option.desc);
        elseif type(option.desc) == "function" then
            local originalDesc = option.desc;
            option.desc = function(...)
                return addon.LocalizeText(originalDesc(...));
            end
        end
        if type(option.values) == "table" then
            for key, value in pairs(option.values) do
                if type(value) == "string" then
                    option.values[key] = addon.LocalizeText(value);
                end
            end
        end
        if type(option.args) == "table" then
            for _, child in pairs(option.args) do
                LocalizeOption(child);
            end
        end
    end

    LocalizeOption(optionGroup);
    return optionGroup;
end

addon.ICON_PATH = function (iconName)
    return "interface/icons/" .. iconName;
end

addon.EXCLAMATION = "|TInterface/OptionsFrame/UI-OptionsFrame-NewFeatureIcon:0:0:0:-1|t";

addon.ICON_ID_HEALER = addon.INTERFACE_SWEEPY .. "Art/AuxiliaryIcons/HealerFriendly";
addon.ICON_ID_HEALER_ENEMY = addon.INTERFACE_SWEEPY .. "Art/AuxiliaryIcons/Healing_Red";
addon.ICON_ID_HEALER_ARENA_FRAME = addon.INTERFACE_SWEEPY .. "Art/AuxiliaryIcons/HealerArenaFrame";
addon.SPEC_ICON_ENEMY_HEALER_LOGO = addon.FORMAT_TEXTURE(addon.ICON_ID_HEALER_ENEMY);
addon.ICON_ID_PET = addon.INTERFACE_SWEEPY .. "Art/AuxiliaryIcons/Pet";
addon.ICON_CRITTER = "WildBattlePet";
addon.ICON_ID_CLASSES = "Interface/GLUES/CHARACTERCREATE/UI-CHARACTERCREATE-CLASSES";
addon.FULL_ICON_TEX_COORDS = {0, 1, 0, 1};
addon.BUNDLED_CLASS_ICON_TEXTURES = {
    [addon.WARRIOR] = addon.INTERFACE_SWEEPY .. "Art/ClassIcons/WARRIOR",
    [addon.PALADIN] = addon.INTERFACE_SWEEPY .. "Art/ClassIcons/PALADIN",
    [addon.HUNTER] = addon.INTERFACE_SWEEPY .. "Art/ClassIcons/HUNTER",
    [addon.ROGUE] = addon.INTERFACE_SWEEPY .. "Art/ClassIcons/ROGUE",
    [addon.PRIEST] = addon.INTERFACE_SWEEPY .. "Art/ClassIcons/PRIEST",
    [addon.DEATHKNIGHT] = addon.INTERFACE_SWEEPY .. "Art/ClassIcons/DEATHKNIGHT",
    [addon.SHAMAN] = addon.INTERFACE_SWEEPY .. "Art/ClassIcons/SHAMAN",
    [addon.MAGE] = addon.INTERFACE_SWEEPY .. "Art/ClassIcons/MAGE",
    [addon.WARLOCK] = addon.INTERFACE_SWEEPY .. "Art/ClassIcons/WARLOCK",
    [addon.MONK] = addon.INTERFACE_SWEEPY .. "Art/ClassIcons/MONK",
    [addon.DRUID] = addon.INTERFACE_SWEEPY .. "Art/ClassIcons/DRUID",
    [addon.DEMONHUNTER] = addon.INTERFACE_SWEEPY .. "Art/ClassIcons/DEMONHUNTER",
    [addon.EVOKER] = addon.INTERFACE_SWEEPY .. "Art/ClassIcons/EVOKER",
};
addon.BUNDLED_SPEC_ICON_TEXTURES = {
    [addon.SPECID.BLOOD] = addon.INTERFACE_SWEEPY .. "Art/SpecIcons/Spell_Deathknight_BloodPresence",
    [addon.SPECID.FROST_DK] = addon.INTERFACE_SWEEPY .. "Art/SpecIcons/Spell_Deathknight_FrostPresence",
    [addon.SPECID.UNHOLY] = addon.INTERFACE_SWEEPY .. "Art/SpecIcons/Spell_Deathknight_UnholyPresence",
    [addon.SPECID.HAVOC] = addon.INTERFACE_SWEEPY .. "Art/SpecIcons/Ability_DemonHunter_SpecDPS",
    [addon.SPECID.VENGEANCE] = addon.INTERFACE_SWEEPY .. "Art/SpecIcons/Ability_DemonHunter_SpecTank",
    [addon.SPECID.DEVOURER] = addon.INTERFACE_SWEEPY .. "Art/SpecIcons/Classicon_DemonHunter_Void",
    [addon.SPECID.BALANCE] = addon.INTERFACE_SWEEPY .. "Art/SpecIcons/Spell_Nature_StarFall",
    [addon.SPECID.FERAL] = addon.INTERFACE_SWEEPY .. "Art/SpecIcons/Ability_Druid_CatForm",
    [addon.SPECID.GUARDIAN] = addon.INTERFACE_SWEEPY .. "Art/SpecIcons/Ability_Racial_BearForm",
    [addon.SPECID.RESTORATION_DRUID] = addon.INTERFACE_SWEEPY .. "Art/SpecIcons/SPELL_NATURE_HEALINGTOUCH",
    [addon.SPECID.DEVASTATION] = addon.INTERFACE_SWEEPY .. "Art/SpecIcons/ClassIcon_Evoker_Devastation",
    [addon.SPECID.PRESERVATION] = addon.INTERFACE_SWEEPY .. "Art/SpecIcons/ClassIcon_Evoker_Preservation",
    [addon.SPECID.AUGMENTATION] = addon.INTERFACE_SWEEPY .. "Art/SpecIcons/ClassIcon_Evoker_Augmentation",
    [addon.SPECID.BEASTMASTERY] = addon.INTERFACE_SWEEPY .. "Art/SpecIcons/ABILITY_HUNTER_BESTIALDISCIPLINE",
    [addon.SPECID.MARKSMANSHIP] = addon.INTERFACE_SWEEPY .. "Art/SpecIcons/Ability_Hunter_FocusedAim",
    [addon.SPECID.SURVIVAL] = addon.INTERFACE_SWEEPY .. "Art/SpecIcons/Ability_Hunter_Camouflage",
    [addon.SPECID.ARCANE] = addon.INTERFACE_SWEEPY .. "Art/SpecIcons/Spell_Holy_MagicalSentry",
    [addon.SPECID.FIRE] = addon.INTERFACE_SWEEPY .. "Art/SpecIcons/Spell_Fire_FireBolt02",
    [addon.SPECID.FROST_MAGE] = addon.INTERFACE_SWEEPY .. "Art/SpecIcons/Spell_Frost_FrostBolt02",
    [addon.SPECID.BREWMASTER] = addon.INTERFACE_SWEEPY .. "Art/SpecIcons/Spell_Monk_Brewmaster_Spec",
    [addon.SPECID.MISTWEAVER] = addon.INTERFACE_SWEEPY .. "Art/SpecIcons/Spell_Monk_MistWeaver_Spec",
    [addon.SPECID.WINDWALKER] = addon.INTERFACE_SWEEPY .. "Art/SpecIcons/Spell_Monk_WindWalker_Spec",
    [addon.SPECID.HOLY_PALADIN] = addon.INTERFACE_SWEEPY .. "Art/SpecIcons/Spell_Holy_HolyBolt",
    [addon.SPECID.PROTECTION_PALADIN] = addon.INTERFACE_SWEEPY .. "Art/SpecIcons/Ability_Paladin_ShieldoftheTemplar",
    [addon.SPECID.RETRIBUTION] = addon.INTERFACE_SWEEPY .. "Art/SpecIcons/Spell_Holy_AuraOfLight",
    [addon.SPECID.DISCIPLINE] = addon.INTERFACE_SWEEPY .. "Art/SpecIcons/Spell_Holy_PowerWordShield",
    [addon.SPECID.HOLY_PRIEST] = addon.INTERFACE_SWEEPY .. "Art/SpecIcons/Spell_Holy_GuardianSpirit",
    [addon.SPECID.SHADOW] = addon.INTERFACE_SWEEPY .. "Art/SpecIcons/Spell_Shadow_ShadowWordPain",
    [addon.SPECID.ASSASSINATION] = addon.INTERFACE_SWEEPY .. "Art/SpecIcons/Ability_Rogue_DeadlyBrew",
    [addon.SPECID.OUTLAW] = addon.INTERFACE_SWEEPY .. "Art/SpecIcons/Ability_Rogue_Waylay",
    [addon.SPECID.SUBTLETY] = addon.INTERFACE_SWEEPY .. "Art/SpecIcons/Ability_Stealth",
    [addon.SPECID.ELEMENTAL] = addon.INTERFACE_SWEEPY .. "Art/SpecIcons/Spell_Nature_Lightning",
    [addon.SPECID.ENHANCEMENT] = addon.INTERFACE_SWEEPY .. "Art/SpecIcons/Spell_Shaman_ImprovedStormstrike",
    [addon.SPECID.RESTORATION_SHAMAN] = addon.INTERFACE_SWEEPY .. "Art/SpecIcons/Spell_Nature_MagicImmunity",
    [addon.SPECID.AFFLICTION] = addon.INTERFACE_SWEEPY .. "Art/SpecIcons/Spell_Shadow_DeathCoil",
    [addon.SPECID.DEMONOLOGY] = addon.INTERFACE_SWEEPY .. "Art/SpecIcons/Spell_Shadow_Metamorphosis",
    [addon.SPECID.DESTRUCTION] = addon.INTERFACE_SWEEPY .. "Art/SpecIcons/Spell_Shadow_RainOfFire",
    [addon.SPECID.ARMS] = addon.INTERFACE_SWEEPY .. "Art/SpecIcons/Ability_Warrior_SavageBlow",
    [addon.SPECID.FURY] = addon.INTERFACE_SWEEPY .. "Art/SpecIcons/Ability_Warrior_InnerRage",
    [addon.SPECID.PROTECTION_WARRIOR] = addon.INTERFACE_SWEEPY .. "Art/SpecIcons/Ability_Warrior_DefensiveStance",
};
addon.ICON_ID_FLAG_CARRIER_HORDE = addon.INTERFACE_SWEEPY .. "Art/AuxiliaryIcons/FlagCarrierHorde";
addon.ICON_ID_FLAG_CARRIER_ALLIANCE = addon.INTERFACE_SWEEPY .. "Art/AuxiliaryIcons/FlagCarrierAlliance";
addon.ICON_ID_FLAG_CARRIER_NEUTRAL = addon.INTERFACE_SWEEPY .. "Art/AuxiliaryIcons/FlagCarrierNeutral";
addon.ICON_ID_PVP_CURSOR = "interface/cursor/pvp";

-- https://warcraft.wiki.gg/wiki/UI_escape_sequences
addon.HELAER_LOGO = addon.FORMAT_ATLAS("UI-LFG-RoleIcon-Healer");

addon.ICON_COORDS_HEALER = addon.FULL_ICON_TEX_COORDS;

addon.CLASS_ICON_STYLE = {
    ICON = 0,
    ARROW = 1,
    ICON_AND_ARROW = 2,
    PIN = 3,
    ICON_AND_PIN = 4,
};


addon.GetSpellTexture = function(spellId)
    local _, originalIconID = C_Spell.GetSpellTexture(spellId);
    return originalIconID;
end

-- Helper function for secret value check (only exists in retail)
addon.IsSecretValue = function(value)
    if addon.PROJECT_MAINLINE then
        return issecretvalue(value);
    else
        return false;
    end
end

addon.SPELL_DESCRIPTION = {}; -- by spellId, requested via -- https://warcraft.wiki.gg/wiki/SpellMixin

addon.PRINT = function(message)
    DEFAULT_CHAT_FRAME:AddMessage(addon.FORMAT_ATLAS("pvptalents-warmode-swords", 16) .. " |cff00c0ffSweepyBoop's PvP Helper:|r " .. message);
end
