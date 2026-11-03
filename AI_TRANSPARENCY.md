# AI Transparency Log — Horde: Steppe & Steel

This document records all AI-assisted engineering and design work across Team Arsenal. Every team member must log AI usage, personal reviews, manual modifications, and testing procedures for their assigned subsystem.

---

## Log Entry Template

```markdown
### Entry: [Subsystem / Feature Name]
- **Team Member:** [Aziret / Ayaz / Iskender / Alen]
- **Date:** [YYYY-MM-DD]
- **AI Tool Used:** [e.g. Antigravity / Claude / Gemini]
- **Assistance Scope:** [Architecture design / code drafting / refactoring / test writing]
- **Generated Output:** [Describe classes, methods, or documents drafted with AI]
- **Student Review & Manual Modifications:** [Explain what you verified, corrected, or rejected]
- **Testing Procedure:** [Command line, unit test, or in-engine demonstration used to verify]
```

---

## Team Entries

### Entry: Checkpoint 4 Architecture & Technical Validation
- **Team Member:** Team Arsenal (Aziret, Ayaz, Iskender, Alen)
- **Date:** 2026-11-03
- **AI Tool Used:** Antigravity (Advanced Agentic Coding)
- **Assistance Scope:** Technical audit, risk validation, file ownership matrix, combat formula reconciliation, and implementation blueprint.
- **Generated Output:** `IMPLEMENTATION_BLUEPRINT.md`, `DECISION_LOG.md`, `AI_TRANSPARENCY.md`.
- **Student Review & Manual Modifications:**
  - Verified 74/74 test baseline using Godot 4.7.2 console.
  - Corrected combat math to preserve exact `game_manager.gd` calculations without arbitrary coefficients.
  - Corrected bridge spawning coordinates to satisfy `pos1.x * pos2.x < 0` and midpoint constraints.
  - Enforced strict five-color palette across all UI states and materials.
- **Testing Procedure:** Executed `godot --headless -s scripts/tests/test_godot_gameplay.gd` (74/74 passing).
