"""AI controller for enemy factions."""
from __future__ import annotations
import random
from typing import Dict, List, Optional, Tuple, TYPE_CHECKING

if TYPE_CHECKING:
    from horde.models.province import Province
    from horde.models.faction import Faction
    from horde.models.army import Army


class AIController:
    """Simple AI: attacks weakest reachable neighbor, reinforces if weak."""

    def __init__(self):
        pass

    def take_turn(
        self,
        faction: "Faction",
        provinces: Dict[str, "Province"],
        factions: Dict[str, "Faction"],
    ) -> List[dict]:
        """
        Execute AI turn. Returns list of action dicts:
          {"action": "attack", "from": pid, "to": pid}
          {"action": "recruit", "province": pid, "unit_type": str, "count": int}
          {"action": "reinforce", "from": pid, "to": pid}
        """
        actions = []

        if faction.is_defeated:
            return actions

        # Collect income first
        faction.collect_income(provinces)

        # Find owned provinces
        owned = [p for p in provinces.values() if p.owner_id == faction.faction_id]
        if not owned:
            faction.is_defeated = True
            return actions

        # Recruit: spend gold on new units if affordable
        actions += self._recruit(faction, owned, provinces)

        # Attack: find best attack opportunity
        actions += self._attack_phase(faction, owned, provinces, factions)

        return actions

    def _recruit(
        self,
        faction: "Faction",
        owned: list,
        provinces: dict,
    ) -> List[dict]:
        from horde.models.unit import UNIT_STATS
        from horde.constants import UNIT_INFANTRY, UNIT_HORSE_ARCHER
        actions = []
        # Recruit infantry at capital if we have gold
        capital = next((p for p in owned if p.is_capital), None)
        recruit_province = capital or (owned[0] if owned else None)
        if recruit_province and faction.gold >= 100:
            unit_type = UNIT_INFANTRY if faction.gold < 250 else UNIT_HORSE_ARCHER
            cost = UNIT_STATS[unit_type]["cost"]
            if faction.gold >= cost:
                army = faction.armies.get(recruit_province.pid)
                if army is None:
                    from horde.models.army import Army
                    army = Army(faction.faction_id)
                    faction.set_army(recruit_province.pid, army)
                army.add_unit(unit_type, 50)
                faction.gold -= cost
                actions.append({
                    "action": "recruit",
                    "province": recruit_province.pid,
                    "unit_type": unit_type,
                    "count": 50,
                })
        return actions

    def _attack_phase(
        self,
        faction: "Faction",
        owned: list,
        provinces: dict,
        factions: dict,
    ) -> List[dict]:
        actions = []
        # For each owned province that has an army, try to attack a neighbor
        for province in owned:
            army = faction.armies.get(province.pid)
            if army is None or army.is_empty:
                continue
            # Find attackable neighbors (not owned by us)
            targets = [
                provinces[pid] for pid in province.neighbors
                if pid in provinces and provinces[pid].owner_id != faction.faction_id
            ]
            if not targets:
                continue
            # Pick target with weakest defense
            def target_strength(t):
                owner = factions.get(t.owner_id) if t.owner_id else None
                if owner:
                    tarmy = owner.armies.get(t.pid)
                    return tarmy.total_strength if tarmy and not tarmy.is_empty else 0
                return 0

            target = min(targets, key=target_strength)
            # Only attack if we have numeric advantage or target is undefended
            our_str = army.total_strength
            their_str = target_strength(target)
            if our_str > their_str or their_str == 0:
                actions.append({
                    "action": "attack",
                    "from": province.pid,
                    "to": target.pid,
                })
        return actions
