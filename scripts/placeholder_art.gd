class_name PlaceholderArt
extends RefCounted
## ============================================================================
## PlaceholderArt – erzeugt ALLE Grafiken prozedural zur Laufzeit.
##
## Es werden bewusst keine externen Bilddateien geladen: jedes Tile und jedes
## Charakter-Sprite wird hier aus farbigen Pixeln zusammengesetzt. So sind alle
## Grafiken garantiert selbst erstellt (keine originalen One-Piece-Assets) und
## das Projekt braucht keine Binär-Assets im Repository.
##
## Alle Funktionen sind `static`, Aufruf z.B.:
##     var tex := PlaceholderArt.make_actor({"skin":"f0c090", ...})
## ============================================================================

const TILE := 16

## Reihenfolge der Tiles im Atlas. Der Index (Spalte) entspricht der
## Atlas-Koordinate, die der TileMap/Arc-Code verwendet.
const TILE_ORDER := [
	"gras", "wasser", "sand", "weg", "boden",
	"baum", "dach", "wand", "tuer", "deck",
	"steg", "fels", "blume"
]

## Welche Tiles blockieren die Bewegung (für die Kollisionsschicht).
const SOLID_TILES := {
	"wasser": true, "baum": true, "dach": true, "wand": true, "fels": true
}

# ----------------------------------------------------------------------------
# Hilfsfunktionen
# ----------------------------------------------------------------------------

## Wandelt einen Hex-String ("d94f4f") in eine Color um.
static func hex(c: String) -> Color:
	if c == null or c == "":
		return Color(0, 0, 0, 0)  # transparent
	return Color.html("#" + c)

static func _new_image() -> Image:
	var img := Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img

static func _to_tex(img: Image) -> ImageTexture:
	return ImageTexture.create_from_image(img)

# ----------------------------------------------------------------------------
# TILES
# ----------------------------------------------------------------------------

## Erzeugt ein einzelnes 16x16-Tile als Image.
static func tile_image(name: String) -> Image:
	var img := _new_image()
	match name:
		"gras":  _fill_speckle(img, "4a9d3f", ["5cb84e", "3f8a36"], 10)
		"sand":  _fill_speckle(img, "d9c089", ["e6d3a3", "c8ad72"], 8)
		"weg":   _fill_speckle(img, "b08a5a", ["c19a68", "9c784c"], 8)
		"boden": _fill_speckle(img, "6b6f7d", ["7c8090", "5a5e6b"], 8)
		"fels":  _fill_speckle(img, "7a7d88", ["8d909c", "62656f"], 14)
		"wasser":
			img.fill(hex("2f6fb0"))
			for y in range(2, TILE, 4):
				_hline(img, 1, y, 6, "3f86cf")
				_hline(img, 8, y + 2, 5, "3f86cf")
		"deck":
			img.fill(hex("c79a5b"))
			for x in range(0, TILE, 5):
				_vline(img, x, 0, TILE, "a87f47")
		"steg":
			img.fill(hex("9c784c"))
			for y in range(0, TILE, 5):
				_hline(img, 0, y, TILE, "7c5e3a")
		"dach":
			img.fill(hex("a8430f"))
			for y in range(1, TILE, 4):
				_hline(img, 0, y, TILE, "c25516")
			_rect(img, 0, TILE - 2, TILE, 2, "7c2f0a")
		"wand":
			img.fill(hex("caa477"))
			_border(img, "9c784c")
		"tuer":
			img.fill(hex("caa477"))
			_rect(img, 4, 3, 8, 13, "6b4a2a")
			_rect(img, 10, 9, 1, 2, "ffd35e")
		"baum":
			# Stamm
			_rect(img, 7, 11, 2, 4, "6b4a2a")
			# Krone (rund, mehrere Grüntöne)
			_rect(img, 4, 2, 8, 8, "3f9d4a")
			_rect(img, 5, 1, 6, 1, "3f9d4a")
			_rect(img, 6, 4, 4, 4, "5cb84e")
			_border_rect(img, 4, 2, 8, 8, "2f7d3a")
		"blume":
			_fill_speckle(img, "4a9d3f", ["5cb84e", "3f8a36"], 8)
			_rect(img, 7, 7, 2, 2, "ff6b9d")
			_rect(img, 8, 8, 1, 1, "ffd35e")
		_:
			img.fill(hex("ff00ff"))  # auffälliges Magenta = unbekanntes Tile
	return img

## Baut ein einziges Atlas-Bild mit allen Tiles nebeneinander.
## Wird vom TileSet (Atlas-Quelle) genutzt.
static func tile_atlas() -> ImageTexture:
	var count := TILE_ORDER.size()
	var atlas := Image.create(count * TILE, TILE, false, Image.FORMAT_RGBA8)
	atlas.fill(Color(0, 0, 0, 0))
	for i in count:
		var t := tile_image(TILE_ORDER[i])
		atlas.blit_rect(t, Rect2i(0, 0, TILE, TILE), Vector2i(i * TILE, 0))
	return _to_tex(atlas)

# ----------------------------------------------------------------------------
# AKTEURE (Spieler / NPCs / Gegner) – einfacher Top-Down-Mensch, 16x16
# ----------------------------------------------------------------------------

## colors: { skin, hair, shirt, pants, accent } (Hex-Strings, accent optional).
static func make_actor(colors: Dictionary) -> ImageTexture:
	var img := _new_image()
	var skin := str(colors.get("skin", "f0c090"))
	var hair := str(colors.get("hair", "3a2a1a"))
	var shirt := str(colors.get("shirt", "d94f4f"))
	var pants := str(colors.get("pants", "3a4a8a"))
	var accent := str(colors.get("accent", ""))

	_rect(img, 4, 14, 8, 1, "00000040")   # Bodenschatten
	# Beine
	_rect(img, 5, 11, 2, 3, pants)
	_rect(img, 9, 11, 2, 3, pants)
	# Arme
	_rect(img, 3, 7, 1, 4, skin)
	_rect(img, 12, 7, 1, 4, skin)
	# Rumpf
	_rect(img, 4, 7, 8, 5, shirt)
	# Kopf
	_rect(img, 5, 2, 6, 5, skin)
	# Haare oder Hut
	if accent != "":
		_rect(img, 4, 1, 8, 2, accent)
		_rect(img, 5, 0, 6, 1, accent)
	else:
		_rect(img, 5, 1, 6, 2, hair)
	# Augen (Blick nach unten)
	_rect(img, 6, 4, 1, 1, "1a1420")
	_rect(img, 9, 4, 1, 1, "1a1420")
	return _to_tex(img)

## Gegner-Sprite: etwas grimmiger, anhand einer Hauptfarbe.
static func make_enemy(main_hex: String, accent_hex: String = "1a1420") -> ImageTexture:
	return make_actor({
		"skin": "c89a6a", "hair": accent_hex, "shirt": main_hex,
		"pants": "303030", "accent": ""
	})

# ----------------------------------------------------------------------------
# Tiefe Zeichen-Helfer (arbeiten direkt auf Image)
# ----------------------------------------------------------------------------

static func _rect(img: Image, x: int, y: int, w: int, h: int, c: String) -> void:
	var col := Color.html("#" + c)
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			if xx >= 0 and yy >= 0 and xx < TILE and yy < TILE:
				img.set_pixel(xx, yy, col)

static func _hline(img: Image, x: int, y: int, w: int, c: String) -> void:
	_rect(img, x, y, w, 1, c)

static func _vline(img: Image, x: int, y: int, h: int, c: String) -> void:
	_rect(img, x, y, 1, h, c)

static func _border(img: Image, c: String) -> void:
	_border_rect(img, 0, 0, TILE, TILE, c)

static func _border_rect(img: Image, x: int, y: int, w: int, h: int, c: String) -> void:
	_hline(img, x, y, w, c)
	_hline(img, x, y + h - 1, w, c)
	_vline(img, x, y, h, c)
	_vline(img, x + w - 1, y, h, c)

static func _fill_speckle(img: Image, base: String, spots: Array, density: int) -> void:
	img.fill(Color.html("#" + base))
	var rng := RandomNumberGenerator.new()
	rng.seed = base.hash()  # deterministisch je Grundfarbe -> stabile Optik
	for i in density:
		var c: String = spots[rng.randi() % spots.size()]
		var x := rng.randi_range(0, TILE - 2)
		var y := rng.randi_range(0, TILE - 1)
		_rect(img, x, y, 2, 1, c)
