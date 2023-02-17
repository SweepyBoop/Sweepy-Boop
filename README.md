# SweepyBoop's Arena Helper
My lightweight addon to support arena plays.

Here is how my UI looks like:
![image](https://user-images.githubusercontent.com/78008331/212603812-af58c455-962c-45d2-8dc4-2c82cab7cd53.png)

#### Note
This is my private version which includes a lot of stuff specifically made for myself (thus not needed by external users of the addon).

If you want to directly download this version, make sure in SweepyBoop.toc, only the keep files in the "#Publish" section.

Currently there is no plan to publish this addon on CurseForge, but I will do so if there are enough number of requests.

## Class and pet icons
For friendly players and their primary pets, places a class (for players) or pet (for pets) icon on top.

When selected, shows an orange highlight border.

This makes it much easier to track where your teammates are duing an arena match, especially for healers.

This is a great alternative to enabling friendly nameplates, since it's not always easy to distinguish between enemy/friendly nameplates. Some players use a script to make friendly nameplates shorter, but then there is the issue with priest mind control, i.e., friendly nameplates can become default width, or enemy nameplates can become shorter width after mind control effect.

To make the most of this module, configure your name & nameplate settings as follows:
![Nameplate settings](https://user-images.githubusercontent.com/78008331/219557897-5c1f0d38-9a64-408c-b1b5-6d7f8207899b.png)

## Nameplate filtering
While in arena, only show enemy player nameplates and important non-player units, e.g.,
- For Beast Mastery Hunter pets, only show the primary one, so you know which one to kill
- For warlocks, only show the pet, not the 1,000 wild imps

In short, this module shows the minimal set of unit nameplates that you need to keep an eye on during an arena match.

## Arena enemy cooldown tracking
The cooldown tracking mod comes with various advanced features:
- Shows duration when the cooldown is active with a glow, and shows cooldown timer otherwise (similar to tournament UI)
- Sort icons by priority/threat, e.g., on an Assasination Rogue, Deathmark will always show before other icons
- Cooldown reduction: for instance, Windwalker Monk Storm, Earth, and Fire cooldown reduced by spending Chi, Fire Mage Combustion cooldown reduced by casting Fireball or crit damage

#### Note
Currently this module only supports sArena, since that's what I use.

If you use Gladius and want to use this module, feel free to make a feature request 😊

## Fix Blizzard raid frame aggro highlight
Blizzard's raid frame aggro highlight only tracks PvE threats. That means pet threats inside arenas, which is not very useful.

This module fixes that by highlighting the teammate who is targetted by enemy DPS players.

For this module to work, disable the following setting under Interface settings so that it stops showing PvE threats:
![image](https://user-images.githubusercontent.com/78008331/216872796-737ec8a0-336b-4721-a122-bb9daaf70583.png)

