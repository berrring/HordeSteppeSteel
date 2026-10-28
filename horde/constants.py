"""Constants for Horde: Steppe and Steel."""

# --- Window ---
SCREEN_WIDTH = 1280
SCREEN_HEIGHT = 720
TITLE = "Horde: Steppe and Steel"
FPS = 60

# --- Colors ---
BLACK       = (0, 0, 0)
WHITE       = (255, 255, 255)
GRAY        = (128, 128, 128)
DARK_GRAY   = (40, 40, 40)
LIGHT_GRAY  = (200, 200, 200)
RED         = (200, 50, 50)
DARK_RED    = (140, 20, 20)
GREEN       = (50, 180, 50)
DARK_GREEN  = (20, 120, 20)
BLUE        = (50, 100, 200)
DARK_BLUE   = (20, 60, 150)
YELLOW      = (220, 200, 60)
DARK_YELLOW = (160, 140, 20)
ORANGE      = (210, 120, 30)
BROWN       = (139, 90, 43)
DARK_BROWN  = (80, 50, 20)
TAN         = (210, 180, 140)
SAND        = (240, 220, 170)
PARCHMENT   = (245, 230, 190)

# Faction colors
PLAYER_COLOR    = (220, 180, 60)   # Golden Horde
ENEMY_1_COLOR   = (160, 60, 60)    # Red faction
ENEMY_2_COLOR   = (60, 60, 160)    # Blue faction
ENEMY_3_COLOR   = (60, 140, 60)    # Green faction
NEUTRAL_COLOR   = (140, 140, 140)

# --- Game States ---
STATE_MAIN_MENU    = "main_menu"
STATE_CAMPAIGN     = "campaign"
STATE_BATTLE       = "battle"
STATE_VICTORY      = "victory"
STATE_DEFEAT       = "defeat"
STATE_QUIT         = "quit"

# --- Gameplay ---
PROVINCES_TO_WIN = 10   # Capture this many provinces to win
MAX_TURNS = 60          # Turn limit before defeat

# --- Unit Types ---
UNIT_HORSE_ARCHER   = "Horse Archer"
UNIT_HEAVY_CAVALRY  = "Heavy Cavalry"
UNIT_INFANTRY       = "Infantry"
UNIT_SIEGE          = "Siege Engine"

# --- Battle ---
BATTLE_GRID_COLS = 8
BATTLE_GRID_ROWS = 5
