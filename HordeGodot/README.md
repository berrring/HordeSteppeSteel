# Horde: Steppe and Steel — Godot 4 3D Edition

A stylized, miniature-scale low-poly 3D grand strategy game set in medieval Eurasia, built with **Godot 4.7.2** and **GDScript**.

---

## 🌟 Visual & Design Direction
Inspired by the clean, readable aesthetic of tabletop miniature worlds and games like *The Battle of Polytopia*:
- **3D World & Diorama**: Elevated three-quarter isometric camera with smooth WASD/arrow pan and wheel zoom.
- **Stylized Historical Factions**:
  - **Mongol Khanate (The Golden Horde)**: Yurts (Ger), Khan's command tents with Töno smoke rings, campfires, horse hitching posts, Nine White Banners / Tug, mounted Horse Archers with composite recurve bows and leather armor, Armored Cataphract Heavy Cavalry with barded warhorses and lances.
  - **Rus' Principalities**: Log palisades, corner watchtowers with hipped roofs, Boyar wooden halls, wooden churches with onion domes and gold crosses, Druzhina footmen with kite shields and battle axes, heavy spearmen with 2-meter pikes and round shields.
  - **Seljuk Sultanate**: Sandstone block compounds, turquoise/cobalt glazed domes, slender minarets, and siege engines.
  - **Khwarazmshah Dynasty**: Mudbrick caravanserai ramparts, emerald domes, and desert garrisons.
- **Cohesive Low-Poly Terrain**:
  - 12 distinct territorial provinces spanning Steppe grasslands, northern birch/pine forests, arid silk road plateaus, and rocky mountain foothills.
  - Natural winding river with glossy reflective water.
  - 3D dirt roads physically linking adjacent provinces.
  - Dynamic 3D attack and movement path beams (`MovementPath3D`) showing route lines and pulsing markers.
  - Environment details: Steppe Pine trees, Rus' White Birch trees, Broadleaf Oaks, rock clusters, pastures, and farm plots.

---

## 🔊 Audio Feedback System
Equipped with a built-in procedural 16-bit 44.1 kHz PCM audio synthesizer (`AudioSynth` & `AudioManager`):
- **War Horn**: Low resonant brass-style call signaling army mobilization and attacks.
- **War Drum**: Low-frequency percussion rumble on turns and marching.
- **Weapon & Combat SFX**: Arrow volleys, metallic sword clangs, wooden shield blocks, and galloping cavalry hooves.
- **Economic Feedback**: Anvil strikes for recruitment, hammer knocks for construction, UI clicks and error buzzes.
- **Atmospheric Ambience**: Continuous wind sweeping across the Eurasian steppe.
- **Original Music**: D-minor pentatonic medieval steppe melody played by procedural acoustic instruments.
- **Full Audio Controls**: Real-time Master, Music, and SFX volume sliders accessible via the Pause / Settings menu (`ESC`).

---

## ⚔ Tactical 3D Combat System
When armies clash, players can engage in an interactive 3D tactical battle (`tactical_battle.tscn`):
- **3D Battle Arena**: High-angle SubViewport displaying attacker squads on the left facing defender squads on the right on an elevated circular field.
- **Command Card & Unit Details**: View unit role, warrior count, HP bar, attack/defense stats, and tactical advice.
- **Tactical Options**:
  - **Attack**: Strike target enemy squad with animated lunge/arrows, sound effects, floating damage numbers, and casualty feedback.
  - **Defend / Brace**: Assume defensive posture (+50% defense until next turn).
  - **Auto-Resolve**: Instantly simulate the remaining battle rounds using statistical modifiers.
  - **Retreat**: Pull back survivors to prevent complete army annihilation.
- **Battle Report**: Summary overlay detailing surviving warriors, casualties sustained, and captured territory.

---

## 🎮 How to Launch

### Option 1: Quick Launch
Double-click `run_game.bat` inside `HordeGodot/`.

### Option 2: Command Line
```cmd
"C:\Users\user\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe" --path C:\Users\user\Desktop\HordeSteppeSteel\HordeGodot
```

### Option 3: Run Automated Test Suite (58 Tests)
```cmd
"C:\Users\user\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe" --headless --path C:\Users\user\Desktop\HordeSteppeSteel\HordeGodot --script "res://scripts/tests/test_godot_gameplay.gd"
```
Or double-click `run_tests.bat`.

---

## 🕹 Camera & Controls

| Action | Control |
|---|---|
| **Pan Camera** | `W, A, S, D` or `Arrow Keys` |
| **Mouse Drag Pan** | Hold **Right Mouse Button** and drag |
| **Zoom View** | **Mouse Scroll Wheel** or `Q` (Out) / `E` (In) |
| **Select Province** | **Left Click** on any 3D province plateau |
| **Attack / March** | Select your province $\rightarrow$ Click adjacent enemy/friendly province $\rightarrow$ Confirm **Launch Attack / March** |
| **Tactical Combat** | Click enemy squads to target $\rightarrow$ Press **ATTACK** or **DEFEND** |
| **Recruit Warriors** | Select your province $\rightarrow$ Choose unit in Left Panel |
| **Construct Buildings**| Select your province $\rightarrow$ Build Palisade (+10 Def), Pasture (+40 Food), or Market (+50 Gold) |
| **End Turn** | Click **⚔ END TURN** (Bottom Right) |
| **Pause / Settings** | Press `ESC` or click **Settings** (Master, Music, SFX sliders, Fullscreen toggle) |
| **Save / Load** | **Save** and **Load** buttons in the top bar (`user://savegame.json`) |

---

## ⚔ Strategic Gameplay Loop
1. **Turn Economy**: Each turn, provinces yield **Gold**, **Food**, and **Wood**.
2. **Recruitment**: Spend Gold and Food to recruit Horse Archers, Light Cavalry, Heavy Cavalry, Infantry, Spearmen, or Siege Engines into your province garrisons.
3. **Construction**: Spend Wood to build defensive timber palisades or economic infrastructure.
4. **Combat Resolution**: Choose between tactical 3D squad battles or quick strategic auto-resolution. Capturing a province updates its 3D borders, visual banners, and income.
5. **AI Turns**: Rival rulers collect taxes, recruit garrisons at their capitals, and launch military offensives against weaker borders.
6. **Victory / Defeat**:
   - **Victory**: Control 10 or more provinces, or defeat all 3 rival factions.
   - **Defeat**: Lose all your territories and armies, or exceed 60 turns.

---

## 📁 Project Architecture
```
HordeGodot/
├── project.godot                     # Project config, Autoloads, Display & Inputs
├── icon.svg                          # Game icon
├── run_game.bat                      # One-click launcher
├── run_tests.bat                     # Test runner
├── screenshots/                      # Captured runtime screenshots
│   ├── main_menu.png
│   ├── campaign_map.png
│   ├── campaign_selection.png
│   └── tactical_battle.png
├── scripts/
│   ├── core/
│   │   ├── audio_synth.gd            # Procedural 16-bit 44.1kHz audio generator (SFX, ambient, music)
│   │   ├── audio_manager.gd          # Autoload audio singleton: volume channels, SFX pooling
│   │   ├── game_manager.gd           # Autoload singleton: factions, provinces, simulation, AI, battle, save/load
│   │   └── campaign_controller.gd    # 3D campaign scene controller, lighting, environment, signal routing
│   ├── combat/
│   │   └── tactical_battle.gd        # Interactive 3D tactical battle system, squad management, animations
│   ├── visuals/
│   │   ├── model_builder.gd          # Procedural low-poly 3D asset generator (units, yurts, forts, trees, rocks)
│   │   ├── movement_path_3d.gd       # 3D attack and movement path beams & destination markers
│   │   └── fx_manager.gd             # Procedural floating combat text & dust puff particles
│   ├── map/
│   │   ├── province_visual.gd        # Interactive 3D province node, collision, highlight rings, settlement, 3D labels
│   │   └── campaign_map_3d.gd        # Map manager, road mesh generator, river mesh, selection logic
│   ├── camera/
│   │   └── strategic_camera.gd       # 3/4 isometric camera with smooth pan, zoom clamp, drag pan
│   ├── ui/
│   │   ├── campaign_hud.gd           # CanvasLayer HUD, top bar, province/army panel, recruit/build, modals
│   │   └── main_menu.gd              # 3D diorama background, turntable camera, menu buttons, settings modal
│   └── tests/
│       ├── test_godot_gameplay.gd    # 58-test automated verification suite
│       └── capture_screenshots.gd    # Runtime viewport screenshot capture tool
└── scenes/
    ├── main_menu/
    │   └── main_menu.tscn            # Main menu scene
    ├── campaign/
    │   └── campaign_view.tscn        # Main 3D campaign scene
    └── combat/
        └── tactical_battle.tscn      # 3D tactical combat arena scene
```

---

## 🧪 Verification Status
- **Godot 4 Verification Suite**: **58 / 58 PASSING (100%)**
- **Python Prototype Test Suite**: **40 / 40 PASSING (100%)**
- **Live Engine Execution**: Verified on Godot 4.7.2 official (Vulkan Forward+, NVIDIA RTX 4050 GPU).
