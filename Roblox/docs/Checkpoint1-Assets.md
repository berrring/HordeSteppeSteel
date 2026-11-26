# Checkpoint 1 asset inventory

The original workspace showcase, refined pack, benchmark and backups are preserved. The 13 original deployment models are held in `ServerStorage.HordeAssets` and came from the refined pack. The older `Roblox/HordeSteppeSteel.rbxm` also preserves the asset collection and the earlier gameplay slice.

The original Horse Archer was cloned into the live scene as a control. Studio reported 40 opaque MeshParts and replicated the model hierarchy, but the horse was invisible in the rendered close-up. Roblox rejected editable conversion of the opaque mesh. `CampaignArt.luau` creates portable equivalents with native geometry, using the source transforms, bounds, materials and colors, and retains available original native parts. All playable equivalents are anchored. Raycasts use separate queryable selection bounds on armies and settlements.

| Asset | Original and current template path, relative to HordeAssets | Campaign usage and verification |
| --- | --- | --- |
| Horse Archer | `Units/Mongol_HorseArcher` | U1 in Sarai. Portable miniature observed at close zoom. |
| Light Cavalry | `Units/Mongol_LightCavalry` | U2 in Urgench. Moves to Kipchak in the Studio opening. |
| Heavy Cavalry | `Units/Mongol_HeavyCavalry` | Runtime roster template and presentation regression check. Recruitment is outside this milestone. |
| Infantry | `Units/Mongol_Infantry` | Mongol roster template and presentation regression check. Starting Rus infantry has its own miniature. |
| Spearman | `Units/Mongol_Spearman` | Mongol roster template and presentation regression check. Moscow uses a separate Rus spearman. |
| Yurt | `Buildings/Mongol_Yurt` | Neutral camps and captured settlements. |
| Capital Yurt | `Buildings/Mongol_CapitalYurt` | Sarai's capital ger. Visible in the close-up. |
| Fortress | `Buildings/Mongol_Fortress` | Decorative frontier palisade. It adds no province, road or gameplay bonus. |
| Banner Pole | `Buildings/Mongol_BannerPole` | Mongol settlement standards. |
| Pine | `Environment/Steppe_Tree_Pine` | Northern stands and forest province props. |
| Birch | `Environment/Steppe_Tree_Broadleaf` | Sparse broadleaf stands. The original is catalogued under Broadleaf. |
| Rock | `Environment/Steppe_Rock` | Hill provinces and regional ridges. |
| Grass Tile | `Environment/Steppe_GrassTile` | Terrain cuts below the province platforms. |

Rus settlements use native timber halls and a watch post at Novgorod. Rus infantry and spearmen keep axes or spears, pointed helmets, timber shields and crimson accents. The example assets use the established steel, gold, snow, wood and steppe palette.

The native geometry simplifies details that were originally grouped into individual mesh objects. A fully exact reproduction requires the original editable source meshes or authorized portable asset IDs. The preserved showcase can still show warnings when Studio attempts to load legacy references.
