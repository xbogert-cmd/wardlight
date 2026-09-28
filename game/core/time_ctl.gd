extends Node
## Owns Engine.time_scale. Systems request a factor by name (spell wheel,
## hit-stop...) and the slowest active factor wins, so closing one never
## clobbers another.

var _factors := {}
var _hitstop_left := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func set_factor(key: String, scale: float) -> void:
	_factors[key] = scale
	_apply()


func clear(key: String) -> void:
	_factors.erase(key)
	_apply()


func clear_all() -> void:
	_factors.clear()
	_hitstop_left = 0.0
	_apply()


func has(key: String) -> bool:
	return _factors.has(key)


func _apply() -> void:
	var s := 1.0
	for k in _factors:
		s = minf(s, _factors[k])
	Engine.time_scale = s


## Brief freeze-frame on meaningful hits, measured in unscaled frame time.
func hitstop(seconds: float, scale: float = 0.05) -> void:
	_hitstop_left = maxf(_hitstop_left, seconds)
	set_factor("hitstop", scale)


func _process(delta: float) -> void:
	if _hitstop_left > 0.0:
		_hitstop_left -= delta / maxf(Engine.time_scale, 0.0001)
		if _hitstop_left <= 0.0:
			clear("hitstop")
