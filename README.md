# aSweepyBoop
My personal addon with quality-of-life features, and a library to support advanced arena cooldown tracking WeakAuras as well as a clean Plater Nameplate profile.

For the WeakAuras and Plater profile to work, you would need to install this addon of course :D

## WeakAuras
Here are the arena WeakAuras based on this addon:

- [Arena Enemy CC Cooldowns](https://wago.io/G3Ai96asn)
- [Arena Enemy Offensive Cooldowns](https://wago.io/EtVxNHjcg)
- [Arena Enemy Defensive Cooldowns](https://wago.io/ZqFOXpRY-)
- [Arena Enemy Dispel Cooldowns](https://wago.io/a_AIv4HJp)
- [Arena Enemy Interrupt (similar as default Omnibar)](https://wago.io/UgjuEm1mk)

- [Mortal Strike Debuff on Team](https://wago.io/pCKbpzW-Q)
- [Group member stun DR on raid frames](https://wago.io/FUT9JPGxV)
- [Player's own DR timer](https://wago.io/cD-yK8HTF)

The cooldown tracking WeakAuras come with various advanced features:
- Cooldown reduction: Hammer of Justice (from Fist of Justice), Combustion (from Pyrokinesis, Kindling, Shifting Power), etc.
- Talent memorization such as:
  - If a paladin casts Repentance or Blinding Light, Fist of Justice calculation for that player would be suppressed
  - If a priest casts a second Psychic Scream within 60 sec after the first one, we know they are playing Psychic Voice, thus will adjust the Psychic Scream cooldown for that unit to 30 sec

## Plater
[Plater profile based on this addon](https://wago.io/KnkjLULX7)

The main feature of this profile is called "Nameplate Filtering" inside arenas:
- For enemy units, only show nameplates of enemy players, primary pets, and high priority non-player units that are whitelisted
  - Primary pet refer to the main warlock pets (i.e., you will not see a horde of wild imps running around), and the main hunter pet (which means for Beast Mastery hunters, you will only see the real pet with 120 focus)
  - High priority units are generally those you want to target and kill instantly, e.g., Grounding Totem, Psyfiend, War Banner, Tremor Totem (if you are playing a class that has fear spells)
- If you are playing with friendly nameplates on, party members' nameplates will be reduced to half width, the names on top will be hidden (and raid markers would take that space), and buffs/cast bar will be hidden.
  - The logic behind this is for many players especially healers, they want to be able to track their teammates' positioning easily, with a strong distinction between friendly/enemy units