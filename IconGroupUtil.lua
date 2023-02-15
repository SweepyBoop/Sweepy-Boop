local _, NS = ...;

local CreateFrame = CreateFrame;
local UIParent = UIParent;
local GetTime = GetTime;
local wipe = wipe;
local PlayerFrame = PlayerFrame;

NS.CreateIconGroup = function (setPointOptions, growOptions, unit)
    local point, relativeTo, relativePoint, offsetX, offsetY =
        setPointOptions.point, setPointOptions.relativeTo, setPointOptions.relativePoint, setPointOptions.offsetX, setPointOptions.offsetY;

    local f = CreateFrame("Frame", nil, UIParent);
    f:SetSize(1, 1);
    -- For static relativeTo point, call SetPoint now
    if ( relativeTo == UIParent ) or ( relativeTo == PlayerFrame ) then
        f:SetPoint(point, relativeTo, relativePoint, offsetX, offsetY);
    else
        f.setPointOptions = setPointOptions;
    end

    -- e.g., grow = "LEFT", growAnchor = "BOTTOMRIGHT": set icon's bottomright to group's bottom right
    f.growDirection = growOptions.direction;
    f.growAnchor = growOptions.anchor;
    f.margin = growOptions.margin;
    f.columns = growOptions.columns; -- For center alignment only
    f.growUpward = growOptions.growUpward; -- "UP" or "DOWN"

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

    local baseIconSize = group.active[1]:GetWidth();

    -- Reposition icons
    local growDirection = group.growDirection;
    local anchor = group.growAnchor;
    local numActive = #(group.active);

    local count, rows = 0, 1;
    local grow = group.growUpward and 1 or -1;
    local margin = group.margin;

    for i = 1, numActive do
        group.active[i]:ClearAllPoints();
        local columns = ( group.columns and group.columns < numActive and group.columns ) or numActive;
        if ( i == 1 ) then
            if growDirection == "CENTER" then
                local offsetX = (-baseIconSize-margin)*(columns-1)/2;
                group.active[i]:SetPoint(anchor, group, anchor, (-baseIconSize-margin)*(columns-1)/2, 0);
            else
                group.active[i]:SetPoint(anchor, group, anchor, 0, 0);
            end
        else
            count = count + 1;
            if count >= columns then
                if growDirection == "CENTER" then
                    group.active[i]:SetPoint(anchor, group, anchor, (-baseIconSize-margin)*(columns-1)/2, (baseIconSize+margin)*rows*grow);
                else
                    group.active[i]:SetPoint(anchor, group, anchor, 0, (baseIconSize+margin)*rows*grow);
                end

                count = 0;
                rows = rows + 1;
            else
                if growDirection == "LEFT" then
                    group.active[i]:SetPoint("TOPRIGHT", group.active[i-1], "TOPLEFT", -1 * margin, 0);
                else
                    group.active[i]:SetPoint("TOPLEFT", group.active[i-1], "TOPRIGHT", margin, 0);
                end
            end
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

-- TODO: Add a slash command to call out test mode which also calls sArena:Test()
local function CalculateArenaFrameOffsetX(frameName)
    local offsetX = 0;

    if string.sub(frameName, 1, 7) == "Gladius" then
        local frame = _G["GladiusButtonFramearena1"];
        local frameRight = frame:GetRight() * frame:GetEffectiveScale();
        local trinket = _G["GladiusTrinketFramearena1"];
        if trinket then
            offsetX = math.max(offsetX, trinket:GetRight() * trinket:GetEffectiveScale() - frameRight);
        end
        local racial = _G["GladiusRacialFramearena1"];
        if racial then
            offsetX = math.max(offsetX, racial:GetRight() * racial:GetEffectiveScale() - frameRight);
        end
    elseif string.sub(frameName, 1, 6) == "sArena" then
        local frame = _G["sArenaEnemyFrame1"];
        local frameRight = frame:GetRight() * frame:GetEffectiveScale();
        if frame.Trinket then
            local trinket = frame.Trinket;
            if trinket then
                offsetX = math.max(offsetX, trinket:GetRight() * trinket:GetEffectiveScale() - frameRight);
            end
        end
        if frame.Racial then
            local racial = frame.Racial;
            if racial then
                offsetX = math.max(offsetX, racial:GetRight() * racial:GetEffectiveScale() - frameRight);
            end
        end
    end

    -- We got the offsetX by comparing the GetRight values, which are values after all the scaling factors.
    -- Now revert it to pre-scaling
    local UIScale = UIParent:GetEffectiveScale();
    return offsetX / UIScale + 10;
end

NS.IconGroup_Insert = function (group, icon, index)
    -- If already showing, do not need to add
    if ( not group ) or ( icon:IsShown() ) then return end

    -- Re-adjust positioning if this group attaches to an arena frame, since arena frames can change position
    if group.setPointOptions then
        local options = group.setPointOptions;
        if ( not options.relativeTo ) or ( string.sub(options.relativeTo, 1, 4) == "NONE" ) then return end

        options.offsetX = options.offsetX or CalculateArenaFrameOffsetX(options.relativeTo);
        group:SetPoint(options.point, _G[options.relativeTo], options.relativePoint, options.offsetX, options.offsetY);
    end

    -- Give icon a timeStamp before inserting
    icon.timeStamp = GetTime();

    local active = group.active;

    -- Insert at the last position, then sort by priority
    table.insert(active, icon);
    if index then
        group.activeMap[index] = icon;
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

-- For arena offensive cooldown tracking, index is just spellID since we are always tracking a single unitId
-- For Omnibar icons, we will use unitId - spellID
NS.IconGroup_PopulateIcon = function (group, icon, index)
    icon.timers = {}; -- Reset current timers
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
    group.unitGUID = nil;
    group.unitGUIDs = {};
end
