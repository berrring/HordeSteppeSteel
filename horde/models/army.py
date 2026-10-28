"""Army model - a collection of units belonging to one faction."""
from __future__ import annotations
from typing import List, Optional
from horde.models.unit import Unit, UNIT_STATS
from horde.constants import (
    UNIT_HORSE_ARCHER, UNIT_HEAVY_CAVALRY, UNIT_INFANTRY, UNIT_SIEGE
)


class Army:
    """An army is a list of units stationed in or moving toward a province."""

    def __init__(self, faction_id: str):
        self.faction_id = faction_id
        self.units: List[Unit] = []

    def add_unit(self, unit_type: str, count: int = 100) -> Unit:
        u = Unit(unit_type, self.faction_id, count)
        self.units.append(u)
        return u

    def remove_dead(self):
        self.units = [u for u in self.units if u.is_alive and u.count > 0]

    @property
    def is_empty(self) -> bool:
        self.remove_dead()
        return len(self.units) == 0

    @property
    def total_strength(self) -> int:
        return sum(u.count for u in self.units if u.is_alive)

    @property
    def total_attack(self) -> float:
        return sum(u.effective_attack for u in self.units if u.is_alive)

    @property
    def total_defense(self) -> float:
        return sum(u.effective_defense for u in self.units if u.is_alive)

    def unit_count(self) -> int:
        return len([u for u in self.units if u.is_alive])

    def living_units(self) -> List[Unit]:
        return [u for u in self.units if u.is_alive and u.count > 0]

    def reset_for_turn(self):
        for u in self.units:
            u.reset_for_turn()

    def to_dict(self) -> dict:
        return {
            "faction_id": self.faction_id,
            "units": [u.to_dict() for u in self.units],
        }

    @classmethod
    def from_dict(cls, d: dict) -> "Army":
        a = cls(d["faction_id"])
        a.units = [Unit.from_dict(ud) for ud in d["units"]]
        return a

    def __repr__(self):
        return f"Army({self.faction_id}, units={len(self.units)}, str={self.total_strength})"
