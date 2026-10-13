extends RefCounted
const Scenery=preload("res://scripts/scenario_theme.gd")
static func build(track: Node3D, parent: Node3D, id: int) -> void:
	for index in range(8):
		var site:=Node3D.new(); parent.add_child(site)
		site.transform=Scenery.safe_site(track,(index+0.6)*track.track_length/8,32 if index%2==0 else -32,27)
		match id:
			1: reactor(site,index)
			2: jungle(site,index)
			3: workshop(site,index)
			4: city(site,index)
			0: grandstand(site,index)
static func reactor(site: Node3D, index: int) -> void:
	var steel=Scenery.surface(Color("273c50")); var metal=Scenery.surface(Color("7b99ab"))
	var cyan=Scenery.surface(Color("48dfff"),true); var amber=Scenery.surface(Color("ffb92e"),true)
	Scenery.block(site,Vector3(15,0.6,15),Vector3(0,0.3,0),steel)
	Scenery.cylinder(site,3.6,15,Vector3(0,7.8,0),steel)
	for level in range(4):
		var y=1.6+level*4
		Scenery.cylinder(site,3.8,0.25,Vector3(0,y,0),metal)
		Scenery.cylinder(site,3.65,0.6,Vector3(0,y+0.7,0),cyan)
		for side in [-1.0,1.0]:
			Scenery.block(site,Vector3(0.3,3.1,0.3),Vector3(side*2.65,y+2,2.65),metal)
	Scenery.badge(site,1,Vector3(0,9,3.7),2)
	for side in [-1.0,1.0]:
		Scenery.cylinder(site,0.22,13,Vector3(side*6,6.5,0),amber)
		var pipe=Scenery.cylinder(site,0.28,9,Vector3(side*4,3,5),metal)
		pipe.rotation.z=PI/2
		for clamp_y in [2.0,6.0,10.0]: Scenery.cylinder(site,0.38,0.15,Vector3(side*6,clamp_y,0),steel)
	# Cable gantry beside the roadway; decoration never adds invisible collision.
	Scenery.block(site,Vector3(14,0.3,1.5),Vector3(0,13,5),metal)
	for x in range(-6,7,2): Scenery.block(site,Vector3(0.1,1,0.1),Vector3(x,13.5,5.7),amber)
	for x in [-5.0,5.0]:
		Scenery.block(site,Vector3(1.8,2.2,1),Vector3(x,1.4,-5),steel)
		Scenery.block(site,Vector3(1.3,1,0.08),Vector3(x,1.7,-5.55),cyan)
static func jungle(site: Node3D,index: int) -> void:
	var stone=Scenery.surface(Color("52655d")); var leaf=Scenery.surface(Color("287046"))
	for n in range(5):
		Scenery.sphere(site,Vector3(6,4+n%3*2,5),Vector3(n*3-6,2+n%3,0),stone)
		Scenery.sphere(site,Vector3(5,0.6,4),Vector3(n*3-6,4+n%3*2,0),leaf)
	if index%2==0:
		var water=Scenery.surface(Color("72d2d6"),true)
		Scenery.block(site,Vector3(1.8,9,0.12),Vector3(0,4.5,2.6),water)
		Scenery.block(site,Vector3(8,0.1,5),Vector3(0,0.1,4),water)
	else:
		for x in [-5.0,5.0]: Scenery.block(site,Vector3(1.8,7,2),Vector3(x,3.5,4),stone)
		Scenery.block(site,Vector3(12,1.5,2),Vector3(0,7,4),stone)
		for x in range(-5,6,2): Scenery.block(site,Vector3(1.5,0.6,1.5),Vector3(x,8,4),leaf)
static func workshop(site: Node3D,index: int) -> void:
	var wall=Scenery.surface(Color("a37350")); var metal=Scenery.surface(Color("3a4651"))
	Scenery.block(site,Vector3(14,5,7),Vector3(0,2.5,0),wall)
	Scenery.block(site,Vector3(15,0.35,9),Vector3(0,5,0),metal)
	for x in [-4.0,0.0,4.0]:
		Scenery.block(site,Vector3(3,3.5,0.1),Vector3(x,1.8,3.6),metal)
		for row in range(6): Scenery.block(site,Vector3(2.8,0.04,0.15),Vector3(x,0.4+row*0.5,3.7),wall)
	Scenery.badge(site,3,Vector3(0,4.2,3.65),1.3)
	for x in [-6.0,6.0]:
		Scenery.cylinder(site,0.65,1.8,Vector3(x,0.9,5),Scenery.surface(Color("cc6033")))
		for y in [0.3,1.5]: Scenery.cylinder(site,0.67,0.1,Vector3(x,y,5),metal)
static func city(site: Node3D,index: int) -> void:
	var wall=Scenery.surface(Color("192638")); var cyan=Scenery.surface(Color("41daf1"),true)
	var neon=Scenery.surface(Color("ca65ff"),true)
	var height=18+index%3*8
	Scenery.block(site,Vector3(13,height,10),Vector3(0,height/2,0),wall)
	for row in range(7):
		for col in range(5): Scenery.block(site,Vector3(1.2,1.4,0.05),Vector3(-5+col*2.5,2+row*(height-3)/7,5.1),cyan if (row+col)%3 else neon)
	Scenery.block(site,Vector3(13.2,0.4,10.2),Vector3(0,height,0),neon)
	Scenery.block(site,Vector3(8,2.5,0.2),Vector3(0,5,5.2),wall)
	var sign:=Label3D.new(); sign.text=["MINIKARTS","NEÓN","GARAJE","META"][index%4]
	sign.position=Vector3(0,5,5.4); sign.font_size=64; sign.pixel_size=0.025
	sign.modulate=Color("ffe65d"); site.add_child(sign)
static func grandstand(site: Node3D,index: int) -> void:
	var steel=Scenery.surface(Color("687990"))
	for row in range(4): Scenery.block(site,Vector3(13,0.6,2),Vector3(0,0.3+row*0.7,row*1.5),steel)
	for x in [-6.0,6.0]: Scenery.block(site,Vector3(0.25,6,0.25),Vector3(x,3,3),steel)
	Scenery.block(site,Vector3(15,0.2,8),Vector3(0,6,3),Scenery.surface(Color("ffd13b")))
