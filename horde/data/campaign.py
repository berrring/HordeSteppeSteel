"""Campaign data: provinces, factions, starting armies."""
from __future__ import annotations
from typing import Dict, List, Tuple
from horde.models.province import Province
from horde.models.faction import Faction
from horde.models.army import Army
from horde.constants import (
    PLAYER_COLOR, ENEMY_1_COLOR, ENEMY_2_COLOR, ENEMY_3_COLOR,
    UNIT_HORSE_ARCHER, UNIT_HEAVY_CAVALRY, UNIT_INFANTRY, UNIT_SIEGE,
)


def build_campaign() -> Tuple[Dict[str, Province], Dict[str, Faction]]:
    """
    Build a 12-province campaign map.
    Returns (provinces_dict, factions_dict).
    """
    # --- Factions ---
    factions: Dict[str, Faction] = {}

    player = Faction("player", "The Golden Horde", PLAYER_COLOR, is_player=True)
    player.gold = 500
    factions["player"] = player

    red = Faction("red", "Rus Principalities", ENEMY_1_COLOR)
    red.gold = 400
    factions["red"] = red

    blue = Faction("blue", "Persian Sultanate", ENEMY_2_COLOR)
    blue.gold = 400
    factions["blue"] = blue

    green = Faction("green", "Chinese Dynasty", ENEMY_3_COLOR)
    green.gold = 400
    factions["green"] = green

    # --- Provinces ---
    # Layout: steppe map roughly 0..1 in x,y
    # Each province: (pid, name, x, y, owner, income)
    raw_provinces = [
        # Steppe heartland (player start)
        ("sarai",    "Sarai",         0.35, 0.45, "player", 150, 10),
        ("kipchak",  "Kipchak Steppe",0.25, 0.35, "player", 120, 0),
        # Northern (red faction)
        ("novgorod", "Novgorod",      0.20, 0.15, "red",    130, 15),
        ("moscow",   "Moscow",        0.30, 0.20, "red",    140, 10),
        ("kiev",     "Kiev",          0.25, 0.30, "red",    120, 5),
        # Eastern (green faction)
        ("karakorum","Karakorum",     0.70, 0.30, "green",  160, 20),
        ("zhongdu",  "Zhongdu",       0.80, 0.40, "green",  180, 15),
        ("shangdu",  "Shangdu",       0.75, 0.20, "green",  140, 10),
        # Southern (blue faction)
        ("samarkand","Samarkand",     0.55, 0.60, "blue",   150, 10),
        ("bukhara",  "Bukhara",       0.45, 0.65, "blue",   130, 5),
        ("tabriz",   "Tabriz",        0.40, 0.72, "blue",   120, 5),
        # Neutral center
        ("urgench",  "Urgench",       0.50, 0.50, None,     110, 0),
    ]

    provinces: Dict[str, Province] = {}
    for pid, name, x, y, owner, income, defb in raw_provinces:
        p = Province(pid, name, x, y, owner, income, defb)
        provinces[pid] = p

    # Mark capitals
    provinces["sarai"].is_capital = True
    provinces["novgorod"].is_capital = True
    provinces["karakorum"].is_capital = True
    provinces["tabriz"].is_capital = True

    # --- Neighbors (adjacency graph) ---
    edges = [
        ("sarai",     "kipchak"),
        ("sarai",     "urgench"),
        ("sarai",     "kiev"),
        ("sarai",     "samarkand"),
        ("kipchak",   "kiev"),
        ("kipchak",   "moscow"),
        ("kipchak",   "urgench"),
        ("kiev",      "moscow"),
        ("moscow",    "novgorod"),
        ("urgench",   "samarkand"),
        ("urgench",   "karakorum"),
        ("samarkand", "bukhara"),
        ("samarkand", "karakorum"),
        ("bukhara",   "tabriz"),
        ("tabriz",    "samarkand"),
        ("karakorum", "zhongdu"),
        ("karakorum", "shangdu"),
        ("zhongdu",   "shangdu"),
    ]
    for a, b in edges:
        provinces[a].add_neighbor(b)
        provinces[b].add_neighbor(a)

    # --- Starting Armies ---
    # Player
    pa = Army("player")
    pa.add_unit(UNIT_HORSE_ARCHER, 100)
    pa.add_unit(UNIT_HORSE_ARCHER, 80)
    pa.add_unit(UNIT_INFANTRY, 60)
    player.set_army("sarai", pa)

    pa2 = Army("player")
    pa2.add_unit(UNIT_HORSE_ARCHER, 70)
    player.set_army("kipchak", pa2)

    # Red faction
    ra = Army("red")
    ra.add_unit(UNIT_INFANTRY, 100)
    ra.add_unit(UNIT_HEAVY_CAVALRY, 50)
    red.set_army("novgorod", ra)

    ra2 = Army("red")
    ra2.add_unit(UNIT_INFANTRY, 80)
    red.set_army("moscow", ra2)

    ra3 = Army("red")
    ra3.add_unit(UNIT_INFANTRY, 60)
    red.set_army("kiev", ra3)

    # Blue faction
    ba = Army("blue")
    ba.add_unit(UNIT_SIEGE, 50)
    ba.add_unit(UNIT_INFANTRY, 80)
    blue.set_army("tabriz", ba)

    ba2 = Army("blue")
    ba2.add_unit(UNIT_INFANTRY, 70)
    blue.set_army("samarkand", ba2)

    # Green faction
    ga = Army("green")
    ga.add_unit(UNIT_HEAVY_CAVALRY, 80)
    ga.add_unit(UNIT_INFANTRY, 100)
    green.set_army("karakorum", ga)

    ga2 = Army("green")
    ga2.add_unit(UNIT_HEAVY_CAVALRY, 60)
    green.set_army("zhongdu", ga2)

    return provinces, factions
