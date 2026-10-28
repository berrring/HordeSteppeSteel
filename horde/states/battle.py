"""Battle state — tactical combat screen."""
from __future__ import annotations
import pygame
import random
from typing import List, Optional, TYPE_CHECKING
from horde.constants import (
    SCREEN_WIDTH, SCREEN_HEIGHT, BLACK, WHITE, GRAY, DARK_GRAY,
    YELLOW, ORANGE, GREEN, DARK_GREEN, RED, DARK_RED, BLUE, DARK_BLUE,
    PLAYER_COLOR, BROWN, TAN,
    BATTLE_GRID_COLS, BATTLE_GRID_ROWS,
    STATE_CAMPAIGN,
)
from horde.ui.ui_utils import Button, Panel, draw_text
from horde.models.army import Army
from horde.models.unit import Unit

if TYPE_CHECKING:
    from horde.game import Game

CELL_W = 88
CELL_H = 72
GRID_ORIGIN_X = 60
GRID_ORIGIN_Y = 60
LOG_PANEL_X = GRID_ORIGIN_X + BATTLE_GRID_COLS * CELL_W + 20
LOG_PANEL_Y = 60
LOG_PANEL_W = SCREEN_WIDTH - LOG_PANEL_X - 20
LOG_PANEL_H = SCREEN_HEIGHT - 140

# Sides
ATTACKER_COLS = range(0, 3)
DEFENDER_COLS = range(5, 8)


class BattleState:
    """
    Simplified tactical battle:
    - Grid of BATTLE_GRID_COLS x BATTLE_GRID_ROWS cells
    - Attacker units on left, defender on right
    - Player selects unit, then selects target to attack
    - Attack button or click to fire
    - AI auto-plays defender side
    """

    def __init__(self, game: "Game"):
        self.game = game
        self.ctx = game.battle_context
        self.log: List[str] = []
        self.turn = 0          # 0=player attack, 1=enemy counter-attack
        self.phase = "select"  # select | result | over
        self.selected_unit: Optional[Unit] = None
        self.result: Optional[str] = None  # "victory" | "defeat" | "retreat"

        self._setup_armies()
        self._build_buttons()
        self._add_log("=== BATTLE BEGINS ===")
        self._add_log(f"Attacking: {self.ctx['attacker_pid'].upper()}")
        self._add_log(f"Defending: {self.ctx['defender_pid'].upper()}")

    def _setup_armies(self):
        """Place units on the grid."""
        ctx = self.ctx
        self.attacker_units: List[Unit] = []
        self.defender_units: List[Unit] = []

        atk_army: Optional[Army] = ctx.get("attacker_army")
        def_army: Optional[Army] = ctx.get("defender_army")

        # Place attacker units (left side)
        if atk_army:
            living = atk_army.living_units()
            for i, u in enumerate(living):
                u.col = 1
                u.row = i % BATTLE_GRID_ROWS
                u.moved = False
                u.attacked = False
                self.attacker_units.append(u)

        # Place defender units (right side, or create defenders for undefended)
        if def_army and not def_army.is_empty:
            living = def_army.living_units()
            for i, u in enumerate(living):
                u.col = BATTLE_GRID_COLS - 2
                u.row = i % BATTLE_GRID_ROWS
                u.moved = False
                u.attacked = False
                self.defender_units.append(u)
        else:
            # Undefended — create a token militia garrison
            garrison = Army("garrison")
            g = garrison.add_unit("Infantry", 30)
            g.col = BATTLE_GRID_COLS - 2
            g.row = 2
            self.defender_units.append(g)

    def _build_buttons(self):
        self.btn_retreat = Button(
            LOG_PANEL_X, LOG_PANEL_Y + LOG_PANEL_H + 10,
            LOG_PANEL_W // 2 - 5, 45,
            "Retreat", (80, 40, 10), (140, 70, 20), WHITE, 20
        )
        self.btn_next_turn = Button(
            LOG_PANEL_X + LOG_PANEL_W // 2 + 5, LOG_PANEL_Y + LOG_PANEL_H + 10,
            LOG_PANEL_W // 2 - 5, 45,
            "End Turn", (20, 70, 20), DARK_GREEN, WHITE, 20
        )
        self.btn_continue = Button(
            SCREEN_WIDTH // 2 - 120, SCREEN_HEIGHT // 2 + 60,
            240, 55, "Continue", DARK_GREEN, GREEN, WHITE, 26
        )

    def _add_log(self, msg: str):
        self.log.append(msg)
        if len(self.log) > 20:
            self.log.pop(0)

    def _cell_rect(self, col, row) -> pygame.Rect:
        x = GRID_ORIGIN_X + col * CELL_W
        y = GRID_ORIGIN_Y + row * CELL_H
        return pygame.Rect(x, y, CELL_W, CELL_H)

    def _get_unit_at(self, col, row) -> Optional[Unit]:
        for u in self.attacker_units + self.defender_units:
            if u.col == col and u.row == row and u.is_alive:
                return u
        return None

    def handle_event(self, event):
        if self.phase == "over":
            if self.btn_continue.handle_event(event):
                self._finish_battle()
            return

        if self.phase != "select":
            return

        mx, my = pygame.mouse.get_pos()

        if self.btn_retreat.handle_event(event):
            self.result = "retreat"
            self.phase = "over"
            self._add_log("Player retreated!")
            return

        if self.btn_next_turn.handle_event(event):
            self._run_enemy_turn()
            return

        if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            # Check grid clicks
            for col in range(BATTLE_GRID_COLS):
                for row in range(BATTLE_GRID_ROWS):
                    cr = self._cell_rect(col, row)
                    if cr.collidepoint(mx, my):
                        unit = self._get_unit_at(col, row)
                        if unit:
                            if unit in self.attacker_units and not unit.attacked:
                                self.selected_unit = unit
                                self._add_log(f"Selected: {unit.unit_type}")
                            elif unit in self.defender_units and self.selected_unit:
                                # Attack!
                                dmg = self.selected_unit.attack_unit(unit)
                                self._add_log(
                                    f"{self.selected_unit.symbol} attacks "
                                    f"{unit.symbol}: {dmg} dmg!"
                                )
                                if not unit.is_alive:
                                    self._add_log(f"  {unit.unit_type} DESTROYED!")
                                self.selected_unit = None
                                self._check_battle_end()

    def _run_enemy_turn(self):
        """Enemy AI attacks player units."""
        self._add_log("--- Enemy Turn ---")
        for u in self.defender_units:
            if not u.is_alive:
                continue
            u.reset_for_turn()
            # Find nearest attacker
            targets = [a for a in self.attacker_units if a.is_alive]
            if not targets:
                break
            target = random.choice(targets)
            dmg = u.attack_unit(target)
            self._add_log(f"Enemy {u.symbol} attacks {target.symbol}: {dmg} dmg!")
            if not target.is_alive:
                self._add_log(f"  {target.unit_type} DESTROYED!")

        # Reset player units for next round
        for u in self.attacker_units:
            u.reset_for_turn()

        self._check_battle_end()

    def _check_battle_end(self):
        living_att = [u for u in self.attacker_units if u.is_alive]
        living_def = [u for u in self.defender_units if u.is_alive]

        if not living_att:
            self.result = "defeat"
            self.phase = "over"
            self._add_log("=== DEFEAT — All attackers destroyed! ===")
        elif not living_def:
            self.result = "victory"
            self.phase = "over"
            self._add_log("=== VICTORY — All defenders destroyed! ===")

    def _finish_battle(self):
        """Apply battle results to campaign and return to map."""
        ctx = self.ctx
        game = self.game
        att_pid = ctx["attacker_pid"]
        def_pid = ctx["defender_pid"]
        def_fid = ctx["defender_faction"]

        if self.result == "victory":
            # Transfer province to player
            game.provinces[def_pid].owner_id = "player"
            # Remove defeated army
            if def_fid and def_fid in game.factions:
                game.factions[def_fid].remove_army(def_pid)
                # Check if faction is eliminated
                def_faction = game.factions[def_fid]
                pcount = def_faction.province_count(game.provinces)
                if pcount == 0:
                    def_faction.is_defeated = True
                    game.factions["player"].armies.get(att_pid)  # keep army
                    self._add_log(f"Faction {def_faction.name} ELIMINATED!")
            # Move attacker army to new province
            player = game.factions["player"]
            army = player.armies.pop(att_pid, None)
            if army:
                army.remove_dead()
                if not army.is_empty:
                    existing = player.armies.get(def_pid)
                    if existing:
                        existing.units.extend(army.units)
                    else:
                        player.set_army(def_pid, army)

        elif self.result == "defeat":
            # Attacker army destroyed
            player = game.factions["player"]
            player.remove_army(att_pid)

        # retreat: armies stay where they are, no province change

        game.battle_context = None
        game.change_state(STATE_CAMPAIGN)

    def update(self, dt):
        mouse = pygame.mouse.get_pos()
        self.btn_retreat.update(mouse)
        self.btn_next_turn.update(mouse)
        if self.phase == "over":
            self.btn_continue.update(mouse)

    def draw(self, surface: pygame.Surface):
        surface.fill((20, 15, 10))

        # Title
        draw_text(surface, "BATTLE", SCREEN_WIDTH // 2, 20, 28, YELLOW, center=True, shadow=True)

        # Draw grid
        for col in range(BATTLE_GRID_COLS):
            for row in range(BATTLE_GRID_ROWS):
                cr = self._cell_rect(col, row)
                # Color zones
                if col < 3:
                    base_col = (30, 50, 30)
                elif col > 4:
                    base_col = (50, 30, 30)
                else:
                    base_col = (35, 35, 20)
                pygame.draw.rect(surface, base_col, cr)
                pygame.draw.rect(surface, (60, 55, 40), cr, 1)

        # Draw units
        for u in self.attacker_units + self.defender_units:
            if u.is_alive:
                self._draw_unit(surface, u)

        # Highlight selected unit
        if self.selected_unit and self.selected_unit.is_alive:
            u = self.selected_unit
            cr = self._cell_rect(u.col, u.row)
            pygame.draw.rect(surface, YELLOW, cr, 3)

        # Log panel
        log_panel = Panel(LOG_PANEL_X - 5, LOG_PANEL_Y - 5,
                          LOG_PANEL_W + 10, LOG_PANEL_H + 10,
                          color=(20, 20, 30), alpha=230)
        log_panel.draw(surface)
        draw_text(surface, "Battle Log", LOG_PANEL_X + 5, LOG_PANEL_Y, 16, ORANGE)
        for i, line in enumerate(self.log[-18:]):
            draw_text(surface, line, LOG_PANEL_X + 5,
                      LOG_PANEL_Y + 22 + i * 18, 13, WHITE)

        if self.phase != "over":
            self.btn_retreat.draw(surface)
            self.btn_next_turn.draw(surface)

        # Labels
        draw_text(surface, "YOUR ARMY", GRID_ORIGIN_X + 1 * CELL_W + CELL_W // 2,
                  GRID_ORIGIN_Y - 30, 16, PLAYER_COLOR, center=True)
        draw_text(surface, "ENEMY", GRID_ORIGIN_X + 6 * CELL_W + CELL_W // 2,
                  GRID_ORIGIN_Y - 30, 16, RED, center=True)

        # Phase overlay
        if self.phase == "over":
            self._draw_result_overlay(surface)

    def _draw_unit(self, surface, u: Unit):
        cr = self._cell_rect(u.col, u.row)
        is_attacker = u in self.attacker_units
        color = PLAYER_COLOR if is_attacker else RED

        # Unit box
        box = cr.inflate(-10, -10)
        pygame.draw.rect(surface, color, box, border_radius=6)
        pygame.draw.rect(surface, WHITE, box, 1, border_radius=6)

        # Symbol
        draw_text(surface, u.symbol, box.centerx, box.centery - 8,
                  16, WHITE, center=True)
        # Count
        hp_ratio = u.count / u.max_count
        bar_w = int(box.width * hp_ratio)
        bar_rect = pygame.Rect(box.left, box.bottom - 8, bar_w, 7)
        pygame.draw.rect(surface, GREEN if hp_ratio > 0.5 else ORANGE if hp_ratio > 0.25 else RED, bar_rect)
        draw_text(surface, str(u.count), box.centerx, box.bottom - 18,
                  12, WHITE, center=True)

    def _draw_result_overlay(self, surface):
        overlay = pygame.Surface((SCREEN_WIDTH, SCREEN_HEIGHT), pygame.SRCALPHA)
        overlay.fill((0, 0, 0, 160))
        surface.blit(overlay, (0, 0))

        cx = SCREEN_WIDTH // 2
        cy = SCREEN_HEIGHT // 2
        if self.result == "victory":
            draw_text(surface, "VICTORY!", cx, cy - 40, 72, YELLOW, center=True, shadow=True)
            draw_text(surface, "Province captured!", cx, cy + 20, 28, GREEN, center=True)
        elif self.result == "defeat":
            draw_text(surface, "DEFEAT", cx, cy - 40, 72, RED, center=True, shadow=True)
            draw_text(surface, "Your army was destroyed.", cx, cy + 20, 28, ORANGE, center=True)
        else:
            draw_text(surface, "RETREAT", cx, cy - 40, 60, ORANGE, center=True, shadow=True)
            draw_text(surface, "You withdrew from battle.", cx, cy + 20, 28, WHITE, center=True)

        self.btn_continue.draw(surface)
