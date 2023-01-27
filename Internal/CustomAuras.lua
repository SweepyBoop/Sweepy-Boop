local _, NS = ...

local CreateFrame = CreateFrame;
local UnitClass = UnitClass;
local PlayerFrame = PlayerFrame;

-- https://wowpedia.fandom.com/wiki/FileDataID
-- https://wow.tools/files/
-- https://www.townlong-yak.com/framexml/live/Helix/ArtTextureID.lua

function Custom_SpellActivationOverlayTexture_OnFadeInFinished(animGroup)
    local overlay = animGroup:GetParent()
    overlay:SetAlpha(0.5)
    overlay.pulse:Play()
end

local function CreateTexture(buff, filePath, width, height, offsetX, offsetY)
    local frame = CreateFrame("Frame", nil, UIParent, "CustomSpellActivationOverlayTemplate")
    frame.buff = buff
    frame:SetSize(width, height)
    frame:SetPoint("CENTER", offsetX, offsetY)
    frame.texture:SetTexture(filePath)
    frame:Hide() -- Hide initially until aura is detected

    frame:RegisterEvent("UNIT_AURA")
    frame:SetScript("OnEvent", function (self, event, unitTarget)
        if ( unitTarget ~= "player" ) then return end
        local duration = select(5, NS.Util_GetUnitBuff("player", self.buff))
        if duration then
            self:Show()
        else
            self:Hide()
        end
    end)

    return frame
end

local class = select(3, UnitClass("player"));

if ( class == NS.classId.Druid ) then
    local soulOfTheForest = CreateTexture("Soul of the Forest", 1518303, 150, 50, 0, 150) -- predatory_swiftness_green.blp
    local predatorySwiftness = CreateTexture("Predatory Swiftness", 898423, 150, 50, 0, 150) -- predatory_swiftness.blp
    local apexPredatorsCraving = CreateTexture("Apex Predator's Craving", 627609, 150, 50, 0, 180) -- shadow_of_death.blp
end



-- BigDebuffs player portrait override
local playerPortraitStealthAbility = {}
-- If we use table, then we can't do ipairs to keep the order
-- If buff has no duration, duration will be false
playerPortraitStealthAbility[NS.classId.Druid] = {
    "Refreshment",
    "Drink",
    "Prowl",
}
playerPortraitStealthAbility[NS.classId.Rogue] = {
    "Stealth",
    "Subterfuge",
}

local classStealthAbility = playerPortraitStealthAbility[class]

local playerPortraitAuraFrame = CreateFrame("Frame", nil, PlayerFrame)
playerPortraitAuraFrame:SetPoint(PlayerFrame.portrait:GetPoint())
playerPortraitAuraFrame:SetSize(PlayerFrame.portrait:GetSize())
playerPortraitAuraFrame:SetFrameStrata("HIGH")
playerPortraitAuraFrame.tex = playerPortraitAuraFrame:CreateTexture()
playerPortraitAuraFrame.tex:SetAllPoints(playerPortraitAuraFrame)
playerPortraitAuraFrame.tex:SetTexCoord(0.1, 0.9, 0.1, 0.9) -- To appear naturally as a round button

-- Apply a circle texture mask (https://wowpedia.fandom.com/wiki/UIOBJECT_MaskTexture)
playerPortraitAuraFrame.mask = playerPortraitAuraFrame:CreateMaskTexture()
playerPortraitAuraFrame.mask:SetAllPoints(playerPortraitAuraFrame.tex)
playerPortraitAuraFrame.mask:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
playerPortraitAuraFrame.tex:AddMaskTexture(playerPortraitAuraFrame.mask)

playerPortraitAuraFrame.cooldown = CreateFrame("Cooldown", nil, playerPortraitAuraFrame, "CooldownFrameTemplate")
playerPortraitAuraFrame.cooldown:SetAllPoints()
-- Options copied from BigDebuffs (https://github.com/jordonwow/bigdebuffs/blob/master)
playerPortraitAuraFrame.cooldown:SetReverse(true)
playerPortraitAuraFrame.cooldown:SetDrawBling(false)
playerPortraitAuraFrame.cooldown:SetDrawEdge(false)
playerPortraitAuraFrame.cooldown:SetSwipeTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMaskSmall")
playerPortraitAuraFrame.cooldown:SetSwipeColor(0, 0, 0, 0.6)

playerPortraitAuraFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
playerPortraitAuraFrame:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS") -- Between solo shuffle rounds
playerPortraitAuraFrame:RegisterEvent("UNIT_AURA")
playerPortraitAuraFrame:Hide()

function playerPortraitAuraFrame:OnEvent(self, event, unitTarget)
    if ( event == "UNIT_AURA" and unitTarget ~= "player" ) or ( not classStealthAbility ) then return end

    for i = 1, #(classStealthAbility) do
        local spell = classStealthAbility[i]
        local name, icon, _, _, duration, expirationTime = NS.Util_GetUnitBuff("player", spell)
        if name then
            playerPortraitAuraFrame.tex:SetTexture(icon)

            if duration and ( duration ~= 0 ) then
                playerPortraitAuraFrame.cooldown:SetCooldown(expirationTime - duration, duration)
                playerPortraitAuraFrame.cooldown:Show()
            else
                playerPortraitAuraFrame.cooldown:Hide()
            end

            playerPortraitAuraFrame:Show()
            return
        end
    end

    -- No early return means no matching aura
    playerPortraitAuraFrame:Hide()
end
playerPortraitAuraFrame:SetScript("OnEvent", playerPortraitAuraFrame.OnEvent)



-- Glowing buff icon

local function debug(button, message)
    if ( button.spellID == 117679 ) then
        print(message)
    end
end

local function ShowOverlayGlow(button)
    if not button.spellActivationAlert then
        return;
    end

    if button.spellActivationAlert.animOut:IsPlaying() then
        debug(button, "animOut:Stop")
        button.spellActivationAlert.animOut:Stop();
    end

    if not button.spellActivationAlert:IsShown() then
        debug(button, "animIn:Play")
        print(button);
        button.spellActivationAlert.animIn:Play();
    end
end

local function HideOverlayGlow(button)
    if not button.spellActivationAlert then
        return;
    end

    if button.spellActivationAlert.animIn:IsPlaying() then
        debug(button, "animIn:Stop")
        button.spellActivationAlert.animIn:Stop();
    end

    if button:IsVisible() then
        debug(button, "animOut:Play")
        button.spellActivationAlert.animOut:Play();
    else
        debug(button, "animOut:OnFinished")
        button.spellActivationAlert.animOut:OnFinished();	--We aren't shown anyway, so we'll instantly hide it.
    end
end

local function CreateGlowingBuffIcon(spellID, size, point, relativeTo, relativePoint, offsetX, offsetY)
    local frame = CreateFrame("Frame", nil, UIParent);
    frame:Hide() -- Hide initially until aura is detected

    frame.spellID = spellID;
    frame:SetSize(size, size);
    frame:SetPoint(point, relativeTo, relativePoint, offsetX, offsetY);
    
    frame.texture = frame:CreateTexture();
    local icon = select(3, GetSpellInfo(spellID));
    frame.texture:SetTexture(icon);
    frame.texture:SetAllPoints();

    frame.cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate");
    -- Copied from bigdebuffs options
    frame.cooldown:SetAllPoints();
    frame.cooldown:SetDrawEdge(false);
    frame.cooldown:SetAlpha(1);
    frame.cooldown:SetDrawBling(false);
    frame.cooldown:SetDrawSwipe(true);
    frame.cooldown:SetReverse(true);

    frame.spellActivationAlert = CreateFrame("Frame", nil, frame, "ActionBarButtonSpellActivationAlert");
    frame.spellActivationAlert:SetSize(size * 1.4, size * 1.4);
    frame.spellActivationAlert:SetPoint("CENTER", frame, "CENTER", 0, 0);
    frame.spellActivationAlert:Hide();

    frame:RegisterEvent("UNIT_AURA");
    frame:SetScript("OnEvent", function (self, event, ...)
        local unitTarget = ...;
        if ( unitTarget == "player" ) then
            local duration, expirationTime = select(5, NS.Util_GetUnitBuff(unitTarget, frame.spellID));
            if duration and ( duration ~= 0 ) then
                self.cooldown:SetCooldown(expirationTime - duration, duration);
                ShowOverlayGlow(self);
                self:Show();
            else
                HideOverlayGlow(self);
                self:Hide();
            end
        end
    end)

    return frame;
end

-- No duration text, only show stacks, and glow when max stacks (if set)
local function CreateStackBuffIcon(spellID, size, point, relativeTo, relativePoint, offsetX, offsetY, maxStacks, duration)
    local frame = CreateFrame("Frame", nil, UIParent);
    frame.spellID = spellID;
    frame.maxStacks = maxStacks;
    frame:Hide();

    frame.spellID = spellID;
    frame:SetSize(size, size);
    frame:SetPoint(point, relativeTo, relativePoint, offsetX, offsetY);

    frame.text = frame:CreateFontString(nil, "ARTWORK");
    frame.text:SetFont("Fonts\\ARIALN.ttf", size / 2, "OUTLINE");
    frame.text:SetPoint("CENTER", 0, 0);

    frame.texture = frame:CreateTexture();
    local icon = select(3, GetSpellInfo(spellID));
    frame.texture:SetTexture(icon);
    frame.texture:SetAllPoints();

    if duration then
        frame.cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate");
        -- Copied from bigdebuffs options
        frame.cooldown:SetAllPoints();
        frame.cooldown:SetDrawEdge(false);
        frame.cooldown:SetAlpha(1);
        frame.cooldown:SetDrawBling(false);
        frame.cooldown:SetDrawSwipe(true);
        frame.cooldown:SetReverse(true);

        -- No numeric display on cooldown
        frame.cooldown:SetHideCountdownNumbers(true);
    end

    if maxStacks then
        frame.spellActivationAlert = CreateFrame("Frame", nil, frame, "ActionBarButtonSpellActivationAlert");
        frame.spellActivationAlert:SetSize(size * 1.4, size * 1.4);
        frame.spellActivationAlert:SetPoint("CENTER", frame, "CENTER", 0, 0);
        frame.spellActivationAlert:Hide();
    end

    frame:RegisterEvent("UNIT_AURA");
    frame:SetScript("OnEvent", function (self, event, ...)
        local unitTarget = ...;
        if ( unitTarget == "player" ) then
            local name, _, count, _, duration, expirationTime = NS.Util_GetUnitBuff(unitTarget, frame.spellID);
            if ( not name ) then
                self:Hide();
                return;
            end

            if duration and ( duration ~= 0 ) and self.cooldown then
                self.cooldown:SetCooldown(expirationTime - duration, duration);
            end

            if ( count > 0 ) then
                self.text:SetText(count);

                if ( count == self.maxStacks ) then
                    ShowOverlayGlow(self);
                else
                    HideOverlayGlow(self);
                end
            end

            self:Show();
        end
    end)

    return frame;
end

local testGlowingBuffIcon = true;

if ( class == NS.classId.Druid ) then
    local treeOfLife = CreateGlowingBuffIcon(117679, 36, "BOTTOM", _G["MultiBarBottomRightButton2"], "TOP", 0, 50);
    local wildSynthesis = CreateStackBuffIcon(400534, 36, "BOTTOM", _G["MultiBarBottomRightButton3"], "TOP", 0, 50, 3);
    
    if testGlowingBuffIcon then
        local test = CreateGlowingBuffIcon(774, 36, "BOTTOM", _G["MultiBarBottomRightButton4"], "TOP", 0, 5);
    end
end