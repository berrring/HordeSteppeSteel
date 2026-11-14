# Roblox campaign

## Open in Studio

The native [HordeSteppeSteel.rbxm](HordeSteppeSteel.rbxm) package contains the Roblox campaign, the refined assets, and the original art showcase. Import it into **Workspace in a clean Baseplate** using Explorer's **Insert from File**. In the Studio Command Bar, with Play stopped, run:

```lua
print(require(workspace.HordeCampaignPackage.InstallAsPlace)())
```

The installer checks for naming conflicts before moving any instances. Save the resulting place as a Roblox place file, then press **Play**. If you are using the original edited Place1, the campaign is already installed there.

## Play

- Click a unit or city to inspect it. Teal marks reachable tiles and red marks enemies in attack range. Hover a reachable tile to preview the path.
- Use WASD or right drag to pan, the wheel to zoom, Q and E to rotate, and F to center the camera on the selection.
- Sarai starts with a horse archer, light cavalry, and infantry. Click Sarai to switch between the unit and city panel. Spend Gold, Food, and Wood to recruit and construct.
- End the turn to let Rus act. To capture a settlement, clear its garrison and march onto its tile. Capturing either capital ends the campaign.
- Save a checkpoint from the pause menu and restore it in the same running server. Checkpoints are lost when the server closes. There is no DataStore persistence.

## Explorer and source

| Explorer location | Responsibility |
| --- | --- |
| `ReplicatedStorage/HordeShared` | Palette, factions, unit and building data, hex pathfinding, command remote |
| `ServerScriptService/HordeServer` | Authoritative rules, AI, renderer, session and checkpoint management |
| `StarterPlayer/StarterPlayerScripts/HordeClient` | Camera, selection, setup, HUD, city management, result screens |
| `ServerStorage/HordeAssets` | Reusable copies of refined models |
| `Workspace/HordeWorld` | Generated board and runtime visuals during play |

`src/` mirrors script locations. The visual assets and RemoteFunction are part of the bundled model, not the Luau source mirror.

## Verification and limits

Run the code in `tests/MatchSmoke.luau` in the Studio **Server** Command Bar during Play to exercise the authoritative rules. The smoke checks cover all three sizes across nine seeds, starts, movement and rejection, combat and destruction, economy, recruitment, construction, capture, both capital outcomes, snapshot isolation, and repeated AI turns.

In the live Studio client, the new-game flow, a 196-tile board, selection and movement, recruitment, farm construction, End Turn, AI capture of Sarai, the defeat screen, and checkpoint restoration were exercised. Capital victory was checked at the rules level. A full live victory run, long-session profiling, and other device sizes have not been verified.

This slice targets one commander per server. Mongol models move by pivot interpolation; Rus art is temporary. Skeletal animation, full faction campaigns, and persistent saves are future work.
