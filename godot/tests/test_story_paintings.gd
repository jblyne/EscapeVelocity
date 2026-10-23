extends SceneTree
var failures=0
func check(ok: bool,message: String) -> void:
	if not ok: failures+=1;push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var intro=load("res://scripts/startup.gd").new();intro.story_only=true;root.add_child(intro);intro.set_process(false)
	intro.show_phase("story")
	check(intro.story_paintings.visible,"Paintings appear only in story")
	var paintings=intro.story_paintings
	for dimensions in [Vector2i(1280,960),Vector2i(2560,1080)]:
		root.size=dimensions
		await process_frame;await process_frame;intro.fit()
		var bounds=intro.story_clip.get_global_transform()*Rect2(Vector2.ZERO,intro.story_clip.size)
		check(absf(bounds.position.y)<1 and absf(bounds.end.y-root.get_visible_rect().size.y)<1,"Scroll covers full viewport vertically")
		intro.show_phase("story")
		check(is_equal_approx(intro.story.position.y,intro.story_clip.size.y),"Text enters at bottom")
		for line in [3,11,12,30,36,39,46,53,59,66,72,78]:
			intro.elapsed=(intro.story_clip.size.y*.5+float(line)*39)/intro.STORY_SPEED;intro._process(0)
			var visible_sides=[false,false]
			for i in paintings.panels.size():
				if paintings.panels[i].visible:
					visible_sides[paintings.CUES[i].side]=true
					check(paintings.panels[i].texture!=null,"Painting asset available")
			if line>=12: check(visible_sides[0] and visible_sides[1],"Both sides persist between topic changes")
			if "--visual" in OS.get_cmdline_user_args():
				await process_frame;await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("/tmp/ev213-story-%d-%d.png" % [line,dimensions.x])
		var last_line: int=paintings.STORY.data.size()-1
		for fraction in [2.0/3.0,5.0/12.0,1.0/6.0,0.0]:
			paintings.present(intro.story_clip.size.y*fraction-last_line*39,39,intro.STORY_SPEED,intro.story_clip.size.y)
			for index in [paintings.panels.size()-2,paintings.panels.size()-1]:
				var alpha: float=paintings.panels[index].modulate.a
				if fraction>=2.0/3.0: check(alpha>.99,"Final artwork remains visible until send-off travels a third upward")
				elif fraction>1.0/6.0: check(alpha>0 and alpha<1,"Both final paintings fade gradually with send-off position")
				else: check(is_zero_approx(alpha),"Final paintings disappear before last text leaves viewport")
		# Fade starts independently: right arrives while left keeps showing.
		paintings.present(intro.story_clip.size.y*.5-8.5*39,39,intro.STORY_SPEED,intro.story_clip.size.y)
		check(paintings.panels[0].modulate.a>.99 and paintings.panels[1].modulate.a>0 and paintings.panels[1].modulate.a<1,"Independent left/right fade")
	for line in [34.5,35.25,36.0,52.5,53.25,54.0]:
		paintings.present(intro.story_clip.size.y*.5-line*39,39,intro.STORY_SPEED,intro.story_clip.size.y)
		var counts=[0,0]
		for i in paintings.panels.size():
			if paintings.panels[i].visible: counts[paintings.CUES[i].side]+=1
		check(counts[0]<=1 and counts[1]<=1,"No doubled art during same-side replacement")
	for step in range(880):
		var line: float=step*.1
		paintings.present(intro.story_clip.size.y*.5-line*39,39,intro.STORY_SPEED,intro.story_clip.size.y)
		var shown: Array[String]=[]
		for i in paintings.panels.size():
			if paintings.panels[i].visible:
				check(not str(paintings.CUES[i].image) in shown,"Never duplicate a painting across both sides")
				shown.append(str(paintings.CUES[i].image))
	intro.show_phase("arrival");check(not paintings.visible,"Paintings hidden outside story")
	intro.free();await process_frame
	print("STORY PAINTINGS: %d failures" % failures);quit(1 if failures else 0)
