"""Unit model for Horde: Steppe and Steel."""
from __future__ import annotations
import random
from horde.constants import (
    UNIT_HORSE_ARCHER, UNIT_HEAVY_CAVALRY, UNIT_INFANTRY, UNIT_SIEGE
)

# Base stats: (max_hp, attack, defense, movement, range, cost, description)
UNIT_STATS = {
    UNIT_HORSE_ARCHER: {
        "max_hp": 60,
        "attack": 35,
        "defense": 20,
        "movement": 3,
        "range": 2,
        "cost": 150,
        "description": "Fast mounted archers. Hit-and-run specialists.",
        "symbol": "HA",
    },
    UNIT_HEAVY_CAVALRY: {
        "max_hp": 100,
        "attack": 55,
        "defense": 45,
        "movement": 2,
        "range": 1,
        "cost": 250,
        "description": "Armoured shock cavalry. Devastating charge.",
        "symbol": "HC",
    },
    UNIT_INFANTRY: {
        "max_hp": 90,
        "attack": 40,
        "defense": 50,
        "movement": 1,
        "range": 1,
        "cost": 100,
        "description": "Sturdy foot soldiers. Excellent defense.",
        "symbol": "IN",
    },
    UNIT_SIEGE: {
        "max_hp": 50,
        "attack": 70,
        "defense": 10,
        "movement": 1,
        "range": 3,
        "cost": 300,
        "description": "Siege weapons. Long range, slow movement.",
        "symbol": "SG",
    },
}


class Unit:
    """A single battlefield unit."""

    _id_counter = 0

    def __init__(self, unit_type: str, faction_id: str, count: int = 100):
        Unit._id_counter += 1
        self.uid = Unit._id_counter
        self.unit_type = unit_type
        self.faction_id = faction_id
        self.count = count          # number of soldiers
        self.max_count = count

        stats = UNIT_STATS[unit_type]
        self.max_hp = stats["max_hp"]
        self.hp = self.max_hp
        self.attack = stats["attack"]
        self.defense = stats["defense"]
        self.movement = stats["movement"]
        self.range = stats["range"]
        self.cost = stats["cost"]
        self.description = stats["description"]
        self.symbol = stats["symbol"]

        # Battle state
        self.col: int = 0
        self.row: int = 0
        self.moved: bool = False
        self.attacked: bool = False
        self.is_alive: bool = True

    @property
    def name(self) -> str:
        return self.unit_type

    @property
    def effective_attack(self) -> float:
        """Attack scaled by remaining count."""
        return self.attack * (self.count / self.max_count)

    @property
    def effective_defense(self) -> float:
        return self.defense * (self.count / self.max_count)

    def reset_for_turn(self):
        self.moved = False
        self.attacked = False

    def take_damage(self, raw_damage: float):
        """Apply damage, reduce count proportionally."""
        actual = max(0.0, raw_damage - self.effective_defense * 0.3)
        self.hp -= actual
        # Reduce count proportionally
        if self.hp <= 0:
            self.count = 0
            self.hp = 0
            self.is_alive = False
        else:
            hp_ratio = self.hp / self.max_hp
            self.count = max(1, int(self.max_count * hp_ratio))

    def attack_unit(self, target: "Unit") -> int:
        """Perform an attack on target. Returns damage dealt."""
        base = self.effective_attack
        variance = random.uniform(0.8, 1.2)
        damage = base * variance
        target.take_damage(damage)
        self.attacked = True
        return int(damage)

    def can_reach(self, target_col: int, target_row: int) -> bool:
        dist = abs(self.col - target_col) + abs(self.row - target_row)
        return dist <= self.range

    def to_dict(self) -> dict:
        return {
            "unit_type": self.unit_type,
            "faction_id": self.faction_id,
            "count": self.count,
            "max_count": self.max_count,
            "hp": self.hp,
        }

    @classmethod
    def from_dict(cls, d: dict) -> "Unit":
        u = cls(d["unit_type"], d["faction_id"], d["max_count"])
        u.count = d["count"]
        u.hp = d["hp"]
        if u.count <= 0:
            u.is_alive = False
        return u

    def __repr__(self):
        return f"Unit({self.unit_type}, {self.faction_id}, {self.count}/{self.max_count})"
