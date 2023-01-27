local _, NS = ...;

NS.CreateIconGroup = function (setPointOptions, growOptions)
    local point, relativeTo, relativePoint, offsetX, offsetY =
        setPointOptions.point, setPointOptions.relativeTo, setPointOptions.relativePoint, setPointOptions.offsetX, setPointOptions.offsetY;

    local f = CreateFrame("Frame", nil, UIParent);
    f:SetSize(1, 1);
    f:SetPoint(point, relativeTo, relativePoint, offsetX, offsetY);

    -- e.g., grow = "LEFT", growAnchor = "BOTTOMRIGHT": set icon's bottomright to group's bottom right
    f.growDirection = growOptions.direction;
    f.growAnchor = growOptions.anchor;
    f.margin = growOptions.margin;

    f.icons = {};
    f.active = {};

    return f;
end

local function IconGroup_Position(group)
    if ( not group ) or ( #(group.active) == 0 ) then
        return;
    end

    -- Reposition icons
    local growDirection = group.growDirection;
    local growAnchor = group.growAnchor;

    local offset = 0;
    for _, icon in pairs(group.active) do
        icon:SetPoint(growAnchor, group, growAnchor, offset, 0);
        local iconSize = select(1, icon:GetSize());

        -- TODO: support centered horizontal
        if ( growDirection == "LEFT" ) then
            offset = offset - iconSize - group.margin;
        elseif (growDirection == "RIGHT" ) then
            offset = offset + iconSize + group.margin;
        end
    end
end

NS.IconGroup_Insert = function (group, icon)
    if ( not group ) then return end

    local active = group.active;

    -- Insert at the last position, then sort by priority
    table.insert(active, icon);
    table.sort(active, function(a, b) return a.priority < b.priority end);

    IconGroup_Position(group);
end

NS.IconGroup_Remove = function (group, icon)
    if ( not group ) or ( #(group.active) == 0 ) then
        return;
    end

    local active = group.active;

    local index
    for key, value in pairs(active) do
        if ( value == icon ) then
            index = key
        end
    end

    if index then
        table.remove(active, index)
        IconGroup_Position(group);
    end
end

NS.IconGroup_CreateIcon = function (group, icon)
    icon:SetParent(group);

    table.insert(group.icons, icon);
end

-- TODO: wipe icons (unregister events, hide, set to nil)
-- TODO: create icons based on class and spec
