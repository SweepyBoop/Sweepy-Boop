# SweepyBoop's PvP Helper
An _extremely_ _lightweight_ addon to support arena gameplay.

Some of the features, such as class & pet icons and enemy nameplate highlight, also carry well into battlegrounds.

Type **/sb** in game to invoke the options panel.

Every module can be toggled on/off, with customization options (default settings should work great for most players).

![Options panel](https://github.com/user-attachments/assets/4590c455-8456-4dac-b2d6-c432134cc07e)





[Open a ticket](https://github.com/SweepyBoop/Sweepy-Boop/issues/new) to report any issues or request new features

## Friendly class and pet icons
![ClassIcons](https://github.com/user-attachments/assets/2fcdfdd5-f853-4288-b33b-62beba4ca0d4)

For friendly players and their primary pets, replace their health bars with class (for players) or pet (for pets) icons.
- Shows a highlight border for current target
- <span style="color:#36f"><strong>Option to use a special icon for healers in your group!</strong></span> No more "where is my healer" panic :)
- Easy to distinguish between friendly class icons and enemy nameplates

This module makes it much easier to track where your teammates are during an arena match, especially for healers!


![Flag Carrier Icons](https://github.com/user-attachments/assets/ba8d4723-57b0-42e6-adfa-2af4bf18e3da)

(Flag carrier icon in battlegrounds)

![Pet icons](https://github.com/user-attachments/assets/6e937613-bf68-4024-937a-28661b0ebd1c)




(Pet icon on primary hunter pet, but not on the extra pet summoned by talent)

To make the most of this module, configure your name & nameplate settings as follows:

![image](https://github.com/user-attachments/assets/3f43fe3b-5c84-4863-aa0a-29a0b61aaae8)

## Enemy nameplate filtering & highlighting
![TotemHighlight](https://github.com/user-attachments/assets/3ca7871f-0566-44f0-b141-4560213c30f0)

While in arenas / battlegrounds, customize which non-player enemy units to show, e.g.,
- Hide Beast Mastery hunters' extra pets from talents like "Animal Companion", so you know which one to kill
- Option to choose which non-player hostile units to show nameplates in arenas/battlegrounds
- Option to highlight chosen units with an animating icon!


Players can customize which units to hide / show / highlight:

![Nameplate filter](https://github.com/user-attachments/assets/d19f8f3f-ac53-476a-afb9-acb10b1246b2)

## Arena enemy offensive/defensive cooldown tracking
![image](https://github.com/user-attachments/assets/7e7a7368-84c6-4eb7-ac46-c69eb0f73ce0)

A set of icons attached to (corresponding) arena enemy frames, which is very close to the AWC UI.

This module comes with a few key features:
- Glows when spell is active, and shows cooldown timer otherwise
- Sorts icons by priority/threat, e.g., on an Assassination Rogue, Deathmark will always show before other icons
- Filter by spec, e.g., only shows Convoke the Spirits for Balance/Feral Druids, but not Restoration Druids
- Cooldown reduction: for instance, Fury Warrior's Relentlessness cooldown reduced by spending rage, Fire Mage Combustion cooldown reduced by casting Fireball or crit damage

This module is designed to give you **a quick overview** of
- Which enemy player is bursting (so you can peel accordingly if needed)
- Which enemy player(s) ran out of defensive options (thus would be the ideal kill target for next go)

It is **not** designed as some icons for players to stare at, or a spacestation WeakAuras group that replaces awareness :)

[Here is my Twitch clip of the cooldown tracking module in action!](https://github.com/user-attachments/assets/c4438f23-2e91-415d-9da5-f2860b727131)

**Note**
- This module looks for Gladius / sArena frames to anchor to, if neither is present icons will anchor to default Blizzard arena frames
- This module tracks damage offensives and defensives, and players can fully customize which cooldowns to track in the options panel

![Cooldown tracking spell list](https://github.com/user-attachments/assets/b379bf63-861f-4c85-adba-92654df9a193)

## Arena nameplate numbers & spec icons
![Enemy spec icons](https://github.com/user-attachments/assets/6520d5c7-a85f-444e-9688-76dd60fba753)

Replace arena enemy names on top of nameplates with arena numbers.

There is also an option to show enemy spec icons on top of their names inside arenas

(by default only healers' are shown but you can choose to show all players).



## Sort raid frames
![SortGroup](https://github.com/user-attachments/assets/3636ced6-c8a1-47db-9a35-43b3a4627d92)

Sort raid frames inside arena. Currently supports player on top/bottom, or in the middle between party1 and party2.

## Fix Blizzard raid frame aggro highlight
Blizzard's raid frame aggro highlight only tracks PvE threats, i.e., pet threats inside arenas, which is basically useless.

This module fixes that by highlighting the teammate who is targetted by enemy DPS players.

For this module to work, uncheck the following under Interface settings so that it stops showing PvE threats:

![image](https://github.com/user-attachments/assets/38505bd7-5f7d-4f7d-95a0-f8d6f232c02e)

## Miscellaneous quality-of-life features 
![Misc](https://github.com/user-attachments/assets/67f632e5-936e-4250-aca6-80eeadd68abd)


### Type /afk to surrender arena
Players can conveniently surrender arena by simply typing /afk.

If unable to surrender, e.g., no teammates have died, a confirmation dialog will pop up to leave.

There is also an option to leave directly without the confirmation dialog, but be careful:

leaving arena without ever entering combat might result in deserter status!

### Dampen display inside arena
![image](https://github.com/user-attachments/assets/329aa2b9-2a5e-4239-b40a-f68d90f8971b)

Shows the dampening percentage under the remaining time on the arena widget:


This is a more optimized version than the Dampening Display addon, as that addon updates the dampening display on every aura change, which could be hundreds or even thousands of times per second inside arena.

Our module updates once per second, which is more than enough since the dampening % only changes every few seconds!
