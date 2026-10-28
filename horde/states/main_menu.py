"""Main Menu state."""
from __future__ import annotations
import pygame
from horde.constants import (
    SCREEN_WIDTH, SCREEN_HEIGHT, PARCHMENT, DARK_BROWN, BROWN,
    YELLOW, ORANGE, WHITE, BLACK, DARK_GREEN, GREEN, RED, DARK_RED,
)
from horde.ui.ui_utils import Button, draw_text, Panel, get_font


class MainMenuState:
    """Renders the main menu and handles new game / quit."""

    def __init__(self, game):
        self.game = game
        self._build_buttons()
        self._tick = 0

    def _build_buttons(self):
        cx = SCREEN_WIDTH // 2
        self.btn_new_game = Button(cx - 120, 380, 240, 55, "New Campaign",
                                   DARK_GREEN, GREEN, WHITE, 26)
        self.btn_quit = Button(cx - 120, 460, 240, 55, "Quit",
                               DARK_RED, RED, WHITE, 26)
        self.buttons = [self.btn_new_game, self.btn_quit]

    def handle_event(self, event):
        for btn in self.buttons:
            if btn.handle_event(event):
                if btn is self.btn_new_game:
                    self.game.start_new_campaign()
                elif btn is self.btn_quit:
                    self.game.quit()

    def update(self, dt):
        self._tick += dt
        mouse = pygame.mouse.get_pos()
        for btn in self.buttons:
            btn.update(mouse)

    def draw(self, surface: pygame.Surface):
        # Background gradient (steppe sky)
        surface.fill((30, 20, 10))
        # Draw decorative border
        pygame.draw.rect(surface, (100, 70, 20),
                         pygame.Rect(20, 20, SCREEN_WIDTH - 40, SCREEN_HEIGHT - 40), 4)
        pygame.draw.rect(surface, (180, 140, 60),
                         pygame.Rect(24, 24, SCREEN_WIDTH - 48, SCREEN_HEIGHT - 48), 2)

        # Title
        draw_text(surface, "HORDE", SCREEN_WIDTH // 2, 150,
                  size=96, color=YELLOW, center=True, shadow=True)
        draw_text(surface, "Steppe and Steel", SCREEN_WIDTH // 2, 250,
                  size=42, color=ORANGE, center=True, shadow=True)
        draw_text(surface, "A Turn-Based Strategy Game",
                  SCREEN_WIDTH // 2, 310, size=22, color=(180, 160, 120),
                  center=True)

        for btn in self.buttons:
            btn.draw(surface)

        draw_text(surface, "v1.0  |  2026", SCREEN_WIDTH // 2, SCREEN_HEIGHT - 40,
                  size=16, color=(100, 80, 50), center=True)
