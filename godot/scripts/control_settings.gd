extends RefCounted
const DEFAULTS={"thrust":[KEY_W,KEY_UP],"retrograde":[KEY_S,KEY_DOWN],"left":[KEY_LEFT],"right":[KEY_D,KEY_RIGHT],"fire":[KEY_SPACE],"secondary_fire":[KEY_CTRL],"weapon_safety":[KEY_R],"recall_fighters":[KEY_BACKSPACE],"afterburner":[KEY_SHIFT],"face_target":[KEY_T],"jump":[KEY_J],"map":[KEY_M],"land":[KEY_L],"hail_ship":[KEY_Y],"hail_world":[KEY_H],"board":[KEY_B],"fleet":[KEY_F],"info":[KEY_P],"journal":[KEY_I],"cloak":[KEY_K],"next_destination":[KEY_N],"next_target":[KEY_TAB],"previous_weapon":[KEY_Q],"next_weapon":[KEY_E]}
const RESERVED=[KEY_A,KEY_CAPSLOCK,KEY_ESCAPE,KEY_F5,KEY_F9,KEY_F11,KEY_C,KEY_G,KEY_V,KEY_X,KEY_1,KEY_3,KEY_4,KEY_F1,KEY_F2,KEY_F3,KEY_F4]
const PAD_DEFAULTS={"land":"b0","board":"b2","next_target":"b3","cloak":"b1","previous_weapon":"b9","next_weapon":"b10","jump":"b11","map":"b14","hail_ship":"b13","next_world":"b12","fleet":"b4","journal":"b20","afterburner":"b7","face_target":"b8","fire":"a5","secondary_fire":"a4"}
var pad_bindings: Dictionary=PAD_DEFAULTS.duplicate()
var capture_action: String=""
signal pad_binding_changed(error: String)
var controller
var bindings: Dictionary=DEFAULTS.duplicate(true)
var speed: float=1.0
var classic_fire: bool=false
var path: String="user://preferences.json"
func load_settings() -> void:
 if not FileAccess.file_exists(path): return
 var data=JSON.parse_string(FileAccess.get_file_as_string(path))
 if not data is Dictionary: return
 var saved=data.get("bindings",{})
 if not saved is Dictionary: return
 var used: Array=RESERVED.duplicate();var candidate: Dictionary={}
 var claimed: Array=RESERVED.duplicate()
 for existing in saved:
  if DEFAULTS.has(existing) and saved[existing] is Array: claimed.append_array(saved[existing])
 for action in DEFAULTS:
  var keys=saved.get(action,DEFAULTS[action])
  if not saved.has(action):
   keys=DEFAULTS[action].filter(func(key):return key not in claimed)
   if keys.is_empty():
    for fallback in [KEY_F6,KEY_F7,KEY_F8,KEY_F10,KEY_INSERT,KEY_HOME,KEY_END]:
     if fallback not in claimed: keys=[fallback];break
   claimed.append_array(keys)
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
 var saved_pad=data.get("controller_bindings",{})
 if saved_pad is Dictionary:
  var next_pad: Dictionary=PAD_DEFAULTS.duplicate()
  next_pad.merge(saved_pad,true)
  var valid: bool=next_pad.size()==PAD_DEFAULTS.size()
  var used_pad: Array=[]
  for action in next_pad:
   var token=next_pad[action]
   if not PAD_DEFAULTS.has(action) or not token is String or token not in PAD_DEFAULTS.values() or token in used_pad: valid=false
   used_pad.append(token)
  if valid: pad_bindings=next_pad
 classic_fire=data.get("classic_fire",false)==true
 speed=clampf(float(data.get("speed",1)),.5,2.0)
func save_settings() -> bool:
 var file=FileAccess.open(path+".tmp",FileAccess.WRITE)
 if file==null: return false
 file.store_string(JSON.stringify({"bindings":bindings,"speed":speed,"classic_fire":classic_fire,"controller_bindings":pad_bindings}));file.close()
 return DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),ProjectSettings.globalize_path(path))==OK
func bind(action: String,key: int) -> String:
 if not DEFAULTS.has(action) or key<=0: return "Choose a keyboard key."
 if key in RESERVED: return "That key is reserved for menus or system controls."
 for other in bindings:
  if other!=action and key in bindings[other]: return "Already assigned to "+str(other).replace("_"," ")+"."
 bindings[action]=[key];save_settings();return ""
func preset(classic: bool=false) -> void:
 classic_fire=classic
 bindings=DEFAULTS.duplicate(true)
 if classic:
  bindings.thrust=[KEY_UP];bindings.retrograde=[KEY_DOWN];bindings.left=[KEY_LEFT];bindings.right=[KEY_RIGHT]
  bindings.afterburner=[KEY_2];bindings.secondary_fire=[KEY_SHIFT];bindings.cloak=[KEY_U]
  bindings.next_weapon=[KEY_W];bindings.weapon_safety=[KEY_S]
 save_settings()
func pressed(action: String) -> bool:
 if is_instance_valid(controller) and controller.pressed(action): return true
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
 lines.append("Cmd+K    Jettison all cargo (Option: ordinary cargo only)")
 lines.append("Hold Cmd+D 10 seconds    Self-destruct (release cancels)")
 lines.append("F5 / F9    Save / load (living pilots)")
 lines.append("Caps Lock    Toggle 2× time")
 return "\n".join(lines)

func turn() -> float:
 var keyboard: float=float(Input.is_physical_key_pressed(int(bindings.right[0])) or (bindings.right.size()>1 and Input.is_physical_key_pressed(int(bindings.right[1]))))-float(Input.is_physical_key_pressed(int(bindings.left[0])) or (bindings.left.size()>1 and Input.is_physical_key_pressed(int(bindings.left[1]))))
 if not is_zero_approx(keyboard): return keyboard
 return controller.analog(JOY_AXIS_LEFT_X) if is_instance_valid(controller) and not controller.land_pending else 0.0

func pad_caption(action: String) -> String:
 var names={"b0":"Cross / A","b1":"Circle / B","b2":"Square / X","b3":"Triangle / Y","b4":"Create / Back","b7":"L3","b8":"R3","b9":"L1","b10":"R1","b11":"D-pad Up","b12":"D-pad Down","b13":"D-pad Left","b14":"D-pad Right","b20":"Touchpad","a4":"L2","a5":"R2"}
 return str(names.get(pad_bindings[action],pad_bindings[action]))
func bind_pad(action: String,token: String) -> String:
 if not PAD_DEFAULTS.has(action) or token not in PAD_DEFAULTS.values(): return "Choose a controller button or trigger. Options is reserved for pause."
 var previous: String=pad_bindings[action]
 var other=pad_bindings.find_key(token)
 if other!=null: pad_bindings[other]=previous
 pad_bindings[action]=token
 save_settings()
 if is_instance_valid(controller): controller.reset()
 return ""
func reset_pad() -> void:
 pad_bindings=PAD_DEFAULTS.duplicate();save_settings()
 if is_instance_valid(controller): controller.reset()
