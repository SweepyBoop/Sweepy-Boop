local _, NS = ...;

local test = true;

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

local function SetupAuraGroup(group, unit)
    local class = select(3, UnitClass(unit));
    for spellID, spell in pairs(NS.spellData) do
        if ( spell.class == class ) then
            NS.IconGroup_CreateIcon(group, NS.CreateWeakAuraIcon(unit, spellID, 32, true));
        end
    end
end

if test then
    local testGroup = NS.CreateIconGroup(setPointOptions[1], growOptions);
    SetupAuraGroup(testGroup, "player");
else

end