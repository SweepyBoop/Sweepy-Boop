local _, NS = ...

-- https://wowpedia.fandom.com/wiki/FileDataID
-- https://wow.tools/files/
-- https://www.townlong-yak.com/framexml/live/Helix/ArtTextureID.lua

function Custom_SpellActivationOverlayTexture_OnFadeInFinished(animGroup)
    local overlay = animGroup:GetParent()
	overlay:SetAlpha(0.5)
	overlay.pulse:Play()
end

local function CreateTexture(buff, filePath, width, height, offsetX, offsetY)
    local frame = CreateFrame("Frame", buff, UIParent, "CustomSpellActivationOverlayTemplate")
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

local soulOfTheForest = CreateTexture("Soul of the Forest", 1518303, 150, 50, 0, 150) -- predatory_swiftness_green.blp
local predatorySwiftness = CreateTexture("Predatory Swiftness", 898423, 150, 50, 0, 150) -- predatory_swiftness.blp
local apexPredatorsCraving = CreateTexture("Apex Predator's Craving", 627609, 150, 50, 0, 180) -- shadow_of_death.blp



-- BigDebuffs player portrait override
local iconPath = "Interface\\Addons\\aSweepyBoop\\AbilityIcons\\"

local playerPortraitStealthAbility = {}
-- If we use table, then we can't do ipairs to keep the order
-- If buff has no duration, duration will be false
playerPortraitStealthAbility[NS.classId.Druid] = {
    "Prowl",
}
playerPortraitStealthAbility[NS.classId.Rogue] = {
    "Stealth",
    "Subterfuge",
}

local class = select(3, UnitClass("player"))
local classStealthAbility = playerPortraitStealthAbility[class]

local playerPortraitAuraFrame = CreateFrame("Frame", nil, PlayerFrame)
playerPortraitAuraFrame:SetPoint(PlayerFrame.portrait:GetPoint())
playerPortraitAuraFrame:SetSize(PlayerFrame.portrait:GetSize())
playerPortraitAuraFrame:SetFrameStrata("HIGH")
local playerPortraitAuraTexture = playerPortraitAuraFrame:CreateTexture()
playerPortraitAuraTexture:SetAllPoints()

local playerPortraitAuraCooldown = CreateFrame("Cooldown", nil, playerPortraitAuraFrame, "CooldownFrameTemplate")
playerPortraitAuraCooldown:SetAllPoints()

playerPortraitAuraFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
playerPortraitAuraFrame:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS") -- Between solo shuffle rounds
playerPortraitAuraFrame:RegisterEvent("UNIT_AURA")
playerPortraitAuraFrame:Hide()

function playerPortraitAuraFrame:OnEvent(event, unitTarget)
    if ( event == "UNIT_AURA" and unitTarget ~= "player" ) or ( not classStealthAbility ) then return end

    for i = 1, #(classStealthAbility) do
        local spell = classStealthAbility[i]
        local name, _, _, _, duration, expirationTime = NS.Util_GetUnitBuff("player", spell)
        if name then
            playerPortraitAuraTexture:SetTexture(iconPath .. spell)

            if duration and ( duration ~= 0 ) then
                playerPortraitAuraCooldown:SetCooldown(expirationTime - duration, duration)
                playerPortraitAuraCooldown:Show()
            else
                playerPortraitAuraCooldown:Hide()
            end

            playerPortraitAuraFrame:Show()
            return
        end
    end

    -- No early return means no matching aura
    playerPortraitAuraFrame:Hide()
end
playerPortraitAuraFrame:SetScript("OnEvent", playerPortraitAuraFrame.OnEvent)