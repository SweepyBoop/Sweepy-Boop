local _, NS = ...;

NS.CreateIconGroup = function (setPointOptions, growOptions, unit)
    local point, relativeTo, relativePoint, offsetX, offsetY =
        setPointOptions.point, setPointOptions.relativeTo, setPointOptions.relativePoint, setPointOptions.offsetX, setPointOptions.offsetY;

    local f = CreateFrame("Frame", nil, UIParent);
    f:SetSize(1, 1);
    f:SetPoint(point, relativeTo, relativePoint, offsetX, offsetY);

    -- e.g., grow = "LEFT", growAnchor = "BOTTOMRIGHT": set icon's bottomright to group's bottom right
    f.growDirection = growOptions.direction;
    f.growAnchor = growOptions.anchor;
    f.margin = growOptions.margin;

    f.unit = unit;

    f.icons = {}; -- Table, spellID -> icon
    f.active = {}; -- Array of active icons, sort by priority
    f.activeMap = {}; -- Table, spellID -> icon
    f.npcMap = {}; -- Table, npcGUID -> spellID, for processing SPELL_SUMMON / UNIT_DIED

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

local function sortFunc(a, b)
    if ( a.priority ~= b.priority ) then
        return a.priority < b.priority;
    else
        return a.timeStamp < b.timeStamp;
    end
end

NS.IconGroup_Insert = function (group, icon)
    -- If already showing, do not need to add
    if ( not group ) or ( icon:IsShown() ) then return end

    -- Give icon a timeStamp before inserting
    icon.timeStamp = GetTime();

    local active = group.active;

    -- Insert at the last position, then sort by priority
    table.insert(active, icon);
    if icon.spellID then
        group.activeMap[icon.spellID] = icon;
    end

    table.sort(active, sortFunc);

    IconGroup_Position(group);

    -- Reposition first, then show, to avoid new icon occluding previously shown ones.
    icon:Show();
end

NS.IconGroup_Remove = function (group, icon)
    -- Hide icon first, then reposition, to avoid occlusion.
    icon:Hide();

    if ( not group ) or ( #(group.active) == 0 ) then
        return;
    end

    if icon.spellID then
        group.activeMap[icon.spellID] = nil;
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

NS.IconGroup_PopulateIcon = function (group, icon, index)
    icon:SetParent(group);
    group.icons[index] = icon;
end

NS.IconGroup_Wipe = function (group)
    if ( not group ) then return end

    for _, icon in pairs(group.icons) do
        if icon.cooldown then
            icon.cooldown:SetCooldown(0, 0);
        end
        if icon.spellActivationAlert then
            if icon.spellActivationAlert.animIn:IsPlaying() then
                icon.spellActivationAlert.animIn:Stop();
            end
            if icon.spellActivationAlert.animOut:IsPlaying() then
                icon.spellActivationAlert.animOut:Stop();
            end
        end
        if icon.duration then
            icon.duration:SetCooldown(0, 0);
        end
        icon:Hide();
    end
    
    wipe(group.icons);
    wipe(group.active);
    wipe(group.activeMap);
    wipe(group.npcMap);
end
