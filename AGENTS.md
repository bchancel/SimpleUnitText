# SimpleUnitText Maintainer Notes

## Scope
- Keep the addon lightweight and text-first.
- Preserve the existing player/target HUD behavior unless a change is explicitly requested.
- Prefer small shared modules over growing another monolithic file.

## Midnight Safety
- Treat `UnitHealthPercent`, `UnitPowerPercent`, `UnitPower`, `UnitPowerMax`, `GetComboPoints`, and similar unit-resource APIs as potentially returning Secret values.
- Do not compare, add, subtract, clamp, cache, serialize, or stringify Secret values in normal Lua logic.
- Only pass Secret values directly into Blizzard APIs/widgets that are documented or already proven safe for redisplay.
- When a display transform is needed, prefer Blizzard curve objects (`CurveConstants`, `C_CurveUtil.CreateCurve`, `C_CurveUtil.CreateColorCurve`) over custom Lua math.

## Display Rules
- Health and mana recoloring should flow through color curves, not manual percent thresholds.
- Secondary-resource redisplay should stay in the display lane: direct redisplay or Blizzard curve-based remapping only.
- If a new rendering path needs a numeric decision on a resource value, stop and verify it is not Secret-safe first.

## Config / Data Rules
- Shared settings belong in the DB/profile layer; UI code should not invent parallel state.
- Global vs character scope should keep using `SimpleUnitTextDB` plus `SimpleUnitTextCharDB`.
- Export/import payloads must contain settings only, never runtime or Secret-derived values.
