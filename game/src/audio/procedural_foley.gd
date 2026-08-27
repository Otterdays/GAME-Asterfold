class_name ProceduralFoley
extends RefCounted

## Seeded Karplus-Strong and foley transients for prototype title audio.
## Constraint: original material only; no sampled libraries. See docs/AUDIO_DIRECTION.md.

const SAMPLE_RATE: int = 22050
const TITLE_DURATION_S: float = 24.0
const TITLE_BPM: float = 90.0


static func title_loop_samples() -> PackedFloat32Array:
	var total: int = int(TITLE_DURATION_S * float(SAMPLE_RATE))
	var mix: PackedFloat32Array = PackedFloat32Array()
	mix.resize(total)
	var beat_s: float = 60.0 / TITLE_BPM
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260827
	_mix_add(mix, _sine_drone(146.83, TITLE_DURATION_S, 0.045), 0)
	_mix_add(mix, _sine_drone(220.00, TITLE_DURATION_S, 0.028), 0)
	var melody: Array[float] = [
		293.66, 0.0, 440.00, 349.23,
		392.00, 440.00, 293.66, 0.0,
		349.23, 392.00, 440.00, 523.25,
		440.00, 349.23, 293.66, 220.00,
	]
	var beat_count: int = int(TITLE_DURATION_S / beat_s)
	for beat: int in beat_count:
		var start: int = int(float(beat) * beat_s * float(SAMPLE_RATE))
		var degree: float = melody[beat % melody.size()]
		if beat >= 16 and beat < 24 and degree > 0.0:
			degree *= 1.5
		if degree > 0.0:
			var pluck: PackedFloat32Array = _karplus_pluck(
				degree,
				beat_s * 1.35,
				rng.randi(),
				0.72
			)
			_mix_add(mix, pluck, start)
		if beat % 3 == 0:
			_mix_add(mix, _wood_knock(rng.randi(), 0.22), start)
		if beat % 16 == 8:
			_mix_add(mix, _small_bell(880.0, 1.4, rng.randi()), start)
		if beat % 8 == 4:
			_mix_add(mix, _cloth_rustle(rng.randi(), 0.18), start)
	_mix_add(mix, _room_hiss(total, 20260827, 0.012), 0)
	_normalize(mix, 0.72)
	return mix


static func hover_bling_samples() -> PackedFloat32Array:
	var mix: PackedFloat32Array = PackedFloat32Array()
	mix.resize(int(0.16 * float(SAMPLE_RATE)))
	_mix_add(mix, _small_bell(1174.66, 0.16, 11), 0)
	_mix_add(mix, _karplus_pluck(1567.98, 0.12, 13, 0.9), 0)
	_normalize(mix, 0.55)
	return mix


static func click_samples() -> PackedFloat32Array:
	var mix: PackedFloat32Array = PackedFloat32Array()
	mix.resize(int(0.09 * float(SAMPLE_RATE)))
	_mix_add(mix, _wood_knock(17, 0.55), 0)
	_mix_add(mix, _karplus_pluck(196.0, 0.08, 19, 0.4), 0)
	_normalize(mix, 0.62)
	return mix


static func to_pcm16(samples: PackedFloat32Array) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for index: int in samples.size():
		var clipped: float = clampf(samples[index], -1.0, 1.0)
		var pcm: int = clampi(int(clipped * 32767.0), -32768, 32767)
		bytes.encode_s16(index * 2, pcm)
	return bytes


static func make_wav_stream(samples: PackedFloat32Array) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = to_pcm16(samples)
	return stream


static func _karplus_pluck(
	frequency_hz: float,
	duration_s: float,
	seed_value: int,
	brightness: float
) -> PackedFloat32Array:
	var period: int = maxi(2, int(round(float(SAMPLE_RATE) / frequency_hz)))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var delay: PackedFloat32Array = PackedFloat32Array()
	delay.resize(period)
	for tap: int in period:
		delay[tap] = rng.randf_range(-1.0, 1.0) * brightness
	var total: int = maxi(1, int(duration_s * float(SAMPLE_RATE)))
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(total)
	var write_index: int = 0
	var decay: float = 0.988
	for sample_index: int in total:
		var current: float = delay[write_index]
		out[sample_index] = current
		var next_index: int = (write_index + 1) % period
		delay[write_index] = (current + delay[next_index]) * 0.5 * decay
		write_index = next_index
	return out


static func _sine_drone(frequency_hz: float, duration_s: float, amplitude: float) -> PackedFloat32Array:
	var total: int = int(duration_s * float(SAMPLE_RATE))
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(total)
	var omega: float = TAU * frequency_hz / float(SAMPLE_RATE)
	for index: int in total:
		var envelope: float = 1.0
		if index < SAMPLE_RATE:
			envelope = float(index) / float(SAMPLE_RATE)
		var remaining: int = total - index
		if remaining < SAMPLE_RATE:
			envelope *= float(remaining) / float(SAMPLE_RATE)
		out[index] = sin(omega * float(index)) * amplitude * envelope
	return out


static func _wood_knock(seed_value: int, amplitude: float) -> PackedFloat32Array:
	var total: int = int(0.07 * float(SAMPLE_RATE))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(total)
	var previous: float = 0.0
	for index: int in total:
		var burst: float = rng.randf_range(-1.0, 1.0)
		previous = previous * 0.55 + burst * 0.45
		var envelope: float = exp(-float(index) / (0.012 * float(SAMPLE_RATE)))
		out[index] = previous * envelope * amplitude
	return out


static func _small_bell(frequency_hz: float, duration_s: float, seed_value: int) -> PackedFloat32Array:
	var total: int = int(duration_s * float(SAMPLE_RATE))
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(total)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var detune: float = 1.0 + rng.randf_range(-0.004, 0.004)
	var omega: float = TAU * frequency_hz * detune / float(SAMPLE_RATE)
	var omega_fifth: float = omega * 1.498
	for index: int in total:
		var t: float = float(index) / float(SAMPLE_RATE)
		var envelope: float = exp(-t * 6.5)
		out[index] = (sin(omega * float(index)) * 0.72 + sin(omega_fifth * float(index)) * 0.28) * envelope * 0.35
	return out


static func _cloth_rustle(seed_value: int, amplitude: float) -> PackedFloat32Array:
	var total: int = int(0.22 * float(SAMPLE_RATE))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(total)
	var previous: float = 0.0
	for index: int in total:
		var burst: float = rng.randf_range(-1.0, 1.0)
		previous = previous * 0.15 + burst * 0.85
		var envelope: float = sin(PI * float(index) / float(total))
		out[index] = previous * envelope * amplitude
	return out


static func _room_hiss(total: int, seed_value: int, amplitude: float) -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(total)
	var previous: float = 0.0
	for index: int in total:
		previous = previous * 0.92 + rng.randf_range(-1.0, 1.0) * 0.08
		out[index] = previous * amplitude
	return out


static func _mix_add(destination: PackedFloat32Array, source: PackedFloat32Array, start: int) -> void:
	var limit: int = mini(source.size(), destination.size() - start)
	if limit <= 0 or start < 0:
		return
	for index: int in limit:
		destination[start + index] += source[index]


static func _normalize(samples: PackedFloat32Array, peak: float) -> void:
	var loudest: float = 0.0001
	for index: int in samples.size():
		loudest = maxf(loudest, absf(samples[index]))
	var gain: float = peak / loudest
	for index: int in samples.size():
		samples[index] *= gain
