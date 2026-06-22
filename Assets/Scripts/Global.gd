extends Node

#global variables go here
const SAVEPATH = "user://save.json"
const OPTIONSPATH = "user://options.json"
var countdown_happening:bool
var gameSpeed = 300
enum state {ASTEROID, ICE, BOSS}
var game_state = state.ASTEROID
signal phase_changed(new_state)


#to do list
	#projectile(Gun) - need to program hitting target, also hit fx
	#options menu - reset high score button
	#bossfight - need to add skeleton to the arms, need to change the look of the arms
