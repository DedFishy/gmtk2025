extends Control

func get_message(game_count):
	if game_count == 1: return "How was your first game?"
	if game_count == 2: return "You came back for another?"
	if game_count == 3: return "Oh boy, it's getting serious."
	if 10 > game_count > 3: return "Okay, I'm sick of writing these. Come back when you have 10 games."
	return "Junkie."

func _ready():
	SaveDataManager.save_game_data()
	var latest_game = SaveDataManager.get_latest_game()
	var best_time_score = SaveDataManager.get_lowest_time()
	var best_death_score = SaveDataManager.get_lowest_deaths()
	
	print(best_time_score[0])
	print(latest_game[0])
	
	$Stats.text = "You've finished game #" + str(latest_game[0]+1) + "."
	$Stats.text += ("\nIt took you " + str(latest_game[1]["time"]/1000.0) + " seconds") + ((",\nbeating your best time!" if best_time_score[0] == latest_game[0] else ",\nnot beating your best time of " + str(best_time_score[1]/1000.0) + " seconds.") if latest_game[0] > 0 else ".")
	$Stats.text += ("\nYou died " + str(latest_game[1]["deaths"]) + " times") + ((",\nbeating your best death count!" if best_death_score[0] == latest_game[0] else ",\nnot beating your best death count of " + str(int(best_death_score[1])) + " deaths.") if latest_game[0] > 0 else ".")
