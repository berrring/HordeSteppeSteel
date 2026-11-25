# Horde: Steppe & Steel

Horde is Team Arsenal's turn-based strategy game set in medieval Eurasia. **Roblox Studio** is the current engine. In Checkpoint 1, the player commands the Mongol Khanate against the Rus AI on the original twelve-province road network.

## Play

1. Open [Place1-Checkpoint1.rbxl](Roblox/Place1-Checkpoint1.rbxl) directly in Roblox Studio.
2. Press **Play**, then choose **New Campaign → Start Campaign**.
3. Select a gold army marker. Click a connected province to march or a neighboring enemy army to fight. Each army can act once per turn. Click **End Turn** to hand control to Rus and collect the next Mongol turn's income.

## Team

These responsibilities are the provisional ownership listed in prior project materials. Team confirmation is pending.

| Team member | Provisional responsibility |
| --- | --- |
| Aziret | Core gameplay loop and campaign controller |
| Ayaz | Economy and UI |
| Iskender | Combat and enemy AI |
| Alen | Map and visuals |

## Checkpoint 1 status

The Studio build supports province inspection, server-validated orders, deterministic combat and capture, Rus turns, income, fresh campaigns, and session checkpoints. The single campaign uses two factions. Extra maps and civilizations, recruitment and construction, advanced Rus strategy, and persistent saves are outside this checkpoint.

The match is single commander per server. The playable board uses native army miniatures and 2D markers because some older runtime mesh references do not reload reliably. The art library and original Mongol showcase remain in the place.

- [Studio setup and script locations](Roblox/README.md)
- [Checkpoint verification and demo](Roblox/docs)
- [Architecture decisions](DECISION_LOG.md)
- [AI transparency log](AI_TRANSPARENCY.md)
- [Archived Godot rules](legacy/godot-reference/README.md)

The retired Python prototype is available in Git history at `6076eca`.
