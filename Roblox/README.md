# Checkpoint 1 in Roblox Studio

Open [Place1-Checkpoint1.rbxl](Place1-Checkpoint1.rbxl) as a place in Studio. Press **Play → New Campaign → Start Campaign**. The earlier `HordeSteppeSteel.rbxm` model package is historical. It contains the prior hex prototype.

## Controls

- Click an army badge or province. Teal highlights a legal march, and red highlights a legal fight. Each army gets one order per turn.
- To capture an occupied enemy province, rout its defender and survive the counterattack. If the defender holds, the province stays with its owner.
- Use WASD or right drag to pan, the wheel to zoom, Q/E to rotate, and F to focus. Close the inspector if it covers a marker.
- Click **End Turn**. Rus acts once, then income is credited and Mongol orders reset.
- The pause menu's **Save session checkpoint** restores in the same running server. Stopping Play clears it.

## Explorer and source

| Explorer | Responsibility |
| --- | --- |
| `ReplicatedStorage > HordeShared > Provinces, Board, Config` | Province and road definitions, spatial topology, rules configuration |
| `ReplicatedStorage > HordeShared > Remotes > Command` | RemoteFunction for campaign commands and state snapshots |
| `ServerScriptService > HordeServer > GameManager, CommandPolicy` | Campaign/turn identity, player and phase gates, payload checks, session snapshots |
| `ServerScriptService > HordeServer > Match, AI, Renderer` | Campaign rules and common damage calculation, Rus decisions, native map visuals |
| `StarterPlayer > StarterPlayerScripts > HordeClient` | Campaign controller, camera, main menu, HUD, and markers |
| `Workspace > HordeWorld` | Per-match provinces, roads, armies and settlements created in Play |
| `ServerStorage > HordeBeforeCheckpoint1` | Prior UI, server and shared script groups |

The `src/` tree mirrors the place scripts and does not need a build step when opening the place. The earlier generated-grid functions are kept for historical comparison. Checkpoint 1 launches the authored map only.

## Verification and demo

- [Ten-step Studio test record](docs/Checkpoint1-Manual.md)
- [Server validation evidence](docs/Checkpoint1-Security.md)
- [One-minute demonstration directions](docs/Checkpoint1-Demo.md)
