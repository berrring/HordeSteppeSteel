"""Tests for campaign logic and AI."""
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import pytest
from horde.data.campaign import build_campaign
from horde.models.army import Army
from horde.models.faction import Faction
from horde.ai.ai_controller import AIController
from horde.constants import (
    UNIT_INFANTRY, UNIT_HORSE_ARCHER, PROVINCES_TO_WIN
)


class TestCampaignSetup:
    def setup_method(self):
        self.provinces, self.factions = build_campaign()

    def test_provinces_exist(self):
        assert len(self.provinces) >= 10

    def test_player_faction_exists(self):
        assert "player" in self.factions
        assert self.factions["player"].is_player

    def test_enemy_factions_exist(self):
        enemies = [f for fid, f in self.factions.items() if not f.is_player]
        assert len(enemies) >= 2

    def test_player_starts_with_provinces(self):
        player = self.factions["player"]
        pcount = player.province_count(self.provinces)
        assert pcount >= 1

    def test_provinces_have_neighbors(self):
        for pid, p in self.provinces.items():
            assert len(p.neighbors) >= 1, f"{pid} has no neighbors"

    def test_neighbor_symmetry(self):
        for pid, p in self.provinces.items():
            for npid in p.neighbors:
                assert npid in self.provinces, f"Neighbor {npid} of {pid} not in provinces"
                assert pid in self.provinces[npid].neighbors, \
                    f"Neighbor relationship not symmetric: {pid} <-> {npid}"

    def test_player_has_starting_army(self):
        player = self.factions["player"]
        assert player.has_any_army()

    def test_gold_initialized(self):
        for fid, f in self.factions.items():
            assert f.gold >= 0


class TestFactionLogic:
    def setup_method(self):
        self.provinces, self.factions = build_campaign()

    def test_collect_income(self):
        player = self.factions["player"]
        initial = player.gold
        income = player.collect_income(self.provinces)
        assert income > 0
        assert player.gold == initial + income

    def test_province_count(self):
        player = self.factions["player"]
        owned = [p for p in self.provinces.values() if p.owner_id == "player"]
        assert player.province_count(self.provinces) == len(owned)

    def test_defeat_when_no_provinces(self):
        provinces, factions = build_campaign()
        player = factions["player"]
        # Give all provinces to red
        for p in provinces.values():
            p.owner_id = "red"
        player.armies.clear()
        pcount = player.province_count(provinces)
        assert pcount == 0
        assert not player.has_any_army()


class TestArmyLogic:
    def test_add_units(self):
        army = Army("player")
        army.add_unit(UNIT_INFANTRY, 100)
        army.add_unit(UNIT_HORSE_ARCHER, 80)
        assert army.unit_count() == 2
        assert army.total_strength == 180

    def test_remove_dead_units(self):
        army = Army("player")
        u = army.add_unit(UNIT_INFANTRY, 100)
        u.take_damage(99999)
        army.remove_dead()
        assert army.is_empty

    def test_empty_army_detection(self):
        army = Army("player")
        assert army.is_empty

    def test_army_serialization(self):
        army = Army("player")
        army.add_unit(UNIT_INFANTRY, 100)
        d = army.to_dict()
        army2 = Army.from_dict(d)
        assert army2.faction_id == army.faction_id
        assert army2.unit_count() == army.unit_count()


class TestVictoryConditions:
    """Test win/lose detection via a mock Game-like object."""

    def _mock_game(self):
        from types import SimpleNamespace
        provinces, factions = build_campaign()
        g = SimpleNamespace(
            provinces=provinces,
            factions=factions,
            turn=1,
        )
        return g, provinces, factions

    def test_no_win_at_start(self):
        from horde.constants import PROVINCES_TO_WIN
        g, provinces, factions = self._mock_game()
        player = factions["player"]
        pcount = player.province_count(provinces)
        assert pcount < PROVINCES_TO_WIN

    def test_win_when_all_provinces_owned(self):
        g, provinces, factions = self._mock_game()
        player = factions["player"]
        for p in provinces.values():
            p.owner_id = "player"
        pcount = player.province_count(provinces)
        assert pcount == len(provinces)
        assert pcount >= PROVINCES_TO_WIN

    def test_lose_when_no_provinces_and_no_armies(self):
        g, provinces, factions = self._mock_game()
        player = factions["player"]
        for p in provinces.values():
            if p.owner_id == "player":
                p.owner_id = "red"
        player.armies.clear()
        assert player.province_count(provinces) == 0
        assert not player.has_any_army()


class TestAIController:
    def setup_method(self):
        self.provinces, self.factions = build_campaign()
        self.ai = AIController()

    def test_ai_produces_actions(self):
        red = self.factions["red"]
        actions = self.ai.take_turn(red, self.provinces, self.factions)
        # Should produce at least income collection (no exception)
        assert isinstance(actions, list)

    def test_defeated_ai_does_nothing(self):
        red = self.factions["red"]
        red.is_defeated = True
        actions = self.ai.take_turn(red, self.provinces, self.factions)
        assert actions == []

    def test_ai_collects_income(self):
        red = self.factions["red"]
        initial_gold = red.gold
        self.ai.take_turn(red, self.provinces, self.factions)
        # Gold should increase (income collected)
        assert red.gold >= initial_gold
