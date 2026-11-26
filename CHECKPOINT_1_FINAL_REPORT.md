# Checkpoint 1 acceptance

**Date:** November 26, 2026. **Team:** Team Arsenal. **Starting revision:** `c98c562`. **Technical status:** playable local demo with a verified server campaign loop. **Academic completion:** partial. Independent teammate playtesting and exact portable original meshes remain open.

The professor's separate Checkpoint Guide file was not available in the inspected materials. Entries 1–11 and 15–19 apply the core requirements reproduced in the supplied brief and baseline audit. Entries 12–14 and 20–24 are explicit recovery or delivery requirements. Peer playtesting is also an academic completion criterion in the supplied brief.

| # | Requirement | Status | Evidence and limitations |
| ---: | --- | --- | --- |
| 1 | New Campaign | PASS | Actual Studio menu completed MT-01. `GameManager.server.luau` initialized the match. |
| 2 | 12 playable provinces | PASS | `Provinces.luau`, MT-02, 12 live instances. |
| 3 | Canonical connectivity | PASS | 18 reciprocal roads, connected traversal, shared graph and visible roads. |
| 4 | Army selection | PASS | UI selection of Urgench cavalry and Sarai archer. `Campaign.client.luau` also includes tagged 3D bounds. |
| 5 | Movement | PASS | Legal Urgench–Kipchak march, rejected Urgench–Tabriz order, retained selection. |
| 6 | Combat | PASS | Routed Kiev defender, explicit casualties, successful capture. `Match.damage` and `Match.attack`. |
| 7 | End Turn | PASS | UI action, Rus phase and duplicate request rejected. |
| 8 | Enemy AI | PASS | Live Rus counterattack and subsequent phases, via `AI.checkpoint`. |
| 9 | Several stable turns | PASS | Six completed Rus phases and intact occupancy, followed by clean restart. |
| 10 | Server-authoritative rules | PASS | Live wrong-owner, overlap and stale ticket checks. |
| 11 | Server-authoritative economy | PASS | Rejected a request with a gold override. Verified 34/27/22 initially and 42/35/25 on turn 2 after capturing Kiev. |
| 12 | Original 3D assets | PARTIAL | All 13 templates preserved and used as source for portable variants. Original `Opaque` geometry cannot be guaranteed to render after reopen. See the asset inventory. |
| 13 | Strategy camera | PASS | Framed view shows all 12 labels. Runtime close view and default overview inspected. |
| 14 | Readable and functional UI | PARTIAL | Desktop controls tested. Simulated landscape HUD stayed on-screen at 1280×720 and 800×450, but some labels overlap at 800×450. Physical mobile play remains unverified. |
| 15 | Consistent README | PASS | Root and Studio README describe the native standalone file, current controls and scope. |
| 16 | ADR-005 | PASS | Migration and consequences documented. Historical decision date and individual signoff are flagged for confirmation. |
| 17 | ADR-003 and ADR-004 | PASS | Both are marked superseded by the verified Roblox systems. |
| 18 | AI transparency | PASS | Current Codex and historical Antigravity scopes are recorded with the available evidence. |
| 19 | Ten-step manual verification | PASS | Exactly ten executed and recorded cases. MT-03 documents the exact original asset limitation. |
| 20 | Contribution report | PASS | Actual Git author/committer/diff evidence, missing approvals and AI work separated. |
| 21 | Individual defense guide | PASS | Four subsystem and function walkthroughs. |
| 22 | Human teammate validation | NOT VERIFIED | Requires another student to independently play and record results. |
| 23 | One-minute demo | PASS | Studio produced two sequential captures totaling about 58 seconds, plus a recording guide. A shorter capture also covers the opening in the exact final save. |
| 24 | Synchronized standalone build | PASS | `Roblox/HordeSteppeSteel.rbxl` reopened in a fresh Studio window, core loop replayed and 16 sources compared. External asset access from another account remains untested. |

**Tally:** 21 PASS, 2 PARTIAL, 0 FAIL, 1 NOT VERIFIED. See [manual results](Roblox/docs/CHECKPOINT_1_MANUAL_TESTS.md), [assets](Roblox/docs/Checkpoint1-Assets.md) and [demo](Roblox/docs/Checkpoint1-Demo.md).

## Baselines and remaining scope

The Antigravity audit was attached to the desktop checkout at `ec09748`, which shipped the older hex package. The newer `main` baseline at `c98c562` already provided the canonical board and campaign rules. Baseline Studio testing confirmed the basic opening still ran, but the map was sparsely populated and the original horse mesh failed to render. The recovery also reproduced a campaign error persisting in the main menu, fixed the transition and ran the same test successfully. The brief takes precedence over audit suggestions to replace canonical provinces with Sarkel and Crossroads. No recruitment, construction, stack merging, persistent saves or additional playable factions are introduced.

The fresh place uses no local import paths or external development tooling at runtime. Older showcase opaque assets may generate non-blocking engine warnings, while the campaign uses portable native art. Another authorized user should verify ZIP download and Studio playback under their own account. Human teammate playtesting and review of individual credit remain due.
