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
    NS.IconGroup_CreateIcon(group, NS.CreateWeakAuraIcon(unit, 1126, 32, true));
end

if test then
    local testGroup = NS.CreateIconGroup(setPointOptions[1], growOptions);
else

end