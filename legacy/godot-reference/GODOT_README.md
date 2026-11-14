# Horde: Steppe and Steel — Godot edition

A small turn-based grand strategy MVP in GDScript. The original full campaign
has 12 connected provinces and six playable factions. The separate checkpoint
demo has three provinces and is played as the Mongols. The older Unity plan is
a design reference; this project runs in Godot.

## Run

Open `project.godot` in Godot 4, or run:

```sh
godot --path HordeGodot
```

For machines without Vulkan support, add `--rendering-method gl_compatibility`.
The current gameplay and rendered checks were run on Godot 4.5.2 on Linux.

Choose **New Campaign** to select one of the six factions, or **Checkpoint
Demo** for the three-province scenario. **Continue Campaign** loads the last save.

## Play

- Left-click a province to inspect its owner, income, army and movement.
- Select a province containing your army, then click a connected neighbor.
  Confirm **March / Merge** for friendly territory or **Launch Attack** for
  enemy territory. Clicking a non-neighbor only inspects it.
- A friendly march costs one movement point and transfers the whole army.
  Armies meeting in a province merge without losing troops. The resulting host
  inherits the lower remaining movement budget; merging cannot reset movement.
- Movement follows the slowest unit, multiplied by the faction movement trait
  and rounded up, with at least one point. A battle spends all remaining movement.
- Recruit 50 soldiers at a time using gold and food. New armies must wait until
  the next turn to march; reinforcing an existing army does not reset movement.
- Build each structure at most once per province. Construction costs wood and
  applies the listed income or defense benefit once.
- **End Turn** lets other factions recruit, develop their economy and act.
  Interior armies reinforce the frontier. Enemy attacks account for fortifications
  and faction bonuses. The next player turn restores movement, collects income
  once, and advances Spring → Summer → Autumn → Winter.
- **Save / Load** preserves scenario, troops, resources, buildings and remaining
  movement. Loading rebuilds the map and clears old selections. Malformed saves
  are rejected before replacing the current campaign.

WASD pans the camera; right-drag also pans; the mouse wheel zooms. F10 switches
perspective/orthographic projection. Escape opens settings. Map commands are
blocked behind dialogs and during army marches and battles.

## Battles and objectives

Battles use one `BattleCalculator` result. The 3D replay displays those exact
casualties; **Skip to Report** skips the animation. **Retreat** commits a defender
victory with the existing losing-attacker retention rules. Manual damage commands are hidden: combat is a visualized automatic resolution.

Winning attackers retain 70–95% per stack (minimum one survivor); routed defenders
retain 10–40% in the report. Losing attackers retain 40–70%; winning defenders keep
their army. Counts use integer truncation, so very small routed stacks can vanish.
The winning attacking army occupies the province; routed defenders leave it.
Fortifications contribute defense ×10 before the faction modifier. A tactical
capture preserves the existing five-point fortification damage rule.

Full campaign victory requires 10 provinces or elimination of all five rivals.
Losing all provinces and armies or exceeding 60 turns is defeat. The checkpoint
objective is to capture Sarkel before its 30-turn limit. Rus only counterattacks
player-held Crossroads when competitive; neutral clans never attack.

## Verify

Python 3 and the Godot executable are sufficient; no Python packages are needed:

```sh
python HordeGodot/run_tests.py --engine /path/to/godot
```

The runner imports assets, executes nine suites (combat, AI, tactical results,
economy, camera/terrain, general gameplay, campaign orders, complete UI flow and viewport input routing),
and checks startup. It treats GDScript runtime errors as failures even when Godot
returns exit code zero. Full logs go to a temporary directory printed at the end.

Tests cover invalid orders, friendly movement and merging, exhausted armies,
duplicate construction, paid AI recruitment, battle locking and exactly-once
results, modal recovery, cross-scenario loading, completed-game continuation,
and multi-turn invariants for all six factions.

A rendered camera/terrain smoke check is also available:

```sh
godot --path HordeGodot --script res://scripts/tests/test_alen_visual.gd -- /tmp/horde-renders
```

Godot currently reports ObjectDB instances leaked at exit in test runs, including
the original suites. The runner records these warnings; they are separate from
script errors and failed checks. Seasons are currently a calendar indicator and
lighting context, with no weather penalties. Diplomacy, technology trees and
real-time unit micromanagement remain outside this implementation.
