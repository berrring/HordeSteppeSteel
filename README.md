# Horde: Steppe and Steel

**Horde: Steppe & Steel** is a stylized low-poly 3D turn-based grand strategy game developed by Team Arsenal, set in medieval Eurasia (Steppe vs Steel).

Lead one of 6 historical civilizations to dominance across the Great Steppe through territorial conquest, fortification development, economic administration, and combined-arms warfare.

---

## 🎮 Playable Civilizations

When starting a New Campaign, you can choose from 6 distinct historical factions, each with unique bonuses, architectural identity, military doctrines, starting territories, and lore:

1. **🐎 Mongol Khanate (The Golden Horde)**
   - *Khagan Genghis Khan* • Capital: *Sarai*
   - Traits: +15% Cavalry Attack, +20% Movement Speed, Master Horse Archers, Nomadic Camps.
2. **🛡 Rus' Principalities (Ancient Rus')**
   - *Grand Prince of Novgorod & Kiev* • Capital: *Novgorod*
   - Traits: +30% Fortification Defense, +50% Timber Income, Druzhina Heavy Axemen, Winter Attrition resistance.
3. **🏹 Cumans / Kipchaks (The Wild Field)**
   - *Khan of the Wild Field* • Capital: *Bukhara*
   - Traits: +25% Steppe Movement, -20% Light Cavalry recruitment costs, Nomad Swarm doctrine.
4. **🦅 Byzantine Empire (Eastern Rome)**
   - *Strategos of Cherson* • Capital: *Urgench*
   - Traits: +20% Physical Armor & Defense, +25% Basilica trade & Fortifications, Armored Cataphracts & Varangian Guards.
5. **⚔ Seljuk Sultanate (Great Seljuks)**
   - *Sultan of Rum & Khorasan* • Capital: *Tabriz*
   - Traits: -25% Siege Engine & Trebuchet costs, +10% Combined-Arms Attack/Defense, Heavy Trebuchets.
6. **👑 Khwarazmshah Dynasty (Silk Road Empire)**
   - *Shahanshah of Khwarazm* • Capital: *Karakorum*
   - Traits: +25% Gold Tax & Silk Road Caravan Revenue, +10% Heavy Cavalry Attack/Armor, Royal Lancers.

---

## 🚀 Running the Game

### Godot 4 Low-Poly 3D Edition (Primary)
The Godot 4 game is located in the `HordeGodot` folder.
To launch directly with Godot Engine 4.7+:
```powershell
godot --path HordeGodot
```
Or open the `HordeGodot/project.godot` file inside the Godot 4 Editor.

### Running Godot Tests
```powershell
godot --headless --path HordeGodot --script res://scripts/tests/test_godot_gameplay.gd
```
*(75/75 tests passing)*

---

### Python Prototype (Preserved)
```powershell
pip install -r requirements.txt
python main.py
```
To run Python tests:
```powershell
pytest tests/ -v
```
*(40/40 tests passing)*

---

## 🗺 How to Play

### Main Menu & Civilization Selection
- Click **⚔ NEW CAMPAIGN** to open the **Civilization Selection** dossier.
- Browse the 6 historical factions to review their cultural traits, leader, quote, units, and bonuses.
- Click **⚔ EMBARK ON CAMPAIGN AS [FACTION]** to begin.
- Use **⚙ SETTINGS** to adjust Master, Music, and SFX volume sliders or toggle Fullscreen.

### Strategic Campaign Map
- **Left-click** one of your provinces (highlighted in gold ring) to inspect garrisons, recruit units, or construct stockades/pastures.
- **Left-click** an adjacent province to preview an attack vector with the 3D target beam.
- Click **⚔ LAUNCH ATTACK** to engage the defending army in 3D automated tactical combat.
- Click **⌛ END TURN** to collect province taxes, harvest resources, advance the campaign calendar (Act I to Act III), and process AI moves.
- **ESC** brings up the Pause & Strategic Audio menu.

### ⚔ Tactical 3D Combat Overlay
- **SubViewport 3D Arena** displays 3D low-poly miniature armies facing each other on a steppe plateau.
- 3D floating unit badges indicate warrior strength.
- Automated round exchanges with dynamic player interaction:
  - **⚔ STRIKE NOW**: Order squads to attack immediately.
  - **🛡 BRACE (+30% Def)**: Take a defensive posture to minimize incoming damage.
  - **⚡ SKIP TO REPORT**: Autoresolve combat instantly.
  - **🏳 TACTICAL RETREAT**: Withdraw safely without losing the entire force.

---

## 🏆 Victory & Defeat Conditions
- **Victory**: Conquer **10 or more provinces** or completely eliminate all rival factions.
- **Defeat**: Lose all your provinces and field armies, or fail to achieve victory within 60 seasonal turns.

---

## 🎨 Official Five-Color Palette & Team Arsenal Canon
- **Steppe Green / Olive (`#6B8E23`)**: Dominant terrain and steppe identity
- **Wood Brown (`#5C4033`)**: Timber, yurts, palisades, and natural materials
- **Bronze Gold (`#DAA520`)**: UI accents, currency, selection rings
- **Snow White (`#E8ECEF`)**: Snow, northern frontiers, typography
- **Deep Steel Blue (`#2B3A4A`)**: Armor, dark UI backing, and shadows
