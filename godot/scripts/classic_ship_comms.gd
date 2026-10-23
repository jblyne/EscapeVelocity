extends "res://scripts/classic_port.gd"
# Original hail reference: captain response at upper left, ship portrait and
# identity at right, compact grey communication controls below.
var layout=Vector2(820,374)
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_STOP
	font=preload("res://scripts/classic_text.gd").body()
	var comms=game.interactions;var npc: Dictionary=comms.contact
	if comms.page=="person_mission": layout.y=430
	canvas=Control.new();canvas.size=layout;add_child(canvas);panel(Rect2(Vector2.ZERO,layout))
	var response=RichTextLabel.new();response.name="CommResponse";response.position=Vector2(22,20)
	var has_offer: bool=comms.page not in ["person_mission","refuel","bribe"] and not game.persons.linked_offer(npc,false).is_empty()
	response.size=Vector2(526,layout.y-166-(44 if has_offer else 0));response.text=comms.response;response.bbcode_enabled=false
	response.add_theme_font_override("normal_font",font);response.add_theme_font_size_override("normal_font_size",20)
	response.add_theme_color_override("default_color",Color("dddddd"));canvas.add_child(response)
	game.hud.target_panel.refresh()
	var portrait=TextureRect.new();portrait.name="CommPortrait";portrait.position=Vector2(582,16);portrait.size=Vector2(212,132)
	portrait.texture=game.hud.target_panel.preview_texture.texture;portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;canvas.add_child(portrait)
	label_at("CommShipName",npc.name,Rect2(582,150,216,46),18)
	label_at("CommFaction",game.Factions.name_of(game.catalog,npc.faction),Rect2(582,196,216,26),15)
	var y: float=layout.y-102
	if comms.page=="person_mission":
		button_at("AcceptContract","Accept Contract",Rect2(22,y,252,38),game.persons.accept_offer)
		button_at("DeclineContract","Decline",Rect2(290,y,252,38),func():comms.reply("Channel open."))
	elif comms.page=="refuel" or comms.page=="bribe":
		var refuel: bool=comms.page=="refuel"
		var price: int=comms.refuel_price(npc) if refuel else comms.bribe_price(npc)
		var action=button_at("AcceptRefuel" if refuel else "PayBribe",("Rendezvous · %s cr" if refuel else "Pay %s credits") % game.hud.commas(price),Rect2(22,y,300,38),comms.accept_refuel if refuel else comms.pay_bribe)
		action.disabled=game.pilot.credits<price;action.tooltip_text="Insufficient credits." if action.disabled else ""
		if not refuel:
			var negotiate=button_at("NegotiateBribe","Negotiate",Rect2(344,y,284,38),comms.negotiate_bribe)
			negotiate.disabled=bool(comms.bribe_terms(npc).negotiated)
		button_at("BackComms","Back",Rect2(650,y,144,38),func():comms.reply("Channel open."))
	else:
		button_at("Greetings","Greetings",Rect2(22,y,190,38),comms.greetings)
		button_at("RequestAssistance","Request Assistance",Rect2(228,y,260,38),comms.request_assistance)
		button_at("OfferBribe","Offer Bribe",Rect2(504,y,290,38),comms.offer_bribe)
		button_at("OfferAssistance","Offer Assistance",Rect2(22,y-44,300,38),comms.offer_assistance)
		if not game.persons.linked_offer(npc,false).is_empty():
			button_at("DiscussContract","Discuss a Contract",Rect2(22,y-88,300,38),game.persons.show_offer.bind(npc,false))
	button_at("EndCommunication","End Communication",Rect2(22,layout.y-54,350,38),comms.close)
	var board=button_at("AttemptBoard","Board Ship",Rect2(504,layout.y-54,290,38),comms.board)
	board.tooltip_text=comms.boarding_reason(npc)
	resized.connect(fit);fit()
func fit() -> void:
	var ratio=minf(1.0,minf((size.x-40)/layout.x,(size.y-40)/layout.y))
	canvas.scale=Vector2.ONE*ratio;canvas.position=(size-layout*ratio)*.5
