extends RefCounted
const DEFAULTS={"thrust":[KEY_W,KEY_UP],"retrograde":[KEY_S,KEY_DOWN],"left":[KEY_LEFT],"right":[KEY_D,KEY_RIGHT],"fire":[KEY_SPACE],"afterburner":[KEY_SHIFT],"face_target":[KEY_T],"jump":[KEY_J],"map":[KEY_M],"land":[KEY_L],"hail_ship":[KEY_Y],"hail_world":[KEY_H],"board":[KEY_B],"fleet":[KEY_F],"info":[KEY_P],"journal":[KEY_I],"cloak":[KEY_K],"next_destination":[KEY_N],"next_target":[KEY_TAB],"previous_weapon":[KEY_Q],"next_weapon":[KEY_E]}
const RESERVED=[KEY_A,KEY_CAPSLOCK,KEY_ESCAPE,KEY_F5,KEY_F9,KEY_F11,KEY_C,KEY_G,KEY_V,KEY_X,KEY_1,KEY_3,KEY_4,KEY_F1,KEY_F2,KEY_F3,KEY_F4]
var bindings: Dictionary=DEFAULTS.duplicate(true)
var speed: float=1.0
var path: String="user://preferences.json"
func load_settings() -> void:
 if not FileAccess.file_exists(path): return
 var data=JSON.parse_string(FileAccess.get_file_as_string(path))
 if not data is Dictionary: return
 var saved=data.get("bindings",{})
 if not saved is Dictionary: return
 var used: Array=RESERVED.duplicate();var candidate: Dictionary={}
 for action in DEFAULTS:
  var keys=saved.get(action,DEFAULTS[action])
  if not keys is Array or keys.is_empty() or keys.size()>2: return
  var migrated: Array=[]
  for key in keys:
   if not (key is int or key is float) or key!=int(key) or key<=0: return
   if int(key)!=KEY_A: migrated.append(int(key))
  keys=migrated if not migrated.is_empty() else DEFAULTS[action].duplicate()
  candidate[action]=[]
  for key in keys:
   if not (key is int or key is float) or key!=int(key) or key<=0 or int(key) in used: return
   candidate[action].append(int(key));used.append(int(key))
 bindings=candidate
 speed=clampf(float(data.get("speed",1)),.5,2.0)
func save_settings() -> bool:
 var file=FileAccess.open(path+".tmp",FileAccess.WRITE)
 if file==null: return false
 file.store_string(JSON.stringify({"bindings":bindings,"speed":speed}));file.close()
 return DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),ProjectSettings.globalize_path(path))==OK
func bind(action: String,key: int) -> String:
 if not DEFAULTS.has(action) or key<=0: return "Choose a keyboard key."
 if key in RESERVED: return "That key is reserved for menus or system controls."
 for other in bindings:
  if other!=action and key in bindings[other]: return "Already assigned to "+str(other).replace("_"," ")+"."
 bindings[action]=[key];save_settings();return ""
func preset(classic: bool=false) -> void:
 bindings=DEFAULTS.duplicate(true)
 if classic:
  bindings.thrust=[KEY_UP];bindings.retrograde=[KEY_DOWN];bindings.left=[KEY_LEFT];bindings.right=[KEY_RIGHT]
  bindings.afterburner=[KEY_2];bindings.cloak=[KEY_U]
 save_settings()
func pressed(action: String) -> bool:
 for key in bindings[action]:
  if Input.is_physical_key_pressed(int(key)): return true
 return false
func caption(action: String) -> String:
 var names: PackedStringArray=[]
 for key in bindings[action]: names.append(OS.get_keycode_string(int(key)))
 return " / ".join(names)
func remapped(event: InputEventKey) -> InputEventKey:
 for action in bindings:
  if event.physical_keycode in bindings[action]:
   var result=event.duplicate();result.physical_keycode=DEFAULTS[action][0];return result
 # A replaced default key must not continue to trigger its old action.
 for action in DEFAULTS:
  if event.physical_keycode in DEFAULTS[action]:
   var result=event.duplicate();result.physical_keycode=KEY_NONE;return result
 return event

func summary() -> String:
 var lines: PackedStringArray=[]
 for action in bindings: lines.append("%s    %s" % [caption(action),str(action).replace("_"," ").capitalize()])
 lines.append("A    Autopilot / cancel")
 lines.append("F1–F4    Select world")
 lines.append("Shift+X    Escape pod")
 lines.append("F5 / F9    Save / load (living pilots)")
 lines.append("Caps Lock    Toggle 2× time")
 return "\n".join(lines)
