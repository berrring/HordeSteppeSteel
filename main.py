"""
Horde: Steppe and Steel
========================
Entry point.
"""
import sys
import os

# Ensure package is importable
sys.path.insert(0, os.path.dirname(__file__))

from horde.game import Game


def main():
    game = Game()
    game.run()


if __name__ == "__main__":
    main()
