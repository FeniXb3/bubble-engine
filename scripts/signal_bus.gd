extends Node

@warning_ignore("unused_signal")
signal query_picked(query: Query)
@warning_ignore("unused_signal")
signal query_submitted
@warning_ignore("unused_signal")
signal results_submitted(results: Array[Result])
@warning_ignore("unused_signal")
signal result_read(result: Result)
@warning_ignore("unused_signal")
signal results_known(results: Array[Result])
@warning_ignore("unused_signal")
signal reaction_calculated(score: int)
@warning_ignore("unused_signal")
signal mood_calculated(mood: int)
@warning_ignore("unused_signal")
signal ready_to_pick_query
@warning_ignore("unused_signal")
signal human_picked(human: Human, index: int)
@warning_ignore("unused_signal")
signal flip_change_requested(toggled_on: bool)
@warning_ignore("unused_signal")
signal starting
@warning_ignore("unused_signal")
signal reseting
@warning_ignore("unused_signal")
signal human_encountered(human: Human)
@warning_ignore("unused_signal")
signal tag_encountered(tag: String)
