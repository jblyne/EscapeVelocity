extends Node3D
var age: float=0
var sparks: Array=[]
var words: Label3D
var letters: MultiMeshInstance3D
var destinations: Array=[]
func setup(at: Vector3,text: String):
 position=at
 words=Label3D.new();words.text=text;words.font_size=64;words.pixel_size=.85;words.billboard=BaseMaterial3D.BILLBOARD_ENABLED;words.no_depth_test=true;words.modulate=Color("ffe79b");words.outline_modulate=Color("ed6c32");add_child(words);words.hide()
 build_letters(text)
 var rng=RandomNumberGenerator.new();rng.randomize()
 var material=preload("res://scripts/models.gd").material(Color("ffd46b"),0,3)
 for i in 50:
  var node=preload("res://scripts/models.gd").sphere(self,Vector3.ZERO,rng.randf_range(.7,1.8),material)
  sparks.append({"node":node,"velocity":Vector3(rng.randf_range(-80,80),rng.randf_range(5,50),rng.randf_range(-40,40))})
func advance(dt: float) -> bool:
 age+=dt
 # Rockets lift above the world, burst, then illuminate the plea.
 position.y+=dt*35
 words.visible=false
 words.modulate.a=0 # The message is rendered as individual glowing firework dots.
 var reveal=clampf((age-1.1)/1.3,0,1)
 for i in destinations.size():
  var point: Vector3=destinations[i]*reveal
  point.y+=sin(age*8+i)*.8
  var scale_value=maxf(.01,minf(1,(7-age)/1.5))*(.65+.35*sin(age*10+i))
  letters.multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*scale_value),point))
 words.scale=Vector3.ONE*minf(1,(age-1.0)*3) if age>1 else Vector3.ONE*.01
 for s in sparks:
  s.node.position=s.velocity*maxf(0,age-1.2)
  s.node.scale=Vector3.ONE*maxf(.01,1-age/7)
 return age>=7

const GLYPHS={
 "A":["01110","10001","10001","11111","10001","10001","10001"],
 "C":["01111","10000","10000","10000","10000","10000","01111"],
 "E":["11111","10000","10000","11110","10000","10000","11111"],
 "I":["111","010","010","010","010","010","111"],
 "L":["10000","10000","10000","10000","10000","10000","11111"],
 "M":["10001","11011","10101","10101","10001","10001","10001"],
 "O":["01110","10001","10001","10001","10001","10001","01110"],
 "P":["11110","10001","10001","11110","10000","10000","10000"],
 "R":["11110","10001","10001","11110","10100","10010","10001"],
 "S":["01111","10000","10000","01110","00001","00001","11110"],
 "U":["10001","10001","10001","10001","10001","10001","01110"],
 "V":["10001","10001","10001","10001","10001","01010","00100"],
 "W":["10001","10001","10001","10101","10101","10101","01010"],
 "Y":["10001","10001","01010","00100","00100","00100","00100"],
 "!":["1","1","1","1","1","0","1"],
 "'":["1","1","0","0","0","0","0"]}
func build_letters(text: String):
 var x: float=0
 for character in text:
  if character==" ": x+=16;continue
  var glyph: Array=GLYPHS.get(character,GLYPHS["!"])
  for row in glyph.size():
   for col in str(glyph[row]).length():
    if str(glyph[row])[col]=="1": destinations.append(Vector3(x+col*4.5,0,row*4.5))
  x+=(str(glyph[0]).length()+1)*4.5
 for i in destinations.size():
  destinations[i].x-=x*.5
  destinations[i].z-=160
 letters=MultiMeshInstance3D.new();letters.multimesh=MultiMesh.new()
 letters.multimesh.transform_format=MultiMesh.TRANSFORM_3D
 var dot=SphereMesh.new();dot.radius=1.5;dot.height=3.0;dot.radial_segments=6;dot.rings=3
 letters.multimesh.mesh=dot;letters.multimesh.instance_count=destinations.size()
 var mat=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.albedo_color=Color("ff9c24");mat.emission_enabled=true;mat.emission=Color("ff6620");mat.emission_energy_multiplier=.8
 letters.material_override=mat;add_child(letters)
