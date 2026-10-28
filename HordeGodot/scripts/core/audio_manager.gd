extends Node

const AudioSynth = preload("res://scripts/core/audio_synth.gd")

# Volumes in 0.0 - 1.0 linear scale
var master_volume: float = 0.85
var music_volume: float = 0.65
var sfx_volume: float = 0.8
var ui_volume: float = 0.75

# Players
var music_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer
var ui_player: AudioStreamPlayer
var sfx_pool: Array[AudioStreamPlayer] = []
var pool_size: int = 8
var pool_index: int = 0

# Cached audio streams
var streams: Dictionary = {}
var sound_cooldowns: Dictionary = {}

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_init_players()
	_pregenerate_sounds()
	start_ambience()
	start_music()

func _init_players():
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Master"
	add_child(music_player)
	
	ambient_player = AudioStreamPlayer.new()
	ambient_player.name = "AmbientPlayer"
	ambient_player.bus = "Master"
	add_child(ambient_player)
	
	ui_player = AudioStreamPlayer.new()
	ui_player.name = "UIPlayer"
	ui_player.bus = "Master"
	add_child(ui_player)
	
	for i in range(pool_size):
		var p = AudioStreamPlayer.new()
		p.name = "SFXPlayer_" + str(i)
		p.bus = "Master"
		add_child(p)
		sfx_pool.append(p)
		
	_apply_volumes()

func _pregenerate_sounds():
	streams["click"] = AudioSynth.make_ui_click()
	streams["confirm"] = AudioSynth.make_ui_confirm()
	streams["error"] = AudioSynth.make_ui_error()
	streams["horn"] = AudioSynth.make_war_horn()
	streams["drum"] = AudioSynth.make_war_drum()
	streams["arrow"] = AudioSynth.make_arrow_shoot()
	streams["sword"] = AudioSynth.make_sword_clash()
	streams["shield"] = AudioSynth.make_shield_block()
	streams["cavalry"] = AudioSynth.make_cavalry_gallop()
	streams["build"] = AudioSynth.make_hammer_build()
	streams["recruit"] = AudioSynth.make_recruit_clink()
	streams["wind"] = AudioSynth.make_steppe_wind_loop()
	streams["music"] = AudioSynth.make_steppe_music_loop()
	streams["victory"] = AudioSynth.make_victory_fanfare()
	streams["defeat"] = AudioSynth.make_defeat_drum()

func _process(delta: float):
	# Decrement cooldowns
	for key in sound_cooldowns.keys():
		sound_cooldowns[key] -= delta
		if sound_cooldowns[key] <= 0:
			sound_cooldowns.erase(key)

func _can_play(sound_name: String, cooldown: float = 0.08) -> bool:
	if sound_cooldowns.has(sound_name):
		return false
	sound_cooldowns[sound_name] = cooldown
	return true

func play_ui(sound_name: String):
	if not _can_play(sound_name, 0.05):
		return
	if streams.has(sound_name):
		ui_player.stream = streams[sound_name]
		ui_player.pitch_scale = randf_range(0.96, 1.04)
		ui_player.volume_db = linear_to_db(master_volume * ui_volume)
		ui_player.play()

func play_sfx(sound_name: String, cooldown: float = 0.08, pitch_var: float = 0.08):
	if not _can_play(sound_name, cooldown):
		return
	if not streams.has(sound_name):
		return
		
	var player = sfx_pool[pool_index]
	pool_index = (pool_index + 1) % pool_size
	
	player.stream = streams[sound_name]
	player.pitch_scale = randf_range(1.0 - pitch_var, 1.0 + pitch_var)
	player.volume_db = linear_to_db(master_volume * sfx_volume)
	player.play()

# Convenience SFX triggers
func play_click(): play_ui("click")
func play_confirm(): play_ui("confirm")
func play_error(): play_ui("error")
func play_war_horn(): play_sfx("horn", 0.4, 0.04)
func play_war_drum(): play_sfx("drum", 0.15, 0.1)
func play_arrow(): play_sfx("arrow", 0.06, 0.1)
func play_sword(): play_sfx("sword", 0.08, 0.12)
func play_shield(): play_sfx("shield", 0.1, 0.08)
func play_cavalry(): play_sfx("cavalry", 0.25, 0.06)
func play_build(): play_sfx("build", 0.2, 0.05)
func play_recruit(): play_sfx("recruit", 0.15, 0.05)
func play_victory(): play_sfx("victory", 0.35, 0.02)
func play_defeat(): play_sfx("defeat", 0.35, 0.02)

func start_ambience():
	if streams.has("wind") and ambient_player and ambient_player.is_inside_tree():
		ambient_player.stream = streams["wind"]
		ambient_player.volume_db = linear_to_db(master_volume * sfx_volume * 0.4)
		ambient_player.play()

func start_music():
	if streams.has("music") and music_player and music_player.is_inside_tree():
		music_player.stream = streams["music"]
		music_player.volume_db = linear_to_db(master_volume * music_volume * 0.55)
		music_player.play()

func stop_music():
	if music_player:
		music_player.stop()

func set_master_volume(val: float):
	master_volume = clampf(val, 0.0, 1.0)
	_apply_volumes()

func set_music_volume(val: float):
	music_volume = clampf(val, 0.0, 1.0)
	_apply_volumes()

func set_sfx_volume(val: float):
	sfx_volume = clampf(val, 0.0, 1.0)
	_apply_volumes()

func _apply_volumes():
	if music_player:
		music_player.volume_db = linear_to_db(master_volume * music_volume * 0.55)
	if ambient_player:
		ambient_player.volume_db = linear_to_db(master_volume * sfx_volume * 0.4)
	if ui_player:
		ui_player.volume_db = linear_to_db(master_volume * ui_volume)
	for p in sfx_pool:
		p.volume_db = linear_to_db(master_volume * sfx_volume)
