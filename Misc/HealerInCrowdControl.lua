local _, addon = ...;

local iconSize = addon.DEFAULT_ICON_SIZE;
local borderSize = iconSize * 1.25;

local containerFrame;
local isInTest = false;

local function HideIcon(frame)
    if ( not frame ) then return end

    frame.cooldown:SetCooldown(0, 0);
    frame.text:SetText("");
    frame:Hide();
    isInTest = false;
end

local function CreateContainerFrame()
    local frame = CreateFrame("Frame");
    frame:SetMouseClickEnabled(false);
    frame:SetFrameStrata("HIGH");
    frame:SetSize(iconSize, iconSize);

    frame.icon = frame:CreateTexture(nil, "BORDER");
    frame.icon:SetSize(iconSize, iconSize);
    frame.icon:SetAllPoints(frame);

    frame.mask = frame:CreateMaskTexture();
    frame.mask:SetTexture("Interface/Masks/CircleMaskScalable");
    frame.mask:SetSize(iconSize, iconSize);
    frame.mask:SetAllPoints(frame.icon);
    frame.icon:AddMaskTexture(frame.mask);

    frame.border = frame:CreateTexture(nil, "OVERLAY");
    frame.border:SetAtlas("talents-warmode-ring");
    frame.border:SetSize(borderSize, borderSize);
    frame.border:SetPoint("CENTER", frame);

    frame.cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate");
    frame.cooldown:SetAllPoints();
    frame.cooldown:SetDrawEdge(true);
    frame.cooldown:SetUseCircularEdge(true);
    frame.cooldown:SetReverse(true);
    frame.cooldown:SetSwipeTexture("Interface/Masks/CircleMaskScalable");
    frame.cooldown:SetSwipeColor(0, 0, 0, 0.5); -- to achieve a transparent background
    frame.cooldown:SetHideCountdownNumbers(true);
    frame.cooldown.noCooldownCount = true; -- hide OmniCC timers
    frame.cooldown:SetScript("OnCooldownDone", function (self)
        local parent = self:GetParent();
        if parent:IsShown() then
            HideIcon(parent);
        end
    end)

    frame.text = frame:CreateFontString(nil, "OVERLAY", "GameTooltipText");
    frame.text:SetPoint("TOP", frame, "BOTTOM", 0, -5);
    frame.text:SetText("");

    frame.timer = 0;
    frame:SetScript("OnUpdate", function (self, elapsed)
        self.timer = self.timer + elapsed;
        if self.timer > 0.05 then -- Update every 0.05s
            local start, duration = self.cooldown:GetCooldownTimes();

            if start and duration then
                local remainingMs = start + duration - GetTime() * 1000;
                if remainingMs > 0 then
                    self.text:SetText(string.format("%.1f Sec", remainingMs / 1000));
                else
                    self.text:SetText("");
                end
            else
                self.text:SetText("");
            end

            self.timer = 0;
        end
    end)

    return frame;
end

local function ShowIcon(iconID, startTime, duration)
    containerFrame = containerFrame or CreateContainerFrame();

    if ( containerFrame.lastModified ~= SweepyBoop.db.profile.misc.lastModified ) then
        local config = SweepyBoop.db.profile.misc;
        local scale = config.healerInCrowdControlSize / iconSize;
        containerFrame:SetScale(scale);
        containerFrame:SetPoint("CENTER", UIParent, "CENTER", config.healerInCrowdControlOffsetX / scale, config.healerInCrowdControlOffsetY / scale);

        containerFrame.lastModified = SweepyBoop.db.profile.misc.lastModified;
    end

    containerFrame.icon:SetTexture(iconID);
    if duration then
        containerFrame.cooldown:SetCooldown(startTime, duration);
        containerFrame.cooldown:Show();
    else
        containerFrame.cooldown:SetCooldown(0, 0);
    end

    containerFrame:Show();

end

function SweepyBoop:TestHealerInCrowdControl()
    if IsInInstance() then
        addon.PRINT("Cannot run textest mode inside an instance");
        return;
    end

    ShowIcon(addon.ICON_PATH("spell_nature_polymorph"), GetTime(), 8);
    isInTest = true;
end

function SweepyBoop:UpdateHealerInCrowdControl()
    if containerFrame and containerFrame:IsShown() then
        if ( containerFrame.lastModified ~= SweepyBoop.db.profile.misc.lastModified ) then
            local config = SweepyBoop.db.profile.misc;
            local scale = config.healerInCrowdControlSize / iconSize;
            containerFrame:SetScale(scale);
            containerFrame:SetPoint("CENTER", UIParent, "CENTER", config.healerInCrowdControlOffsetX / scale, config.healerInCrowdControlOffsetY / scale);

            containerFrame.lastModified = SweepyBoop.db.profile.misc.lastModified;
        end
    end
end

function SweepyBoop:HideTestHealerInCrowdControl()
    HideIcon(containerFrame);
end

local crowdControlPriority = { -- sort by priority first, then remaining time
    ["stun"] = 100,
    ["silence"] = 90,
    ["disorient"] = 80,
    ["incapacitate"] = 80,
};

local updateFrame = CreateFrame("Frame"); -- When a frame is hidden it might not receive event, so we create a frame to catch events
updateFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
updateFrame:RegisterEvent(addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS);
updateFrame:RegisterEvent(addon.UNIT_AURA);
updateFrame:SetScript("OnEvent", function (self, event, unitTarget)
    if ( event ~= addon.UNIT_AURA ) then -- Hide when switching map or entering new round of solo shuffle
        HideIcon(containerFrame);
        return;
    end

    if ( not SweepyBoop.db.profile.misc.healerInCrowdControl ) and ( not isInTest ) then
        HideIcon(containerFrame);
        return;
    end

    if ( not IsActiveBattlefieldArena() ) and ( not isInTest ) and ( not addon.TEST_MODE ) then
        HideIcon(containerFrame);
        return;
    end

    if ( UnitGroupRolesAssigned("player") == "HEALER" ) then -- do not need to show if player is playing a healing spec
        HideIcon(containerFrame);
        return;
    end

    local isFriendly = unitTarget and ( UnitIsUnit(unitTarget, "party1") or UnitIsUnit(unitTarget, "party2") );
    local isFriendlyHealer = ( UnitGroupRolesAssigned(unitTarget) == "HEALER" and isFriendly ) or ( addon.TEST_MODE and unitTarget == "target" );
    if isFriendlyHealer then
        local spellID;
        local priority = 0; -- init with a low priority
        local duration;
        local expirationTime;

        for i = 1, 40 do
            local auraData = C_UnitAuras.GetDebuffDataByIndex(unitTarget, i);
            if auraData and auraData.spellId and addon.DRList[auraData.spellId] then
                local category = addon.DRList[auraData.spellId];
                if crowdControlPriority[category] then -- Found a CC that should be shown
                    if crowdControlPriority[category] > priority then -- first compare by priority
                        priority = crowdControlPriority[category];
                        duration = auraData.duration;
                        expirationTime = auraData.expirationTime;
                        spellID = auraData.spellId;
                    elseif crowdControlPriority[category] == priority then -- same priority, use expirationTime as tie breaker
                        if ( not expirationTime ) or ( not auraData.expirationTime ) or ( auraData.expirationTime < expirationTime) then
                            duration = auraData.duration;
                            expirationTime = auraData.expirationTime;
                            spellID = auraData.spellId;
                        end
                    end
                end
            end
        end

        if ( not spellID ) then -- No CC found, hide
            HideIcon(containerFrame);
        else
            ShowIcon(C_Spell.GetSpellTexture(spellID), duration and (expirationTime - duration), duration);
        end
    end
end)
