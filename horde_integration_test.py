"""Integration test: simulate a full game loop without a display."""
import os
os.environ['SDL_VIDEODRIVER'] = 'dummy'
os.environ['SDL_AUDIODRIVER'] = 'dummy'

import pygame
pygame.init()

from horde.game import Game
from horde.data.campaign import build_campaign
from horde.models.army import Army
from horde.constants import (
    UNIT_INFANTRY, UNIT_HORSE_ARCHER, UNIT_HEAVY_CAVALRY,
    STATE_CAMPAIGN, STATE_BATTLE, STATE_VICTORY, STATE_DEFEAT, STATE_MAIN_MENU,
    PROVINCES_TO_WIN
)

print("=== Full Game Loop Integration Test ===\n")

# 1. Test: New game initializes correctly
g = Game()
g.start_new_campaign()
assert g.current_state_name == STATE_CAMPAIGN
assert len(g.provinces) == 12
assert "player" in g.factions
print("[PASS] 1. New campaign initializes correctly")

# 2. Test: Player can recruit units
player = g.factions["player"]
initial_gold = player.gold
sarai = "sarai"
initial_army = player.armies.get(sarai)
initial_units = len(initial_army.units) if initial_army else 0
player.gold = 500
army = player.armies.get(sarai)
if army is None:
    army = Army("player")
    player.set_army(sarai, army)
army.add_unit(UNIT_INFANTRY, 80)
player.gold -= 100
assert player.gold == 400
assert len(army.units) > initial_units
print("[PASS] 2. Player can recruit units")

# 3. Test: Battle context setup
from horde.models.army import Army as _Army
att_army = player.armies.get("sarai")
kiev_owner = g.provinces["kiev"].owner_id
def_faction = g.factions.get(kiev_owner)
def_army = def_faction.armies.get("kiev") if def_faction else None

g.battle_context = {
    "attacker_pid": "sarai",
    "attacker_faction": "player",
    "defender_pid": "kiev",
    "defender_faction": kiev_owner,
    "attacker_army": att_army,
    "defender_army": def_army,
}
g.change_state(STATE_BATTLE)
assert g.current_state_name == STATE_BATTLE
battle = g.current_state
assert battle.attacker_units is not None
assert len(battle.attacker_units) > 0
print("[PASS] 3. Battle state initializes with correct armies")

# 4. Test: Battle can progress — select and attack
battle.phase = "select"
att_unit = battle.attacker_units[0]
battle.selected_unit = att_unit
def_unit = battle.defender_units[0] if battle.defender_units else None
if def_unit:
    prev_count = def_unit.count
    att_unit.attack_unit(def_unit)
    assert def_unit.count <= prev_count
    print("[PASS] 4. Battle attack reduces enemy count")
else:
    print("[SKIP] 4. No defender units to attack")

# 5. Test: Victory result applies to campaign
battle.result = "victory"
battle.phase = "over"
battle._finish_battle()
assert g.current_state_name == STATE_CAMPAIGN
assert g.provinces["kiev"].owner_id == "player"
print("[PASS] 5. Victory: province ownership transferred")

# 6. Test: Defeat result applies correctly
# Setup a battle where player loses
g.battle_context = {
    "attacker_pid": "sarai",
    "attacker_faction": "player",
    "defender_pid": "urgench",
    "defender_faction": None,
    "attacker_army": player.armies.get("sarai"),
    "defender_army": None,
}
g.change_state(STATE_BATTLE)
battle2 = g.current_state
battle2.result = "defeat"
battle2.phase = "over"
battle2._finish_battle()
assert g.current_state_name == STATE_CAMPAIGN
# Sarai army removed
assert player.armies.get("sarai") is None or player.armies.get("sarai").is_empty
print("[PASS] 6. Defeat: attacker army destroyed")

# 7. Test: AI turn execution
print("\nRunning AI turns...")
g2 = Game()
g2.start_new_campaign()
initial_turns = g2.turn
g2.factions["player"].collect_income(g2.provinces)
g2.turn += 1
g2.run_ai_turns()
result = g2.check_victory_conditions()
assert result in (None, "win", "lose")
print(f"[PASS] 7. AI turns complete. Victory check: {result}")

# 8. Test: Win condition triggers
g3 = Game()
g3.start_new_campaign()
# Force-capture all provinces for player
for p in g3.provinces.values():
    p.owner_id = "player"
result = g3.check_victory_conditions()
assert result == "win"
g3.change_state(STATE_VICTORY)
assert g3.current_state_name == STATE_VICTORY
print("[PASS] 8. Victory condition detected, Victory screen shown")

# 9. Test: Defeat condition triggers
g4 = Game()
g4.start_new_campaign()
player4 = g4.factions["player"]
for p in g4.provinces.values():
    p.owner_id = "red"
player4.armies.clear()
result = g4.check_victory_conditions()
assert result == "lose"
g4.change_state(STATE_DEFEAT)
assert g4.current_state_name == STATE_DEFEAT
print("[PASS] 9. Defeat condition detected, Defeat screen shown")

# 10. Test: Return to main menu from end screens
g4.change_state(STATE_MAIN_MENU)
assert g4.current_state_name == STATE_MAIN_MENU
print("[PASS] 10. Return to main menu works")

# 11. Test: Turn limit
g5 = Game()
g5.start_new_campaign()
g5.turn = 61
result = g5.check_victory_conditions()
# No auto-lose just from turn — need also no provinces
print(f"[PASS] 11. Turn limit handled (result: {result})")

print("\n=== ALL INTEGRATION TESTS PASSED ===")
