extends RefCounted
const Models=preload("res://scripts/models.gd")

# Original spïn 263 / PICT 230: yellow industrial forklift, dark tires,
# open overhead guard, upright lift mast and two separate forward tines.
static func create() -> Node3D:
	var root=Node3D.new();root.name="Forklift"
	var yellow=Models.material(Color("e8ca16"),0.35)
	var dark=Models.material(Color("252820"),0.25)
	var rubber=Models.material(Color("10120e"))
	var steel=Models.material(Color("90978d"),0.75)
	Models.box(root,Vector3(0,4,3),Vector3(14,5,17),yellow).name="Chassis"
	Models.box(root,Vector3(0,7,9),Vector3(15,5,7),yellow).name="Counterweight"
	Models.box(root,Vector3(0,7,1),Vector3(6,2,5),dark).name="Seat"
	Models.box(root,Vector3(0,9,3),Vector3(6,5,2),dark)
	for side in [-1,1]:
		for z in [-4,8]:
			var wheel=MeshInstance3D.new();wheel.name="Wheel"
			var cylinder=CylinderMesh.new();cylinder.top_radius=3.6;cylinder.bottom_radius=3.6;cylinder.height=3.5;cylinder.radial_segments=16
			wheel.mesh=cylinder;wheel.material_override=rubber
			wheel.rotation.z=PI/2;wheel.position=Vector3(side*8,3.6,z);root.add_child(wheel)
		for z in [-3,6]: Models.box(root,Vector3(side*6,11,z),Vector3(1.2,11,1.2),yellow)
		Models.box(root,Vector3(side*6,16,1.5),Vector3(1.5,1.2,11),yellow)
		Models.box(root,Vector3(side*5,10,-8),Vector3(1.8,17,2),dark).name="LiftMast"
		Models.box(root,Vector3(side*4.5,2,-14),Vector3(2.2,1.3,13),steel).name="ForkTine"
		Models.box(root,Vector3(side*4.5,5,-8),Vector3(2.2,7,1.5),steel)
	for z in [-3,1.5,6]: Models.box(root,Vector3(0,16,z),Vector3(13,1.2,1.2),yellow)
	Models.box(root,Vector3(0,11,-8),Vector3(11,1.5,1.5),steel)
	return root
