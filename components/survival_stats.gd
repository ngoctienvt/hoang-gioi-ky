class_name SurvivalStats
extends RefCounted
var max_health: float = 150.0
var health: float = 150.0
var stamina: float = 150.0
var dao: float = 100.0
var poison: float = 0.0
var darkness_time: float = 0.0
var revivals: int = 0
func tick(delta: float, dark: bool, near_fire: bool) -> void:
	if not is_finite(delta) or delta <= 0.0:
		return
	stamina = maxf(0.0, stamina - delta * 0.18)
	poison = maxf(0.0, poison - delta * 10.0 / 480.0)
	dao = clampf(dao + delta * (0.25 if near_fire else (-0.5 if dark else 0.06)), 0.0, 100.0)
	if stamina <= 0.0:
		damage(delta * 1.5)
	if dark and not near_fire:
		var before = darkness_time
		darkness_time += delta
		var hits = maxi(0, int((darkness_time - 3.0) / 2.0)) - maxi(0, int((before - 3.0) / 2.0))
		damage(hits * 25.0)
	else:
		darkness_time = 0.0
	if poison > 50.0:
		damage(delta * 0.3)
func damage(amount: float) -> void:
	if is_finite(amount):
		health = clampf(health - maxf(0.0, amount), 0.0, max_health)
func eat(item: ItemDef) -> void:
	if item == null:
		return
	health = clampf(health + item.restore_health, 0.0, max_health)
	stamina = clampf(stamina + item.restore_stamina, 0.0, 150.0)
	dao = clampf(dao + item.restore_dao_heart, 0.0, 100.0)
	if item.category == ItemDef.Category.ELIXIR:
		poison = minf(100.0, poison + 20.0)
func revive() -> void:
	revivals = mini(2, revivals + 1)
	max_health = 150.0 * (1.0 - 0.25 * revivals)
	health = max_health * 0.5
	stamina = 75.0
	darkness_time = 0.0
func to_dict() -> Dictionary:
	return {"health": health, "max_health": max_health, "stamina": stamina, "dao": dao, "poison": poison, "revivals": revivals, "darkness_time": darkness_time}
func from_dict(state: Dictionary) -> void:
	revivals = clampi(int(state.get("revivals", 0)), 0, 2)
	max_health = 150.0 * (1.0 - 0.25 * revivals)
	health = clampf(float(state.get("health", max_health)), 0.0, max_health)
	stamina = clampf(float(state.get("stamina", 150.0)), 0.0, 150.0)
	dao = clampf(float(state.get("dao", 100.0)), 0.0, 100.0)
	poison = clampf(float(state.get("poison", 0.0)), 0.0, 100.0)
	darkness_time = maxf(0.0, float(state.get("darkness_time", 0.0)))
