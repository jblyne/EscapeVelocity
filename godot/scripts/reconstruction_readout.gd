extends Label
var game
var ports: Array=[]
func _make_custom_tooltip(_text: String) -> Object:
 var layout=VBoxContainer.new()
 for id in ports:
  var status: Dictionary=game.world_killer.reconstruction(int(id))
  if status.is_empty(): continue
  var row=HBoxContainer.new();layout.add_child(row)
  var image=TextureRect.new();image.custom_minimum_size=Vector2(140,140);image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  var path: String="res://assets/reconstruction/orbital/%d_%d.webp" % [int(id),int(status.stage)]
  if ResourceLoader.exists(path): image.texture=load(path)
  else: image.custom_minimum_size=Vector2(1,1)
  row.add_child(image)
  var caption=Label.new();caption.custom_minimum_size=Vector2(300,140);caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;caption.text=game.catalog.record("objects",int(id)).name+"\n"+game.world_killer.reconstruction_text(int(id));row.add_child(caption)
 return layout
