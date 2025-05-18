local _, addon = ...;

local castBarTexture = "Interface/RaidFrame/Raid-Bar-Hp-Fill";

-- This needs to be called once only per cast bar
local function FixBlizzardCastBar(self)
    if self.blizzardCastBarFixed then return end

    self:HookScript("OnEvent", function(frame)
        if frame:IsForbidden() then return end
        if ( frame.barType == "uninterruptible" ) then
            if frame.NumStages then -- Set up by CastingBarMixin:AddStages
                frame:SetStatusBarTexture("ui-castingbar-uninterruptable");
            end
        elseif ( frame.barType == "empowered" ) then
            frame:SetStatusBarTexture("ui-castingbar-filling-standard");
        end

        -- https://github.com/tomrus88/BlizzardInterfaceCode/blob/25276211effd4b92effa1c2c6671b5e68db85e84/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/CastingBarFrame.lua#L908
        -- Should be using self.NumStages instead of hard-coded 4 here, but self.NumStages is not set yet when we call FixBlizzardCastBar
        -- Just need to fix if the value 4 changes in the future...
        for i = 1, 4 do
            if self["ChargeTier"..i] then
                self["ChargeTier"..i]:Hide();
            end
        end
    end);

    self.blizzardCastBarFixed = true;
end

local function FixNamePlateCastBar(unit)
    local nameplate = C_NamePlate.GetNamePlateForUnit(unit);
    local unitFrame = nameplate and nameplate.UnitFrame;
    if unitFrame and unitFrame.castBar then
        FixBlizzardCastBar(unitFrame.castBar);
    end
end

local eventFrame;
function SweepyBoop:SetupFixBlizzardCastbars()
    if ( not eventFrame ) then
        eventFrame = CreateFrame("Frame");
        eventFrame:RegisterEvent(addon.NAME_PLATE_UNIT_ADDED);
        eventFrame:SetScript("OnEvent", function(self, event, ...)
            if ( event == addon.NAME_PLATE_UNIT_ADDED ) then
                local unit = ...;
                FixNamePlateCastBar(unit);
            end
        end)

        local castBars = {
            TargetFrameSpellBar,
            FocusFrameSpellBar,
        };
        if sArena then -- We load after sArena, so no need to worry about sArena not loaded yet, what if we need to fix another addon that's loaded after us?
            for i = 1, addon.MAX_ARENA_SIZE do
                local frame = _G["ArenaEnemyFrame"..i];
                if frame and frame.CastBar then
                    frame.CastBar.sArenaCastBar = true;
                    tinsert(castBars, frame.CastBar);
                end
            end
        end
        for _, castBar in ipairs(castBars) do
            FixBlizzardCastBar(castBar);
        end
    end
end
