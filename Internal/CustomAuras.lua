local _, addon = ...

local GetSpellTexture = C_Spell.GetSpellTexture;
local GetPlayerAuraBySpellID = C_UnitAuras.GetPlayerAuraBySpellID;

-- https://wowpedia.fandom.com/wiki/FileDataID
-- https://wow.tools/files/
-- https://www.townlong-yak.com/framexml/live/Helix/ArtTextureID.lua

-- To find the spellID of an aura
local checkSpellID = CreateFrame("Frame");
checkSpellID.enabled = addon.TEST_MODE;

checkSpellID.spellName = "Moonfire";
checkSpellID:RegisterEvent(addon.UNIT_AURA);
checkSpellID:RegisterEvent(addon.COMBAT_LOG_EVENT_UNFILTERED);
checkSpellID:SetScript("OnEvent", function (self, event, unitTarget)
    if ( not self.enabled ) then return end

    if ( event == addon.UNIT_AURA ) and ( unitTarget == "player" ) then
        local auraData = addon.Util_GetUnitAura("player", self.spellName);
        if auraData and auraData.spellId then print("UNIT_AURA", auraData.sourceUnit, auraData.spellId) end
    elseif ( event == addon.COMBAT_LOG_EVENT_UNFILTERED ) then
        local _, subEvent, _, sourceGUID = CombatLogGetCurrentEventInfo();
        if ( subEvent == addon.SPELL_AURA_APPLIED ) and ( sourceGUID == UnitGUID("player") ) then
            local spellId, spellName = select(12, CombatLogGetCurrentEventInfo());
            if spellName == self.spellName then print("COMBATLOG", spellId) end
        end
    end
end)

function SpellActivationOverlayFadeInAnimMixin:CustomOnFinished(animGroup)
    local overlay = self:GetParent();
	overlay:SetAlpha(0.5);
	overlay.pulse:Play();
end

local function CreateOverlayTexture(buff, filePath, width, height, offsetX, offsetY, rotate)
    local frame = CreateFrame("Frame", nil, UIParent, "CustomSpellActivationOverlayTemplate");
    frame:SetMouseClickEnabled(false);
    frame.buff = buff;
    frame:SetSize(width, height);
    frame:SetPoint("CENTER", offsetX, offsetY);
    frame.texture:SetTexture(filePath);
    if rotate then
        frame.texture:SetRotation(rotate);
    end
    frame:Hide() -- Hide initially until aura is detected

    frame:RegisterEvent(addon.UNIT_AURA);
    frame:SetScript("OnEvent", function (self, event, unitTarget)
        if ( unitTarget ~= "player" ) then return end
        local aura = GetPlayerAuraBySpellID(self.buff);
        if aura and aura.duration then
            self:Show();
        else
            self:Hide();
        end
    end)

    return frame;
end

local class = addon.GetUnitClass("player");

if ( class == addon.DRUID ) then
    CreateOverlayTexture(114108, 1518303, 150, 50, 0, 150); -- Soul of the Forest, predatory_swiftness_green.blp
    CreateOverlayTexture(429474, 450915, 100, 100, -100, 150); -- Blooming Infusion (damage), Eclipse_Sun.blp
    CreateOverlayTexture(429438, 450914, 100, 100, 100, 150, math.pi); -- Blooming Infusion (heal), Eclipse_Moon.blp
    CreateOverlayTexture(69369, 898423, 150, 50, 0, 150); -- Predatory Swiftness, predatory_swiftness.blp
    CreateOverlayTexture(391882, 627609, 150, 50, 0, 180); -- Apex Predator's Craving, shadow_of_death.blp
end



-- BigDebuffs player portrait override for healer drink buff
local playerPortraitAbilities = {};
-- If we use table, then we can't do ipairs to keep the order
-- If buff has no duration, duration will be false
playerPortraitAbilities[addon.DRUID] = {
    167152, -- Refreshment
    452384, -- Drink
};

local classPortraitAbilities = playerPortraitAbilities[class];

local playerPortraitAuraFrame = CreateFrame("Frame", nil, PlayerFrame);
playerPortraitAuraFrame:SetPoint(PlayerFrame.portrait:GetPoint());
playerPortraitAuraFrame:SetSize(PlayerFrame.portrait:GetSize());
playerPortraitAuraFrame:SetFrameStrata("HIGH");
playerPortraitAuraFrame.tex = playerPortraitAuraFrame:CreateTexture();
playerPortraitAuraFrame.tex:SetAllPoints(playerPortraitAuraFrame);
playerPortraitAuraFrame.tex:SetTexCoord(0.1, 0.9, 0.1, 0.9); -- To appear naturally as a round button

-- Apply a circle texture mask (https://wowpedia.fandom.com/wiki/UIOBJECT_MaskTexture)
playerPortraitAuraFrame.mask = playerPortraitAuraFrame:CreateMaskTexture();
playerPortraitAuraFrame.mask:SetAllPoints(playerPortraitAuraFrame.tex);
playerPortraitAuraFrame.mask:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE");
playerPortraitAuraFrame.tex:AddMaskTexture(playerPortraitAuraFrame.mask);

playerPortraitAuraFrame.cooldown = CreateFrame("Cooldown", nil, playerPortraitAuraFrame, "CooldownFrameTemplate");
playerPortraitAuraFrame.cooldown:SetAllPoints();
playerPortraitAuraFrame.cooldown:SetReverse(true);
playerPortraitAuraFrame.cooldown:SetDrawBling(false);
playerPortraitAuraFrame.cooldown:SetDrawEdge(false);
playerPortraitAuraFrame.cooldown:SetSwipeTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMaskSmall");
playerPortraitAuraFrame.cooldown:SetSwipeColor(0, 0, 0, 0.6);

playerPortraitAuraFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
playerPortraitAuraFrame:RegisterEvent(addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS); -- Between solo shuffle rounds
playerPortraitAuraFrame:RegisterEvent(addon.UNIT_AURA);
playerPortraitAuraFrame:Hide();

function playerPortraitAuraFrame:OnEvent(event, unitTarget)
    if ( event == addon.UNIT_AURA and unitTarget ~= "player" ) or ( not classPortraitAbilities ) then return end

    for i = 1, #(classPortraitAbilities) do
        local spell = classPortraitAbilities[i];
        local aura = GetPlayerAuraBySpellID(spell);
        if aura and aura.name then
            playerPortraitAuraFrame.tex:SetTexture(aura.icon);

            if aura.duration and ( aura.duration ~= 0 ) then
                playerPortraitAuraFrame.cooldown:SetCooldown(aura.expirationTime - aura.duration, aura.duration);
                playerPortraitAuraFrame.cooldown:Show();
            else
                playerPortraitAuraFrame.cooldown:Hide();
            end

            playerPortraitAuraFrame:Show();
            return
        end
    end

    -- No early return means no matching aura
    playerPortraitAuraFrame:Hide();
end
playerPortraitAuraFrame:SetScript("OnEvent", playerPortraitAuraFrame.OnEvent);



-- glowAtStacks: nil means no glow, 0 means always glow, positive value means glow at certain stacks
local function CreateAuraIcon(spellID, size, point, relativeTo, relativePoint, offsetX, offsetY, glowAtStacks, stackFunc, alwaysShow, suppressedBy)
    local frame = CreateFrame("Frame", nil, UIParent);
    frame:SetMouseClickEnabled(false);
    frame:SetFrameStrata("HIGH");
    frame:Hide(); -- Hide initially until aura is detected, for alwaysShow icons, it will stay visible once detected

    frame.spellID = spellID;
    frame:SetSize(size, size);
    frame:SetPoint(point, relativeTo, relativePoint, offsetX, offsetY);
    frame.glowAtStacks = glowAtStacks;
    frame.stackFunc = stackFunc;
    frame.alwaysShow = alwaysShow;
    frame.suppressedBy = suppressedBy;

    frame.texture = frame:CreateTexture();
    frame.texture:SetTexture(GetSpellTexture(spellID));
    frame.texture:SetAllPoints();

    frame.cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate");
    frame.cooldown:SetAllPoints();
    frame.cooldown:SetDrawEdge(false);
    frame.cooldown:SetAlpha(1);
    frame.cooldown:SetDrawBling(false);
    frame.cooldown:SetDrawSwipe(true);
    frame.cooldown:SetReverse(true);

    if glowAtStacks and ( glowAtStacks > 0 ) then
        frame.text = frame:CreateFontString(nil, "ARTWORK");
        -- https://wow.tools/files/#search=fonts&page=1&sort=0&desc=asc
        frame.text:SetFont("Fonts\\2002.ttf", size / 2, "OUTLINE");
        frame.text:SetPoint("CENTER", 0, 0);
        frame.text:SetText("");
        frame.text:SetTextColor(1, 1, 0); -- Yellow

        frame.cooldown:SetHideCountdownNumbers(true); -- Hide cooldown numbers to see stack count more clearly
    end

    if glowAtStacks then
        frame.spellActivationAlert = CreateFrame("Frame", nil, frame, "ActionBarButtonSpellActivationAlert");
        frame.spellActivationAlert:SetSize(size * 1.4, size * 1.4);
        frame.spellActivationAlert:SetPoint("CENTER", frame, "CENTER", 0, 0);
        frame.spellActivationAlert:Hide();
    end

    frame:RegisterEvent(addon.UNIT_AURA);
    frame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
    frame:SetScript("OnEvent", function (self, event, ...)
        local unitTarget = ...;
        if ( event == addon.PLAYER_ENTERING_WORLD ) or ( unitTarget == "player" ) then
            local aura = GetPlayerAuraBySpellID(self.spellID);

            if suppressedBy then
                local otherAura = GetPlayerAuraBySpellID(self.suppressedBy);
                if otherAura then
                    addon.HideOverlayGlow(self);
                    self:Hide();
                    return;
                end
            end

            if aura then
                if aura.duration and ( aura.duration ~= 0 ) then
                    self.cooldown:SetCooldown(aura.expirationTime - aura.duration, aura.duration);
                    self.cooldown:Show();
                else
                    if ( not self.alwaysShow ) then
                        self.cooldown:Hide();
                    end
                end

                local shouldGlow;
                if ( glowAtStacks == 0 ) then
                    shouldGlow = true;
                elseif glowAtStacks and ( glowAtStacks > 0 ) then
                    local stacks;
                    if self.stackFunc then
                        stacks = self.stackFunc(aura.applications, aura.duration, aura.expirationTime, aura.points);
                    else
                        stacks = aura.applications;
                    end
                    
                    self.text:SetText( (stacks and stacks >= self.glowAtStacks and "") or stacks );
                    shouldGlow = ( stacks == glowAtStacks );
                end

                if shouldGlow then
                    addon.ShowOverlayGlow(self);
                else
                    addon.HideOverlayGlow(self);
                end
                self:Show();
            else
                addon.HideOverlayGlow(self);
                self:Hide();
            end
        end
    end)

    return frame;
end

-- The first ActionBarButtonSpellActivationAlert created seems to be corrupted by other icons, so we create a dummy here that does nothing
CreateFrame("Frame", nil, UIParent, "ActionBarButtonSpellActivationAlert");

CreateAuraIcon(377362, 35, "CENTER", UIParent, "CENTER", 0, 60, 0); -- precongnition

if ( class == addon.DRUID ) then
    CreateAuraIcon(5215, 64, "TOP", PlayerFrame.portrait, "BOTTOM", 0, -32, 0); -- Prowl

    -- Track at most 4 buffs with glowing icons, more than that it sort of becomes space station UI
    local manaBar = PlayerFrame_GetManaBar();

    -- Common
    CreateAuraIcon(319454, 40, "TOPLEFT", manaBar, "BOTTOM", 5, -100, 0); -- Heart of the Wild
    CreateAuraIcon(382912, 50, "TOP", MultiBarRightButton1, "BOTTOM", 0, 0, nil, nil, true); -- Well-Honed Instincts

    -- Restoration
    CreateAuraIcon(392360, 40, "TOPLEFT", manaBar, "BOTTOM", 5, -50, 3, nil, nil, 117679); -- Reforestation
    CreateAuraIcon(117679, 40, "TOPLEFT", manaBar, "BOTTOM", 5, -50, 0); -- Tree of Life

    CreateAuraIcon(426790, 40, "TOPLEFT", manaBar, "BOTTOM", 5, -100, nil, nil, nil, 319454); -- Call of the Elder Druid

    -- Feral
    CreateAuraIcon(145152, 40, "TOPRIGHT", manaBar, "BOTTOM", -5, -50, 3, nil); -- Blood Talons (max 3 stacks)
    CreateAuraIcon(5217, 40, "TOPRIGHT", manaBar, "BOTTOM", -5, -100, 0); -- Tiger's Fury
    CreateAuraIcon(106951, 40, "TOPLEFT", manaBar, "BOTTOM", 5, -50, 0); -- Berserk
    CreateAuraIcon(102543, 40, "TOPLEFT", manaBar, "BOTTOM", 5, -50, 0); -- Incarnation: Avatar of Ashamane

    if addon.TEST_MODE then -- Test all 4 icons with Rejuvenation
        CreateAuraIcon(774, 40, "TOPLEFT", manaBar, "BOTTOM", 0, -50, 0);
        CreateAuraIcon(774, 40, "TOPLEFT", manaBar, "BOTTOM", 0, -100, 0);
        CreateAuraIcon(774, 40, "TOPRIGHT", manaBar, "BOTTOM", 0, -50, 0); -- test with Rejuvenation
        CreateAuraIcon(774, 40, "TOPRIGHT", manaBar, "BOTTOM", 0, -100, 0); -- test with Rejuvenation
    end
elseif ( class == addon.PRIEST ) then
    --373181 Harsh Discipline
elseif ( class == addon.PALADIN ) then
    --247676 Aura of Reckoning
    --31884 Avenging Wrath
    --216331 Avenging Crusader
end

-- Defensive buffs
local teamDefensiveBuffs = {
    145629, -- Anti-Magic Zone

    209426, -- Darkness

    102342, -- Ironbark
    53480, -- Roar of Sacrifice

    116849, -- Life Cocoon

    6940, -- Blessing of Sacrifice
    199448, -- Ultimate Sacrifice
    1022, -- Blessing of Protection

    81782, -- Power Word: Barrier
    47788, -- Guardian Spirit
    33206, -- Pain Suppression

    201633, -- Earthen Wall Totem

    147833, -- Intervene
    97463, -- Rallying Cry
};
local personalDefensiveBuffs = {
    145629, -- Anti-Magic Zone
    48707, -- Anti-Magic Shell
    48792, -- Icebound Fortitude

    209426, -- Darkness
    212800, -- Blur
    196555, -- Netherwalk

    102342, -- Ironbark
    61336, -- Survival Instincts
    22812, -- Barkskin

    363916, -- Obsidian Scales

    53480, -- Roar of Sacrifice
    186265, -- Aspect of the Turtle

    45438, -- Ice Block
    342246, -- Alter Time (Arcane)
    110909, -- Alter Time (Fire/Frost)

    116849, -- Life Cocoon
    125174, -- Touch of Karma

    642, -- Divine Shield
    1022, -- Blessing of Protection
    498, -- Divine Protection

    81782, -- Power Word: Barrier
    47585, -- Dispersion
    47788, -- Guardian Spirit
    33206, -- Pain Suppression

    5277, -- Evasion
    31224, -- Cloak of Shadows

    108271, -- Astral Shift
    210918, -- Ethereal Form
    201633, -- Earthen Wall Totem

    104773, -- Unending Resolve
    108416, -- Dark Pact
    212295, -- Nether Ward

    118038, -- Die by the Sword
    184364, -- Enraged Regeneration
    97463, -- Rallying Cry
};

local function ShouldDisplayDefensiveBuff(icon, aura)
    if icon.external then
        return aura.sourceUnit ~= "player";
    else
        return aura.sourceUnit == "player";
    end
end

local function CreateGlowingDefensiveBuffs(spells, size, point, relativeTo, relativePoint, offsetX, offsetY, external)
    local frame = CreateFrame("Frame", nil, UIParent);
    frame:SetMouseClickEnabled(false);
    frame:Hide() -- Hide initially until aura is detected

    frame.spells = spells;
    frame.external = external;
    frame:SetSize(size, size);
    frame:SetPoint(point, relativeTo, relativePoint, offsetX, offsetY);

    frame.texture = frame:CreateTexture();
    frame.texture:SetAllPoints();

    frame.cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate");
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

    frame:RegisterEvent(addon.UNIT_AURA);
    frame:SetScript("OnEvent", function (self, event, ...)
        local unitTarget = ...;
        if ( event == addon.PLAYER_ENTERING_WORLD ) or ( unitTarget == "player" ) then
            for i = 1, #(self.spells) do
                local spell = self.spells[i];
                local aura = GetPlayerAuraBySpellID(spell);
                if aura and aura.name and ShouldDisplayDefensiveBuff(self, aura) then
                    local icon = GetSpellTexture(spell);
                    self.texture:SetTexture(icon);

                    if aura.duration and ( aura.duration ~= 0 ) then
                        self.cooldown:SetCooldown(aura.expirationTime - aura.duration, aura.duration);
                    end

                    addon.ShowOverlayGlow(self);
                    self:Show();
                    return;
                end
            end

            -- If no early return, no matching aura has been found
            addon.HideOverlayGlow(self);
            self:Hide();
        end
    end)

    return frame;
end

local teamBuffIcon = CreateGlowingDefensiveBuffs(teamDefensiveBuffs, 35, "CENTER", UIParent, "CENTER", 0, 100, true);
local selfBuffIcon = CreateGlowingDefensiveBuffs(personalDefensiveBuffs, 35, "CENTER", UIParent, "CENTER", 0, 100, false);
teamBuffIcon:Raise(); -- Don't use personal if already covered by teammates
selfBuffIcon:Lower();
