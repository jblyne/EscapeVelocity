extends Node
# Shared by every classic dialog. Only the frontmost visible guard owns input.
var panel: Control
var game
var swallow_release: bool=false
func _ready() -> void:
 add_to_group("classic_modal_guards")
func frontmost() -> bool:
 var top: Node
 for guard in get_tree().get_nodes_in_group("classic_modal_guards"):
  if is_instance_valid(guard.panel) and guard.panel.is_visible_in_tree() and not guard.panel.is_queued_for_deletion():top=guard
 return top==self
func _input(event: InputEvent) -> void:
 if not event is InputEventMouseButton or event.button_index not in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_RIGHT,MOUSE_BUTTON_MIDDLE]:return
 if not frontmost():return
 if not event.pressed:
  if swallow_release:
   swallow_release=false;get_viewport().set_input_as_handled()
  return
 swallow_release=false
 if not panel.get_global_rect().has_point(event.position):
  swallow_release=true
  game.sound("modal_alert")
  get_viewport().set_input_as_handled()
