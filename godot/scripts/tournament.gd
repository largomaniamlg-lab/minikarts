extends RefCounted
const Settings = preload("res://scripts/race_settings.gd")
var stage := 0 # 0: three-lap qualifying; 1..4: races on new circuits.
var race_laps := 3
var started := false
var completed := false
var table: Dictionary = {}
var grid: Array = []

func start(entries: Array, laps: int) -> void:
	stage=0; completed=false; started=true; table.clear(); grid.clear()
	race_laps=Settings.valid_laps(laps)
	for entry in entries:
		table[entry.id]={"id":entry.id,"name":entry.name,"driver":entry.driver,"points":0,"wins":0,"qualifying":-1.0}
		grid.append(entry.id)

func laps() -> int:
	return 3 if stage==0 else race_laps

func finish(results: Array) -> Array:
	if completed: return results
	var ordered := results.duplicate(true)
	if stage==0:
		ordered.sort_custom(func(a,b):
			var av := float(a.get("best_lap",-1))
			var bv := float(b.get("best_lap",-1))
			if av<0: av=INF
			if bv<0: bv=INF
			return av<bv if av!=bv else int(a.id)<int(b.id)
		)
		for result in ordered:
			if table.has(result.id): table[result.id].qualifying=result.get("best_lap",-1.0)
	else:
		ordered.sort_custom(func(a,b):
			if (a.time>=0)!=(b.time>=0): return a.time>=0
			return a.time<b.time if a.time!=b.time else int(a.id)<int(b.id)
		)
		for i in range(ordered.size()):
			var result: Dictionary = ordered[i]
			if table.has(result.id) and result.time>=0:
				table[result.id].points += maxi(1,Settings.CAPACITY-i)
				if i==0: table[result.id].wins+=1
	grid=ordered.map(func(r):return r.id)
	completed=true
	return ordered

func next() -> bool:
	if not completed or stage>=4: return false
	stage+=1; completed=false
	return true

func standings() -> Array:
	var entries := table.values().duplicate(true)
	entries.sort_custom(func(a,b):
		if a.points!=b.points: return a.points>b.points
		if a.wins!=b.wins: return a.wins>b.wins
		var av: float = a.qualifying if a.qualifying>=0 else INF
		var bv: float = b.qualifying if b.qualifying>=0 else INF
		return av<bv if av!=bv else int(a.id)<int(b.id)
	)
	return entries

func summary() -> Dictionary:
	return {"enabled":true,"stage":stage,"finished":stage==4 and completed,"standings":standings(),"grid":grid}
