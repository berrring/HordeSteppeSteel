"""Province model for the campaign map."""
from __future__ import annotations
from typing import Optional, List


class Province:
    """A province on the campaign map."""

    def __init__(
        self,
        pid: str,
        name: str,
        x: float,
        y: float,
        owner_id: Optional[str],
        income: int = 100,
        defense_bonus: int = 0,
    ):
        self.pid = pid
        self.name = name
        self.x = x          # normalized 0-1 position on map
        self.y = y
        self.owner_id = owner_id
        self.income = income
        self.defense_bonus = defense_bonus
        self.neighbors: List[str] = []   # list of province pids
        self.is_capital: bool = False
        self.fortified: bool = False

    def add_neighbor(self, pid: str):
        if pid not in self.neighbors:
            self.neighbors.append(pid)

    def to_dict(self) -> dict:
        return {
            "pid": self.pid,
            "name": self.name,
            "x": self.x,
            "y": self.y,
            "owner_id": self.owner_id,
            "income": self.income,
            "defense_bonus": self.defense_bonus,
            "neighbors": self.neighbors,
            "is_capital": self.is_capital,
            "fortified": self.fortified,
        }

    @classmethod
    def from_dict(cls, d: dict) -> "Province":
        p = cls(
            d["pid"], d["name"], d["x"], d["y"],
            d["owner_id"], d["income"], d["defense_bonus"]
        )
        p.neighbors = d["neighbors"]
        p.is_capital = d["is_capital"]
        p.fortified = d["fortified"]
        return p

    def __repr__(self):
        return f"Province({self.pid}, {self.name}, owner={self.owner_id})"
