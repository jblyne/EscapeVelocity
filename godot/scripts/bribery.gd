extends RefCounted
# EV 1.0.5 PPC: 0xefc8–0xf2a8, 0x109ec–0x10bbc, 0x12bd8–0x12c98.
# Prices depend on the pilot's wallet, not the contacted ship's purchase cost.
static func rounded_quote(amount: float, credits: int) -> int:
 return clampi(int(minf(amount,float(credits)*.333)/1000)*1000,1000,900000)

static func ship_quote(credits: int,flags: int,rng: RandomNumberGenerator) -> int:
 var mood: float=(80+rng.randi_range(0,40))*.01
 if rng.randi_range(0,4)==0: mood-=.5
 elif rng.randi_range(0,4)==0: mood+=.5
 var expensive: bool=(flags&0x8000)!=0
 var bound: int=maxi(1,int(credits*(.0001 if expensive else .0000005)))
 var base: int=(10000 if expensive else 3000)+rng.randi_range(0,bound-1)*1000
 return rounded_quote(base*mood,credits)

static func landing_quote(credits: int,flags: int,rng: RandomNumberGenerator) -> int:
 var bound: int=maxi(1,int(credits*.000001))
 var base: int=3000+rng.randi_range(0,bound-1)*1000
 return rounded_quote(base*(1.5 if flags&0x8000 else 1.0),credits)

static func landing_willing(roll: int,flags: int,government: int) -> bool:
 # 0x10d88–0x10dfc: roll must exceed 30; governed ports require bit 14.
 return roll>30 and (government<0 or (flags&0x4000)!=0)

static func discount(price: int) -> int:
 # Negotiated paying-price multiplier .75; truncate to hundreds afterward.
 return int(int(price*.75)/100)*100
