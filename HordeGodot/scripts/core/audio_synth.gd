class_name AudioSynth
extends RefCounted

# Generates clean, crisp 16-bit 44.1kHz mono PCM AudioStreamWAV resources procedurally
# Zero external dependencies, 100% royalty-free and guaranteed to load instantly.

static func create_wav(samples: PackedFloat32Array, sample_rate: int = 44100, loop_mode: AudioStreamWAV.LoopMode = AudioStreamWAV.LOOP_DISABLED) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.loop_mode = loop_mode
	
	var byte_data = PackedByteArray()
	byte_data.resize(samples.size() * 2)
	
	for i in range(samples.size()):
		var val = clampf(samples[i], -1.0, 1.0)
		var int_val = int(val * 32767.0)
		# 16-bit signed little-endian
		byte_data[i * 2] = int_val & 0xFF
		byte_data[i * 2 + 1] = (int_val >> 8) & 0xFF
		
	wav.data = byte_data
	if loop_mode != AudioStreamWAV.LOOP_DISABLED:
		wav.loop_begin = 0
		wav.loop_end = samples.size()
	return wav

# 1. UI Click: crisp wooden/stone tap
static func make_ui_click() -> AudioStreamWAV:
	var rate = 44100
	var dur = 0.04
	var count = int(rate * dur)
	var samples = PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t = float(i) / rate
		var env = exp(-t * 90.0)
		var freq = 1200.0 - t * 8000.0
		samples[i] = sin(TAU * freq * t) * env * 0.7
	return create_wav(samples, rate)

# 2. UI Confirm: resonant bronze chime
static func make_ui_confirm() -> AudioStreamWAV:
	var rate = 44100
	var dur = 0.18
	var count = int(rate * dur)
	var samples = PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t = float(i) / rate
		var env = exp(-t * 18.0)
		var s1 = sin(TAU * 587.33 * t) # D5
		var s2 = sin(TAU * 880.0 * t) * 0.5 # A5
		var s3 = sin(TAU * 1174.66 * t) * 0.25 # D6
		samples[i] = (s1 + s2 + s3) * env * 0.6
	return create_wav(samples, rate)

# 3. UI Error / Deny: dull wooden clunk
static func make_ui_error() -> AudioStreamWAV:
	var rate = 44100
	var dur = 0.15
	var count = int(rate * dur)
	var samples = PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t = float(i) / rate
		var env = exp(-t * 28.0)
		var s1 = sin(TAU * 110.0 * t)
		var s2 = sin(TAU * 146.0 * t) * 0.6
		samples[i] = (s1 + s2) * env * 0.8
	return create_wav(samples, rate)

# 4. Horn Call / War Horn (Mongol Brass / Ox Horn)
static func make_war_horn() -> AudioStreamWAV:
	var rate = 44100
	var dur = 1.1
	var count = int(rate * dur)
	var samples = PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t = float(i) / rate
		# Swell envelope
		var env = 0.0
		if t < 0.25:
			env = t / 0.25
		elif t < 0.85:
			env = 1.0
		else:
			env = (1.1 - t) / 0.25
		# Horn fundamental ~220Hz (A3) with brass harmonics
		var f = 220.0 + sin(t * 4.0) * 2.0
		var s = sin(TAU * f * t)
		s += sin(TAU * f * 2.0 * t) * 0.6
		s += sin(TAU * f * 3.0 * t) * 0.35
		s += sin(TAU * f * 4.0 * t) * 0.15
		samples[i] = s * env * 0.5
	return create_wav(samples, rate)

# 5. Marching War Drum (Steppe Taiko / Kettle Drum)
static func make_war_drum() -> AudioStreamWAV:
	var rate = 44100
	var dur = 0.45
	var count = int(rate * dur)
	var samples = PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t = float(i) / rate
		var env = exp(-t * 12.0)
		var freq = 120.0 * exp(-t * 15.0) + 45.0
		var s = sin(TAU * freq * t)
		# Add punch transient
		var noise = randf_range(-1.0, 1.0) * exp(-t * 40.0) * 0.4
		samples[i] = (s + noise) * env * 0.9
	return create_wav(samples, rate)

# 6. Arrow Whoosh / Launch
static func make_arrow_shoot() -> AudioStreamWAV:
	var rate = 44100
	var dur = 0.22
	var count = int(rate * dur)
	var samples = PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t = float(i) / rate
		var env = sin(PI * (t / dur))
		var freq = 450.0 + t * 2400.0
		var noise = randf_range(-0.5, 0.5)
		samples[i] = (sin(TAU * freq * t) * 0.6 + noise * 0.4) * env * 0.6
	return create_wav(samples, rate)

# 7. Sword / Steel Clang
static func make_sword_clash() -> AudioStreamWAV:
	var rate = 44100
	var dur = 0.35
	var count = int(rate * dur)
	var samples = PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t = float(i) / rate
		var env = exp(-t * 14.0)
		# Metallic non-harmonic frequencies
		var s = sin(TAU * 1850.0 * t) * 0.5
		s += sin(TAU * 2620.0 * t) * 0.35
		s += sin(TAU * 3480.0 * t) * 0.2
		var noise = randf_range(-0.8, 0.8) * exp(-t * 60.0)
		samples[i] = (s + noise) * env * 0.75
	return create_wav(samples, rate)

# 8. Heavy Shield Block
static func make_shield_block() -> AudioStreamWAV:
	var rate = 44100
	var dur = 0.3
	var count = int(rate * dur)
	var samples = PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t = float(i) / rate
		var env = exp(-t * 22.0)
		var s = sin(TAU * 95.0 * t) + sin(TAU * 190.0 * t) * 0.4
		var thud = randf_range(-0.6, 0.6) * exp(-t * 45.0)
		samples[i] = (s + thud) * env * 0.85
	return create_wav(samples, rate)

# 9. Cavalry Hooves Gallop
static func make_cavalry_gallop() -> AudioStreamWAV:
	var rate = 44100
	var dur = 0.5
	var count = int(rate * dur)
	var samples = PackedFloat32Array()
	samples.resize(count)
	# 3 distinct hoof thuds in 0.5 sec
	var thuds = [0.02, 0.16, 0.32]
	for idx in range(thuds.size()):
		var start_t = thuds[idx]
		var start_i = int(start_t * rate)
		for j in range(int(rate * 0.09)):
			if start_i + j < count:
				var t = float(j) / rate
				var env = exp(-t * 35.0)
				var s = sin(TAU * 75.0 * t) + randf_range(-0.4, 0.4) * exp(-t * 50.0)
				samples[start_i + j] += s * env * 0.7
	return create_wav(samples, rate)

# 10. Construction / Hammering Timber
static func make_hammer_build() -> AudioStreamWAV:
	var rate = 44100
	var dur = 0.4
	var count = int(rate * dur)
	var samples = PackedFloat32Array()
	samples.resize(count)
	var hits = [0.02, 0.18]
	for h in hits:
		var start_i = int(h * rate)
		for j in range(int(rate * 0.08)):
			if start_i + j < count:
				var t = float(j) / rate
				var env = exp(-t * 40.0)
				var s = sin(TAU * 480.0 * t) + randf_range(-0.5, 0.5) * exp(-t * 80.0)
				samples[start_i + j] += s * env * 0.75
	return create_wav(samples, rate)

# 11. Recruitment Anvil / Armor Clink
static func make_recruit_clink() -> AudioStreamWAV:
	var rate = 44100
	var dur = 0.3
	var count = int(rate * dur)
	var samples = PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t = float(i) / rate
		var env = exp(-t * 16.0)
		var s = sin(TAU * 1480.0 * t) * 0.6 + sin(TAU * 2960.0 * t) * 0.3
		samples[i] = s * env * 0.7
	return create_wav(samples, rate)

# 12. Steppe Wind Loop (Ambient)
static func make_steppe_wind_loop() -> AudioStreamWAV:
	var rate = 22050
	var dur = 4.0
	var count = int(rate * dur)
	var samples = PackedFloat32Array()
	samples.resize(count)
	
	# Pink/filtered brown noise with gentle rolling volume modulation
	var b0 = 0.0
	var b1 = 0.0
	var b2 = 0.0
	for i in range(count):
		var t = float(i) / rate
		var white = randf_range(-1.0, 1.0)
		b0 = 0.99 * b0 + white * 0.05
		b1 = 0.98 * b1 + b0 * 0.05
		b2 = 0.95 * b2 + b1 * 0.05
		
		# Gentle gust wave
		var gust = 0.6 + 0.35 * sin(TAU * 0.25 * t) + 0.15 * sin(TAU * 0.55 * t)
		samples[i] = b2 * gust * 0.5
	return create_wav(samples, rate, AudioStreamWAV.LOOP_FORWARD)

# 13. Atmospheric Medieval Steppe Music Loop
static func make_steppe_music_loop() -> AudioStreamWAV:
	var rate = 22050
	var dur = 8.0 # 8-second seamless modal steppe loop (D minor pentatonic: D, F, G, A, C)
	var count = int(rate * dur)
	var samples = PackedFloat32Array()
	samples.resize(count)
	
	# Drone note on D2 (73.4Hz) & A2 (110Hz) throughout
	for i in range(count):
		var t = float(i) / rate
		var drone = sin(TAU * 73.42 * t) * 0.22 + sin(TAU * 110.0 * t) * 0.14
		# Morin Khuur / Horsehead fiddle style melody notes
		# Notes pattern over 8s: D4(2s) -> F4(1.5s) -> G4(1.5s) -> A4(2s) -> C5(1s)
		var melody_freq = 293.66 # D4
		if t >= 6.5:
			melody_freq = 523.25 # C5
		elif t >= 4.5:
			melody_freq = 440.0 # A4
		elif t >= 3.0:
			melody_freq = 392.0 # G4
		elif t >= 1.5:
			melody_freq = 349.23 # F4
			
		var note_env = 0.5 + 0.5 * sin(TAU * (t * 0.5))
		var melody = sin(TAU * melody_freq * t) + sin(TAU * melody_freq * 2.0 * t) * 0.35
		samples[i] = (drone + melody * note_env * 0.25) * 0.6
		
	return create_wav(samples, rate, AudioStreamWAV.LOOP_FORWARD)
