"""Victory and Defeat screens."""
from __future__ import annotations
import pygame
from typing import TYPE_CHECKING
from horde.constants import (
    SCREEN_WIDTH, SCREEN_HEIGHT,
    BLACK, WHITE, YELLOW, ORANGE, GREEN, DARK_GREEN, RED, DARK_RED, GRAY,
    STATE_MAIN_MENU,
)
from horde.ui.ui_utils import Button, draw_text

if TYPE_CHECKING:
    from horde.game import Game


class VictoryState:
    """Victory screen shown when player wins the campaign."""

    def __init__(self, game: "Game"):
        self.game = game
        cx = SCREEN_WIDTH // 2
        self.btn_menu = Button(cx - 130, SCREEN_HEIGHT - 150, 260, 55,
                               "Return to Menu", (80, 60, 10), (140, 110, 20), WHITE, 24)
        self._tick = 0.0

    def handle_event(self, event):
        if self.btn_menu.handle_event(event):
            self.game.change_state(STATE_MAIN_MENU)

    def update(self, dt):
        self._tick += dt
        self.btn_menu.update(pygame.mouse.get_pos())

    def draw(self, surface: pygame.Surface):
        surface.fill((10, 20, 10))
        # Decorative border
        pygame.draw.rect(surface, (80, 120, 30),
                         pygame.Rect(20, 20, SCREEN_WIDTH - 40, SCREEN_HEIGHT - 40), 4)
        pygame.draw.rect(surface, YELLOW,
                         pygame.Rect(25, 25, SCREEN_WIDTH - 50, SCREEN_HEIGHT - 50), 2)

        cx = SCREEN_WIDTH // 2
        draw_text(surface, "VICTORY!", cx, 140, 96, YELLOW, center=True, shadow=True)
        draw_text(surface, "The steppe bows to your might!", cx, 260, 36,
                  GREEN, center=True, shadow=True)

        player = self.game.factions.get("player")
        if player:
            pcount = player.province_count(self.game.provinces)
            draw_text(surface, f"Provinces Controlled: {pcount}", cx, 340, 26, WHITE, center=True)
            draw_text(surface, f"Turns Taken: {self.game.turn}", cx, 380, 26, WHITE, center=True)
            draw_text(surface, f"Gold Accumulated: {player.gold}g", cx, 420, 26, YELLOW, center=True)

        self.btn_menu.draw(surface)


class DefeatState:
    """Defeat screen shown when player loses."""

    def __init__(self, game: "Game"):
        self.game = game
        cx = SCREEN_WIDTH // 2
        self.btn_menu = Button(cx - 130, SCREEN_HEIGHT - 150, 260, 55,
                               "Return to Menu", DARK_RED, RED, WHITE, 24)

    def handle_event(self, event):
        if self.btn_menu.handle_event(event):
            self.game.change_state(STATE_MAIN_MENU)

    def update(self, dt):
        self.btn_menu.update(pygame.mouse.get_pos())

    def draw(self, surface: pygame.Surface):
        surface.fill((20, 5, 5))
        pygame.draw.rect(surface, (120, 20, 20),
                         pygame.Rect(20, 20, SCREEN_WIDTH - 40, SCREEN_HEIGHT - 40), 4)
        pygame.draw.rect(surface, RED,
                         pygame.Rect(25, 25, SCREEN_WIDTH - 50, SCREEN_HEIGHT - 50), 2)

        cx = SCREEN_WIDTH // 2
        draw_text(surface, "DEFEAT", cx, 140, 96, RED, center=True, shadow=True)
        draw_text(surface, "The horde is scattered to the winds.", cx, 260, 34,
                  ORANGE, center=True, shadow=True)

        player = self.game.factions.get("player")
        if player:
            pcount = player.province_count(self.game.provinces)
            draw_text(surface, f"Provinces Held at End: {pcount}", cx, 340, 26, WHITE, center=True)
            draw_text(surface, f"Turns Survived: {self.game.turn}", cx, 380, 26, WHITE, center=True)

        self.btn_menu.draw(surface)
