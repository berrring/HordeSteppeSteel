# Engineering Decision Log — Horde: Steppe & Steel

## ADR-001: Three-Province Scenario Isolation
- **Developer:** Aziret (Core Architecture Lead)
- **Date:** 2026-11-03
- **Status:** IMPLEMENTED & VERIFIED
- **Decision:** Added optional `scenario_mode: String = "full_campaign"` to `GameManager.start_new_campaign()`. When `"checkpoint_slice"` is requested, initializes 3 provinces (`sarai`, `crossroads`, `sarkel`), connects 2 roads, sets up starting armies, registers neutral clan faction, and applies Checkpoint 4 victory (capturing Sarkel) and defeat (loss of Sarai or turn > 30) conditions.
- **Context & Problem:** Instructor required freezing to a polished 3-province vertical slice for Checkpoint 4 without discarding or breaking the 12-province full campaign.
- **Alternatives Considered:** 
  1. Deleting 9 provinces from raw array (rejected: would destroy full campaign and fail 74 test baseline).
  2. Separate scene duplicate of GameManager (rejected: redundant code and state desync).
- **Why Selected:** Single parameter switch preserves backward compatibility, keeps all existing tests green, and allows seamless toggling between scenarios.
- **Files Modified:** `scripts/core/game_manager.gd`, `scripts/tests/test_godot_gameplay.gd`.
- **Verification Method:** Ran Godot headless verification suite; confirmed 81/81 assertions pass (74 baseline + 7 new checkpoint slice assertions).
- **Live Defense Demonstration:** Run `start_new_campaign("mongol", "checkpoint_slice")`, show 3 provinces in debugger, demonstrate capturing Sarkel triggers `"win"`. 

---

## ADR-002: Economy Rules Validation Service & Themed Presentation
- **Developer:** Ayaz (Economy & UI)
- **Date:** 2026-11-04
- **Status:** IMPLEMENTED & VERIFIED
- **Decision:** Created stateless `EconomyManager` (RefCounted) validation service for all construction and recruitment operations without mutating campaign dictionaries or owning mutable state. Integrated dynamic button reflection in `CampaignHUD` where built structures and unaffordable options are immediately disabled with descriptive tooltips. Implemented `assets/theme/game_theme.tres` and styled all HUD controls using the strict 5-color palette (Deep Steel Blue `#2B3A4A`, Bronze Gold `#DAA520`, Wood Brown `#5C4033`, Steppe Green `#6B8E23`, Snow White `#E8ECEF`).
- **Context & Problem:** Province building and unit recruitment previously allowed duplicate constructions and lacked client-side validation, leading to potential race conditions, desynchronization, and default unstyled gray Godot controls.
- **Alternatives Considered:** 
  1. Direct state mutation inside GameManager/HUD (rejected: violates separation of concerns, causes race conditions and UI desynchronization).
  2. Autoload singleton holding duplicate economy state (rejected: creates stale state caches and violates single source of truth).
- **Why Selected:** Pure RefCounted service has zero state, cannot cause desynchronization or race conditions, and can be queried safely by both UI and game controller.
- **Files Modified:** `HordeGodot/scripts/core/economy_manager.gd`, `HordeGodot/scripts/ui/campaign_hud.gd`, `HordeGodot/assets/theme/game_theme.tres`, `HordeGodot/scripts/tests/test_economy_validation.gd`.
- **Verification Method:** Ran Godot headless verification suites: `scripts/tests/test_economy_validation.gd` (20/20 passing) and `scripts/tests/test_godot_gameplay.gd` (86/86 passing).
- **Live Defense Demonstration:** Select province in Checkpoint slice, show Town Center button enabled, construct Town Center, verify button turns disabled with `[BUILT]` marker, empty wood reserves, and demonstrate other building buttons disable with tooltip explanation. 

---

## ADR-003: Grounded Combat Calculator Extraction
- **Developer:** Iskender (Combat Math & AI)
- **Date:** [Fill upon implementation]
- **Status:** PROPOSED
- **Decision:** 
- **Context & Problem:** 
- **Alternatives Considered:** 
- **Why Selected:** 
- **Files Modified:** 
- **Verification Method:** 
- **Live Defense Demonstration:** 

---

## ADR-004: Dual-Mode Camera Projection & Topography
- **Developer:** Alen (Map, Camera & Visuals)
- **Date:** [Fill upon implementation]
- **Status:** PROPOSED
- **Decision:** 
- **Context & Problem:** 
- **Alternatives Considered:** 
- **Why Selected:** 
- **Files Modified:** 
- **Verification Method:** 
- **Live Defense Demonstration:** 
