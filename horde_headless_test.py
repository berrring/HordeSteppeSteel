import os
os.environ['SDL_VIDEODRIVER'] = 'dummy'
os.environ['SDL_AUDIODRIVER'] = 'dummy'

import pygame
pygame.init()

from horde.game import Game
print("Game import OK")

from horde.data.campaign import build_campaign
provinces, factions = build_campaign()
print(f"Provinces: {len(provinces)}")
print(f"Factions: {list(factions.keys())}")

player = factions["player"]
print(f"Player provinces: {player.province_count(provinces)}")
print(f"Player gold: {player.gold}")
print(f"Player has army: {player.has_any_army()}")

# Test AI turn
from horde.ai.ai_controller import AIController
ai = AIController()
red = factions["red"]
actions = ai.take_turn(red, provinces, factions)
print(f"AI actions for red: {len(actions)} actions")

# Test victory condition check
from horde.constants import PROVINCES_TO_WIN
pcount = player.province_count(provinces)
print(f"Player needs {PROVINCES_TO_WIN} provinces, has {pcount}")

# Test full state machine init (headless)
g = Game()
g.start_new_campaign()
print(f"Campaign state: {g.current_state_name}")
g.run_ai_turns()
result = g.check_victory_conditions()
print(f"Victory check result: {result}")

print("ALL HEADLESS CHECKS PASSED")
