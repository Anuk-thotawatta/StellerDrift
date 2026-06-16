extends Node

#global variables go here
const SAVEPATH = "user://save.json"
const OPTIONSPATH = "user://options.json"
var countdown_happening:bool
enum state {ASTEROID, ICE, BOSS}
var game_state = state.ASTEROID
signal phase_changed(new_state)


#to do list
	#life system(sheild) - need the animations, need UI element
	#projectile(Gun) - need to program hitting target, also hit fx
	#options menu - reset high score button
	#bossfight
