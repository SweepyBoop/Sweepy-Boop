Current Lib versions:
- Ace3: Release-r1390 with selected r1400-alpha AceGUI widget files for 12.1 PTR compatibility
- LibDBIcon: v12.0.2
- LibDeflate: 1.0.2-release (hasn't updated since 2020)

Tasks:
- [x] Re-implement arena numbers for mainline, this can unblock enemy spec icons too
- [x] Re-enable the secure Raid Frame healer buff helper for Restoration Druid and Preservation Evoker, including missing class-buff warnings and Blizzard-managed Lifebloom pandemic highlighting
- [x] Replace remaining Raid Frame healer-helper LibCustomGlow usage with local or Blizzard-managed visuals that do not read restricted UI alpha/state
- [ ] Re-implement battleground enemy spec icons (blocked)
- [x] Recover secure Raid Frame Big Debuff icons with configurable countdown threshold, Big Debuffs styling, a 50% default scale, and a matching settings preview
- [ ] Investigate Raid Frame arena target dots not appearing in arena (confirmed; intentionally deferred from the 12.1 compatibility patch)
- [x] Bug fix: friendly class icon "Show CC" sometimes get stuck on the CC icon and never switches back to the class icon (mainline keeps Blizzard CC selection and clears the shown overlay when that aura instance is removed)
- [x] Self stun DR that's super visible to play vs. swaps
- [ ] Test icon for "Honor reminder" should dismiss when resetting profile
- [ ] Update vendored Ace3 lib files once a stable 12.1-compatible release is available; currently using selected r1400-alpha files
- [ ] TBC Classic is missing the option to turn off minimap icon
- [ ] Re-generate HD icons from extracted in-game art (instead of from the wow-ui-texture repo which is a few years behind)
