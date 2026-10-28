# Horde: Steppe and Steel

A turn-based grand strategy game set in the Mongol steppe era.

## Requirements

```
pip install -r requirements.txt
```

## Running

```
python main.py
```

## Running Tests

```
pytest tests/ -v
```

## How to Play

### Campaign Map
- **Left-click** one of your provinces (highlighted gold) to select it
- **Left-click** an adjacent enemy province (red border) to attack
- Use the **Recruit** buttons to train new units in your selected province
- Click **End Turn** to advance time and trigger AI turns

### Battle Screen
- Click a **friendly unit** (left side) to select it
- Click an **enemy unit** (right side) to attack
- Click **End Turn** to let the enemy attack
- Click **Retreat** to withdraw without fighting

### Victory Conditions
- Capture **10 provinces** to win the campaign
- Or eliminate all enemy factions

### Defeat Conditions
- Lose all provinces and all armies
- Turn limit exceeded (60 turns)

## Controls
- Mouse: All interactions
- Window close button: Exit game
