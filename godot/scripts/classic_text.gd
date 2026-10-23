extends RefCounted
# EV 1.0.5 repeatedly selects TextFont(3 / Geneva), TextSize(9).
# Render the classic small strike once, then scale its original glyph shapes
# rather than switching to the modern font's large-size outline rendering.
# Load the Mac's installed font at runtime; no Apple font data is redistributed.
static var cached: Font
static func body() -> Font:
 if cached!=null: return cached
 var path: String=OS.get_system_font_path("Geneva")
 if not path.is_empty() and FileAccess.file_exists(path):
  var font=FontFile.new();font.data=FileAccess.get_file_as_bytes(path)
  font.fixed_size=9;font.fixed_size_scale_mode=TextServer.FIXED_SIZE_SCALE_ENABLED
  font.disable_embedded_bitmaps=false
  font.antialiasing=TextServer.FONT_ANTIALIASING_NONE
  font.hinting=TextServer.HINTING_NORMAL
  font.subpixel_positioning=TextServer.SUBPIXEL_POSITIONING_DISABLED
  cached=font
 else:
  var font=preload("res://scripts/classic_text.gd").body()
  font.hinting=TextServer.HINTING_NORMAL
  cached=font
 return cached
