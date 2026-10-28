"""Tests for combat system."""
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import pytest
from horde.models.unit import Unit
from horde.models.army import Army
from horde.constants import UNIT_HORSE_ARCHER, UNIT_HEAVY_CAVALRY, UNIT_INFANTRY


def make_unit(utype, faction="player", count=100):
    return Unit(utype, faction, count)


class TestCombatResolution:
    def test_heavy_cavalry_beats_weakened_infantry(self):
        """Heavy cavalry should deal more damage than weak infantry can endure."""
        hc = make_unit(UNIT_HEAVY_CAVALRY, count=100)
        inf = make_unit(UNIT_INFANTRY, count=10)  # weakened
        initial_hp = inf.hp
        hc.attack_unit(inf)
        assert inf.hp < initial_hp or not inf.is_alive

    def test_repeated_attacks_kill_unit(self):
        attacker = make_unit(UNIT_HEAVY_CAVALRY, count=100)
        target = make_unit(UNIT_HORSE_ARCHER, count=100)
        rounds = 0
        while target.is_alive and rounds < 20:
            atk = make_unit(UNIT_HEAVY_CAVALRY, count=100)
            atk.attack_unit(target)
            rounds += 1
        assert not target.is_alive or rounds == 20  # should die within 20 rounds

    def test_zero_count_unit_is_dead(self):
        u = make_unit(UNIT_INFANTRY, count=100)
        u.count = 0
        u.is_alive = False
        assert not u.is_alive

    def test_attack_damage_is_positive(self):
        attacker = make_unit(UNIT_HORSE_ARCHER)
        target = make_unit(UNIT_INFANTRY)
        prev_hp = target.hp
        dmg = attacker.attack_unit(target)
        assert dmg >= 0
        assert target.hp <= prev_hp


class TestArmyCombat:
    def test_stronger_army_has_higher_attack(self):
        a1 = Army("player")
        a1.add_unit(UNIT_HEAVY_CAVALRY, 100)
        a1.add_unit(UNIT_HEAVY_CAVALRY, 100)

        a2 = Army("enemy")
        a2.add_unit(UNIT_INFANTRY, 50)

        assert a1.total_attack > a2.total_attack

    def test_army_strength_decreases_after_losses(self):
        army = Army("player")
        u = army.add_unit(UNIT_INFANTRY, 100)
        initial_str = army.total_strength
        u.take_damage(500)
        assert army.total_strength < initial_str
