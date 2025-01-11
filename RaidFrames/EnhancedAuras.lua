local _, addon = ...;

local lifeblooms = {
    [33763] = true,  -- Normal
    [188550] = true, -- Undergrowth
};

local lifebloomInstances = {};
local lifebloomAuras = {};

local lifebloomUpdate = CreateFrame("Frame");
lifebloomUpdate.timer = 0;
lifebloomUpdate:SetScript("OnUpdate", function (self, elapsed)
    if ( not SweepyBoop.db.profile.raidFrames.enhancedAuras ) then
        self:Hide();
        return;
    end

    self.timer = self.timer + elapsed;
    if self.timer > 0.01 then
        self.timer = 0;

        if next(lifebloomAuras) == nil then
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
                    addon.ShowOverlayGlow(buffFrame);
                else
                    buffFrame.glow:Hide()
                end
            else
                addon.HideOverlayGlow(buffFrame);
                lifebloomAuras[buffFrame] = nil;
            end
        end
    end
end)

local function EnsureGlowFrame(buffFrame)
    if ( not buffFrame.glowFrame ) then
        local glowFrame = CreateFrame("Frame", nil, buffFrame, "ActionBarButtonSpellActivationAlert");
        glowFrame:SetAllPoints();
        glowFrame:Hide();
        buffFrame.glowFrame = glowFrame;
    end
end

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

local function HandleRaidFrameAuras(buffFrame, aura)
    if ( not SweepyBoop.db.profile.raidFrames.enhancedAuras ) or ( not aura ) or ( aura.isHarmful ) then
        addon.HideOverlayGlow(buffFrame);
        return;
    end

    EnsureGlowFrame(buffFrame);

    GlowLifeBloom(aura, buffFrame);
end

function SweepyBoop:SetupRaidFrameAuraModule()
    hooksecurefunc("CompactUnitFrame_UtilSetBuff", function(self, ...)
        HandleRaidFrameAuras(self, ...);
    end)
end
