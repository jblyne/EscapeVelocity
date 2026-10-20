extends SceneTree
var game
var checks=0
var failures=0
func check(ok: bool,message: String):
 checks+=1
 if not ok: failures+=1;push_error(message)
func _initialize(): call_deferred("run")
func run():
 game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-weapon-audio.json"
 game.traffic.enabled=false;game.muted=true;root.add_child(game)
 game.set_process(false);game.set_physics_process(false);game.set_mode("flight")
 for record in game.catalog.data.weapons.values():
  var key=game.arsenal.weapon_sound_key(int(record.id))
  check(key=="weapon_%d" % (200+int(record.fields.Sound)),"original Sound field mapping: "+record.name)
  check(game.audio.has(key) and game.audio[key].stream is AudioStreamWAV and game.audio[key].stream.get_length()>0,"original sample loaded: "+record.name)
 game.muted=false
 check(game.arsenal.fire(128,game.pilot.position,0),"laser fires")
 check(game.audio.weapon_200.playing,"laser plays original sample")
 game.audio.weapon_200.stop()
 var source={"radius":30,"position":game.pilot.position,"id":131}
 check(game.arsenal.fire(133,game.pilot.position,0,false,source),"NPC turret fires")
 check(game.audio.weapon_200.playing,"NPC turret uses original laser sound")
 game.arsenal.fire(129,game.pilot.position,0)
 check(game.audio.weapon_201.playing,"neutron uses distinct original sound")
 game.arsenal.fire(142,game.pilot.position,0)
 check(game.audio.weapon_212.playing,"particle beam plays original sample")
 game.audio.weapon_202.stop();game.muted=true
 game.arsenal.fire(130,game.pilot.position,0)
 check(not game.audio.weapon_202.playing,"mute prevents firing audio")
 game.muted=false;game.audio.weapon_202.stop()
 game.arsenal.play_weapon_sound(130,game.pilot.position+Vector2(3000,0))
 check(not game.audio.weapon_202.playing,"distant weapons remain inaudible")
 game.free();await process_frame
 print("WEAPON AUDIO: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
