# SweepyBoop
My library addon to support advanced arena cooldown tracking WeakAuras as well as a clean Plater Nameplate profile.

All the Weakauras and Plater profiles linked below depend on this library, which means you need to install this addon for them to work 😉

Here is how my UI looks like:
![image](https://user-images.githubusercontent.com/78008331/212603812-af58c455-962c-45d2-8dc4-2c82cab7cd53.png)

## Class and pet icons
For friendly players and their primary pets, place a class (for players) or pet icon on top.

When selected, show an orange border to highlight.

This makes it much easier to track where your teammates are duing an arena match.

## WeakAuras
Here are the arena WeakAuras based on this addon:

- [Arena Enemy Offensive Cooldowns](https://wago.io/EtVxNHjcg)
- [Mortal Strike Debuff on Team](https://wago.io/pCKbpzW-Q)
- [Player's own DR timer](https://wago.io/cD-yK8HTF)

The cooldown tracking WeakAuras come with various advanced features:
- Cooldown reduction: Hammer of Justice (from Fist of Justice), Combustion (from Pyrokinesis, Kindling, Shifting Power), Vendetta (from Duskwalker's Patch legendary armor) etc.
- Talent memorization such as:
  - If a paladin casts Repentance or Blinding Light, Fist of Justice cooldown reduction for that player would be suppressed
  - If a priest casts a second Psychic Scream within 60 sec after the first one, we know they are playing Psychic Voice, thus will adjust the Psychic Scream cooldown for that unit to 30 sec
  - Detect optional charges for abilities such as DK grip, warrior charge, priest dispel. Once this is detected, if for instance a DK uses his first charge of grip, on the cooldown timer, you can see a charge number 1 meaning he still has one charge of grip available

## Fix Blizzard raid frame aggro highlight
Blizzard's raid frame aggro highlight only tracks PvE threats. That means pet threats inside arenas, which is rather unreliable.

This module fixes that by highlighting the teammate who is targetted by the most enemy players.

For this module to work, disable the following setting under Interface settings so that it stops showing PvE threats:
![image](https://user-images.githubusercontent.com/78008331/175849539-7a7180d4-28f8-4453-b979-d98f56a2623c.png)
