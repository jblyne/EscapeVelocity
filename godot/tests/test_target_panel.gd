extends SceneTree
var game
var count: int = 0
var failures: int = 0

func check(ok: bool, message: String) -> void:
	count += 1
	if ok: print("PASS: "+message)
	else:
		failures += 1
		push_error("FAIL: "+message)

func _initialize() -> void:
	call_deferred("run")

func tab() -> void:
	var event = InputEventKey.new()
	event.physical_keycode = KEY_TAB
	event.pressed = true
	game._unhandled_key_input(event)
	game.hud._process(0)

func run() -> void:
	game = load("res://main.tscn").instantiate()
	game.save_path = ProjectSettings.globalize_path("res://../builds/test-target-pilot.json")
	if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
	game.muted = true
	game.traffic.enabled = false # Isolate this feature from independently tested ambient traffic.
	root.add_child(game)
	game.set_physics_process(false)
	game.set_process(false)
	game.hud.set_process(false)
	for i in 3: game.spawn_npc(false,game.pilot.position+Vector2(350+i*150,-400),i)
	var panel = game.hud.target_panel
	check(panel.contact_name.text=="No ship selected" and not panel.details.visible and panel.preview_model==null,"empty selection shows an honest prompt without stale details or preview")
	var first = game.npcs[0]
	var original_transform: Transform3D = first.model.transform
	var original_flame_visibility: bool = first.model.get_node("Flame-1").visible
	tab()
	check(game.selected_contact()==first and panel.contact_name.text==first.name,"Tab selects a ship and populates the side panel")
	check(panel.contact_status.text=="NEUTRAL" and panel.integrity.value==100,"neutral contact shows live full integrity")
	check(is_instance_valid(panel.preview_model) and panel.preview_model!=first.model and panel.preview_source_id==first.model.get_instance_id(),"preview is a separate copy of the selected ship's actual model")
	check(panel.preview_model.get_child_count()==first.model.get_child_count() and panel.preview_model.get_child(0).mesh==first.model.get_child(0).mesh,"preview uses matching ship geometry")
	check(first.model.transform==original_transform and first.model.get_node("Flame-1").visible==original_flame_visibility,"creating a preview never changes the world ship's transform or exhaust")
	check(panel.preview_viewport.own_world_3d and panel.preview_viewport.get_world_3d()!=game.get_world_3d(),"preview is rendered in its own world")
	var model_id: int = panel.preview_model.get_instance_id()
	game.hud._process(0)
	check(panel.preview_model.get_instance_id()==model_id,"unchanged selection reuses its preview instead of rebuilding each frame")
	first.position = game.pilot.position + Vector2(300,400)
	first.velocity = Vector2(30,40)
	game.damage_npc(first,first.max_health*.3)
	game.hud._process(0)
	check(panel.contact_status.text=="HOSTILE" and panel.integrity.value==70 and panel.integrity_text.text.contains("Integrity 70%") and panel.integrity_text.text.contains("Shields") and panel.integrity_text.text.contains("Armor"),"target status and integrity update live after damage")
	check(panel.distance_text.text=="Distance   500 km" and panel.speed_text.text=="Speed      50","panel derives distance and speed from the selected ship's current motion")
	var second=game.npcs[1]
	tab()
	check(game.selected_contact()==second and panel.contact_name.text=="Courier" and panel.preview_source_id==second.model.get_instance_id(),"next Tab switches both target information and preview")
	tab();tab()
	check(game.target_index==-1 and game.selected_contact().is_empty() and panel.preview_model==null and panel.contact_name.text=="No ship selected","Tab clears the target and preview after the last contact")
	tab()
	check(game.selected_contact()==first,"Tab restarts at the first contact after the empty selection")
	first.hostile=false # The damage test must not block the single-hostile combat drill.
	game.combat_drill()
	game.hud._process(0)
	var pirate=game.selected_contact()
	check(panel.contact_name.text=="Pirate Defender" and panel.contact_status.text=="Defender · HOSTILE","combat selection shows the hostile ship's name and class")
	var pirate_preview_id: int=panel.preview_model.get_instance_id()
	game.damage_npc(first,10000)
	game.hud._process(0)
	check(game.selected_contact()==pirate and panel.preview_model.get_instance_id()==pirate_preview_id,"destroying another ship preserves the selected contact across array index changes")
	game.damage_npc(pirate,10000)
	game.hud._process(0)
	check(game.selected_contact().is_empty() and panel.preview_model==null and panel.contact_name.text=="No ship selected","destroying the selected ship clears its preview and information")
	tab()
	game.set_mode("pause")
	var selected_index: int = game.target_index
	tab()
	check(game.target_index==selected_index,"Tab does not cycle contacts while paused")
	game.set_mode("flight")
	game.load_system()
	game.hud._process(0)
	check(panel.preview_model==null and not panel.details.visible,"system reload clears the previous target panel")
	game.spawn_npc(false,game.pilot.position+Vector2(350,-400),0)
	tab();tab()
	check(game.target_index==-1 and game.selected_contact().is_empty() and panel.preview_model==null,"a one-ship system cycles from its ship to no selection")
	tab()
	check(game.selected_contact()==game.npcs[0] and panel.preview_model!=null,"the following Tab reselects that single ship")
	for contact in game.npcs: contact.model.free()
	game.npcs.clear()
	tab()
	check(panel.empty_hint.text=="No ships detected." and game.selected_contact().is_empty(),"Tab in an empty system safely shows no contacts")
	game.target_index=999
	tab()
	check(game.target_index==-1 and panel.preview_model==null and not panel.details.visible,"Tab clears a stale target index safely in an empty system")
	await process_frame
	game.free()
	await process_frame
	print("TARGET RESULT: %d checks; %d failures" % [count,failures])
	quit(1 if failures else 0)
