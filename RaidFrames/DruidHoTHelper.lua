local _, addon = ...;

local lifeblooms = {
    [33763] = true,  -- Normal
    [188550] = true, -- Undergrowth
};

local soTFSpells = {
    [774] = true,    -- Rejuv
    [155777] = true, -- Germination
};

local lifebloomInstances = {};
local lifebloomAuras = {};

local function EnsureGlowFrame(buffFrame)
    if ( not buffFrame.glowFrame ) then
        local glowFrame = CreateFrame("Frame", nil, buffFrame, "ActionBarButtonSpellActivationAlert");
        glowFrame:SetAllPoints();
        glowFrame:Hide();
        buffFrame.glowFrame = glowFrame;
    end
end

local lifebloomUpdate = CreateFrame("Frame");
lifebloomUpdate.timer = 0;
lifebloomUpdate:SetScript("OnUpdate", function (self, elapsed)
    self.timer = self.timer + elapsed;
    if self.timer > 0.025 then
        self.timer = 0;

        if next(lifebloomAuras) == nil then -- No more active lifeblooms
            self:Hide();
            return;
        end

        for buffFrame, aura in pairs(lifebloomAuras) do
            if aura.expirationTime < GetTime() then
                addon.HideOverlayGlow(buffFrame);
                lifebloomAuras[buffFrame] = nil;
                lifebloomInstances[aura.auraInstanceID] = nil;
            elseif lifebloomInstances[aura.auraInstanceID] then
                local timeRemaining = (aura.expirationTime - GetTime()) / aura.timeMod
                local refreshTime = aura.duration * 0.3

                if (timeRemaining <= refreshTime) then
                    EnsureGlowFrame(buffFrame);
                    addon.ShowOverlayGlow(buffFrame);
                else
                    addon.HideOverlayGlow(buffFrame);
                end
            else
                addon.HideOverlayGlow(buffFrame);
                lifebloomAuras[buffFrame] = nil;
            end
        end
    end
end)

local function GlowLifeBloom(aura, buffFrame)
    if lifeblooms[aura.spellId] and (aura.sourceUnit == "player") then
        lifebloomInstances[aura.auraInstanceID] = true;
        lifebloomAuras[buffFrame] = aura;
        lifebloomUpdate:Show();
    else
        addon.HideOverlayGlow(buffFrame);
        lifebloomAuras[buffFrame] = nil;
    end
end

local isDruid = ( addon.GetUnitClass("player") == addon.DRUID ); -- this won't change for a login session

local function HandleRaidFrameAuras(buffFrame, aura)
    if ( not isDruid ) then return end -- if not druid, none of the following code is relevant

    if ( not SweepyBoop.db.profile.raidFrames.druidHoTHelper ) or ( not aura ) or ( aura.isHarmful ) then
        addon.HideOverlayGlow(buffFrame);
        if buffFrame.icon then
            buffFrame.icon:SetAlpha(1); -- Cenarion ward texture might have been greyed out
        end
        return;
    end

    if buffFrame.icon then
        if ( aura.spellId == 102351 ) then -- Cenarion Ward before healing procs
            buffFrame.icon:SetAlpha(0.25);
        else
            buffFrame.icon:SetAlpha(1);
        end
    end

    EnsureGlowFrame(buffFrame);
    GlowLifeBloom(aura, buffFrame);

    -- Don't do SoTF for now, it's just a guess based on the timing of SoTF buff being consumed
end

function SweepyBoop:SetupRaidFrameAuraModule()
    hooksecurefunc("CompactUnitFrame_UtilSetBuff", function(self, ...)
        HandleRaidFrameAuras(self, ...);
    end)
end
