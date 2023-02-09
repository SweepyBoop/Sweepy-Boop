local _, NS = ...;

local CreateFrame = CreateFrame;
local UIParent = UIParent;
local GetTime = GetTime;
local GetSpellInfo = GetSpellInfo;
local UnitIsUnit = UnitIsUnit;

local function StartAnimation(icon)
    icon.flashAnim:Play();
	icon.newitemglowAnim:Play();
end

local function StopAnimation(icon)
    if icon.flashAnim:IsPlaying() then icon.flashAnim:Stop() end
	if icon.newitemglowAnim:IsPlaying() then icon.newitemglowAnim:Stop() end
end

local function OnCooldownTimerFinished(self)
    StopAnimation(self:GetParent());
    NS.RefreshCooldownTimer(self);
end

function CooldownTracking_UpdateBorder(icon)
    --[[ if UnitIsUnit(icon.unit, "focus") then
        icon.FocusTexture:SetAlpha(1);
    else
        icon.FocusTexture:SetAlpha(0);
    end ]]

    -- Target highlight overwrites focus highlight
    if UnitIsUnit(icon.unit, "target") then
        --icon.FocusTexture:SetAlpha(0);
        icon.TargetTexture:SetAlpha(1);
    else
        icon.TargetTexture:SetAlpha(0);
    end
end

-- Only put static info in this function
-- An icon for a unit + spellID is only created once per session
NS.CreateCooldownTrackingIcon = function (unit, spellID, size, hideHighlight)
    local frame = CreateFrame("Button", nil, UIParent, "CooldownTrackingButtonTemplate");
    frame.group = true; -- To add itself to parent group
    frame:Hide();

    frame.unit = unit;
    frame.spellID = spellID;
    local spell = NS.cooldownSpells[spellID];
    frame.category = spell.category;

    if size then
        local scale = size / 32;
        frame:SetScale(scale);
    end

    if hideHighlight then
        frame.TargetTexture:Hide();
    end
    
    -- Fill in static info here
    frame.spellInfo = {
        cooldown = spell.cooldown,
        opt_lower_cooldown = spell.opt_lower_cooldown,
        charges = spell.charges,
        opt_charges = spell.opt_charges,
        reduce_on_interrupt = spell.reduce_on_interrupt,
        trackEvent = spell.trackEvent,
        trackPet = spell.trackPet,
    };
    frame.priority = spell.priority;

    frame.icon:SetTexture(select(3, GetSpellInfo(spellID)));
    frame.icon:SetAllPoints();
    frame.Count:SetText(""); -- Call this before setting color
    frame.Count:SetTextColor(1, 1, 0); -- Yellow
    frame.cooldown:SetScript("OnCooldownDone", OnCooldownTimerFinished);

    return frame;
end

NS.StartCooldownTrackingIcon = function (icon)
    local spell = icon.spellInfo; -- static spell info
    local info = icon.info; -- dynamic info for current icon
    local timers = icon.timers;

    -- Init default charge
    if #(timers) == 0 then
        table.insert(timers, {start = 0, duration = 0, finish = 0});
    end

    -- Initialize charge expire if baseline charge
    if info.charges and #(timers) < 2 then
        table.insert(timers, {start = 0, duration = 0, finish = 0});
    end

    if icon:IsShown() then
        if spell.opt_lower_cooldown then
            info.cooldown = math.min(info.cooldown, spell.opt_lower_cooldown);
        end

        if spell.opt_charges and #(timers) < 2 then
            table.insert(timers, {start = 0, duration = 0, finish = 0});
        end
    end

    -- Always use timers[1] since it will be either off cooldown, or closet to come off cooldown
    local now = GetTime();
    timers[1].start = now;
    timers[1].duration = info.cooldown;
    timers[1].finish = now + info.cooldown;

    -- Sort after changing timers
    table.sort(timers, NS.TimerCompare);
    NS.RefreshCooldownTimer(icon.cooldown);

    StartAnimation(icon);

    NS.IconGroup_Insert(icon:GetParent(), icon, icon.unit .. "-" .. icon.spellID);
end

-- For spells with reduce_on_interrupt, set an internal cooldown so it doesn't reset cd multiple times
-- This is basically only for solar beam
NS.ResetCooldownTrackingCooldown = function (icon, amount, internalCooldown)
    if internalCooldown then
        local now = GetTime();
        if icon.info.lasteReset and ( now < icon.info.lasteReset + internalCooldown ) then
            return;
        end

        icon.info.lasteReset = now;
    end

    NS.ResetIconCooldown(icon, amount);
end
