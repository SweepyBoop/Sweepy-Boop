local _, addon = ...;

addon.isTestMode = false;

addon.SPELLCATEGORY = {
    OFFENSIVE = 1,

    INTERRUPT = 2,
    DISRUPT = 3,
    CROWDCONTROL = 4,
    DISPEL = 5,
    DEFENSIVE = 6,
};

addon.SPELLPRIORITY = {
    DEFAULT = 50,
    HIGH = 10,
    LOW = 100,
};

addon.DURATION_DYNAMIC = "DURATION_DYNAMIC";

addon.SPECID = {
    ARCANE = 62,
    RET = 70,
    BALANCE = 102,
    FERAL = 103,
    GUARDIAN = 104,
    RESTODRUID = 105,
    BM = 253,
    SHADOW = 258,
    ASSASSIN = 259,
    OUTLAW = 260,
    SUBTLETY = 261,
    WW = 269,
    DEVASTATION = 1467,
    AUGMENTATION = 1473,
};

-- Event name constants
addon.BAG_UPDATE = "BAG_UPDATE";
addon.LOSS_OF_CONTROL_ADDED = "LOSS_OF_CONTROL_ADDED";
addon.LOSS_OF_CONTROL_UPDATE = "LOSS_OF_CONTROL_UPDATE";
addon.PLAYER_ENTERING_WORLD = "PLAYER_ENTERING_WORLD";
addon.PLAYER_TARGET_CHANGED = "PLAYER_TARGET_CHANGED";
addon.PLAYER_REGEN_ENABLED = "PLAYER_REGEN_ENABLED";
addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS = "ARENA_PREP_OPPONENT_SPECIALIZATIONS";
addon.PLAYER_SPECIALIZATION_CHANGED = "PLAYER_SPECIALIZATION_CHANGED";
addon.UNIT_SPELLCAST_SUCCEEDED = "UNIT_SPELLCAST_SUCCEEDED";
addon.UNIT_AURA = "UNIT_AURA";
addon.UNIT_TARGET = "UNIT_TARGET";
addon.UNIT_HEALTH = "UNIT_HEALTH";
addon.UNIT_MAXHEALTH = "UNIT_MAXHEALTH";
addon.UNIT_POWER_FREQUENT = "UNIT_POWER_FREQUENT";
addon.UNIT_MAXPOWER = "UNIT_MAXPOWER";
addon.UNIT_PET = "UNIT_PET";
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
addon.PARTY_KILL = "PARTY_KILL";
addon.UNIT_DIED = "UNIT_DIED";
addon.UNIT_DESTROYED = "UNIT_DESTROYED";
addon.UNIT_DISSIPATES = "UNIT_DISSIPATES";
addon.SPELL_DISPEL = "SPELL_DISPEL";
addon.SPELL_INTERRUPT = "SPELL_INTERRUPT";
addon.SPELL_EMPOWER_END = "SPELL_EMPOWER_END";

addon.PetDismissEvents = {
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

addon.classID = {
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

addon.classOrder = {
    addon.classID.DEATHKNIGHT,
    addon.classID.DEMONHUNTER,
    addon.classID.DRUID,
    addon.classID.EVOKER,
    addon.classID.HUNTER,
    addon.classID.MAGE,
    addon.classID.MONK,
    addon.classID.PALADIN,
    addon.classID.PRIEST,
    addon.classID.ROGUE,
    addon.classID.SHAMAN,
    addon.classID.WARLOCK,
    addon.classID.WARRIOR,
};

-- For hiding timer by OmniCC
addon.HIDETIMEROMNICC = "BoopHideTimer";

addon.DEFAULT_ICON_SIZE = 35;

addon.RaidFrameSortOrder = {
    Disabled = 0,
    PlayerTop = 1,
    PlayerBottom = 2,
    PlayerMiddle = 3,
};

addon.CLASSICONSTYLE = {
    ROUND = 1,
    FLAT = 2,
};

addon.PETICONSTYLE = {
    CATS = 1,
    MENDPET = 2,
};

addon.SELECTIONBORDERSTYLE = {
    PLAIN = 0,

    FIRE = 1,
    ARCANE = 2,
    AIR = 3,
};

addon.INTERFACE_SWEEPY = "interface/addons/SweepyBoop/";

addon.flagCarrierHordeLogo = addon.INTERFACE_SWEEPY .. "art/FlagCarrierHorde";
addon.flagCarrierAllianceLogo = addon.INTERFACE_SWEEPY .. "art/FlagCarrierAlliance";

addon.specIconHealerLogo = addon.INTERFACE_SWEEPY .. "art/HealingTouch"; -- icon 136041
addon.specIconOthersLogo = addon.INTERFACE_SWEEPY .. "art/DeathMark"; -- icon 236270

addon.SPEC_ICON_HORIZONTAL_ALIGNMENT = {
    TOP = 0,
    LEFT = 1,
    RIGHT = 2,
};

addon.ICON_FORMAT = "|T%s:20|t";
addon.GetIconPath = function (iconName)
    return "interface/icons/" .. iconName;
end
