extends Node

#global variables go here
const SAVEPATH = "user://save.json"
const OPTIONSPATH = "user://options.json"
var countdown_happening:bool
var gameSpeed = 300
enum state {ASTEROID,BOSS}
var game_state
signal phase_changed(new_state)
var pillarCount = 0

# Phase management
var current_phase_index = 0
var phase_queue = [state.ASTEROID, state.BOSS, state.ASTEROID, state.BOSS]
var is_boss_active: bool = false
var waiting_for_pillars: bool = false

#to do list
	#options menu - reset high score button
