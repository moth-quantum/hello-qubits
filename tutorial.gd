extends Node2D

# Interdependency tutorial for Hello Qubits.
# All content comes from tutorial/tutorial.json, which also generates TUTORIAL.md (tools/build_tutorial.py).
# The board is the Hello Qubits diamond extended with the Y values: all 15 values of two qubits.
#
# Command-line options (after "--"), for testing:
#   --test                    replay every puzzle's solution and print the values, then quit
#   --shot=N --out=FILE.png   open puzzle N (0-based), optionally --press=0,1 and --hover=K, save a screenshot

const P2 = preload("res://pauli2.gd")

const W := 960
const H := 640
const PX := 572            # right panel x
const U := 58.0            # board grid unit
const BX := 286.0          # board centre x
const BY0 := 404.0         # screen y of grid row y = 1 (Z1, Z2)
const DR := 46.0           # diamond half-diagonal
const CR := 25.0           # circle radius
const ANIM := 0.7          # seconds per action
const TOL := 0.05

const C_BG      := Color(0.30, 0.30, 0.62)
const C_PANEL   := Color(0.22, 0.22, 0.50)
const C_CELL    := Color(0.40, 0.40, 0.75, 0.80)
const C_CELL_BG := Color(0.28, 0.28, 0.58, 0.50)
const C_EDGE    := Color(0.70, 0.70, 1.00, 0.30)
const C_LBL     := Color(0.85, 0.88, 1.00)
const C_WIN     := Color(0.35, 1.00, 0.55)
const C_HOV     := Color(1.00, 0.85, 0.30)
const C_TWIN    := Color(1.00, 0.55, 0.85)
const C_BTN_ON  := Color(0.95, 0.95, 1.00)
const C_BTN_HOV := Color(1.00, 1.00, 1.00)
const C_BTN_OFF := Color(0.55, 0.55, 0.72)
const C_BTN_TXT := Color(0.15, 0.15, 0.35)

var _data: Dictionary
var _list: Array = []        # flat list of [chapter_index, puzzle_dict]
var _idx := 0
var _psi: Array = []
var _vals: Dictionary = {}
var _solved := false
var _moves := 0
var _status := ""
var _disc_pole := ""

# action animation
var _act: Dictionary = {}
var _act_t := 1.0
var _act_done := 0.0         # fraction of a turn already applied
var _act_goal: Dictionary = {}

var _btns: Array = []        # {rect, action}
var _nav: Array = []         # {rect, id, label}
var _hov := -1
var _hov_nav := ""
var _font: Font
var _text: RichTextLabel
var _title: Label

func _ready() -> void:
	_font = ThemeDB.fallback_font
	_data = JSON.parse_string(FileAccess.get_file_as_string("res://tutorial/tutorial.json"))
	for ci in _data["chapters"].size():
		for p in _data["chapters"][ci]["puzzles"]:
			_list.append([ci, p])
	_title = Label.new()
	_title.position = Vector2(PX + 14, 30)
	_title.size = Vector2(W - PX - 28, 30)
	_title.add_theme_font_size_override("font_size", 22)
	_title.add_theme_color_override("font_color", Color.WHITE)
	add_child(_title)
	_text = RichTextLabel.new()
	_text.position = Vector2(PX + 14, 66)
	_text.size = Vector2(W - PX - 28, 262)
	_text.bbcode_enabled = true
	_text.scroll_active = true
	_text.mouse_filter = Control.MOUSE_FILTER_PASS
	_text.add_theme_font_size_override("normal_font_size", 14)
	_text.add_theme_color_override("default_color", C_LBL)
	add_child(_text)
	_build_nav()
	var args := _args()
	if args.has("test"):
		_run_test()
		return
	_load(int(args.get("shot", "0")))
	if args.has("shot"):
		await _screenshot(args)

func _args() -> Dictionary:
	var d := {}
	for a in OS.get_cmdline_user_args():
		var s: String = a.trim_prefix("--")
		var kv := s.split("=", true, 1)
		d[kv[0]] = kv[1] if kv.size() > 1 else ""
	return d

# ── Puzzles ───────────────────────────────────────────────────────────────────
func _puz() -> Dictionary:
	return _list[_idx][1]

func _visible() -> Array:
	var v = _puz()["visible"]
	return P2.WORDS if v is String else v

func _load(i: int) -> void:
	_idx = clampi(i, 0, _list.size() - 1)
	_psi = [Vector2(1, 0), Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
	for a in _puz()["start"]:
		_psi = P2.apply(_psi, a)
	_vals = P2.values(_psi)
	_solved = false
	_moves = 0
	_status = ""
	_act_t = 1.0
	_disc_pole = _puz().get("discs_pole", "")
	_build_btns()
	_refresh_text()
	queue_redraw()

func _met() -> bool:
	var goal: Dictionary = _puz()["goal"]
	if goal.is_empty(): return false
	for w in goal:
		if absf(_vals[w] - float(goal[w])) > TOL: return false
	return true

func _refresh_text() -> void:
	var ci: int = _list[_idx][0]
	_title.text = _puz()["title"]
	var s := "[color=#aab0e0]%s   (%d / %d)[/color]\n\n" % [_data["chapters"][ci]["title"], _idx + 1, _list.size()]
	s += _puz()["text"]
	if _solved and _puz()["after"] != "":
		s += "\n\n[color=#5aff8c]Solved![/color] " + _puz()["after"]
	_text.text = s

# ── Actions ───────────────────────────────────────────────────────────────────
func _start(a: Dictionary) -> void:
	if _act_t < 1.0: return
	_act = a
	_act_t = 0.0
	_act_done = 0.0
	_status = ""
	_act_goal = {}
	if a.has("target"):
		for w in a["target"]:
			_act_goal[w] = clampf(_vals[w] + float(a["target"][w]), -1.0, 1.0)
	var ex := [] if (a.has("push") or a.has("target")) else P2.expand(a)
	if ex.size() == 1 and ex[0][0] is String:
		_disc_pole = ex[0][0]

func _advance(frac: float) -> void:
	# Apply the part of the current action between _act_done and frac (0..1).
	var a := _act
	if a.has("push"):
		var n_total := int(round(float(a.get("amount", 0.1)) / 0.01))
		var n := int(round(frac * n_total)) - int(round(_act_done * n_total))
		for i in n: _psi = P2.push_step(_psi, a["push"], float(a.get("sign", 1)), 0.01)
	elif a.has("target"):
		var n := int(round(frac * 200)) - int(round(_act_done * 200))
		for i in n:
			var res := P2.target_step(_psi, _act_goal, a["poles"])
			_psi = res[0]
			if res[1]:
				frac = 1.0
				break
	else:
		for t in P2.expand(a):
			_psi = P2.turn(_psi, t[0], t[1] * (frac - _act_done))
	_act_done = frac
	_vals = P2.values(_psi)

func _finish() -> void:
	_moves += 1
	if _act.has("target"):
		var parts: Array = []
		for w in _act_goal:
			parts.append("%s: wanted %+.2f, reached %+.2f" % [P2.word_name(w), _act_goal[w], _vals[w]])
		_status = "  ".join(parts)
	if not _solved and _met():
		_solved = true
	_refresh_text()

func _process(delta: float) -> void:
	if _act_t >= 1.0: return
	_act_t = minf(_act_t + delta / ANIM, 1.0)
	var f := _act_t * _act_t * (3.0 - 2.0 * _act_t)
	if _act.has("target"): f = _act_t
	_advance(1.0 if _act_t >= 1.0 else f)
	if _act_done >= 1.0:
		_act_t = 1.0
	if _act_t >= 1.0:
		_finish()
	queue_redraw()

# ── Layout ────────────────────────────────────────────────────────────────────
func _grid(w: String) -> Vector2:
	var a := P2.LETTERS.find(w[0])
	var b := P2.LETTERS.find(w[1])
	return Vector2(b - a, a + b)

func _sp(w: String) -> Vector2:
	var g := _grid(w)
	return Vector2(BX + g.x * U, BY0 - (g.y - 1.0) * U)

func _build_btns() -> void:
	_btns.clear()
	var bs: Array = _puz()["buttons"]
	var per_row := 4
	var bw := 128.0
	var bh := 44.0
	var gap := 8.0
	var rows := int(ceil(bs.size() / float(per_row)))
	var y0 := 470.0 if rows <= 2 else 462.0
	for i in bs.size():
		var row := i / per_row
		var in_row := mini(per_row, bs.size() - row * per_row)
		var x0 := BX - (in_row * bw + (in_row - 1) * gap) / 2.0
		var r := Rect2(x0 + (i % per_row) * (bw + gap), y0 + row * (bh + gap), bw, bh)
		_btns.append({"rect": r, "action": bs[i]})

func _build_nav() -> void:
	_nav.clear()
	var ids := [["menu", "Menu"], ["back", "Back"], ["reset", "Reset"], ["next", "Next"]]
	for i in ids.size():
		_nav.append({"rect": Rect2(PX + 14 + i * 92, H - 46, 84, 32), "id": ids[i][0], "label": ids[i][1]})

# ── Input ─────────────────────────────────────────────────────────────────────
func _input(ev: InputEvent) -> void:
	if ev is InputEventMouseMotion:
		var old := _hov
		var old_nav := _hov_nav
		_hov = -1
		_hov_nav = ""
		for i in _btns.size():
			if _btns[i]["rect"].has_point(ev.position): _hov = i
		for n in _nav:
			if n["rect"].has_point(ev.position): _hov_nav = n["id"]
		if _hov != old or _hov_nav != old_nav: queue_redraw()
	elif ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		for b in _btns:
			if b["rect"].has_point(ev.position):
				_start(b["action"]); return
		for n in _nav:
			if n["rect"].has_point(ev.position):
				_nav_press(n["id"]); return
	elif ev is InputEventKey and ev.pressed:
		match ev.keycode:
			KEY_RIGHT, KEY_N: _nav_press("next")
			KEY_LEFT, KEY_B: _nav_press("back")
			KEY_R: _nav_press("reset")

func _nav_press(id: String) -> void:
	match id:
		"menu": get_tree().change_scene_to_file("res://main.tscn")
		"back": _load(_idx - 1)
		"reset": _load(_idx)
		"next":
			if _idx + 1 < _list.size(): _load(_idx + 1)

# ── Drawing ───────────────────────────────────────────────────────────────────
func _shade(v: float) -> Color:
	var p := (1.0 - v) / 2.0
	return Color(p, p, p)

func _diamond(c: Vector2, r: float, fill: Color, line: Color, lw: float) -> void:
	var pts := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)])
	draw_polygon(pts, PackedColorArray([fill, fill, fill, fill]))
	pts.append(pts[0])
	draw_polyline(pts, line, lw)

func _hover_action() -> Dictionary:
	return _btns[_hov]["action"] if _hov >= 0 and _hov < _btns.size() else {}

func _moved_by(a: Dictionary) -> Array:
	var out: Array = []
	if a.is_empty() or a.has("push") or a.has("target"): return out
	for t in P2.expand(a):
		var ws: Array = [t[0]] if t[0] is String else t[0].keys()
		for w in P2.WORDS:
			for g in ws:
				if P2.anticommute(w, g) and not out.has(w): out.append(w)
	return out

func _draw() -> void:
	draw_rect(Rect2(0, 0, W, H), C_BG)
	_draw_board()
	_draw_buttons()
	_draw_panel()

func _draw_board() -> void:
	var vis := _visible()
	var goal: Dictionary = _puz()["goal"]
	var hl: Array = _puz().get("highlight", [])
	var ha := _hover_action()
	var moved := _moved_by(ha)
	# grid lines between neighbours
	for w in P2.WORDS:
		for v in P2.WORDS:
			var d := _grid(v) - _grid(w)
			if (d == Vector2(1, 1) or d == Vector2(-1, 1)) and vis.has(w) and vis.has(v):
				draw_line(_sp(w), _sp(v), C_EDGE, 1.0)
	# qubit labels
	draw_string(_font, _sp("ZI") + Vector2(-122, 6), "qubit 1", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, C_LBL)
	draw_string(_font, _sp("IZ") + Vector2(56, 6), "qubit 2", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, C_LBL)
	for w in P2.WORDS:
		var c := _sp(w)
		if not vis.has(w):
			_diamond(c, DR, C_CELL_BG, Color(0.55, 0.55, 0.85, 0.35), 1.0)
			continue
		var line := Color(0.75, 0.75, 1.0, 0.9)
		var lw := 1.6
		if hl.has(w): line = C_TWIN; lw = 3.0
		if goal.has(w): line = C_WIN; lw = 3.0
		if moved.has(w): line = C_HOV; lw = 3.5
		_diamond(c, DR, C_CELL, line, lw)
		if goal.has(w) and line != C_WIN:
			var gp := PackedVector2Array([c + Vector2(0, -DR + 6), c + Vector2(DR - 6, 0), c + Vector2(0, DR - 6), c + Vector2(-DR + 6, 0), c + Vector2(0, -DR + 6)])
			draw_polyline(gp, C_WIN, 2.0)
		var v: float = _vals[w]
		draw_circle(c, CR, _shade(v))
		draw_arc(c, CR, 0, TAU, 40, Color(1, 1, 1, 0.7), 1.4)
		var tc := Color(0.08, 0.08, 0.12) if v < -0.1 else Color(0.95, 0.95, 0.98)
		var nm := P2.word_name(w)
		var nw := _font.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		draw_string(_font, c + Vector2(-nw / 2.0, -3), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, tc)
		var vs := "%+.2f" % v if absf(v) > 0.005 else "0"
		var vw := _font.get_string_size(vs, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		draw_string(_font, c + Vector2(-vw / 2.0, 12), vs, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, tc)
	# covariance when hovering a push (second pass, so neighbours don't cover it)
	if ha.has("push"):
		for w in vis:
			var cv := P2.covariance(_psi, ha["push"], w)
			if absf(cv) > 0.005:
				var s := "follows x%.2f" % cv
				var sw := _font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
				var p := _sp(w) + Vector2(-sw / 2.0, CR + 14)
				draw_rect(Rect2(p + Vector2(-3, -11), Vector2(sw + 6, 14)), Color(0.1, 0.1, 0.25, 0.9))
				draw_string(_font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, C_HOV)

func _draw_buttons() -> void:
	for i in _btns.size():
		var b: Dictionary = _btns[i]
		var r: Rect2 = b["rect"]
		var busy := _act_t < 1.0
		draw_rect(r, C_BTN_HOV if i == _hov else (C_BTN_OFF if busy else C_BTN_ON))
		draw_rect(r, Color(1, 1, 1, 0.3), false, 1.5)
		var lines := _wrap(b["action"]["label"], r.size.x - 10, 13)
		var y := r.position.y + r.size.y / 2.0 - (lines.size() - 1) * 8.0 + 5.0
		for ln in lines:
			var lw := _font.get_string_size(ln, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
			draw_string(_font, Vector2(r.position.x + (r.size.x - lw) / 2.0, y), ln, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, C_BTN_TXT)
			y += 16.0

func _wrap(s: String, width: float, size: int) -> Array:
	var out: Array = []
	var cur := ""
	for word in s.split(" "):
		var t := word if cur == "" else cur + " " + word
		if _font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width and cur != "":
			out.append(cur); cur = word
		else:
			cur = t
	if cur != "": out.append(cur)
	return out

func _draw_panel() -> void:
	draw_rect(Rect2(PX, 0, W - PX, H), C_PANEL)
	var y := 346.0
	# goal and status
	var goal: Dictionary = _puz()["goal"]
	var gs := ("Goal: explore" if _idx == _list.size() - 1 else "Goal: explore, then press Next") if goal.is_empty() else "Goal: "
	if not goal.is_empty():
		var parts: Array = []
		for w in goal: parts.append("%s = %+.2f" % [P2.word_name(w), float(goal[w])])
		gs += ",  ".join(parts)
	draw_string(_font, Vector2(PX + 14, y), gs, HORIZONTAL_ALIGNMENT_LEFT, W - PX - 28, 14, C_WIN)
	y += 18
	var ss := 0.0
	for w in P2.WORDS: ss += _vals[w] * _vals[w]
	var info := "Moves: %d     Sum of squares of all 15 values: %.2f" % [_moves, ss]
	draw_string(_font, Vector2(PX + 14, y), info, HORIZONTAL_ALIGNMENT_LEFT, W - PX - 28, 12, C_LBL)
	if _status != "":
		y += 16
		draw_string(_font, Vector2(PX + 14, y), _status, HORIZONTAL_ALIGNMENT_LEFT, W - PX - 28, 12, C_HOV)
	_draw_discs(400.0)
	for n in _nav:
		var r: Rect2 = n["rect"]
		var hi: bool = n["id"] == _hov_nav or (n["id"] == "next" and _solved)
		draw_rect(r, C_WIN if (n["id"] == "next" and _solved) else (C_BTN_HOV if hi else C_BTN_ON))
		var lw := _font.get_string_size(n["label"], HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		draw_string(_font, r.position + Vector2((r.size.x - lw) / 2.0, 21), n["label"], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, C_BTN_TXT)

func _draw_discs(y0: float) -> void:
	var pole := _disc_pole
	var ha := _hover_action()
	if not ha.is_empty() and not ha.has("push") and not ha.has("target"):
		var ex := P2.expand(ha)
		pole = ex[0][0] if (ex.size() == 1 and ex[0][0] is String) else ""
		if pole == "":
			draw_string(_font, Vector2(PX + 14, y0 + 14), "This button turns about more than one pole at once.",
				HORIZONTAL_ALIGNMENT_LEFT, W - PX - 28, 13, C_LBL)
			return
	if pole == "": return
	var vis := _visible()
	var ds: Array = []
	for d in P2.discs(pole):
		if vis.has(d[0]) or vis.has(d[1]): ds.append(d)
	var pv: float = _vals[pole]
	draw_string(_font, Vector2(PX + 14, y0 + 12),
		"Discs turned about pole %s  (%s = %+.2f)" % [P2.word_name(pole), P2.word_name(pole), pv],
		HORIZONTAL_ALIGNMENT_LEFT, W - PX - 28, 13, C_HOV)
	var r := 34.0
	var n := ds.size()
	var span := (W - PX - 28) / float(maxi(n, 1))
	for i in n:
		var c := Vector2(PX + 14 + span * (i + 0.5), y0 + 32 + r + 10)
		var a: String = ds[i][0]
		var b: String = ds[i][1]
		draw_circle(c, r, Color(0.30, 0.30, 0.62))
		draw_arc(c, r, 0, TAU, 48, Color(1, 1, 1, 0.8), 1.5)
		var inner := sqrt(maxf(0.0, 1.0 - pv * pv))
		if inner < 0.995:
			draw_arc(c, r * inner, 0, TAU, 48, Color(1, 1, 1, 0.45), 1.0, true)
		draw_line(c + Vector2(-r, 0), c + Vector2(r, 0), Color(1, 1, 1, 0.25), 1.0)
		draw_line(c + Vector2(0, -r), c + Vector2(0, r), Color(1, 1, 1, 0.25), 1.0)
		# vertical axis: first value (up = +1); horizontal: second value (right = +1)
		var pt := c + Vector2(_vals[b] * r, -_vals[a] * r)
		draw_line(c, pt, C_HOV, 2.0)
		draw_circle(pt, 5.0, C_HOV)
		var an := P2.word_name(a)
		var bn := P2.word_name(b)
		var aw := _font.get_string_size(an, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		draw_string(_font, c + Vector2(-aw / 2.0, -r - 4), an, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, C_LBL)
		var bw := _font.get_string_size(bn + " >", HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		draw_string(_font, c + Vector2(-bw / 2.0, r + 14), bn + " >", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, C_LBL)

# ── Testing ───────────────────────────────────────────────────────────────────
func _run_test() -> void:
	var fails := 0
	for i in _list.size():
		_load(i)
		for k in _puz()["solution"]:
			_psi = P2.apply(_psi, _puz()["buttons"][k])
		_vals = P2.values(_psi)
		var ok: bool = _puz()["goal"].is_empty() or _met()
		if not ok: fails += 1
		var vs: Array = []
		for w in P2.WORDS:
			if absf(_vals[w]) > 5e-4: vs.append("%s=%.3f" % [w, _vals[w]])
		print("%d %s %s | %s" % [i, "OK" if ok else "FAIL", _puz()["title"], " ".join(vs)])
	print("TEST %s" % ("PASSED" if fails == 0 else "FAILED (%d)" % fails))
	get_tree().quit()

func _screenshot(args: Dictionary) -> void:
	if args.get("press", "") != "":
		for k in args["press"].split(","):
			_psi = P2.apply(_psi, _puz()["buttons"][int(k)])
			_moves += 1
		_vals = P2.values(_psi)
		if _met(): _solved = true
		var last: Dictionary = _puz()["buttons"][int(args["press"].split(",")[-1])]
		var ex := [] if (last.has("push") or last.has("target")) else P2.expand(last)
		if ex.size() == 1 and ex[0][0] is String: _disc_pole = ex[0][0]
		_refresh_text()
	if args.has("hover"):
		_hov = int(args["hover"])
	queue_redraw()
	for i in 4: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(args.get("out", "user://shot.png"))
	get_tree().quit()
