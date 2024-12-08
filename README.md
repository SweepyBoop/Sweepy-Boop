# SweepyBoop's Arena Helper
A _lightweight_ addon to support arena gameplay.

Here is an overall image of the UI:
![image](https://user-images.githubusercontent.com/78008331/226146638-ecd2f9d5-2276-4dbb-925f-157ff4e3a955.png)

Type **/sb** in game to invoke the options panel.

Every module can be toggled on/off, with a few customization options.

Most changes require a UI reload to take effect, and there is a Reload UI button below the settings for convinience.

![image](https://user-images.githubusercontent.com/78008331/219826235-9a9c1b72-5e5b-4108-9728-576e991f8789.png)

[Open a ticket](https://github.com/SweepyBoop/Sweepy-Boop/issues/new) to report any issues or request new features

## Friendly class and pet icons
For friendly players and their primary pets, places a class (for players) or pet (for pets) icon on top to replace the health bar.
- When selected, shows an orange highlight border.
- This makes it much easier to track where your teammates are during an arena match, especially for healers.
- <span style="color:#36f"><strong>There is an option to use a special icon for healers in your group!</strong></span> No more "where is my healer" scream in an intense arena game for DPS players
- This is a great alternative to enabling friendly nameplates, since it's not always easy to distinguish between enemy/friendly nameplates. Some players use a script to make friendly nameplates shorter, but then there is the issue with priest mind control, i.e., friendly nameplates can become default width, or enemy nameplates can become shorter width after mind control effect.

![image](https://github.com/user-attachments/assets/5c2402c2-6aa3-4a67-8e50-e19558bca9c3)

(Friendly class icons. Option to use a special icon for healers; target is highlighted with a border that's customizable.)

![image](https://github.com/user-attachments/assets/7283015e-bace-4253-ba02-30f3bd4b2ac5)

(Pet icon on primary hunter pet, but not on the extra pet summoned by talent)

To make the most of this module, configure your name & nameplate settings as follows:

![image](https://github.com/user-attachments/assets/3f43fe3b-5c84-4863-aa0a-29a0b61aaae8)

## Arena enemy offensive/defensive cooldown tracking
This module is a set of icons attached to (corresponding) arena enemy frames, which is very close to the tournament UI.

It comes with a few key features:
- Glows when spell is active, and shows cooldown timer otherwise (only the most important spells show cooldown timers)
- Sorts icons by priority/threat, e.g., on an Assassination Rogue, Deathmark will always show before other icons
- Filter by spec, e.g., only shows Convoke the Spirits for Balance/Feral Druids, but not Restoration Druids
- Cooldown reduction: for instance, Fury Warrior's Relentlessness cooldown reduced by spending rage, Fire Mage Combustion cooldown reduced by casting Fireball or crit damage

![image](https://github.com/user-attachments/assets/7e7a7368-84c6-4eb7-ac46-c69eb0f73ce0)

**Note (important)**
- This module supports Gladius and sArena
- Make sure to /reload if you change your Gladius / sArena settings (especially when you change the layout / positioning)
- This module only tracks damage offensives and defensive abilities, and currently there is no option to choose which abilities to track

## Sort raid frames
Sort raid frames inside arena. Currently supports player on top/bottom, or in the middle between party1 and party2.

![image](https://github.com/user-attachments/assets/10ecb4de-691d-4e11-a2a2-69eca3a80938)

## Arena Nameplate Numbers
Quality-of-life feature to replace arena enemy names on top of nameplates with arena numbers.

![image](https://github.com/user-attachments/assets/9a629304-9675-40ea-a5d1-4f39f101032a)

(Arena numbers on top of enemy players)

## Type /afk to surrender arena
Players can conveniently surrender arena by simply typing /afk.

If unable to surrender, e.g., no teammates have died, a confirmation dialog will pop up to leave.

There is also an option to leave directly without the confirmation dialog, but be careful: leaving arena without ever entering combat might result in deserter status!

![image](https://github.com/user-attachments/assets/45663a67-435d-4b45-985f-0924074d3f6c)


## Nameplate filtering
While in arena, only show enemy player nameplates and important non-player units, e.g.,
- For Beast Mastery Hunter pets, only show the primary one, so you know which one to kill
- Tremor totem nameplate will not show, unless current group (including player themselves) have a fear ability (Warrior, Warlock, Priest)
- For warlocks, only show the pet, not the 1,000 wild imps

In short, this module shows the minimal set of unit nameplates that you need to keep an eye on during an arena match.


## Fix Blizzard raid frame aggro highlight
Blizzard's raid frame aggro highlight only tracks PvE threats.
That means pet threats inside arenas, which is not very useful.

This module fixes that by highlighting the teammate who is targetted by enemy DPS players.

For this module to work, disable the following setting under Interface settings so that it stops showing PvE threats:

![image](https://github.com/user-attachments/assets/38505bd7-5f7d-4f7d-95a0-f8d6f232c02e)

## Dampen display inside arena
Shows the dampening percentage under the remaining time on the arena widget:
![image](https://github.com/user-attachments/assets/329aa2b9-2a5e-4239-b40a-f68d90f8971b)


