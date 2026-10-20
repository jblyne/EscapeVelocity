extends "res://scripts/classic_port.gd"
const Artwork=preload("res://scripts/outfit_art.gd")
const LAYOUT=Vector2(1000,530)
var grid: GridContainer
var detail: Control
var cards: Dictionary={}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_STOP
	font=SystemFont.new();font.font_names=PackedStringArray(["Geneva","Helvetica","Arial"])
	canvas=Control.new();canvas.size=LAYOUT;add_child(canvas);panel(Rect2(Vector2.ZERO,LAYOUT))
	var scroll=ScrollContainer.new();scroll.name="OutfitterScroll";scroll.position=Vector2(16,14);scroll.size=Vector2(548,492)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;canvas.add_child(scroll)
	grid=GridContainer.new();grid.name="EquipmentGrid";grid.columns=4
	grid.add_theme_constant_override("h_separation",0);grid.add_theme_constant_override("v_separation",0);scroll.add_child(grid)
	var stock: Array=game.outfitter.stock()
	if game.hud.selected_outfit not in stock: game.hud.selected_outfit=int(stock[0])
	for id in stock:
		var item: Dictionary=game.catalog.record("outfits",id)
		var card=Button.new();card.name="SelectOutfit%d" % id;card.custom_minimum_size=Vector2(132,98);card.focus_mode=Control.FOCUS_NONE
		card.tooltip_text=item.name;card.pressed.connect(func():select_item(id));grid.add_child(card);cards[id]=card
		var image=Artwork.picture(card,game.catalog,id,Vector2(128,58),Color.BLACK);image.position=Vector2(2,2);image.size=Vector2(128,58)
		var title=RichTextLabel.new();title.name="OutfitName%d" % id;title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;title.bbcode_enabled=true;title.text="[center]"+item.name+"[/center]";title.position=Vector2(2,60)
		title.add_theme_font_override("normal_font",font);title.add_theme_font_size_override("normal_font_size",13);title.size=Vector2(128,36)
		title.fit_content=false;title.scroll_active=false;title.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(title)
		if game.outfitter.count(id)>0:
			var count=Label.new();count.text=str(game.outfitter.count(id));count.position=Vector2(78,2);count.size=Vector2(52,20);count.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
			count.add_theme_font_size_override("font_size",14);count.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(count)
	select_item(game.hud.selected_outfit)
	scroll.scroll_vertical=game.hud.outfitter_scroll
	scroll.get_v_scroll_bar().value_changed.connect(func(value):game.hud.outfitter_scroll=int(value))
	resized.connect(fit);fit()

func fit() -> void:
	var ratio=minf(1.0,minf((size.x-40)/LAYOUT.x,(size.y-40)/LAYOUT.y))
	canvas.scale=Vector2.ONE*ratio;canvas.position=(size-LAYOUT*ratio)*.5

func select_item(id: int) -> void:
	game.hud.selected_outfit=id
	for key in cards:
		var style=StyleBoxFlat.new();style.bg_color=Color.BLACK
		style.border_color=Color.GREEN if key==id else Color("11113b");style.set_border_width_all(2 if key==id else 1)
		for state in ["normal","hover","pressed"]: cards[key].add_theme_stylebox_override(state,style)
	if is_instance_valid(detail): canvas.remove_child(detail);detail.queue_free()
	detail=Control.new();detail.size=LAYOUT;detail.mouse_filter=Control.MOUSE_FILTER_IGNORE;canvas.add_child(detail)
	var base: Control=canvas;canvas=detail
	var item: Dictionary=game.catalog.record("outfits",id)
	var description: String=str(game.catalog.data.descriptions.get(str(3000+id-128),game.outfitter.description(id)))
	var body=RichTextLabel.new();body.name="OutfitDescription";body.position=Vector2(576,16);body.size=Vector2(408,228)
	body.bbcode_enabled=false;body.fit_content=false;body.add_theme_font_override("normal_font",font);body.add_theme_font_size_override("normal_font_size",18)
	body.text=description;detail.add_child(body)
	label_at("OutfitPrice","Item Price: %s cr" % game.hud.commas(game.outfitter.price(id)),Rect2(576,256,408,26),18)
	label_at("OutfitBalance","You Have: %s cr" % game.hud.commas(game.pilot.credits),Rect2(576,284,408,26),18)
	label_at("OutfitSpace","Free Space: %d t" % (int(game.catalog.field("ships",game.pilot.ship_id,"FreeMass"))-game.outfitter.space_used()),Rect2(576,312,408,26),18)
	var image=Artwork.picture(detail,game.catalog,id,Vector2(300,104),Color.BLACK);image.position=Vector2(684,334);image.size=Vector2(300,104)
	var reason: String=game.outfitter.reason(id,true)
	var notice=RichTextLabel.new();notice.name="OutfitNotice";notice.position=Vector2(576,438);notice.size=Vector2(408,36);notice.bbcode_enabled=false
	notice.add_theme_font_size_override("normal_font_size",14);notice.text=reason;detail.add_child(notice)
	var buy=button_at("BuyOutfit%d" % id,"Buy",Rect2(578,482,124,32),func():game.outfitter.trade(id,true));buy.disabled=not reason.is_empty();buy.tooltip_text=reason
	var sell=button_at("SellOutfit%d" % id,"Sell",Rect2(718,482,124,32),func():game.outfitter.trade(id,false))
	sell.tooltip_text=game.outfitter.reason(id,false);sell.disabled=not sell.tooltip_text.is_empty()
	if not sell.disabled: sell.tooltip_text="Sell for %s cr" % game.hud.commas(game.outfitter.price(id,false))
	button_at("CloseOutfitter","Leave",Rect2(860,482,124,32),func():game.set_mode("dock"))
	canvas=base
