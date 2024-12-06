local _, NS = ...;

NS.isTestMode = false;

NS.SPELLCATEGORY = {
    OFFENSIVE = 1,

    INTERRUPT = 2,
    DISRUPT = 3,
    CROWDCONTROL = 4,
    DISPEL = 5,
    DEFENSIVE = 6,
};

NS.DURATION_DYNAMIC = "dynamic";

NS.SPECID = {
    ARCANE = 62,
    RET = 70,
    BALANCE = 102,
    FERAL = 103,
    GUARDIAN = 104,
    BM = 253,
    SHADOW = 258,
    ASSASSIN = 259,
    OUTLAW = 260,
    SUBTLETY = 261,
    WW = 269,
    DEVASTATION = 1467,
};

-- Event name constants
NS.BAG_UPDATE = "BAG_UPDATE";
NS.LOSS_OF_CONTROL_ADDED = "LOSS_OF_CONTROL_ADDED";
NS.LOSS_OF_CONTROL_UPDATE = "LOSS_OF_CONTROL_UPDATE";
NS.PLAYER_ENTERING_WORLD = "PLAYER_ENTERING_WORLD";
NS.PLAYER_TARGET_CHANGED = "PLAYER_TARGET_CHANGED";
NS.PLAYER_REGEN_ENABLED = "PLAYER_REGEN_ENABLED";
NS.ARENA_PREP_OPPONENT_SPECIALIZATIONS = "ARENA_PREP_OPPONENT_SPECIALIZATIONS";
NS.PLAYER_SPECIALIZATION_CHANGED = "PLAYER_SPECIALIZATION_CHANGED";
NS.UNIT_SPELLCAST_SUCCEEDED = "UNIT_SPELLCAST_SUCCEEDED";
NS.UNIT_AURA = "UNIT_AURA";
NS.UNIT_TARGET = "UNIT_TARGET";
NS.UNIT_HEALTH = "UNIT_HEALTH";
NS.UNIT_MAXHEALTH = "UNIT_MAXHEALTH";
NS.UNIT_POWER_FREQUENT = "UNIT_POWER_FREQUENT";
NS.UNIT_MAXPOWER = "UNIT_MAXPOWER";
NS.UNIT_PET = "UNIT_PET";
NS.UPDATE_SHAPESHIFT_FORM = "UPDATE_SHAPESHIFT_FORM";
NS.COMBAT_LOG_EVENT_UNFILTERED = "COMBAT_LOG_EVENT_UNFILTERED";
NS.GROUP_ROSTER_UPDATE = "GROUP_ROSTER_UPDATE";
NS.NAME_PLATE_UNIT_ADDED = "NAME_PLATE_UNIT_ADDED";
NS.NAME_PLATE_UNIT_REMOVED = "NAME_PLATE_UNIT_REMOVED";
-- Sub event name constants
NS.SPELL_CAST_SUCCESS = "SPELL_CAST_SUCCESS";
NS.SPELL_AURA_APPLIED = "SPELL_AURA_APPLIED";
NS.SPELL_AURA_REMOVED = "SPELL_AURA_REMOVED";
NS.SPELL_DAMAGE = "SPELL_DAMAGE";
NS.SPELL_CAST_START = "SPELL_CAST_START";
NS.SPELL_SUMMON = "SPELL_SUMMON";
NS.UNIT_DIED = "UNIT_DIED";
NS.PARTY_KILL = "PARTY_KILL";
NS.SPELL_DISPEL = "SPELL_DISPEL";
NS.SPELL_INTERRUPT = "SPELL_INTERRUPT";
NS.SPELL_EMPOWER_END = "SPELL_EMPOWER_END";

-- classFileName constants
NS.DEATHKNIGHT = "DEATHKNIGHT";
NS.DEMONHUNTER = "DEMONHUNTER";
NS.DRUID = "DRUID";
NS.EVOKER = "EVOKER";
NS.HUNTER = "HUNTER";
NS.MAGE = "MAGE";
NS.MONK = "MONK";
NS.PALADIN = "PALADIN";
NS.PRIEST = "PRIEST";
NS.ROGUE = "ROGUE";
NS.SHAMAN = "SHAMAN";
NS.WARLOCK = "WARLOCK";
NS.WARRIOR = "WARRIOR";

-- For hiding timer by OmniCC
NS.HIDETIMEROMNICC = "BoopHideTimer";

NS.DEFAULT_ICON_SIZE = 32;

NS.RaidFrameSortOrder = {
    Disabled = 0,
    PlayerTop = 1,
    PlayerBottom = 2,
    PlayerMiddle = 3,
};
