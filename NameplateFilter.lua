BoopNameplateFilter = {};

BoopNameplateFilter.Initialization = function (modTable)
    --insert code here
    modTable.test = false
    
    -- Whitelist for non-player units
    local whiteList = {
        -- DK
        --["Zombie"] = true, -- Reanimation PVP talent, 10% HP, very deadly
        
        -- Priest
        ["Psyfiend"] = true,
        
        -- Shaman: totems to kill instantly
        ["Grounding Totem"] = true,
        ["Spirit Link Totem"] = true,
        ["Skyfury Totem"] = true,
        ["Ancestral Protection Totem"] = true, -- LOL
        ["Capacitor Totem"] = true,
        ["Earthgrab Totem"] = true, -- Gets you out of stealth
        -- ["Windfury Totem"] = true,
        ["Healing Tide Totem"] = true,
        ["Vesper Totem"] = true, -- One shot
        
        -- Warrior
        ["War Banner"] = true,
        
        -- Seed
        ["Regenerating Wildseed"] = true,
    };

    local classID = select(3, UnitClass("player"));
    whiteList["Tremor Totem"] = ( classID == 1 ) or ( classID == 5 ) or ( classID == 9 );
    
    local function IsArenaPet(unit)
        local isPrimaryPet = UnitIsUnit(unit, "arenapet1") or UnitIsUnit(unit, "arenapet2") or UnitIsUnit(unit, "arenapet3");
        if not isPrimaryPet then
            return false;
        elseif UnitPowerMax(unit, 3) == 200 then
            return true;
        elseif UnitPowerMax(unit, 2) >= 100 then
            local maxFocus = 100;
            if UnitIsUnit(unit, "arenapet1") and GetArenaOpponentSpec(1) == 253 then
                maxFocus = 120;
            elseif UnitIsUnit(unit, "arenapet2") and GetArenaOpponentSpec(2) == 253 then
                maxFocus = 120;
            elseif UnitIsUnit(unit, "arenapet3") and GetArenaOpponentSpec(3) == 253 then
                maxFocus = 120;
            end
            
            return UnitPowerMax(unit, 2) >= maxFocus;
        end
    end
    
    local function IsParty(unitId)
        if modTable.test then
            return UnitIsFriend(unitId, "player");
        end
        return UnitIsUnit(unitId, "party1") or UnitIsUnit(unitId, "party2")
    end
    
    modTable.ShouldShowNameplate = function(unitId)
        if UnitIsPlayer(unitId) then
            return true;
        else
            if IsArenaPet(unitId) then
                return true;
            else
                local name = UnitName(unitId);
                if whiteList[name] then
                    return true;
                end
            end
        end
        
        return false;
    end
    
    -- Hide names for party members and non-players that are not whitelisted
    modTable.UpdateName = function(unitFrame, unitId)
        -- If already hidden, avoid additional checks
        if (not unitFrame.unitName:IsShown()) then return end
        
        if IsParty(unitId) then
            unitFrame.unitName:Hide();
        elseif (not UnitIsPlayer(unitId)) then
            local name = UnitName(unitId);
            if (not whiteList[name]) then
                unitFrame.unitName:Hide();
            end
        end
    end

    -- Hide buff frame for party members
    modTable.UpdateBuffFrame = function (unitFrame, unitId)
        if unitFrame.BuffFrame:IsShown() and IsParty(unitId) then
            unitFrame.BuffFrame:Hide();
        end
    end
    
    local showCastNpc = {
        [1863] = true, -- Succubus
        [61245] = true, -- Capacitor Totem
    };
    
    modTable.UpdateCastBar = function(unitFrame, unitId)
        if (not unitFrame.castBar:IsShown()) then return end
        
        local hideCast = false;
        if IsParty(unitId) then
            hideCast = true;
        elseif (not UnitIsPlayer(unitId)) then
            local npcID = select(6, strsplit("-", UnitGUID(unitId)));
            if (not npcID) or (not showCastNpc[npcID]) then
                hideCast = true;
            end
        end
        
        if hideCast then
            unitFrame.castBar:UnregisterAllEvents();
            unitFrame.castBar:Hide();
        end
    end
    
    modTable.UpdateFrame = function(unitFrame, unitId)
        if IsParty(unitId) then
            -- Smaller party nameplates with no cast bar & buff frame
            Plater.SetNameplateSize(unitFrame, 50, 13);
            unitFrame.castBar:UnregisterAllEvents();
            unitFrame.castBar:Hide();
            unitFrame.BuffFrame:Hide();
        elseif ( not UnitIsPlayer(unitId) ) then
            local npcID = unitFrame.namePlateNpcId; -- select(6, strsplit("-", UnitGUID(unitId)));
            if (not npcID) or (not showCastNpc[npcID]) then
                unitFrame.castBar:UnregisterAllEvents();
                unitFrame.castBar:Hide();
            end
        end
    end
end

BoopNameplateFilter.NameplateAdded = function (self, unitId, unitFrame, envTable, modTable)
    --insert code here
    
    -- A hack to not show any buffs on nameplate (in case mage steals buff from me)
    unitFrame.BuffFrame2:Hide();
    
    if (not unitId) then return end
    if (not IsActiveBattlefieldArena()) and (not modTable.test)  then return end
    
    -- Check if visible nameplate should be hidden
    -- Each nameplate needs to be hidden once only, to avoid repeated checks
    if unitFrame:IsShown() and (not modTable.ShouldShowNameplate(unitId)) then
        unitFrame:Hide();
        return;
    end
    
    modTable.UpdateFrame(unitFrame, unitId);
    modTable.UpdateName(unitFrame, unitId);
end

BoopNameplateFilter.NameplateUpdated = function (self, unitId, unitFrame, envTable, modTable)
    --insert code here
    
    -- A hack to not show any buffs on nameplate (in case mage steals buff from me)
    if (unitFrame.BuffFrame2:IsShown()) then
        unitFrame.BuffFrame2:Hide();
    end
    
    if (not unitId) then return end
    if (not IsActiveBattlefieldArena()) and (not modTable.test)  then return end
    
    modTable.UpdateBuffFrame(unitFrame, unitId);
    modTable.UpdateCastBar(unitFrame, unitId);
    modTable.UpdateName(unitFrame, unitId);
end











































