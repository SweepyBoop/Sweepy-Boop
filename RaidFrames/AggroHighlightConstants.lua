local _, addon = ...;

addon.RAID_FRAME_AGGRO_HIGHLIGHT = {
    TEXTURE_WHITE = "Interface\\BUTTONS\\WHITE8X8",
    TEXTURE_RAID_ICONS = "Interface\\TargetingFrame\\UI-RaidTargetingIcons",
    MARKER_ALPHA = 1,
    OVERLAY_FRAME_LEVEL_OFFSET = 50,
    RAID_FRAME_FLASH_TARGETER_COUNT = 3,
    ARENA_FRAME_FLASH_TARGETER_COUNT = 2,
    FLASH_SECONDS = 0.75,
    FLASH_MIN_ALPHA = 0.67,
    PREVIEW_FRAME_WIDTH = 144,
    PREVIEW_FRAME_HEIGHT = 72,
    PREVIEW_FRAME_SPACING = 28,
    PREVIEW_HEIGHT = 116,
    RAID_ICON_INDICES = {
        Star = 1,
        Circle = 2,
        Diamond = 3,
        Triangle = 4,
        Moon = 5,
        Square = 6,
        Cross = 7,
        Skull = 8,
        Flag = 15,
        Murloc = 16,
    },
};
