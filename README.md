# SweepyBoop's PvP Helper
A <span style="color:#36f; font-style:italic"><strong>super lightweight, easy-to-set-up</strong></span> addon to enhance arena gameplay with <span style="color:#36f; font-style:italic"><strong>minimal changes to original WoW UI</strong></span>.

Type **/sb** in game to bring up the options panel.

Default settings should work great out of the box, though each module can be toggled on/off with customizations.

Some features such as class & pet icons and enemy nameplate highlight also work great in battlegrounds.


[Open a ticket](https://github.com/SweepyBoop/Sweepy-Boop/issues/new) to report any issues or request new features

## Friendly class and pet icons
![ClassIcons](https://github.com/user-attachments/assets/2fcdfdd5-f853-4288-b33b-62beba4ca0d4)

(In-game class icon style)

![Arena Friendly Markers Thin](https://github.com/user-attachments/assets/fd2170d8-7377-4f52-9c74-77efbf7df1a2)

(Class color arrow style)


For friendly players and their primary pets, replace their health bars with class (for players) or pet (for pets) icons.

There are two styles of frinedly icons: in-game class icons and class color arrows:

- Current friendly target will be highlighted with a border (for both styles)
- <span style="color:#36f"><strong>Option to use a special icon for healers in your group!</strong></span> No more "where is my healer" panic :)

This module makes it much easier to track where your teammates are during an arena match, especially for healers!

And it's super easy to distinguish between friendly icons and enemy nameplates.

There is an option to hide class icons outside inside PvP instances to reduce clutter on the screen:

![image](https://github.com/user-attachments/assets/47e026f0-38f9-4cc6-aa80-5837fc30c273)


And some bonus features:
- Flag carrier icons in battlegrounds

![Flag Carrier Icons](https://github.com/user-attachments/assets/ba8d4723-57b0-42e6-adfa-2af4bf18e3da)

- Pet icons

![Pet icons](https://github.com/user-attachments/assets/6e937613-bf68-4024-937a-28661b0ebd1c)

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
- Cooldown reduction: for instance, Fury Warrior's Relentlessness cooldown reduced by spending rage, Fire Mage Combustion cooldown reduced by crit damage

This module is designed to give you **a quick overview** of
- Which enemy player is bursting (so you can peel accordingly if needed)
- Which enemy player(s) ran out of defensive options (thus would be the ideal kill target for next go)

It is **not** designed as some icons for players to stare at, or a spacestation WeakAuras group that replaces awareness :)

[Here is my Twitch clip of the cooldown tracking module in action!](https://github.com/user-attachments/assets/c4438f23-2e91-415d-9da5-f2860b727131)

**Note**
- This module looks for Gladius / sArena frames to anchor to, if neither is present icons will anchor to default Blizzard arena frames
- This module tracks damage offensives and defensives, and players can fully customize which cooldowns to track

![Cooldown tracking spell list](https://github.com/user-attachments/assets/b379bf63-861f-4c85-adba-92654df9a193)

## Arena nameplate numbers & spec icons
![Enemy spec icons](https://github.com/user-attachments/assets/6520d5c7-a85f-444e-9688-76dd60fba753)

Replace arena enemy names on top of nameplates with arena numbers.

There is also an option to show enemy spec icons on top of their names inside arenas

(by default only healers' are shown but you can choose to show all players).



## Sort raid frames
![SortGroup](https://github.com/user-attachments/assets/caefcbd3-ad7b-432f-86e9-dc5f5c6caefd)

Sort raid frames inside arena. Currently supports player on top/bottom, or in the middle between party1 and party2.

## Fix Blizzard raid frame aggro highlight
![PvP raid frame aggro highlight](https://github.com/user-attachments/assets/5fc7913f-3a96-4d2d-9939-55e6ef264ad3)

Blizzard's raid frame aggro highlight only tracks PvE aggro, i.e., threat from pets inside arenas, which is basically useless.

This module fixes that by highlighting the teammate who is targetted by enemy DPS players.

For this module to work, uncheck the following under Interface settings so that it stops showing PvE aggro:

![image](https://github.com/user-attachments/assets/38505bd7-5f7d-4f7d-95a0-f8d6f232c02e)

## Miscellaneous quality-of-life features 
### Arena / battleground queue timer
![SafeQueue](https://github.com/user-attachments/assets/35f6ad2e-63e4-4f46-8cbf-343499b8d8c7)

Timer text color changes to yellow at 20s mark, then red at 10s mark, with an alarm clock sound alert.

This module makes the <span style="color:#36f"><strong>fewest changes to the original WoW UI</strong></span> compared to other similar addons (SafeQueue, BetterBlizzFrames, etc.)

### Healer in crowd control reminder
![Healer in CC](https://github.com/user-attachments/assets/b17b510d-cc48-44bc-9256-7567020cbf5a)


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
