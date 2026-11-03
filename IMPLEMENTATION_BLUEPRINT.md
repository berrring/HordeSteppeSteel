# Horde: Steppe & Steel — Official Technical Blueprint
**Engine:** Godot 4.7.2 Stable (Forward+ Renderer)  
**Verification Baseline:** 74/74 Headless Godot Tests Passing  
**Git Baseline Tag:** `v0.2.0-baseline`

---

## 1. System Inventory & Classification

- **[VERIFIED EXISTING]**: 12-province campaign setup, `collect_income()`, `resolve_battle()` RNG math, `tactical_battle.gd` damage & retreat logic, `ModelBuilder` procedural geometry, `AudioManager` WAV synthesis, 5-color palette constants in `palette.gd`.
- **[PROPOSED NEW]**: Scenario switch (`"checkpoint_slice"` vs `"full_campaign"`), `EconomyManager` validation service, `BattleCalculator` extraction, `StrategicAI` Rus counter-attack logic, dual-mode camera evaluation (`F10`).
- **[UNVERIFIED ASSUMPTION]**: Visual aesthetics of Orthographic 2.5D projection under Forward+ MSAA 3D; mouse raycast picking precision on elevated terrain plateaus (`y = 0.5`).

---

## 2. File Ownership Matrix (Zero Overlap)

| Developer | Assigned Files (Write Permission) | Read-Only Files | Forbidden Modifications |
|---|---|---|---|
| **Aziret** (Core Lead) | `scripts/core/game_manager.gd`<br>`scripts/core/campaign_controller.gd` | `scripts/core/palette.gd` | `campaign_hud.gd`, `tactical_battle.gd`, `strategic_camera.gd`, `model_builder.gd` |
| **Ayaz** (Economy & UI) | `scripts/core/economy_manager.gd`<br>`scripts/ui/campaign_hud.gd`<br>`assets/theme/game_theme.tres` | `scripts/core/palette.gd`<br>`scripts/core/game_manager.gd` | `campaign_controller.gd`, `tactical_battle.gd`, `strategic_camera.gd`, `model_builder.gd` |
| **Iskender** (Combat & AI) | `scripts/combat/battle_calculator.gd`<br>`scripts/combat/tactical_battle.gd`<br>`scripts/ai/strategic_ai.gd` | `scripts/core/palette.gd`<br>`scripts/core/game_manager.gd` | `campaign_hud.gd`, `campaign_controller.gd`, `strategic_camera.gd`, `model_builder.gd` |
| **Alen** (Map & Visuals) | `scripts/camera/strategic_camera.gd`<br>`scripts/map/campaign_map_3d.gd`<br>`scripts/map/province_visual.gd`<br>`scripts/visuals/model_builder.gd` | `scripts/core/palette.gd` | `game_manager.gd`, `campaign_hud.gd`, `tactical_battle.gd`, `economy_manager.gd` |

---

## 3. Strict Five-Color Palette Governance

Only these five base HEX colors are permitted across all materials, UI panels, and typography:

- **Steppe Green:** `#6B8E23` — `Color(0.42, 0.56, 0.14)`
- **Wood Brown:** `#5C4033` — `Color(0.36, 0.25, 0.20)`
- **Bronze Gold:** `#DAA520` — `Color(0.85, 0.65, 0.13)`
- **Snow White:** `#E8ECEF` — `Color(0.91, 0.93, 0.94)`
- **Deep Steel Blue:** `#2B3A4A` — `Color(0.17, 0.23, 0.29)`

*Disabled UI State Rule:* Use Deep Steel Blue (`#2B3A4A`) with reduced alpha (`Color(0.17, 0.23, 0.29, 0.45)`) and Snow White (`#E8ECEF`) with reduced alpha (`Color(0.91, 0.93, 0.94, 0.40)`). Zero unapproved hex codes.

---

## 4. Checkpoint Vertical Slice (3 Provinces)

- **Base (Sarai Steppe):** `x = -3.0`, `z = -0.5`, Owner: `"mongol"`, Capital: `true`, Army: 100 `horse_archer`.
- **Neutral (Crossroads Hill):** `x = 1.0`, `z = 0.5`, Owner: `"neutral"`, Capital: `false`, Army: 40 `spearman`.
- **Enemy (Sarkel Redoubt):** `x = 4.5`, `z = 1.5`, Owner: `"rus"`, Capital: `true`, Army: 80 `infantry`.

*Bridge Proof:*
- `pos1.x * pos2.x = (-3.0) * (1.0) = -3.0 < 0` (True).
- `mid.x = (-3.0 + 1.0) * 0.5 = -1.0`, `abs(-1.0) = 1.0 < 1.2` (True).
- `mid.z = (-0.5 + 0.5) * 0.5 = 0.0`, `abs(0.0) = 0.0 < 2.5` (True).
Bridge spawns centered at `mid = (-1.0, 0.06, 0.0)` crossing the river cleanly.

---

## 5. Integration Sequence (Git Rebase Workflow)

1. **Stage 1 (Aziret):** `aziret` implements `scenario_mode` in `game_manager.gd`. Test 87/87. Merge to `main`.
2. **Stage 2 (Alen):** `feature/ortho-camera-map` rebases on `main`. Implements `F10` camera toggle and topography elevations. Test 74/74. Merge to `main`.
3. **Stage 3 (Ayaz):** `feature/economy-hud-theme` rebases on `main`. Implements `EconomyManager` validation and button states. Test 74/74. Merge to `main`.
4. **Stage 4 (Iskender):** `feature/combat-calculator` rebases on `main`. Implements `BattleCalculator` and `StrategicAI`. Test 74/74. Merge to `main`.
5. **Stage 5 (Release):** Tag `v0.3.0-vertical-slice`.
