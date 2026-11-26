# Horde: Steppe & Steel

Horde is Team Arsenal's turn-based strategy game set in medieval Eurasia. **Roblox Studio** is the current engine. In Checkpoint 1, the player commands the Mongol Khanate against the Rus AI on the original twelve-province road network.

## Play

1. Sign in to GitHub with repository access if prompted. Select **Code → Download ZIP** on `main`, then extract the archive. [Download the main branch ZIP](https://github.com/berrring/HordeSteppeSteel/archive/refs/heads/main.zip)
2. In the current Roblox Studio desktop app, sign in if prompted. Choose **File → Open from File** and open the extracted [Roblox/HordeSteppeSteel.rbxl](Roblox/HordeSteppeSteel.rbxl). The place includes the client, server, GUI code, remotes and portable art.
3. Press **Play**, then choose **New Campaign → Start Campaign**. The file plays locally in Studio without publishing or installing development tooling.
4. Select an army badge or its 3D model. Click a connected province to march or a neighboring enemy army to fight. Each army can act once per turn. Click **End Turn** to run the Rus phase and start the next Mongol turn.
5. Pan with WASD or right drag, zoom with the mouse wheel, rotate with Q/E, and focus with F. The pause menu can save and restore a checkpoint during the same Studio Play session.

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

The match supports one commander per server. The portable campaign uses native adaptations of the original Mongol models and distinct Rus timber settlements. Opaque historical meshes remain in the preserved gallery and can produce Studio warnings. The active map does not depend on those references. Peer playtest and individual signoff remain pending.

- [Studio setup and script locations](Roblox/README.md)
- [Final acceptance matrix](CHECKPOINT_1_FINAL_REPORT.md)
- [Final Studio checklist](Roblox/docs/CHECKPOINT_1_MANUAL_TESTS.md)
- [Asset inventory](Roblox/docs/Checkpoint1-Assets.md)
- [One-minute demonstration](Roblox/docs/Checkpoint1-Demo.md)
- [Contribution evidence](TEAM_CONTRIBUTIONS_CHECKPOINT_1.md)
- [Individual defense guide](CHECKPOINT_1_TEAM_DEFENSE_GUIDE.md)
- [Architecture decisions](DECISION_LOG.md)
- [AI transparency log](AI_TRANSPARENCY.md)
- [Archived Godot rules](legacy/godot-reference/README.md)

The retired Python prototype is available in Git history at `6076eca`.
