extends SceneTree
func _initialize() -> void: call_deferred("run")
func shot(phase: String) -> void:
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/startup-%s-0.1.66.png" % phase))
func run() -> void:
	var boot=load("res://startup.tscn").instantiate();root.add_child(boot);boot.set_process(false)
	while boot.scene==null and not boot.loading_error:
		boot._process(0);await process_frame
	for phase in ["logo","loading"]:
		boot.show_phase(phase);boot.art.modulate.a=1;await shot(phase)
	boot.music.free();boot.free()
	var intro=load("res://scripts/startup.gd").new();intro.story_only=true;root.add_child(intro);intro.set_process(false)
	await shot("arrival")
	intro.show_phase("story");intro._process(14);await shot("story")
	intro.free();await process_frame;quit()
