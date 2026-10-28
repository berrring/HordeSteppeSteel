"""UI utilities: Button, Panel, fonts."""
from __future__ import annotations
import pygame
from horde.constants import (
    BLACK, WHITE, GRAY, DARK_GRAY, LIGHT_GRAY,
    DARK_GREEN, GREEN, RED, DARK_RED, YELLOW, DARK_YELLOW,
    ORANGE, TAN, PARCHMENT,
)

_fonts: dict = {}


def get_font(size: int) -> pygame.font.Font:
    if size not in _fonts:
        try:
            _fonts[size] = pygame.font.SysFont("Georgia", size)
        except Exception:
            _fonts[size] = pygame.font.Font(None, size)
    return _fonts[size]


def draw_text(
    surface: pygame.Surface,
    text: str,
    x: int,
    y: int,
    size: int = 20,
    color=WHITE,
    center: bool = False,
    shadow: bool = False,
):
    font = get_font(size)
    if shadow:
        s = font.render(text, True, BLACK)
        sr = s.get_rect()
        if center:
            sr.center = (x + 2, y + 2)
        else:
            sr.topleft = (x + 2, y + 2)
        surface.blit(s, sr)
    img = font.render(text, True, color)
    r = img.get_rect()
    if center:
        r.center = (x, y)
    else:
        r.topleft = (x, y)
    surface.blit(img, r)
    return r


class Button:
    """A clickable button."""

    def __init__(
        self,
        x: int,
        y: int,
        width: int,
        height: int,
        text: str,
        color=DARK_GREEN,
        hover_color=GREEN,
        text_color=WHITE,
        font_size: int = 22,
        border_radius: int = 6,
    ):
        self.rect = pygame.Rect(x, y, width, height)
        self.text = text
        self.color = color
        self.hover_color = hover_color
        self.text_color = text_color
        self.font_size = font_size
        self.border_radius = border_radius
        self.hovered = False
        self.enabled = True

    def update(self, mouse_pos):
        self.hovered = self.rect.collidepoint(mouse_pos) and self.enabled

    def handle_event(self, event) -> bool:
        """Returns True if button was clicked."""
        if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            if self.hovered and self.enabled:
                return True
        return False

    def draw(self, surface: pygame.Surface):
        col = self.hover_color if self.hovered else self.color
        if not self.enabled:
            col = DARK_GRAY
        pygame.draw.rect(surface, col, self.rect, border_radius=self.border_radius)
        pygame.draw.rect(surface, WHITE, self.rect, 2, border_radius=self.border_radius)
        draw_text(
            surface, self.text,
            self.rect.centerx, self.rect.centery,
            self.font_size, self.text_color, center=True, shadow=True
        )


class Panel:
    """A simple panel background."""

    def __init__(self, x, y, width, height, color=DARK_GRAY, alpha=220, border=True):
        self.rect = pygame.Rect(x, y, width, height)
        self.color = color
        self.alpha = alpha
        self.border = border
        self._surface = pygame.Surface((width, height), pygame.SRCALPHA)

    def draw(self, surface: pygame.Surface):
        self._surface.fill((*self.color, self.alpha))
        surface.blit(self._surface, self.rect.topleft)
        if self.border:
            pygame.draw.rect(surface, YELLOW, self.rect, 2)
