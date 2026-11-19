# Checkpoint 1 Studio verification

Project: `Place1-Checkpoint1.rbxl`. Verification: Roblox Studio Play mode, live client and server. The opening used mouse input on the actual game controls. The extended turn and restart checks used the same Command RemoteFunction from the Studio test client.

## Manual checklist

| Test ID | Action | Expected behavior | Actual behavior | Status | Evidence |
| --- | --- | --- | --- | --- | --- |
| CP1-01 | Click **New Campaign → Start Campaign**. | Mongol play starts on turn 1 with initial resources. | The button opened the campaign, and the HUD showed **Turn 1 · Your turn**, with 34 gold, 27 food, and 22 wood. | Pass | `[CP1] match=1 turn=1 provinces=12 armies=5` |
| CP1-02 | Inspect the generated map after starting. | The board contains exactly 12 playable provinces on the authored road network. | The client saw 12 province instances and 18 roads. A server traversal reached all 12 and checked reciprocal adjacency. | Pass | `Workspace.HordeWorld.Tiles`: 12. `Province Roads`: 18. Rules check passed. |
| CP1-03 | Verify the owners and starting positions of both armies. | Sarai and Urgench begin with Mongol armies. Kiev, Moscow and Novgorod begin with Rus armies. | Initial state and army attributes matched the expected owners and locations. | Pass | Mongol U1/Sarai and U2/Urgench. Rus U3/Kiev, U4/Moscow and U5/Novgorod. |
| CP1-04 | Click the **LC 17** marker at Urgench. | The correct army opens in the inspector, and reachable routes highlight. | The inspector showed **Light Cavalry** and **One order available**. Kipchak Steppe was highlighted. | Pass | Client found `HordeSelectionLocal.Preview kipchak`. |
| CP1-05 | Click **Kipchak Steppe** with the Urgench army selected. | The army crosses the connecting road and uses its order. | U2 changed its province to `kipchak`, and the inspector showed **Order used this turn**. | Pass | `[CP1] match=1 turn=1 move: Light Cavalry marched to Kipchak Steppe.` |
| CP1-06 | Request a march from Sarai directly to Novgorod. | The server rejects the non-adjacent command and leaves the army in Sarai. | The RemoteFunction rejected the order and U1 stayed in Sarai. Separate checks also rejected an enemy-army order and a second order. | Pass | `No road connects these provinces.` U1: `sarai`. |
| CP1-07 | Select **HA 15** in Sarai, then click **IN 5** in Kiev. | The adjacent battle calculates losses and updates the armies and province. | Rus lost 5 strength and U3 was removed. Mongol lost 2 strength. U1 moved to Kiev at 13 strength and Kiev became Mongol. | Pass | `[CP1] match=1 turn=1 attack: Kiev: Mongol −2, Rus −5. Defenders routed. Province captured.` |
| CP1-08 | Click **End Turn**. | The UI enters the Rus phase and disables the End Turn button during processing. | Live polling observed server phase `rus` while the HUD button was disabled. | Pass | Phase observed: `rus`. End Turn interactable: `false` during processing. |
| CP1-09 | Wait for Rus to act and control to return. | Rus acts once, Mongol receives income, and turn 2 starts. | Moscow's Rus spearman attacked Kiev. Control returned on turn 2, with one Rus pass and resources at 42 gold, 35 food, 25 wood. | Pass | `[CP1] match=1 closed=1 rusOrders=1 rusTurns=1 next=2 phase=mongol` |
| CP1-10 | Play consecutive turns, then start another campaign in the same session. | The server advances once per End Turn, keeps occupancy consistent, and cleanly resets the board. | Played through turn 5 with four Rus passes and consistent army occupancy. Restart returned to turn 1 with one board, 12 provinces, and five initial armies. The previous campaign's ticket was rejected. | Pass | `[CP1] match=1 closed=4 rusOrders=2 rusTurns=4 next=5 phase=mongol` and `[CP1] match=2 turn=1 provinces=12 armies=5`. |

The Output contained no Checkpoint 1 script errors during the recorded run. The separate [server validation verification](Checkpoint1-Security.md) records requests that were intentionally rejected.

Supplementary check: saved a session checkpoint, moved U2, and restored the checkpoint. U2 returned to Urgench and the restored match received a new campaign ID.

To rerun the isolated engine checks, execute `Roblox/tests/Checkpoint1Rules.luau` in the **Server** Command Bar during Play. This creates a separate in-memory match. The pass line was `[CP1 RULES] topology, orders, combat, payload validation, AI, income and fresh restart passed`.

## Unverified or outside scope

Live victory through Novgorod and mobile play have not been tested. No video has been captured. Checkpoint 2 features such as recruit/build orders, strategic Rus economics, and a Rus win by taking Sarai are outside this delivery. Older gallery mesh references can fail to load. The playable board uses Studio parts and does not depend on those references.
