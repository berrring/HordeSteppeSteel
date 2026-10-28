# Horde: Steppe & Steel — Vertical Slice Asset List (5-Minute Gameplay)

**Project:** Horde: Steppe & Steel  
**Team:** Arsenal  
**Engine:** Godot 4.7.2 Forward+ / Blender 4.x / GDScript  
**Milestone:** Midterm Vertical Slice

---

## 1. Characters & Military Squads (3D Low-Poly Units)

| ID | Asset Name | Description & Visual Silhouette | Polycount | Texture / Material | Status |
|---|---|---|---|---|---|
| **CHR-01** | Mongol Horse Archer | Mounted composite bowman on steppe pony, quiver, fur cap | ~140 | Palette Ochre/Bronze Gold (`#DAA520`) | **Ready (Готово)** |
| **CHR-02** | Armored Heavy Cavalry | Barded warhorse with lance, iron spangenhelm, mail coat | ~190 | Deep Steel Blue & Faction Accent | **Ready (Готово)** |
| **CHR-03** | Rus' Druzhina Infantry | Footman with heavy kite shield, battle axe, pointed helm | ~110 | Rus' Crimson (`#9E2A2B`) & Steel | **Ready (Готово)** |
| **CHR-04** | Heavy Spearman | Professional phalanx footman, 2.2m spear, round shield | ~90 | Imperial Purple / White | **Ready (Готово)** |
| **CHR-05** | Traction Trebuchet | Timber siege engine on 4-wheel carriage, counterweight beam | ~85 | Wood Brown (`#5C4033`) & Iron fittings | **Ready (Готово)** |
| **CHR-06** | Light Nomad Cavalry | Unarmored outrider with curved saber and leather tunic | ~130 | Steppe Turquoise (`#20B2AA`) | **In Progress (В процессе)** |
| **CHR-07** | Faction Standard Bearer | Unit banner holder carrying historical horse-tail tug/standard | ~120 | Faction Silk & Polished Brass | **In Progress (В процессе)** |
| **CHR-08** | Peasant Militia Garrison | Conscripted levies with hunting spears and bucklers | ~80 | Natural linen & weathered wood | **Not Started (Еще не начато)** |

---

## 2. Settlements, Architecture & Fortifications

| ID | Asset Name | Description & Strategic Role | Polycount | Texture / Material | Status |
|---|---|---|---|---|---|
| **BLD-01** | Khan Yurt Headquarters | Large white felt ger with carved red timber door & horse banner | ~120 | Felt White, Wood Brown, Gold trim | **Ready (Готово)** |
| **BLD-02** | Rus' Kremlin Fortress | Timber citadel with 4 corner watchtowers, gate, church dome | ~240 | Weathered Timber & Gilded Brass | **Ready (Готово)** |
| **BLD-03** | Seljuk Oasis Citadel | Terracotta compound with minaret tower, domed roof | ~180 | Sandstone Ochre & Persian Blue | **Ready (Готово)** |
| **BLD-04** | Byzantine Frontier Basilica | Stone basilica with barrel vault, tiled roof, courtyard wall | ~210 | Weathered Ashlar & Imperial Purple | **Ready (Готово)** |
| **BLD-05** | Wooden Palisade Rampart | Sharpened log defense stockade increasing province defense | ~90 | Rough Pine Timber (`#5C4033`) | **Ready (Готово)** |
| **BLD-06** | Nomadic Pasture & Enclosure | Post-and-rail livestock pen boosting regional food harvest | ~75 | Weathered Timber & Pasture Grass | **Ready (Готово)** |
| **BLD-07** | Caravan Market Bazaar | Open-air trading stalls with fabric canopies boosting gold | ~110 | Ochre Canvas & Timber poles | **Ready (Готово)** |
| **BLD-08** | Military Barracks | Training grounds with weapon racks and archery butts | ~130 | Heavy Timber & Stone foundations | **Ready (Готово)** |
| **BLD-09** | Stone Citadel (Upgrade) | Late-game heavy stone fortification for regional capitals | ~320 | Carved Gray Stone & Iron portcullis | **In Progress (В процессе)** |

---

## 3. Environment, Terrain & World Props

| ID | Asset Name | Description & Biome Role | Polycount | Texture / Material | Status |
|---|---|---|---|---|---|
| **ENV-01** | Steppe Pine Tree | Three-tiered stylized evergreen tree for boreal/steppe borders | ~45 | Steppe Green (`#6B8E23`) & Bark | **Ready (Готово)** |
| **ENV-02** | Rus' Birch Tree | White-barked slender tree with soft rounded foliage canopy | ~40 | Snow White trunk with black notches | **Ready (Готово)** |
| **ENV-03** | Broadleaf Oak Tree | Sturdy forest tree with clustered volumetric canopy | ~60 | Deep Forest Green & Dark Timber | **Ready (Готово)** |
| **ENV-04** | Granite Boulders & Rocks | Faceted natural stone cluster for mountain and river barriers | ~35 | Cool Gray Stone (`#788696`) | **Ready (Готово)** |
| **ENV-05** | Dynamic Winding River | Segmented procedural water channel with specular shorelines | ~120 | Shallow Turquoise Water (`#3A6B88`) | **Ready (Готово)** |
| **ENV-06** | Dirt Road Networks | Winding interconnecting trade and military movement paths | ~90 | Packed Steppe Earth (`#8B7355`) | **Ready (Готово)** |
| **ENV-07** | Province Elevation Steppes | Layered polygonal plateaus distinguishing high ground | ~160 | Steppe Grass & Exposed Bedrock | **Ready (Готово)** |
| **ENV-08** | Winter Snow Overlays | Seasonal dynamic white dusting for northern winter turns | Shader | Snow White (`#E8ECEF`) Roughness 0.2 | **In Progress (В процессе)** |
| **ENV-09** | Steppe Shrubbery & Tufts | Low dry grass clumps and sagebrush for empty ground fill | ~20 | Dry Straw Olive | **Not Started (Еще не начато)** |

---

## 4. User Interface, Menus & Visual FX

| ID | Asset Name | Description & Interaction Function | Layer / Type | Status |
|---|---|---|---|---|
| **UI-01** | Strategic Top Resource Bar | Displays Faction Banner, Turn/60, Act I-III, Gold, Food, Wood | CanvasLayer (0) | **Ready (Готово)** |
| **UI-02** | Province Command Card | Left-side panel for garrison list, recruitment, construction | CanvasLayer (0) | **Ready (Готово)** |
| **UI-03** | Civilization Selection Modal | 6-faction selection cards with leader lore, quotes, traits | CanvasLayer (20) | **Ready (Готово)** |
| **UI-04** | Tactical Combat Overlay | Fullscreen 3D tactical battle view, health bars, strike card | CanvasLayer (15) | **Ready (Готово)** |
| **UI-05** | Victory / Defeat Screen | End-game campaign resolution modal with restart/exit | CanvasLayer (10) | **Ready (Готово)** |
| **UI-06** | Audio & Settings Modal | Sliders for Master, Music, SFX volume & Fullscreen toggle | CanvasLayer (25) | **Ready (Готово)** |
| **VFX-01** | 3D Attack Target Beam | Directional animated trajectory line with pulsing arrival ring | 3D Mesh / Material | **Ready (Готово)** |
| **VFX-02** | Floating Combat / Loot Text | Floating damage numbers, troop counts, resource popups | 3D Billboard Label | **Ready (Готово)** |
| **VFX-03** | Province Selection Ring | Luminous 3D gold torus ring highlighting focused province | 3D Unshaded Torus | **Ready (Готово)** |
| **VFX-04** | Weather Dust & Fog Particles | Subtle ambient steppe dust motes during Act II-III dry spells | GPUParticles3D | **In Progress (В процессе)** |

---

## 5. Audio & Sound FX (Synthesized & Acoustic Streams)

| ID | Sound Asset | Audio Description & Cue Trigger | Format | Status |
|---|---|---|---|---|
| **SND-01** | War Horn Fanfare | Resonant bronze horn signal on attack launch & battle start | 44.1kHz WAV | **Ready (Готово)** |
| **SND-02** | War Drums Cadence | Low resonant percussive pulse on turn advancement | 44.1kHz WAV | **Ready (Готово)** |
| **SND-03** | Sword Clash & Blade Impact | Sharp metallic strike SFX during melee infantry clashes | 44.1kHz WAV | **Ready (Готово)** |
| **SND-04** | Composite Bow Arrow Volley | High-frequency twang and swoosh for horse archer attacks | 44.1kHz WAV | **Ready (Готово)** |
| **SND-05** | Shield Block / Defend | Deep wooden impact thump on defensive brace action | 44.1kHz WAV | **Ready (Готово)** |
| **SND-06** | Heavy Cavalry Gallop | Rhythmic double-thud hoofbeats during cavalry charges | 44.1kHz WAV | **Ready (Готово)** |
| **SND-07** | Victory Trumpet / Defeat Cue | Major/minor chord motifs on campaign and battle finish | 44.1kHz WAV | **Ready (Готово)** |
| **SND-08** | Ambient Steppe Wind Loop | Continuous low wind atmosphere modulated by season/act | OGG Vorbis | **In Progress (В процессе)** |

---

## Summary of 5-Minute Vertical Slice Art Readiness
- **Total Assets Tracked**: 39 items
- **Ready (Готово)**: 31 items (79.5%)
- **In Progress (В процессе)**: 6 items (15.4%)
- **Not Started (Еще не начато)**: 2 items (5.1%)
- **Conclusion**: The production backlog is over 79% realized in-engine, satisfying all requirements for an immediate 5-minute playable vertical slice at the midterm defense.
