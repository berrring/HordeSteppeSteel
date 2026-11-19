# Checkpoint 1 implementation blueprint

The active build is the Roblox campaign. The earlier implementation blueprint described a Godot checkpoint and its historical test suites. Those counts do not describe Roblox verification. The earlier blueprint is available in Git history at `46275e2`.

| Area | Checkpoint implementation |
| --- | --- |
| Map | Twelve provinces and eighteen archived road links in `Roblox/src/ReplicatedStorage/HordeShared/Provinces.luau`. The checkpoint assigns provinces to Mongol, Rus, or neutral. |
| Rules | `Match` owns army orders, strength losses, transfers, income, and movement budgets. The checkpoint uses one order per army per faction turn. |
| Turn and command handling | `GameManager` controls the phase and one Rus action pass. `CommandPolicy` permits only declared command fields. Campaign and turn IDs reject old mutating orders. |
| Presentation | `Renderer` creates the road map and miniatures. The client draws the HUD, projected province and army markers, route highlights, and combat feedback. |
| Verification | See the [ten executed Studio checks](Roblox/docs/Checkpoint1-Manual.md) and [separate server validation evidence](Roblox/docs/Checkpoint1-Security.md). |

The archived Godot rules remain available for comparison. Recruitment, construction and a broader faction economy can be revisited after Checkpoint 1.
