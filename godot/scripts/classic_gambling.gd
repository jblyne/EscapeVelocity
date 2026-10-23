extends "res://scripts/classic_port.gd"
# Original EV 1.0.5: 0xa920 slot machine, six symbols, 1.3x pairs / 3x triples.
var reels: Array[TextureRect]=[]
var bets: Array[Button]=[]
var result: Label
var balance: Label
var outcome: Array[int]=[0,1,2]
var elapsed: float=0.0
var spinning: bool=false
var winnings: int=0
var rng=RandomNumberGenerator.new()
var shown_symbols: Array[int]=[-1,-1,-1]
var stopped_reels: Array[bool]=[false,false,false]
const SLOT_AUDIO=["slot_flip","slot_lock","slot_win","slot_jackpot"]

func _ready() -> void:
	super._ready()
	build_machine()

func build_machine() -> void:
	rng.randomize()
	label_at("GamblingTitle","Spaceport Slot Machine",Rect2(40,24,1100,52),28,Color("55ee33"))
	balance=label_at("Credits","",Rect2(40,88,1100,40),24)
	label_at("Rules","Two matching symbols pay 1.3× your bet. Three matching symbols pay 3×.",Rect2(40,140,1100,56),22)
	for i in 3:
		panel(Rect2(302+i*200,214,180,180))
		var reel=TextureRect.new();reel.position=Vector2(312+i*200,224);reel.size=Vector2(160,160)
		reel.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;canvas.add_child(reel);reels.append(reel);show_symbol(i,outcome[i])
	result=label_at("Result","Place your bet.",Rect2(40,422,1120,64),24);result.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	bets.append(button_at("Bet1000","Bet 1,000 cr",Rect2(240,510,320,46),func():spin(1000)))
	bets.append(button_at("Bet5000","Bet 5,000 cr",Rect2(640,510,320,46),func():spin(5000)))
	button_at("LeaveGambling","Back to Bar",Rect2(440,574,320,42),func():page("bar"))
	refresh_balance()

static func payout(stake: int,symbols: Array) -> int:
	if symbols.size()!=3: return 0
	if symbols[0]==symbols[1] and symbols[1]==symbols[2]: return stake*3
	if symbols[0]==symbols[1] or symbols[0]==symbols[2] or symbols[1]==symbols[2]: return stake*13/10
	return 0

func spin(stake: int) -> void:
	if spinning or stake not in [1000,5000] or game.pilot.credits<stake: return
	outcome=[rng.randi_range(0,5),rng.randi_range(0,5),rng.randi_range(0,5)]
	winnings=payout(stake,outcome)
	# Settle and persist the complete transaction before presenting it. Leaving during
	# animation or reloading cannot lose a pending win or reroll an unpaid bet.
	var previous: int=game.pilot.credits
	game.pilot.credits=previous-stake+winnings
	if not game.save_game(false):
		game.pilot.credits=previous;result.text="Could not save your pilot. No bet was placed.";return
	stop_slot_audio()
	stopped_reels=[false,false,false]
	spinning=true;elapsed=0;result.text="Spinning…"
	game.sound("slot_flip")
	for b in bets: b.disabled=true
	balance.text="Bet: %s cr" % game.hud.commas(stake)

func show_symbol(index: int,symbol: int) -> void:
	shown_symbols[index]=symbol
	var atlas=AtlasTexture.new();atlas.atlas=load("res://assets/classic/9001.png");atlas.region=Rect2(0,symbol*64,64,64)
	reels[index].texture=atlas

func _process(delta: float) -> void:
	if not spinning: return
	elapsed+=delta
	var flipped: bool=false
	for i in 3:
		var stop: float=1.2+i*.5
		var symbol: int=int(elapsed*maxf(4,22-elapsed*5)+i*2)%6 if elapsed<stop else outcome[i]
		if elapsed<stop and symbol!=shown_symbols[i]: flipped=true
		if elapsed>=stop and not stopped_reels[i]:
			stopped_reels[i]=true;game.sound("slot_lock")
		show_symbol(i,symbol)
	# Original 0xac44–0xac6c suppresses overlapping flip samples.
	if flipped and not game.audio.slot_flip.playing: game.sound("slot_flip")
	if elapsed>=2.2:
		spinning=false
		game.audio.slot_flip.stop()
		if winnings>0:
			game.sound("slot_jackpot" if outcome[0]==outcome[1] and outcome[1]==outcome[2] else "slot_win")
		result.text="Congratulations — you win %s credits!" % game.hud.commas(winnings) if winnings else "No match this time."
		refresh_balance()

func refresh_balance() -> void:
	balance.text="You have: %s cr" % game.hud.commas(game.pilot.credits)
	for i in bets.size(): bets[i].disabled=game.pilot.credits<([1000,5000][i])

func stop_slot_audio() -> void:
	for key in SLOT_AUDIO:
		if game.audio.has(key): game.audio[key].stop()

func _exit_tree() -> void:
	stop_slot_audio()
