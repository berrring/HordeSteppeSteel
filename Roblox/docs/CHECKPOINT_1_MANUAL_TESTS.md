# Checkpoint 1 — final Studio manual tests

**Date:** 2026-11-26. **Tester:** Codex operating the real Studio client through MCP, with separate live server checks. **Precondition:** open a fresh copy of `Roblox/HordeSteppeSteel.rbxl`, press Play and start at the main menu. All results below require the peer playtest recorded separately at the end.

| ID | Preconditions and action | Expected result | Actual result and evidence | Status |
| --- | --- | --- | --- | --- |
| MT-01 | No campaign active. Click New Campaign, then Start Campaign. | Turn 1, five armies and resources 34/27/22. | The HUD displayed Mongol Turn 1, and server Output logged `provinces=12 armies=5`. | PASS |
| MT-02 | Campaign running. Inspect the map and compare the spatial network with the server graph. | Exactly 12 distinct connected provinces and 18 legal roads. | Studio showed all 12 labels at the default desktop camera. The presentation and rules suites checked 18 matched roads and reciprocal connectivity. | PASS |
| MT-03 | Opening state. Inspect both factions, settlements and model library in Play. | Faction miniatures and buildings appear, including the original model geometry. | The preserved source library has 13 models. Portable adaptations and native Rus pieces rendered. The exact opaque Horse Archer control did not render, and the exact opaque geometry needs separate source assets. | FAIL |
| MT-04 | Turn 1. Click LC 17 in Urgench. | Light Cavalry selected, with legal roads available. | The inspector was titled Light Cavalry and the player subsequently marched along the highlighted route to Kipchak. | PASS |
| MT-05 | U2 selected in Urgench. Click Kipchak Steppe. | U2 moves to Kipchak and spends its order. | The live UI and returned state placed U2 at `kipchak`. Output logged the march. | PASS |
| MT-06 | Fresh turn 1 with U2 selected. Click Tabriz. | Command rejected and selection unchanged. | The HUD displayed “No road connects these provinces.” and Light Cavalry stayed selected at Urgench. Returning to the main menu cleared the message. | PASS |
| MT-07 | U1 fresh in Sarai. Click HA 15 then the IN 5 marker in Kiev. | Valid combat updates casualties and captures the province. | U3 routed, U1 reached Kiev with 13 strength before Rus acted, and Kiev became Mongol. | PASS |
| MT-08 | End of player orders. Click End Turn. | Rus phase starts and simultaneous requests are rejected. | The UI advanced and the live duplicate request was rejected while the server reported the Rus phase. | PASS |
| MT-09 | Observe the first Rus phase after capture. | AI takes legal action and returns control with income. | Turn 2 began with one Rus pass and Mongol gold 42, food 35 and wood 25. The Rus spear unit counterattacked Kiev. | PASS |
| MT-10 | Continue from the opening, move U2 along the eastern reserve route, then return to the menu and restart. | Five or more complete rounds, coherent occupancy and exactly one fresh world. | The live Command interface completed six rounds to turn 7 with U2 in Zhongdu. The UI restart rebuilt one world, 12 provinces and five opening armies. The initial test route ended in a legitimate Rus victory on turn 5 and was rerun with an alternate route. | PASS |

## Automated and supporting runs

Run these files from the **Server** Command Bar in Studio Play. Start the live campaign before running the presentation check.

- `Roblox/tests/Checkpoint1Rules.luau` returned `true`. It verifies topology, legal and illegal orders, damage, capture, validation, AI, income and reset.
- `Roblox/tests/Checkpoint1Presentation.luau` returned `13`. It verifies the full asset adaptation inventory, road and province counts, bridge, Rus and Mongol buildings, and selectable army volumes.
- `Roblox/tests/MatchSmoke.luau` returned 19 checks, nine seeded legacy boards, six stress cycles and 47 AI actions. This is a regression test for the prior Roblox slice. Current map acceptance uses the two Checkpoint 1 suites.
- The separate live command check rejected an enemy-owned move, injected gold, an overlapping End Turn and a stale turn ticket.
- The final place was reopened from a separate file copy. All 16 scripts matched the repository sources with file-boundary whitespace and line endings normalized.

## Teammate verification

Each feature needs a real teammate other than its owner to play it and link the result to a decision or AI log entry. Record reviewer, role, date, build Git SHA, test IDs, observed result and follow-up. Current peer review is pending for all four team roles. The desktop layout and simulated landscapes at 1280×720 and 800×450 were inspected. The HUD and End Turn remained available. Some northwestern labels overlapped at 800×450 and can be read after panning or zooming. Physical mobile play and another Roblox account remain pending.
