# SweepyBoop's PvP Helper
A <span style="color:#36f; font-style:italic"><strong>super lightweight, easy-to-set-up</strong></span> addon to enhance arena gameplay with <span style="color:#36f; font-style:italic"><strong>minimal changes to original WoW UI</strong></span>.

Features include:
- Friendly player / pet icons: replace friendly nameplates with class icons with target highlight, making it much easier to track teammates' positioning without adding clutter on the screen
- Enemy nameplates: enemy player spec (healer) icons; pulsing totem indicators; customize which enemy units to hide / show; filter auras by whitelists; hide beast master hunters' secondary pets
- Advanced interrupt bar that calculates all cd reduction, even including Mage 4s cd reduction on successful Counterspell!
- Arena offensive & defensive cooldown tracking: cooldown timers attached to each arena frame that are more advanced and accurate, factoring in cooldown reduction (such as combustion)
- Raid frames: sort raid frames in arenas; show real PvP aggro highlight on raid frames
- Misc quality-of-life improvements: queue timer with alert sounds, healer in CC alert, /afk surrender in arena, dampen display, and more

<span style="color:#36f; font-style:italic"><strong>Join [Discord](https://discord.gg/SMRxeZzVwc) for help and discussion on PvP addon / UI</strong></span>.

If you encounter any [issues](https://github.com/SweepyBoop/Sweepy-Boop/issues/new) or have [feature requests](https://github.com/SweepyBoop/Sweepy-Boop/issues/new).

There might be conflicts with other nameplate addons (Plater, Threat Plates, BetterBlizzPlates), but this addon's got every essential nameplate element for PvP, thus you shouldn't need another full nameplate addon. If there are specific features missing from my addon, I'd be happy to fill in the feature gap.

Type **/sb** in game to bring up the options panel. Default settings should work great out of the box, though each module can be toggled on/off and customized.

<span style="color:#36f; font-style:italic"><strong>If you like my addon, please introduce it to your friends who play PvP!</strong></span> I'm really hoping to bring more people to (or back to) PvP with my work :)

## Friendly player / pet icons

![Class icon with names](https://github.com/user-attachments/assets/14eaeb57-c363-4869-b827-ab0a9312abfa)

(In-game class icon style with customizations: show spec icons & class-colored borders & player names)

![Arena Friendly Markers Thin](https://github.com/user-attachments/assets/0fd80425-b217-43ed-81af-beb7c7f2c3d7)

(Class-colored arrow style with player names)

![ClassIcons](https://github.com/user-attachments/assets/2fcdfdd5-f853-4288-b33b-62beba4ca0d4)

(In-game class icon style with plain border and no player names)

Replace nameplates of friendly players and their primary pets with class / healer / pet icons.

Important: to use friendly icons, <span style="color:#36f"><strong>enable the following settings in Options - Interface - Nameplates</strong></span>:

![Nameplate options](https://github.com/user-attachments/assets/2f5f7a9b-43d3-432a-8f11-5f2acbf8cc7b)


There are two styles of friendly icons: in-game class icons and class color arrows:

- Current friendly target will be highlighted with a border (for both styles)
- <span style="color:#36f"><strong>Option to use a special icon for healers</strong></span> in your group! No more "where is my healer" panic :)
- You can also <span style="color:#36f"><strong>customize to show your healer only</strong></span>, a great option for DPS players.

This module makes it much easier to track your teammates' positioning, since the icons are super visible and easily distinguishable from enemy nameplates!

There is also an option to hide friendly icons outside inside PvP instances to reduce clutter on the screen:

![image](https://github.com/user-attachments/assets/32819e4f-d69b-4e68-910f-c5ea04d2d6a2)


And some bonus features:
- Flag carrier icons in battlegrounds

![Flag Carrier Icons](https://github.com/user-attachments/assets/ba8d4723-57b0-42e6-adfa-2af4bf18e3da)

- Pet icons

![Pet icons](https://github.com/user-attachments/assets/6e937613-bf68-4024-937a-28661b0ebd1c)

- Friendly class icons are properly displayed on actual teammates under Priest Mind Control effect, i.e., if you're Mind Controlled, you won't see friendly class icons on enemy team members!

## Enemy nameplate filtering & highlighting
![TotemHighlight](https://github.com/user-attachments/assets/3ca7871f-0566-44f0-b141-4560213c30f0)

(*Pulsing totem indicators*)

![image](https://github.com/user-attachments/assets/ad9c2a2d-aeb7-4877-9656-db71c51c7a2a)

(*Beast Mastery extra pets' health bars are hidden, instead small critter icons are shown*)

While in arenas / battlegrounds, customize which non-player enemy units to show, e.g.,
- Hide Beast Mastery hunters' extra pets from talents like "Animal Companion", so you know which one to kill (there is also an option to show small critter icons on those hidden extra pets, so you have a sense of where they are to cast spells such as Ring of Frost / Mass Entanglement, without actually seeing all those health bars to clutter your UI)
- Option to choose which non-player hostile units to show nameplates in arenas/battlegrounds
- Option to highlight chosen units with an animating icon!


## Advanced interrupt bar
Similar to OmniBar but much more accurate, incorporating all cooldown reduction mechanics in the game, e.g.,
- Mage Counterspell cooldown is reduced by 4 Sec if they successfully landed the interrupt
- Balance Druid Solar Beam cooldown is reduced by 15 Sec if it successfully interrupted a spell cast
- Mage Shifting Power reduces the cooldown of all their abilities by 12 Sec
- Calculates ability charges more accurately, and displays them with a clear daily quest icon texture
- Tracks dispels properly: dispels are put on cooldown only if it dispels some debuffs, i.e., if enemy healer presses dispel after their DPS trinkets and dispeled nothing it should not trigger cooldown

It provides the "Show unused icons" option like OmniBar, but non-baseline abilities will not show until first usage, i.e., you won't see a Spell Lock icon if the opponent warlock is not playing Fel Hunter.

![Interrupt missed](https://github.com/user-attachments/assets/c602311a-f873-426c-be5e-b4497b05c075)

(Counterspell missed, cooldown is 24 Sec)

![Interrupt successful](https://github.com/user-attachments/assets/2dc4970c-07e9-490b-9779-cfb1edd4871d)

(Counterspell landed, cooldown becomes 20 Sec!)

![image](https://github.com/user-attachments/assets/3c0b5a4b-00e8-470c-ac11-b5a97b63119c)

(Clear indicator when another charge of Death Grip is available)

## Aura filter on enemy nameplates
![Auras on enemy nameplates](https://github.com/user-attachments/assets/0124adf6-6fe9-4d40-853f-4f0ed2a27f75)

Show only crowd controls (from all sources) and whitelisted debuffs applied by the player themselves on enemy nameplates.

There is also an option to show whitelisted buffs on enemy nameplates.

Auras are neatly organized into debuff and buff rows:
- On the debuff row, crowd controls are shown first with a larger scale and orange border, followed by other debuffs with normal scale and no border
- Buffs are shown on a separate row with a larger scale. Purgable buffs are shown with a different border (blue) than other buffs (green)

Bonus: racial crowd controls are not shown by Blizzard on enemy nameplates, this module also fixes that.

## Arena enemy cooldown tracking
![image](https://github.com/user-attachments/assets/f2131387-a222-45d9-83ca-c1fb37079b36)

(Arena cooldown tracker, the daily quest icon on Pain Suppression clearly indicates there is another charge available)

A set of icons attached to (corresponding) arena enemy frames, which is very close to the AWC UI.

This module comes with a few key features:
- Burst damage abilities glow during their duration, making it clear when you need to trade defensives, especially when the enemy team is cooldown stacking
- Cooldown reduction: for instance, Fury Warrior's Relentlessness cooldown reduced by spending rage, Fire Mage Combustion cooldown reduced by crit damage
- Detects talents tha reduce cooldowns or add charges to abilities accurately
- Clear indicator when "an additional charge is available", e.g., Discipline Priest has 2 charges of Pain Suppression
- Option to "Show unused icons" like Omnibar but more reliable - non-baseline abilities only show up after detected

This module is designed to give you **a quick overview** of
- Which enemy player is bursting (so you can peel accordingly if needed)
- Which enemy player(s) ran out of defensive options (thus would be the ideal kill target for next go)

This module supports all major arena frames, including Gladius, GladiusEx, sArena and built-in WoW arena frames


## Arena nameplate numbers & enemy player spec icons
![Screenshot 2025-01-05 101115](https://github.com/user-attachments/assets/fd7731af-13ed-48c6-a1c3-bbef63a70847)

Replace arena enemy names on top of nameplates with arena numbers.

Show spec icons (or a special healer icon) on top of enemy players in both arenas and battlegrounds

(by default only healers' are shown but you can choose to show all players).

![image](https://github.com/user-attachments/assets/bf5b9d81-68f6-4928-a2eb-3dfa976a7a55)

## Fix Blizzard raid frame aggro highlight
![Raid frame aggro](https://github.com/user-attachments/assets/8b617dce-10d2-4c4b-8f8b-9332b0d1e528)

Blizzard's raid frame aggro highlight only tracks PvE aggro, i.e., threat from pets inside arenas, which is basically useless.

This module replaces Blizzard raid frame aggro highlight with an animating dotted line border (border thickness and animation speed both customizable!), and the color of the border changes based on how many enemy players are currently targeting a teammate.

## Druid HoT helper
![Lifebloom pandemic glow](https://github.com/user-attachments/assets/a502695d-242a-4422-ba5c-317be20cb243)
![Cenarion Ward fade out before proc](https://github.com/user-attachments/assets/85bf2199-5c40-4ebb-bcf5-3f99967bec5a)


On Blizzard raid frames:
- Glow lifebloom buff during pandemic window for optimal refresh timing
- Cenarion Ward buff fades out until the actual healing procs (to extend the healing with Verdant Infusion)

## Miscellaneous quality-of-life features 
### Arena / battleground queue timer
![SafeQueue](https://github.com/user-attachments/assets/35f6ad2e-63e4-4f46-8cbf-343499b8d8c7)

Timer text color changes to yellow at 20s mark, then red at 10s mark, with an alarm clock sound alert.

### Healer in crowd control reminder
![Healer in CC](https://github.com/user-attachments/assets/4dc581ba-d65f-4ea8-9152-83da224904c8)


### Combat indicator on unit frames
![Combat Indicator](https://github.com/user-attachments/assets/59fc92fc-9a0f-4f97-ad8e-c07bacc5a3cf)


### Healer indicator on Gladius / sArena frames
![Healer indicator on Gladius](https://github.com/user-attachments/assets/d4872859-0594-4c0c-830f-be9ce2a23d88)

Makes it easier to identify the enemy healer when there is class stacking on the opponent team

(e.g., a shadow priest and a disc priest in the screenshot above)

### Type /afk to surrender arena
Players can conveniently surrender arena by simply typing /afk.

If unable to surrender, e.g., no teammates have died, a confirmation dialog will pop up to leave.

There is also an option to leave directly without the confirmation dialog, but be careful:

leaving arena without ever entering combat might result in deserter status!

### Dampen display inside arena
![image](https://github.com/user-attachments/assets/329aa2b9-2a5e-4239-b40a-f68d90f8971b)

Shows the dampening percentage under the remaining time on the arena widget.

This is a more optimized version than the Dampening Display addon, as that addon updates the dampening display on every aura change, which could be hundreds or even thousands of times per second inside arena.

Our module updates once per sec, which is more than enough since dampening % only changes every few seconds!
