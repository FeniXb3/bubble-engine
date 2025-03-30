extends Node

@warning_ignore_start("unused_signal")
signal query_picked(query: Query)
signal query_submitted
signal results_submitted(results: Array[Result])
signal result_read(result: Result)
signal results_known(results: Array[Result])
signal reaction_calculated(score: int)
signal mood_calculated(mood: int)
signal ready_to_pick_query
signal human_picked(human: Human, index: int)
signal flip_change_requested(toggled_on: bool)
signal starting
signal reseting
signal human_encountered(human: Human)
signal tag_encountered(tag: String)
signal results_shown(results: Array[Result])
