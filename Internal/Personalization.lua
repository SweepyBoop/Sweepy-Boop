local _, NS = ...;

SetCVar("cameraDistanceMaxZoomFactor", 2.6)
SetCVar("weatherDensity", 0)

-- Hide target & focus cast bars (duplicate info with sArena cast bars)
TargetFrameSpellBar:UnregisterAllEvents()
FocusFrameSpellBar:UnregisterAllEvents()

-- Hide focus frame
FocusFrame:SetAlpha(0)



-- Move arena scoreboard on screen top
UIWidgetTopCenterContainerFrame:ClearAllPoints()
UIWidgetTopCenterContainerFrame:SetPoint("TOP", Minimap, "BOTTOM", 0, -25)
UIWidgetTopCenterContainerFrame.SetPoint = function() end

ArenaEnemyMatchFrame1PetFrame:SetAlpha(0)
ArenaEnemyMatchFrame2PetFrame:SetAlpha(0)
ArenaEnemyMatchFrame3PetFrame:SetAlpha(0)

-- Hide group indicator
hooksecurefunc("PlayerFrame_UpdateGroupIndicator", function ()
    local groupIndicator = PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.GroupIndicator
    if GetNumGroupMembers() <= 5 then
        groupIndicator:Hide()
    end
end)

-- Hide group leader icon
hooksecurefunc("PlayerFrame_UpdatePartyLeader", function ()
    local playerFrameTargetContextual = PlayerFrame_GetPlayerFrameContentContextual()
    playerFrameTargetContextual.LeaderIcon:Hide()
    playerFrameTargetContextual.GuideIcon:Hide()
end)

-- Hide player name and level (if full level)
PlayerName:Hide();

-- Hide level text when max level
hooksecurefunc("PlayerFrame_UpdateLevel", function ()
    if (UnitExists("player")) then
		local level = UnitLevel(PlayerFrame.unit);
		local effectiveLevel = UnitEffectiveLevel(PlayerFrame.unit);
		if (effectiveLevel ~= level) then
			PlayerLevelText:SetVertexColor(0.1, 1.0, 0.1, 1.0);
		else
			PlayerLevelText:SetVertexColor(1.0, 0.82, 0.0, 1.0);
		end

        if (effectiveLevel ~= 70) then
		    PlayerLevelText:SetText(effectiveLevel);
        else
            PlayerLevelText:SetText("");
        end
	end
end)

-- Hide role icon in arena
hooksecurefunc("PlayerFrame_UpdateRolesAssigned", function ()
	local roleIcon = PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.RoleIcon;
	if IsActiveBattlefieldArena() then
        roleIcon:SetShown(false);
    end
end)

hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
    if frame:IsForbidden() then
        return;
    end

    -- Check if this is a compact party/raid frame
    if ( frame:GetParent() == CompactPartyFrame ) then
        frame.name:Hide();
        return true;
    end
end)

-- Hide reputation/XP bar in arena
local hideXP = CreateFrame("Frame");
hideXP:RegisterEvent(NS.PLAYER_ENTERING_WORLD);
hideXP:RegisterEvent(NS.ARENA_PREP_OPPONENT_SPECIALIZATIONS);
hideXP:SetScript("OnEvent", function (self, event, ...)
    if IsActiveBattlefieldArena() then
        StatusTrackingBarManager:Hide();
    else
        StatusTrackingBarManager:Show();
    end
end)

--[[     

Profile:

4Xz7yU0CAJeeh)tusnVFC0yJRYvTHKkY(6uRaKXQSqsLKiKSh2p7Bp9OhqeGbVSPYH9qk6mp6Pvp)6)QLDu3JUOYQINtZs8MZJRQ9)(515PtIRKE7vzfBDtCr1lsYJRsl82ZlQwMu5TAkkYAslRDZDr5XRtqJ1B8JbU0VTxk2(u(M6KL(zaF0aBeSIRa3HEOkEXRpLN20ogZfTTOkBPFUxsx9sg8VMhJRwL043xD6FL4MXGvTao6LfBZVTytEJF1vXnjlNe30KLSQcgeDXIISnRZRDZmUOnyCCtw5lXUzKpkKWrcUp3f9htVhEuRltYY8jGzcT2yGTptr5CL3WOjmH3GAK4auceeWVwdHycdyyAAyjcUcxmxtSkcoMvjLsVLqlnObLAiCCRCoJeCkvzew8GfO3fgTfnKmTU9y5HPOmMqJ(M7ndtcbopeckMcpfUIBPOZzuILINNqkWdgY51Btlt6tjkFkzzCzt63sWBY4V)WII20xwXIxtWKQ)M2fDhCjuwuN2KwK7jLQKSy)gFSaC7n(7YP5jR)X9vWQXLMc3tTP6U1(LWG3oD2Jt)Ql6hF(z4S(aN4I(oAsPG5ZEp4bLMyx0NME3dp9jFO3th3xSydcELXlxMMVcEubUTcaVYTXvyepFFSOPNXPxbgFiXmoKoeNFZxNo7MouMZoc52xfmc0pqzrpMRofM3LMhaDQrRjiyzvmEGEjkdhzqP2AdCLw1HNAsGDnCTmGHcnxHwCjuSekfOwlfrta2zMa8XvWqZ90QLl9gqbbRDkB4xMIIwAJsJlbgIzrlGCX48cqw1(araABV2)7)KEC49Ph(I)ARPNz7YBNMAHKZhLDG7XX2wnWrAJNjWQUcaBpuoOhVFSmq0)Vw8VoT4F(vH8tigpUiOvuMF(IY8FxfLfxbg)IB8GUlqFfvK)vc7du8PG9oK7Cy9bK9q0(aKpW990ExzYaR3xm2SReZLZ4Nq7(NzC67JXVxRfePIzHuKraVoY98heQJs97Z17s8JRhok1Zog1VlRpubCqQFCxg7eA7s)JZT)o0ocJjBblQKOdmkr0rMGvGN0gEaePCDNARUDNmcbAwb6yqyLA0WqzT9zivT9Sib(ome1yObyLgkHGDfe3nALe9O166krWZYyBBhsOfA0qPnDDWqnTrMuh2nZFS4ygOYalmcT34DqOaMr0qVdHTz5DXJi8IcsOfmovPWjmsSEdEccJl1mSvRZOKIYouhr3E7vVtiM4FrFqxqfd)kuXmUq4D2e)bkdoEnZP7pIFjVYGZ46o9wKU0uEOvef8IbewewtlEjfbQ0yeHPa4HHVx5m4Nd2q9DP(q5cqOZrhMQ6bi)d3BGqJAFDFnVJ)TFKRqFgJrIX8ZB2C9bXHb06)sjxo0EaQKOKDYR43CnPtbffHeTDJqjbrTWxZnzh5zg3Ycs3GcfOLccVsEqJIAj2GYhOUkKx4NXzp5NXDI)geVtXlk7c)mUE1H3O72gCBBQBkwh1L(Hr(wsvTp6NrH)N7FcAP7Ik

]]
