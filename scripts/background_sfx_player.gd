extends AudioStreamPlayer

func play_clip_safely(clip_name: StringName):
	if not playing:
		play()
		
	get_stream_playback().switch_to_clip_by_name(clip_name)
	
