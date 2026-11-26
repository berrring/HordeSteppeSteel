# Team Arsenal contribution evidence — Checkpoint 1

The evidence below verifies commit metadata and file diffs. Personal implementation, outside-Git collaboration and peer approval require each student's own confirmation. Dates are the recorded Git author dates. Assigned roles come from the blueprint and the archived project README. Historical Godot and Roblox work are presented separately.

| Team member | Assigned role | Verified repository record | Remaining responsibility |
| --- | --- | --- | --- |
| Aziret | Core loop and campaign controller | Godot scenario isolation and tests (`214af15`, `23cc7a2`). Early Roblox match boot, networking and 18-cycle test diff (`e51fd2e`, `8b04f23`, `842d8cc`). | Independently play and explain initialization and turn progression. Confirm migration decision ownership. |
| Ayaz | Economy and UI | Godot EconomyManager, campaign HUD, theme and tests (`02cba0c`). Roblox income, UI components, HUD and selection (`690bc1a`, `bf2a3d8`, `9c5f903`, `bec2d59`). | Independently verify income, HUD and smaller screens. Confirm personal versus AI-assisted portions. |
| Iskender | Combat and enemy AI | Godot calculator and counterattack tests (`265caa1`, `6561d07`, `bce7482`, `2442393`). Roblox damage, combat tests and AI (`60eaba6`, `f130f34`, `e398127`, `8f873b3`). | Independently run and explain combat, the Rus phase and objectives. |
| Alen | Map and visuals | Early Roblox terrain, faction models, camera and package files (`16b67e8`, `a3fc3a8`, `4e3923b`, `cb61c77`, `758c368`). Godot visual ownership is documented and Codex-authored Godot visual work is separate. | Independently play the portable build, inspect visual readability and confirm asset provenance. |
| Codex / Antigravity assistance | Recovery and audit | Codex-authored visual work on the Godot branch (`dcffde5`, `8a48e3f`), Roblox slice and canonical restoration (`09d3cd0`–`21ca5a4`, `6076eca`), and current portable build. Antigravity supplied a local audit of the earlier build. | Human peer verification and approval of attribution remain open. |

## Git statistics

Method: `git log --remotes --tags --no-merges --format=...` before recovery commits, counting unique reachable commits by displayed author name and unique relevant paths touched. Counts include docs and engine source, excluding tracked media/binary packages and the retired Python prototype from file counts. Commit counts and paths measure repository activity rather than effort. Commit and committer identities are separate. For example, Codex authored Godot visual changes on `origin/alen` and Aziret is recorded as committer for those revisions. `ec4a673` records Aziret as author and committer of the slice merge, while `9b37644`, `92af83b`, `6a1ff35`, `a5542df` and `3b275c2` record Zeckd as author and committer. GitHub CLI required sign-in for PR and review data. No PR or human approval has been inferred.

| Displayed author | Commits | Relevant paths | Recorded interval | Main historical refs sampled |
| --- | ---: | ---: | --- | --- |
| Aziret Rakhmanov | 21 | 49 | Oct 29–Nov 14, 2026 | `origin/aziret`, `origin/main`, `v0.2.0-baseline` |
| ayzsw | 11 | 42 | Nov 4–14, 2026 | `origin/ayaz`, `origin/main` |
| Zeckd | 16 | 24 | Oct 29–Nov 10, 2026 | `origin/codex/battle-calculator`, `origin/codex/rus-counterattack`, `origin/codex/tactical-battle-results`, `origin/codex/playable-campaign`, `origin/main` |
| Alen | 9 | 4 | Nov 6–14, 2026 | `origin/roblox-playable-slice`, `origin/main` |
| Codex | 4 | 29 | Nov 4–25, 2026 | `origin/alen`, `origin/main` |

## Attribution and testing confidence

- **Aziret — VERIFIED** for the recorded scenario isolation diff, Godot test files and early Roblox server and test files (`214af15`, `23cc7a2`, `8a70b54`, `842d8cc`, `8b04f23`). The archived README documents `berrring` as Aziret. Human test execution and authorship beyond Git are **NOT VERIFIED**.
- **Ayaz — VERIFIED** for the diffs to `economy_manager.gd`, `campaign_hud.gd`, `test_economy_validation.gd`, early Roblox `Config.luau`, `Match.luau`, `UISkin.luau` and client files. The archive links `ayzsw` to Ayaz and the AI log **DOCUMENTS** assistance on economy and HUD. Human execution and personal authorship of every line are **NOT VERIFIED**.
- **Iskender — VERIFIED** for the `Zeckd` revisions to the Godot combat calculator, tactical result tests and counterattack code, and the early Roblox `Match.luau`, `AI.luau` and `MatchSmoke.luau` diffs. The alias is documented in the archive. Branch names and attached test code alone leave individual AI assistance and human test execution **NOT VERIFIED**.
- **Alen — VERIFIED** for the early Roblox `Renderer.luau`, `CameraController.luau`, `Board.luau`, `AI.luau` and binary packaging commits. Godot map ownership is **DOCUMENTED**. Codex authored the sampled Godot visual branch revisions. Exact model-creation provenance within the binary and individual Godot authorship are **UNATTRIBUTED** unless corroborated.
- The current restored province graph, final interface corrections, portable art adaptation and test execution are AI-assisted recovery work. The professor's independent teammate playthrough and human confirmation of role ownership are still **NOT VERIFIED**.
