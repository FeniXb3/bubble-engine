extends Node

signal query_picked(query: Query)
signal query_submitted
signal results_submitted(results: Array[Result])
signal result_read(result: Result)
signal results_known(results: Array[Result])
signal reaction_calculated(score: int)
signal mood_calculated(mood: int)
signal ready_to_pick_query
signal human_picked(human: Human, index: int)
