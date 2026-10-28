"""Tests for unit combat mechanics."""
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import pytest
from horde.models.unit import Unit
from horde.constants import UNIT_HORSE_ARCHER, UNIT_HEAVY_CAVALRY, UNIT_INFANTRY, UNIT_SIEGE


def make_unit(utype, count=100):
    return Unit(utype, "test", count)


class TestUnitCreation:
    def test_horse_archer_stats(self):
        u = make_unit(UNIT_HORSE_ARCHER)
        assert u.unit_type == UNIT_HORSE_ARCHER
        assert u.max_hp == 60
        assert u.attack == 35
        assert u.defense == 20
        assert u.movement == 3
        assert u.range == 2
        assert u.count == 100
        assert u.is_alive

    def test_heavy_cavalry_stats(self):
        u = make_unit(UNIT_HEAVY_CAVALRY)
        assert u.max_hp == 100
        assert u.attack == 55
        assert u.defense == 45

    def test_infantry_stats(self):
        u = make_unit(UNIT_INFANTRY)
        assert u.max_hp == 90
        assert u.defense == 50

    def test_siege_stats(self):
        u = make_unit(UNIT_SIEGE)
        assert u.attack == 70
        assert u.range == 3


class TestUnitCombat:
    def test_take_damage_reduces_count(self):
        u = make_unit(UNIT_INFANTRY, 100)
        u.take_damage(50)
        assert u.count < 100
        assert u.hp < u.max_hp

    def test_lethal_damage_kills_unit(self):
        u = make_unit(UNIT_HORSE_ARCHER, 100)
        u.take_damage(10000)
        assert not u.is_alive
        assert u.count == 0

    def test_attack_marks_attacked(self):
        attacker = make_unit(UNIT_HORSE_ARCHER)
        target = make_unit(UNIT_INFANTRY)
        attacker.attack_unit(target)
        assert attacker.attacked

    def test_attack_reduces_target_hp(self):
        attacker = make_unit(UNIT_HEAVY_CAVALRY)
        target = make_unit(UNIT_INFANTRY)
        original_hp = target.hp
        attacker.attack_unit(target)
        assert target.hp <= original_hp

    def test_reset_for_turn(self):
        u = make_unit(UNIT_HORSE_ARCHER)
        u.attacked = True
        u.moved = True
        u.reset_for_turn()
        assert not u.attacked
        assert not u.moved


class TestUnitRange:
    def test_in_range(self):
        u = make_unit(UNIT_SIEGE)
        u.col = 0
        u.row = 0
        assert u.can_reach(3, 0)   # range == 3

    def test_out_of_range(self):
        u = make_unit(UNIT_INFANTRY)
        u.col = 0
        u.row = 0
        assert not u.can_reach(3, 0)  # infantry range == 1

    def test_adjacent_always_reachable(self):
        u = make_unit(UNIT_INFANTRY)
        u.col = 3
        u.row = 3
        assert u.can_reach(4, 3)


class TestUnitSerialization:
    def test_round_trip(self):
        u = make_unit(UNIT_HORSE_ARCHER, 80)
        d = u.to_dict()
        u2 = Unit.from_dict(d)
        assert u2.unit_type == u.unit_type
        assert u2.count == u.count
        assert u2.faction_id == u.faction_id
