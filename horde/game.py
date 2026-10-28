"""Main Game class — state machine and top-level logic."""
from __future__ import annotations
import sys
import pygame
from typing import Dict, Optional

from horde.constants import (
    SCREEN_WIDTH, SCREEN_HEIGHT, TITLE, FPS,
    STATE_MAIN_MENU, STATE_CAMPAIGN, STATE_BATTLE,
    STATE_VICTORY, STATE_DEFEAT, STATE_QUIT,
    PROVINCES_TO_WIN,
)
from horde.models.province import Province
from horde.models.faction import Faction
from horde.ai.ai_controller import AIController


class Game:
    """Central game object. Owns all state and data."""

    def __init__(self):
        pygame.init()
        pygame.display.set_caption(TITLE)
        self.screen = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT))
        self.clock = pygame.time.Clock()

        self.running = True
        self.current_state_name: str = STATE_MAIN_MENU
        self.current_state = None

        # Campaign data (populated on new game)
        self.provinces: Dict[str, Province] = {}
        self.factions: Dict[str, Faction] = {}
        self.turn: int = 1
        self.battle_context: Optional[dict] = None

        self.ai = AIController()

        # Go to main menu
        self.change_state(STATE_MAIN_MENU)

    def change_state(self, new_state: str):
        self.current_state_name = new_state
        if new_state == STATE_MAIN_MENU:
            from horde.states.main_menu import MainMenuState
            self.current_state = MainMenuState(self)
        elif new_state == STATE_CAMPAIGN:
            from horde.states.campaign_map import CampaignMapState
            self.current_state = CampaignMapState(self)
        elif new_state == STATE_BATTLE:
            from horde.states.battle import BattleState
            self.current_state = BattleState(self)
        elif new_state == STATE_VICTORY:
            from horde.states.end_screens import VictoryState
            self.current_state = VictoryState(self)
        elif new_state == STATE_DEFEAT:
            from horde.states.end_screens import DefeatState
            self.current_state = DefeatState(self)
        elif new_state == STATE_QUIT:
            self.running = False

    def start_new_campaign(self):
        from horde.data.campaign import build_campaign
        self.provinces, self.factions = build_campaign()
        self.turn = 1
        self.battle_context = None
        self.change_state(STATE_CAMPAIGN)

    def run_ai_turns(self):
        """Execute AI turns for all non-player factions."""
        for fid, faction in self.factions.items():
            if faction.is_player or faction.is_defeated:
                continue
            actions = self.ai.take_turn(faction, self.provinces, self.factions)
            for act in actions:
                if act["action"] == "attack":
                    self._resolve_ai_battle(faction, act["from"], act["to"])

    def _resolve_ai_battle(self, faction: Faction, from_pid: str, to_pid: str):
        """Resolve AI-vs-AI or AI-vs-player battles automatically."""
        import random

        att_army = faction.armies.get(from_pid)
        def_province = self.provinces[to_pid]
        def_fid = def_province.owner_id
        def_faction = self.factions.get(def_fid) if def_fid else None
        def_army = def_faction.armies.get(to_pid) if def_faction else None

        att_str = att_army.total_strength if att_army else 0
        def_str = def_army.total_strength if (def_army and not def_army.is_empty) else 0

        # Simple resolution: compare strengths with random factor
        att_roll = att_str * random.uniform(0.7, 1.3)
        def_roll = (def_str + def_province.defense_bonus * 10) * random.uniform(0.7, 1.3)

        if att_roll > def_roll:
            # Attacker wins — capture province
            def_province.owner_id = faction.faction_id
            if def_faction and def_army:
                # Reduce defending army significantly
                for u in def_army.units:
                    u.count = max(0, int(u.count * 0.3))
                    if u.count <= 0:
                        u.is_alive = False
                def_army.remove_dead()
                if def_army.is_empty:
                    def_faction.remove_army(to_pid)
                if def_faction.province_count(self.provinces) == 0:
                    def_faction.is_defeated = True
            # Move part of attacker army
            if att_army:
                for u in att_army.units:
                    u.count = max(1, int(u.count * 0.85))
                new_army_units = att_army.units[:]
                faction.remove_army(from_pid)
                from horde.models.army import Army
                new_army = Army(faction.faction_id)
                new_army.units = new_army_units
                existing = faction.armies.get(to_pid)
                if existing:
                    existing.units.extend(new_army.units)
                else:
                    faction.set_army(to_pid, new_army)
        else:
            # Defender wins — attacker takes losses
            if att_army:
                for u in att_army.units:
                    u.count = max(0, int(u.count * 0.6))
                    if u.count <= 0:
                        u.is_alive = False
                att_army.remove_dead()
                if att_army.is_empty:
                    faction.remove_army(from_pid)

    def check_victory_conditions(self) -> Optional[str]:
        """Return 'win', 'lose', or None."""
        player = self.factions.get("player")
        if not player:
            return "lose"

        # Player win: owns enough provinces
        pcount = player.province_count(self.provinces)
        if pcount >= PROVINCES_TO_WIN:
            return "win"

        # Player win: all enemies defeated
        all_enemies_defeated = all(
            f.is_defeated for fid, f in self.factions.items()
            if not f.is_player
        )
        if all_enemies_defeated:
            return "win"

        # Player lose: no provinces and no armies
        if pcount == 0 and not player.has_any_army():
            player.is_defeated = True
            return "lose"

        return None

    def quit(self):
        self.running = False

    def run(self):
        while self.running:
            dt = self.clock.tick(FPS) / 1000.0  # seconds

            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    self.running = False
                    break
                if self.current_state:
                    self.current_state.handle_event(event)

            if self.current_state:
                self.current_state.update(dt)
                self.current_state.draw(self.screen)

            pygame.display.flip()

        pygame.quit()
        sys.exit(0)
