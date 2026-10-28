# Horde: Steppe & Steel — Technical Production Pipeline

**Project:** Horde: Steppe & Steel  
**Team:** Arsenal  
**Engine:** Godot Engine 4.7.2 (Vulkan Forward+ Rendering Driver)  
**Scripting:** GDScript 2.0 (Strict Typing & Signal-Driven Architecture)  
**3D Modeling / DCC:** Blender 4.2 LTS / Procedural CSG & SurfaceTool Subsystems  
**Audio Workstation:** Audacity / Engine Procedural WAV Synthesizer Subsystem  

---

## Technical Pipeline Specification (Checkpoint 4 Submission)

Our production pipeline is built around a low-friction, high-readability workflow connecting Blender 4.2 LTS and Godot 4.7.2 Forward+. 3D models (characters, mounts, siege engines, architectural settlements, and foliage) are modeled in Blender with strict low-poly budgets (under 250 triangles per character; under 350 triangles per architectural complex). Models are authored with untextured flat-shaded faceted geometry using a single unified 256×256 palette atlas or shared PBR materials locked to our official five-color palette (`Steppe Green #6B8E23`, `Wood Brown #5C4033`, `Bronze Gold #DAA520`, `Snow White #E8ECEF`, and `Deep Steel Blue #2B3A4A`). Meshes are exported via automated scripts as binary GL Transmission Format (`.glb`) files into `res://assets/models/` or procedurally constructed via GDScript's `ModelBuilder` using modular `SurfaceTool` primitives for instant in-engine iteration. In Godot, imported assets are automatically converted into reusable scenes (`.tscn`) inheriting standard material overrides with zero external dependency risks. 

To maintain strict multi-developer organization and eliminate naming collisions, our repository enforces a strict, hierarchical `snake_case` folder and file convention:
- **`res://scenes/`**: Packed scenes segregated by functional domains:
  - `scenes/main_menu/` (`main_menu.tscn`, `diorama.tscn`)
  - `scenes/campaign/` (`campaign_view.tscn`, `campaign_map.tscn`)
  - `scenes/combat/` (`tactical_battle.tscn`, `arena_ground.tscn`)
- **`res://scripts/`**: All logic files organized into core modular systems:
  - `scripts/core/` (`game_manager.gd`, `campaign_controller.gd`, `palette.gd`)
  - `scripts/map/` (`campaign_map_3d.gd`, `province_mesh_3d.gd`)
  - `scripts/combat/` (`tactical_battle.gd`, `combat_ai.gd`)
  - `scripts/camera/` (`strategic_camera.gd`)
  - `scripts/visuals/` (`model_builder.gd`, `movement_path_3d.gd`, `fx_manager.gd`)
  - `scripts/audio/` (`audio_manager.gd`)
  - `scripts/ui/` (`campaign_hud.gd`, `main_menu.gd`)
  - `scripts/tests/` (`test_godot_gameplay.gd`, `capture_screenshots.gd`)
- **Prefix Standards**: All node identifiers and variables adhere to explicit prefixes: `btn_` for UI buttons, `lbl_` for text labels, `p_` for province data structures, `sq_` for combat squads, `mat_` for spatial materials, and `fx_` for visual feedback emitters. 

Every commit undergoes automated headless verification (`godot --headless --script res://scripts/tests/test_godot_gameplay.gd`) before merge to guarantee regression-free production.
