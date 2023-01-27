local _, NS = ...;

local test = true;

-- https://github.com/wardz/DRList-1.0/blob/master/DRList-1.0/Spells.lua
local spellList = {
    [207167]  = "disorient",       -- Blinding Sleet
    [207685]  = "disorient",       -- Sigil of Misery
    [33786]   = "disorient",       -- Cyclone
    [360806]  = "disorient",       -- Sleep Walk
    [1513]    = "disorient",       -- Scare Beast
    [31661]   = "disorient",       -- Dragon's Breath
    [198909]  = "disorient",       -- Song of Chi-ji
    [202274]  = "disorient",       -- Incendiary Brew
    [105421]  = "disorient",       -- Blinding Light
    [10326]   = "disorient",       -- Turn Evil
    [205364]  = "disorient",       -- Dominate Mind
    [605]     = "disorient",       -- Mind Control
    [8122]    = "disorient",       -- Psychic Scream
    [226943]  = "disorient",       -- Mind Bomb
    [2094]    = "disorient",       -- Blind
    [118699]  = "disorient",       -- Fear
    [5484]    = "disorient",       -- Howl of Terror
    [261589]  = "disorient",       -- Seduction (Grimoire of Sacrifice)
    [6358]    = "disorient",       -- Seduction (Succubus)
    [5246]    = "disorient",       -- Intimidating Shout 1
    [316593]  = "disorient",       -- Intimidating Shout 2 (TODO: not sure which one is correct in 9.0.1)
    [316595]  = "disorient",       -- Intimidating Shout 3
    [331866]  = "disorient",       -- Agent of Chaos (Venthyr Covenant)

    [217832]  = "incapacitate",    -- Imprison
    [221527]  = "incapacitate",    -- Imprison (Honor talent)
    [2637]    = "incapacitate",    -- Hibernate
    [99]      = "incapacitate",    -- Incapacitating Roar
    [378441]  = "incapacitate",    -- Time Stop
    [3355]    = "incapacitate",    -- Freezing Trap
    [203337]  = "incapacitate",    -- Freezing Trap (Honor talent)
    [213691]  = "incapacitate",    -- Scatter Shot
    [383121]  = "incapacitate",    -- Mass Polymorph
    [118]     = "incapacitate",    -- Polymorph
    [28271]   = "incapacitate",    -- Polymorph (Turtle)
    [28272]   = "incapacitate",    -- Polymorph (Pig)
    [61025]   = "incapacitate",    -- Polymorph (Snake)
    [61305]   = "incapacitate",    -- Polymorph (Black Cat)
    [61780]   = "incapacitate",    -- Polymorph (Turkey)
    [61721]   = "incapacitate",    -- Polymorph (Rabbit)
    [126819]  = "incapacitate",    -- Polymorph (Porcupine)
    [161353]  = "incapacitate",    -- Polymorph (Polar Bear Cub)
    [161354]  = "incapacitate",    -- Polymorph (Monkey)
    [161355]  = "incapacitate",    -- Polymorph (Penguin)
    [161372]  = "incapacitate",    -- Polymorph (Peacock)
    [277787]  = "incapacitate",    -- Polymorph (Baby Direhorn)
    [277792]  = "incapacitate",    -- Polymorph (Bumblebee)
    [321395]  = "incapacitate",    -- Polymorph (Mawrat)
    [391622]  = "incapacitate",    -- Polymorph (Duck)
    [82691]   = "incapacitate",    -- Ring of Frost
    [115078]  = "incapacitate",    -- Paralysis
    [357768]  = "incapacitate",    -- Paralysis 2 (Perpetual Paralysis?)
    [20066]   = "incapacitate",    -- Repentance
    [9484]    = "incapacitate",    -- Shackle Undead
    [200196]  = "incapacitate",    -- Holy Word: Chastise
    [1776]    = "incapacitate",    -- Gouge
    [6770]    = "incapacitate",    -- Sap
    [51514]   = "incapacitate",    -- Hex
    [196942]  = "incapacitate",    -- Hex (Voodoo Totem)
    [210873]  = "incapacitate",    -- Hex (Raptor)
    [211004]  = "incapacitate",    -- Hex (Spider)
    [211010]  = "incapacitate",    -- Hex (Snake)
    [211015]  = "incapacitate",    -- Hex (Cockroach)
    [269352]  = "incapacitate",    -- Hex (Skeletal Hatchling)
    [309328]  = "incapacitate",    -- Hex (Living Honey)
    [277778]  = "incapacitate",    -- Hex (Zandalari Tendonripper)
    [277784]  = "incapacitate",    -- Hex (Wicker Mongrel)
    [197214]  = "incapacitate",    -- Sundering
    [710]     = "incapacitate",    -- Banish
    [6789]    = "incapacitate",    -- Mortal Coil
    [107079]  = "incapacitate",    -- Quaking Palm (Pandaren racial)

    [47476]   = "silence",         -- Strangulate
    [204490]  = "silence",         -- Sigil of Silence
--      [78675]   = "silence",         -- Solar Beam (has no DR)
    [202933]  = "silence",         -- Spider Sting
    [356727]  = "silence",         -- Spider Venom
    [354831]  = "silence",         -- Wailing Arrow 1
    [355596]  = "silence",         -- Wailing Arrow 2
    [217824]  = "silence",         -- Shield of Virtue
    [15487]   = "silence",         -- Silence
    [1330]    = "silence",         -- Garrote
    [196364]  = "silence",         -- Unstable Affliction Silence Effect

    [210141]  = "stun",            -- Zombie Explosion
    [334693]  = "stun",            -- Absolute Zero (Breath of Sindragosa)
    [108194]  = "stun",            -- Asphyxiate (Unholy)
    [221562]  = "stun",            -- Asphyxiate (Blood)
    [91800]   = "stun",            -- Gnaw (Ghoul)
    [91797]   = "stun",            -- Monstrous Blow (Mutated Ghoul)
    [287254]  = "stun",            -- Dead of Winter
    [179057]  = "stun",            -- Chaos Nova
    [205630]  = "stun",            -- Illidan's Grasp (Primary effect)
    [208618]  = "stun",            -- Illidan's Grasp (Secondary effect)
    [211881]  = "stun",            -- Fel Eruption
    [200166]  = "stun",            -- Metamorphosis (PvE stun effect)
    [203123]  = "stun",            -- Maim
    [163505]  = "stun",            -- Rake (Prowl)
    [5211]    = "stun",            -- Mighty Bash
    [202244]  = "stun",            -- Overrun
    [325321]  = "stun",            -- Wild Hunt's Charge
    [372245]  = "stun",            -- Terror of the Skies
    [117526]  = "stun",            -- Binding Shot
    [357021]  = "stun",            -- Consecutive Concussion
    [24394]   = "stun",            -- Intimidation
    [389831]  = "stun",            -- Snowdrift
    [119381]  = "stun",            -- Leg Sweep
    [202346]  = "stun",            -- Double Barrel
    [385149]  = "stun",            -- Exorcism
    [853]     = "stun",            -- Hammer of Justice
    [255941]  = "stun",            -- Wake of Ashes
    [64044]   = "stun",            -- Psychic Horror
    [200200]  = "stun",            -- Holy Word: Chastise Censure
    [1833]    = "stun",            -- Cheap Shot
    [408]     = "stun",            -- Kidney Shot
    [118905]  = "stun",            -- Static Charge (Capacitor Totem)
    [118345]  = "stun",            -- Pulverize (Primal Earth Elemental)
    [305485]  = "stun",            -- Lightning Lasso
    [89766]   = "stun",            -- Axe Toss
    [171017]  = "stun",            -- Meteor Strike (Infernal)
    [171018]  = "stun",            -- Meteor Strike (Abyssal)
    [30283]   = "stun",            -- Shadowfury
    [385954]  = "stun",            -- Shield Charge
    [46968]   = "stun",            -- Shockwave
    [132168]  = "stun",            -- Shockwave (Protection)
    [145047]  = "stun",            -- Shockwave (Proving Grounds PvE)
    [132169]  = "stun",            -- Storm Bolt
    [199085]  = "stun",            -- Warpath
    [20549]   = "stun",            -- War Stomp (Tauren)
    [255723]  = "stun",            -- Bull Rush (Highmountain Tauren)
    [287712]  = "stun",            -- Haymaker (Kul Tiran)
    [332423]  = "stun",            -- Sparkling Driftglobe Core (Kyrian Covenant)
    -- TODO: Inferal Awakening?

    [204085]  = "root",            -- Deathchill (Chains of Ice)
    [233395]  = "root",            -- Deathchill (Remorseless Winter)
    [339]     = "root",            -- Entangling Roots
    [235963]  = "root",            -- Entangling Roots (Earthen Grasp)
    [170855]  = "root",            -- Entangling Roots (Nature's Grasp)
    [102359]  = "root",            -- Mass Entanglement
    [355689]  = "root",            -- Landslide
    [393456]  = "root",            -- Entrapment (Tar Trap)
    [162480]  = "root",            -- Steel Trap
    [273909]  = "root",            -- Steelclaw Trap
--      [190927]  = "root_harpoon",    -- Harpoon (TODO: confirm)
    [212638]  = "root",            -- Tracker's Net
    [201158]  = "root",            -- Super Sticky Tar
    [122]     = "root",            -- Frost Nova
    [33395]   = "root",            -- Freeze
    [386770]  = "root",            -- Freezing Cold
    [198121]  = "root",            -- Frostbite
    [114404]  = "root",            -- Void Tendril's Grasp
    [342375]  = "root",            -- Tormenting Backlash (Torghast PvE)
    [233582]  = "root",            -- Entrenched in Flame
    [116706]  = "root",            -- Disable
    [324382]  = "root",            -- Clash
    [64695]   = "root",            -- Earthgrab (Totem effect)
--      [356738]  = "root",            -- Earth Unleashed (doesn't seem to DR)
    [285515]  = "root",            -- Surge of Power
    --[356356]  = "root",            -- Warbringer TODO: has DR?
    [39965]   = "root",            -- Frost Grenade (Item)
    [75148]   = "root",            -- Embersilk Net (Item)
    [55536]   = "root",            -- Frostweave Net (Item)
    [268966]  = "root",            -- Hooked Deep Sea Net (Item)

    [209749]  = "disarm",          -- Faerie Swarm (Balance Honor Talent)
    [207777]  = "disarm",          -- Dismantle
    [233759]  = "disarm",          -- Grapple Weapon
    [236077]  = "disarm",          -- Disarm

    [56222]   = "taunt",           -- Dark Command
    [51399]   = "taunt",           -- Death Grip (Taunt Effect)
    [185245]  = "taunt",           -- Torment
    [6795]    = "taunt",           -- Growl (Druid)
    [2649]    = "taunt",           -- Growl (Hunter Pet) (TODO: confirm)
    [20736]   = "taunt",           -- Distracting Shot
    [116189]  = "taunt",           -- Provoke
    [118635]  = "taunt",           -- Provoke (Black Ox Statue)
    [196727]  = "taunt",           -- Provoke (Niuzao)
    [204079]  = "taunt",           -- Final Stand
    [62124]   = "taunt",           -- Hand of Reckoning
    [17735]   = "taunt",           -- Suffering (Voidwalker) (TODO: confirm)
    [355]     = "taunt",           -- Taunt

    -- Experimental
    [108199]  = "knockback",        -- Gorefiend's Grasp
    [202249]  = "knockback",        -- Overrun
    [61391]   = "knockback",        -- Typhoon
    [102793]  = "knockback",        -- Ursol's Vortex
    [186387]  = "knockback",        -- Bursting Shot
    [236777]  = "knockback",        -- Hi-Explosive Trap
    [157981]  = "knockback",        -- Blast Wave
    [237371]  = "knockback",        -- Ring of Peace
    [204263]  = "knockback",        -- Shining Force
    [51490]   = "knockback",        -- Thunderstorm
--      [287712]  = "knockback",        -- Haywire (Kul'Tiran Racial)
}

if test then
    spellList[1126] = "disorient"; -- Mark of the Wild
    spellList[8936] = "stun"; -- Regrowth
    spellList[774] = "incapacitate"; -- Rejuvenation
end

local categoryIcon = {
    ["stun"] = select(3, GetSpellInfo(1833)), -- Cheap Shot
    ["disorient"] = select(3, GetSpellInfo(5782)), -- Fear
    ["incapacitate"] = select(3, GetSpellInfo(118)), -- Polymorph
};

local categoryPriority = {
    ["stun"] = 1,
    ["incapacitate"] = 2,
    ["disorient"] = 3,
};

local playerGUID = UnitGUID("player");

local function CreateDRIcon(category)
    local f = CreateFrame("Frame", nil, UIParent);
    f:Hide();
    f.category = category;
    f.priority = categoryPriority[category];
    f.stacks = 0;
    f:SetSize(28, 28);

    f.texture = f:CreateTexture();
    f.texture:SetTexture(categoryIcon[category]);
    f.texture:SetAllPoints();
    
    f.border = CreateFrame("Frame", nil, f, "NamePlateFullBorderTemplate");
    f.border:SetBorderSizes(3, 3, 3, 3);

    f.cooldown = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate");
    f.cooldown:SetAllPoints();
    f.cooldown:SetDrawEdge(false);
    f.cooldown:SetAlpha(1);
    f.cooldown:SetDrawBling(false);
    f.cooldown:SetDrawSwipe(true);
    f.cooldown:SetReverse(true);
    f.cooldown:SetScript("OnCooldownDone", function (self)
        local parent = self:GetParent();
        if parent then
            parent.stacks = 0;
            parent:Hide();
        end
    end)

    f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
    f:SetScript("OnEvent", function (self, event, ...)
        local _, subEvent, _, _, _, _, _, destGUID, _, _, _, spellID = CombatLogGetCurrentEventInfo();
        if ( subEvent == "SPELL_AURA_REMOVED" ) and ( destGUID == playerGUID ) then
            local category = spellList[spellID];
            if ( category ~= self.category ) then return end

            self.stacks = self.stacks + 1;

            -- Set border color
            if self.stacks == 1 then
                self.border:SetVertexColor(0, 1, 0); -- Green
            elseif self.stacks == 2 then
                self.border:SetVertexColor(1, 1, 0); -- Yellow
            else
                self.border:SetVertexColor(1, 0, 0); -- Red
            end

            -- Refresh timer
            self.cooldown:SetCooldown(GetTime(), ( test and 5 ) or 15);
            self:Show();
        end
    end)

    return f;
end

local setPointOptions = {
    point = "BOTTOMRIGHT",
    relativeTo = _G["PlayerFrame"];
    relativePoint = "TOPRIGHT",
    offsetX = -25,
    offsetY = -38,
};
local drIconGroup = NS.CreateIconGroup(setPointOptions, { direction = "LEFT", anchor = "BOTTOMRIGHT" });
drIconGroup.icons = {};
table.insert(drIconGroup.icons, CreateDRIcon("stun"));
table.insert(drIconGroup.icons, CreateDRIcon("disorient"));
table.insert(drIconGroup.icons, CreateDRIcon("incapacitate"));
drIconGroup.active = {};