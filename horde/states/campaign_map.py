"""Campaign map state — the strategic layer."""
from __future__ import annotations
import pygame
from typing import Dict, Optional, List, TYPE_CHECKING
from horde.constants import (
    SCREEN_WIDTH, SCREEN_HEIGHT, BLACK, WHITE, GRAY, DARK_GRAY,
    YELLOW, ORANGE, GREEN, DARK_GREEN, RED, DARK_RED, BLUE, DARK_BLUE,
    BROWN, TAN, PARCHMENT, SAND,
    NEUTRAL_COLOR, PLAYER_COLOR,
    UNIT_HORSE_ARCHER, UNIT_HEAVY_CAVALRY, UNIT_INFANTRY, UNIT_SIEGE,
    PROVINCES_TO_WIN, MAX_TURNS,
    STATE_BATTLE, STATE_VICTORY, STATE_DEFEAT,
)
from horde.ui.ui_utils import Button, Panel, draw_text, get_font
from horde.models.province import Province
from horde.models.faction import Faction
from horde.models.army import Army
from horde.models.unit import UNIT_STATS

if TYPE_CHECKING:
    from horde.game import Game


MAP_X = 20
MAP_Y = 20
MAP_W = SCREEN_WIDTH - 280
MAP_H = SCREEN_HEIGHT - 40

PANEL_X = MAP_X + MAP_W + 10
PANEL_W = 250
PANEL_H = SCREEN_HEIGHT - 40

RECRUIT_COSTS = {
    UNIT_HORSE_ARCHER: 150,
    UNIT_HEAVY_CAVALRY: 250,
    UNIT_INFANTRY: 100,
    UNIT_SIEGE: 300,
}


class CampaignMapState:
    """Campaign map: player selects provinces to attack or recruit units."""

    def __init__(self, game: "Game"):
        self.game = game
        self.selected_pid: Optional[str] = None
        self.attack_target: Optional[str] = None
        self.message: str = ""
        self.message_timer: float = 0.0
        self._build_side_panel()
        self._hovered_pid: Optional[str] = None

    def _build_side_panel(self):
        self.btn_end_turn = Button(
            PANEL_X, SCREEN_HEIGHT - 80, PANEL_W, 50,
            "End Turn", (100, 60, 20), (160, 100, 30), WHITE, 22
        )
        # Recruit buttons
        self.recruit_buttons: List[Button] = []
        for i, ut in enumerate([UNIT_HORSE_ARCHER, UNIT_INFANTRY,
                                 UNIT_HEAVY_CAVALRY, UNIT_SIEGE]):
            cost = RECRUIT_COSTS[ut]
            btn = Button(
                PANEL_X, 380 + i * 60, PANEL_W, 48,
                f"Recruit {ut} ({cost}g)",
                (40, 60, 100), (60, 90, 150), WHITE, 16
            )
            btn._unit_type = ut
            btn._cost = cost
            self.recruit_buttons.append(btn)

    def _province_screen_pos(self, p: Province):
        x = int(MAP_X + p.x * MAP_W)
        y = int(MAP_Y + p.y * MAP_H)
        return x, y

    def _get_province_at(self, mx, my) -> Optional[str]:
        provinces = self.game.provinces
        for pid, p in provinces.items():
            px, py = self._province_screen_pos(p)
            if (mx - px) ** 2 + (my - py) ** 2 <= 18 ** 2:
                return pid
        return None

    def handle_event(self, event):
        game = self.game
        mx, my = pygame.mouse.get_pos()

        if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            # End turn
            if self.btn_end_turn.rect.collidepoint(mx, my):
                self._end_player_turn()
                return

            # Recruit buttons
            if self.selected_pid:
                for btn in self.recruit_buttons:
                    if btn.rect.collidepoint(mx, my):
                        self._recruit(self.selected_pid, btn._unit_type, btn._cost)
                        return

            # Province click
            pid = self._get_province_at(mx, my)
            if pid:
                p = game.provinces[pid]
                player = game.factions["player"]
                if self.selected_pid is None:
                    if p.owner_id == "player":
                        self.selected_pid = pid
                        self.attack_target = None
                    else:
                        self.show_message("Select one of your provinces first.")
                else:
                    sel = game.provinces[self.selected_pid]
                    if pid == self.selected_pid:
                        # Deselect
                        self.selected_pid = None
                    elif p.owner_id == "player":
                        # Switch selection
                        self.selected_pid = pid
                        self.attack_target = None
                    elif pid in sel.neighbors:
                        # Attack!
                        self.attack_target = pid
                        self._initiate_battle(self.selected_pid, pid)
                    else:
                        self.show_message("Not adjacent to that province.")
            else:
                self.selected_pid = None

        elif event.type == pygame.MOUSEMOTION:
            self._hovered_pid = self._get_province_at(mx, my)

    def _recruit(self, province_pid: str, unit_type: str, cost: int):
        player = self.game.factions["player"]
        if player.gold < cost:
            self.show_message(f"Not enough gold! Need {cost}g.")
            return
        army = player.armies.get(province_pid)
        if army is None:
            army = Army("player")
            player.set_army(province_pid, army)
        army.add_unit(unit_type, 80)
        player.gold -= cost
        self.show_message(f"Recruited {unit_type} at {self.game.provinces[province_pid].name}!")

    def _initiate_battle(self, attacker_pid: str, defender_pid: str):
        game = self.game
        attacker_army = game.factions["player"].armies.get(attacker_pid)
        if attacker_army is None or attacker_army.is_empty:
            self.show_message("No army in that province!")
            self.selected_pid = None
            return

        defender_province = game.provinces[defender_pid]
        defender_faction_id = defender_province.owner_id
        defender_army = None
        if defender_faction_id:
            defender_army = game.factions[defender_faction_id].armies.get(defender_pid)

        # Store battle context in game
        game.battle_context = {
            "attacker_pid": attacker_pid,
            "attacker_faction": "player",
            "defender_pid": defender_pid,
            "defender_faction": defender_faction_id,
            "attacker_army": attacker_army,
            "defender_army": defender_army,
        }
        game.change_state(STATE_BATTLE)

    def _end_player_turn(self):
        game = self.game
        game.turn += 1

        # Collect player income
        player = game.factions["player"]
        income = player.collect_income(game.provinces)
        self.show_message(f"Turn {game.turn}: Collected {income}g income.")

        # Check turn limit
        if game.turn > MAX_TURNS:
            game.change_state(STATE_DEFEAT)
            return

        # AI turns
        game.run_ai_turns()

        # Check win/lose conditions
        result = game.check_victory_conditions()
        if result == "win":
            game.change_state(STATE_VICTORY)
        elif result == "lose":
            game.change_state(STATE_DEFEAT)

        self.selected_pid = None
        self.attack_target = None

    def show_message(self, msg: str, duration: float = 3.0):
        self.message = msg
        self.message_timer = duration

    def update(self, dt):
        if self.message_timer > 0:
            self.message_timer -= dt
            if self.message_timer <= 0:
                self.message = ""
        mouse = pygame.mouse.get_pos()
        self.btn_end_turn.update(mouse)
        player = self.game.factions["player"]
        for btn in self.recruit_buttons:
            btn.update(mouse)
            btn.enabled = (self.selected_pid is not None and
                           self.game.provinces.get(self.selected_pid, None) is not None and
                           self.game.provinces[self.selected_pid].owner_id == "player" and
                           player.gold >= btn._cost)

    def draw(self, surface: pygame.Surface):
        game = self.game
        # Background
        surface.fill((25, 20, 15))

        # Draw map background
        map_rect = pygame.Rect(MAP_X, MAP_Y, MAP_W, MAP_H)
        pygame.draw.rect(surface, (45, 35, 20), map_rect)
        pygame.draw.rect(surface, (100, 80, 30), map_rect, 2)

        # Draw province connections
        for pid, p in game.provinces.items():
            px, py = self._province_screen_pos(p)
            for npid in p.neighbors:
                if npid in game.provinces:
                    np_ = game.provinces[npid]
                    nx, ny = self._province_screen_pos(np_)
                    pygame.draw.line(surface, (80, 70, 50), (px, py), (nx, ny), 2)

        # Draw provinces
        for pid, p in game.provinces.items():
            self._draw_province(surface, p, game)

        # Side panel
        panel = Panel(PANEL_X - 5, MAP_Y, PANEL_W + 10, MAP_H,
                      color=(30, 25, 15), alpha=240)
        panel.draw(surface)

        self._draw_side_panel(surface, game)
        self.btn_end_turn.draw(surface)

        # Message
        if self.message:
            draw_text(surface, self.message, SCREEN_WIDTH // 2,
                      SCREEN_HEIGHT - 20, 18, YELLOW, center=True)

    def _draw_province(self, surface, p: Province, game):
        px, py = self._province_screen_pos(p)
        faction = game.factions.get(p.owner_id) if p.owner_id else None
        color = faction.color if faction else NEUTRAL_COLOR

        # Highlight
        is_selected = (p.pid == self.selected_pid)
        is_neighbor = (self.selected_pid is not None and
                       p.pid in game.provinces[self.selected_pid].neighbors)
        is_hovered = (p.pid == self._hovered_pid)

        radius = 18
        if is_selected:
            pygame.draw.circle(surface, YELLOW, (px, py), radius + 6, 3)
        elif is_neighbor and p.owner_id != "player":
            pygame.draw.circle(surface, RED, (px, py), radius + 4, 2)

        pygame.draw.circle(surface, color, (px, py), radius)
        pygame.draw.circle(surface, WHITE if is_hovered else (150, 130, 80),
                           (px, py), radius, 2)

        if p.is_capital:
            pygame.draw.circle(surface, YELLOW, (px, py), 5)

        # Army indicator
        army = faction.armies.get(p.pid) if faction else None
        if army and not army.is_empty:
            draw_text(surface, str(army.unit_count()), px, py - radius - 14,
                      14, WHITE, center=True)

        # Province name
        draw_text(surface, p.name, px, py + radius + 4,
                  13, (220, 200, 160), center=True)

    def _draw_side_panel(self, surface, game):
        player = game.factions["player"]
        x = PANEL_X + 5
        y = MAP_Y + 10

        draw_text(surface, "THE GOLDEN HORDE", x + PANEL_W // 2 - 5, y,
                  18, YELLOW, center=True)
        y += 30
        draw_text(surface, f"Turn: {game.turn} / {MAX_TURNS}", x, y, 16, WHITE)
        y += 25
        draw_text(surface, f"Gold: {player.gold}g", x, y, 16, YELLOW)
        y += 25
        pcount = player.province_count(game.provinces)
        draw_text(surface, f"Provinces: {pcount} / {PROVINCES_TO_WIN}", x, y, 16, WHITE)
        y += 35

        # Selected province info
        if self.selected_pid and self.selected_pid in game.provinces:
            p = game.provinces[self.selected_pid]
            draw_text(surface, f"Selected: {p.name}", x, y, 16, ORANGE)
            y += 22
            draw_text(surface, f"Income: {p.income}g/turn", x, y, 14, WHITE)
            y += 20
            army = player.armies.get(self.selected_pid)
            if army and not army.is_empty:
                draw_text(surface, f"Army ({army.unit_count()} units):", x, y, 14, WHITE)
                y += 18
                for u in army.living_units():
                    draw_text(surface, f"  {u.symbol} {u.unit_type} [{u.count}]",
                              x, y, 12, (180, 180, 180))
                    y += 16
            else:
                draw_text(surface, "No army here", x, y, 14, GRAY)
                y += 20

        y = 370
        draw_text(surface, "--- Recruit ---", x + PANEL_W // 2 - 5, y, 15,
                  (180, 160, 100), center=True)

        for btn in self.recruit_buttons:
            btn.draw(surface)

        # Faction summary
        y2 = MAP_Y + MAP_H - 200
        draw_text(surface, "Factions:", x, y2, 15, (180, 160, 100))
        y2 += 22
        for fid, f in game.factions.items():
            if f.is_defeated:
                status = " [DEFEATED]"
                col = GRAY
            else:
                pc = f.province_count(game.provinces)
                status = f" ({pc} prov, {f.total_strength()} troops)"
                col = f.color
            draw_text(surface, f.name + status, x, y2, 12, col)
            y2 += 18
