extends RefCounted
# Original spob custom picture overrides the type-indexed EV Titles landscape.
const TEXTURES={
	10000:preload("res://assets/landing/10000.png"),
	10001:preload("res://assets/landing/10001.png"),
	10002:preload("res://assets/landing/10002.png"),
	10003:preload("res://assets/landing/10003.png"),
	10004:preload("res://assets/landing/10004.png"),
	10005:preload("res://assets/landing/10005.png"),
	10006:preload("res://assets/landing/10006.png"),
	10007:preload("res://assets/landing/10007.png"),
	10008:preload("res://assets/landing/10008.png"),
	10009:preload("res://assets/landing/10009.png"),
	10010:preload("res://assets/landing/10010.png"),
	10011:preload("res://assets/landing/10011.png"),
	10012:preload("res://assets/landing/10012.png"),
	10013:preload("res://assets/landing/10013.png"),
	10014:preload("res://assets/landing/10014.png"),
	10015:preload("res://assets/landing/10015.png"),
	10016:preload("res://assets/landing/10016.png"),
	10017:preload("res://assets/landing/10017.png"),
	10018:preload("res://assets/landing/10018.png"),
	10019:preload("res://assets/landing/10019.png"),
	10020:preload("res://assets/landing/10020.png"),
	10021:preload("res://assets/landing/10021.png"),
	10022:preload("res://assets/landing/10022.png"),
	10023:preload("res://assets/landing/10023.png"),
	10024:preload("res://assets/landing/10024.png"),
	10025:preload("res://assets/landing/10025.png"),
	10026:preload("res://assets/landing/10026.png"),
	10027:preload("res://assets/landing/10027.png"),
	10028:preload("res://assets/landing/10028.png"),
	10029:preload("res://assets/landing/10029.png"),
	10030:preload("res://assets/landing/10030.png"),
	10031:preload("res://assets/landing/10031.png"),
	10032:preload("res://assets/landing/10032.png"),
	10033:preload("res://assets/landing/10033.png"),
	11000:preload("res://assets/landing/11000.png"),
	11001:preload("res://assets/landing/11001.png"),
}

static func picture_id(catalog,port: int) -> int:
	var f: Dictionary=catalog.record("objects",port).fields
	return int(f.CustPicID) if int(f.CustPicID)>=0 else 10000+int(f.Type)
static func texture(catalog,port: int) -> Texture2D:
	var id: int=picture_id(catalog,port)
	return TEXTURES.get(id,TEXTURES[10000])
