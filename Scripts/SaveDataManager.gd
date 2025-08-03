extends Node

var games = []

const path = "user://stats.save"

func load_save_data():
	
	var save_file = FileAccess.open(path, FileAccess.READ)
	games = JSON.parse_string(save_file.get_line())
	
func save_game_data():
	var save_file = FileAccess.open(path, FileAccess.WRITE)
	var json_string = JSON.stringify(games)
	save_file.store_line(json_string)
	
func store_game(time_msec, deaths):
	games.append({"time": time_msec, "deaths": deaths})

func get_latest_game():
	return [len(games)-1, games[-1]]
	
func get_lowest_time():
	if len(games) == 0: return -1
	var i = 0
	var best = 0
	var lowest_time = games[0]["time"]
	for game in games:
		if game["time"] < lowest_time:
			lowest_time = game["time"]
			best = i
		i+=1
	return [best, lowest_time]

func get_lowest_deaths():
	if len(games) == 0: return -1
	var i = 0
	var best = -1
	var lowest_deaths = games[0]["deaths"]
	for game in games:
		if game["deaths"] < lowest_deaths:
			lowest_deaths = game["deaths"]
			best = i
		i+=1
	return [best, lowest_deaths]			
	
func _ready():
	load_save_data()
