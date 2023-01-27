local _, NS = ...;

NS.CreateIconGroup = function (setPointOptions, growOptions)
    local point, relativeTo, relativePoint, offsetX, offsetY =
        setPointOptions.point, setPointOptions.relativeTo, setPointOptions.relativePoint, setPointOptions.offsetX, setPointOptions.offsetY;

    local f = CreateFrame("Frame", nil, UIParent);
    f:SetPoint(point, relativeTo, relativePoint, offsetX, offsetY);

    -- e.g., grow = "LEFT", growAnchor = "BOTTOMRIGHT": set icon's bottomright to group's bottom right
    f.growDirection = growOptions.direction;
    f.growAnchor = growOptions.anchor;

    f.active = {};

    return f;
end

-- Insertion sort, find the first icon with a lower priority
local function IconGroup_Insert(group, icon)
    local active = group.active;

    -- Insert at the last position, then sort by priority
    table.insert(active, icon);
    table.sort(active, function(a, b) return a.priority < b.priority end);

    -- Reposition icons
    local growDirection = group.growDirection;
    local growAnchor = group.growAnchor;

    local offset = 0;
    for _, value in pairs(active) do
        value:SetPoint(growAnchor, group, growAnchor, offset, 0);
        local iconSize = select(1, value:GetSize());
        offset = offset + (growDirection == "RIGHT" and iconSize) or (-iconSize);
    end
end

local function IconGroup_Remove(group, icon)
    local active = group.active;

    
end