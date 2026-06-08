extends Node

#global variables go here
var countdown_happening:bool

enum state {ASTEROID, ICE, BOSS}
var game_state = state.ASTEROID
signal phase_changed(new_state)
