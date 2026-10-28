"""Faction model."""
from __future__ import annotations
from typing import Dict, List, Optional, Tuple
from horde.models.army import Army
from horde.models.province import Province


class Faction:
    """Represents a player or AI faction."""

    def __init__(
        self,
        faction_id: str,
        name: str,
        color: Tuple[int, int, int],
        is_player: bool = False,
    ):
        self.faction_id = faction_id
        self.name = name
        self.color = color
        self.is_player = is_player
        self.gold: int = 500
        self.armies: Dict[str, Army] = {}   # province_pid -> Army
        self.is_defeated: bool = False

    def get_army(self, province_pid: str) -> Optional[Army]:
        return self.armies.get(province_pid)

    def set_army(self, province_pid: str, army: Army):
        self.armies[province_pid] = army

    def remove_army(self, province_pid: str):
        self.armies.pop(province_pid, None)

    def has_any_army(self) -> bool:
        return any(not a.is_empty for a in self.armies.values())

    def total_strength(self) -> int:
        return sum(a.total_strength for a in self.armies.values())

    def collect_income(self, provinces: Dict[str, Province]) -> int:
        income = sum(
            p.income for p in provinces.values()
            if p.owner_id == self.faction_id
        )
        self.gold += income
        return income

    def province_count(self, provinces: Dict[str, Province]) -> int:
        return sum(1 for p in provinces.values() if p.owner_id == self.faction_id)

    def __repr__(self):
        return f"Faction({self.faction_id}, {self.name}, gold={self.gold})"
