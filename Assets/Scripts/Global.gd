extends Node

#global variables go here
var countdown_happening:bool
enum state {ASTEROID, ICE, BOSS}
var game_state = state.ASTEROID
signal phase_changed(new_state)


#to do list
	#life system(sheild) - need the animations
	#projectile(Gun)
	#bossfight
