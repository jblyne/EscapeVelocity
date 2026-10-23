extends "res://scripts/classic_port.gd"
# Match the classic game's compact black message dialogs and grey controls.
const LAYOUT=Vector2(660,214)
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_STOP
	font=preload("res://scripts/classic_text.gd").body()
	canvas=Control.new();canvas.size=LAYOUT;add_child(canvas);panel(Rect2(Vector2.ZERO,LAYOUT))
	label_at("DestroyedMessage","Your ship has been destroyed.",Rect2(24,22,612,38),22)
	label_at("PilotRecoveryStatus","This strict pilot has died permanently." if game.pilot.strict_dead else "You may load your last saved pilot or start a new flight.",Rect2(24,70,612,54),18)
	if not game.pilot.strict_dead:
		var restore=button_at("LoadLastSave","Load Last Save",Rect2(174,152,220,38),game.load_game)
		restore.disabled=not FileAccess.file_exists(game.save_path)
		restore.tooltip_text="Your last living pilot save is preserved." if not restore.disabled else "No saved pilot is available."
	button_at("StartFreshFlight","New Flight",Rect2(412,152,224,38),game.restart)
	resized.connect(fit);fit()
func fit() -> void:
	var ratio=minf(1.0,minf((size.x-40)/LAYOUT.x,(size.y-40)/LAYOUT.y))
	canvas.scale=Vector2.ONE*ratio;canvas.position=(size-LAYOUT*ratio)*.5
