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

## ADR-002: Economy Rules Validation Service
- **Developer:** Ayaz (Economy & UI)
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
