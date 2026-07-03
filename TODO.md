Current Lib versions:
- Ace3: Release-r1390
- LibDBIcon: v12.0.2
- LibDeflate: 1.0.2-release (hasn't updated since 2020)

Tasks:
- [x] Re-implement arena numbers for mainline, this can unblock enemy spec icons too
- [x] Re-enable Druid HoT Helper
- [x] If Druid HoT Helper glow taints again in arena, replace any remaining LibCustomGlow usage (especially Mark of the Wild PixelGlow) with a local glow implementation that does not read UI alpha/state (completed, no dependency on LibCustomGlow anymore)
- [ ] Re-implement battleground enemy spec icons (blocked)
- [x] Configurable SetCountdownMillisecondsThreshold for raid frame big debuffs & healer in CC alert
- [x] Bug fix: friendly class icon "Show CC" sometimes get stuck on the CC icon and never switches back to the class icon (mainline now only shows crowd-control auras when Blizzard explicitly returns true, not when the result is secret)
- [ ] Implement rotating style target highlight for class icons
- [ ] Self stun DR that's super visible to play vs. swaps
