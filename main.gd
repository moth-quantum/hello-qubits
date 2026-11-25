extends Node2D

const MicroMoth = preload("res://micromoth.gd")
const Puzzles   = preload("res://puzzles.gd")

# Hello Qubits — Godot 4 port of the Hello Qiskit game from the Qiskit Textbook.
# Two-qubit state displayed as Pauli expectation values in the original diamond layout.
# Gates: x, z, h (single-qubit Clifford) and cz (two-qubit Clifford).
# State is tracked as a 4-element complex statevector; Pauli expectations are derived analytically.

# ── Statevector ────────────────────────────────────────────────────────────────
# Indices: 0=|00⟩, 1=|01⟩, 2=|10⟩, 3=|11⟩  (qubit 0 is the high bit)
var _sv: Array = [[1.0,0.0],[0.0,0.0],[0.0,0.0],[0.0,0.0]]

# Pauli expectations: ZI IZ ZZ XI IX XX ZX XZ  (all in [-1, +1])
var _rho: Dictionary = {}

# ── Puzzle data ────────────────────────────────────────────────────────────────
var _puzzles: Array = []
var _pidx: int = 0
# Working copy of remaining gate uses.  -1 = unlimited;  N>0 = N remaining.
var _uses: Dictionary = {}
var _moves: int = 0

# ── Animation ──────────────────────────────────────────────────────────────────
var _anim_pairs:   Array      = []   # {from, to, color, side}  — H swap
var _anim_paulis:  Array      = []
var _anim_t:       float      = 1.0
var _pending_press: Dictionary = {}
var _flip_cells:   Array      = []   # {pos, start_color, end_color}  — X flip
var _flip_paulis:  Array      = []
var _flip_t:       float      = 1.0
var _pending_flip: Dictionary = {}
var _cz_swaps:     Array      = []   # {from, to, color}  — CZ traveling circles
var _cz_cells:     Array      = []   # {pos, start_color, end_color}  — CZ XX flip
var _cz_paulis:    Array      = []
var _cz_t:         float      = 1.0
var _pending_cz:   Dictionary = {}
const ANIM_DUR := 0.28

# ── Visual constants ───────────────────────────────────────────────────────────
const W    := 960
const H    := 640
const CELL := 82        # grid unit → pixel
const BX   := 318       # screen x for grid x=0 (board centre within 640px board)
const BY   := 295       # screen y for grid y=3.5 (vertical centre, shifted up for button room)
const DR   := 52        # diamond cell half-diagonal
const CR   := 30        # circle radius inside each diamond cell
const PX   := 640       # right panel x

# Gate button geometry
const BTN_S    := 72    # button square side length
const BTN_Y    := 578   # centre-y for Z and X gate buttons (below diamond)
const BTN_Y_H  := 602   # centre-y for H gate buttons (staggered lower)
const CZ_BTN_Y := 68    # centre-y for CZ gate button (above diamond)

# Grid positions from the original hello_quantum.py box dictionary.
const BOXES := {
	"ZI": Vector2(-1,2), "XI": Vector2(-2,3),
	"IZ": Vector2( 1,2), "IX": Vector2( 2,3),
	"ZZ": Vector2( 0,3), "ZX": Vector2( 1,4),
	"XZ": Vector2(-1,4), "XX": Vector2( 0,5)
}

# Connecting lines drawn behind the circles (mirror the original grid-lines).
const EDGES := [
	["ZI","IZ"],["ZI","ZZ"],["IZ","ZZ"],
	["ZI","XI"],["IZ","IX"],
	["XI","XZ"],["IX","ZX"],
	["ZZ","XZ"],["ZZ","ZX"],
	["XZ","XX"],["ZX","XX"]
]

const C_BG      := Color(0.30, 0.30, 0.62)          # blue-purple background
const C_CELL    := Color(0.40, 0.40, 0.75, 0.80)    # active diamond cell fill
const C_CELL_BG := Color(0.28, 0.28, 0.58, 0.50)    # background (inactive) cell
const C_EDGE    := Color(0.70, 0.70, 1.00, 0.35)    # grid connector lines
const C_CONN    := Color(0.80, 0.80, 1.00, 0.45)    # button connection lines
const C_LBL     := Color(0.85, 0.88, 1.00)          # labels
const C_WIN     := Color(0.35, 1.00, 0.55)          # success / goal highlight
const C_BTN_ON  := Color(0.95, 0.95, 1.00)          # active button background
const C_BTN_HOV := Color(1.00, 1.00, 1.00)          # hovered button background
const C_BTN_OFF := Color(0.55, 0.55, 0.72)          # exhausted / disabled button
const C_BTN_TXT := Color(0.15, 0.15, 0.35)          # button text (dark)
const C_PANEL   := Color(0.22, 0.22, 0.50)

# ── Phase ──────────────────────────────────────────────────────────────────────
enum Ph { TITLE, PLAY, SUCCESS }

# Title screen choices: the original puzzles, or the interdependency tutorial (tutorial.tscn).
const TITLE_OPTIONS := [
	["Puzzles", Rect2(330, 360, 300, 46)],
	["Interdependency tutorial", Rect2(330, 420, 300, 46)],
]
var _ph: Ph = Ph.TITLE

# ── Buttons ────────────────────────────────────────────────────────────────────
# Each entry: {rect, gate, qkey}   qkey ∈ {"0","1","both"}
var _btns: Array = []
var _hov: int = -1  # hovered button index

# ── Font ───────────────────────────────────────────────────────────────────────
var _font: Font

# ── Visible boxes for current puzzle ──────────────────────────────────────────
var _visible: Array = []  # subset of BOXES keys

func _ready() -> void:
	_font = ThemeDB.fallback_font
	_build_puzzles()
	if OS.has_feature("web"):
		JavaScriptBridge.eval("var s=document.createElement('style');s.textContent='html{background:#4d4d9e;}body{overflow-x:auto!important;overflow-y:auto!important;display:flex;justify-content:center;align-items:flex-start;background:#4d4d9e;}#canvas{width:960px!important;height:640px!important;}';document.head.appendChild(s);")
	queue_redraw()

func _build_puzzles() -> void:
	_puzzles = Puzzles.get_all()

func _load(idx: int) -> void:
	_pidx = idx
	_sv = [[1.0,0.0],[0.0,0.0],[0.0,0.0],[0.0,0.0]]
	for gp: Array in _puzzles[idx]["init"]:
		_gate(gp[0], gp[1])
	_rho_from_sv()
	_uses = {}
	for qk: String in _puzzles[idx]["gates"]:
		_uses[qk] = {}
		for g: String in _puzzles[idx]["gates"][qk]:
			var lim: int = _puzzles[idx]["gates"][qk][g]
			_uses[qk][g] = -1 if lim == 0 else lim
	_moves = 0
	_visible = _get_visible(idx)
	_ph = Ph.PLAY
	_build_btns()
	queue_redraw()

func _get_visible(idx: int) -> Array:
	var puz: Dictionary = _puzzles[idx]
	if puz["visible"] is String:
		return BOXES.keys()
	return puz["visible"]

# ── Quantum logic ──────────────────────────────────────────────────────────────
func _re_dot(a: Array, b: Array) -> float:
	return a[0]*b[0] + a[1]*b[1]

func _mag2(a: Array) -> float:
	return a[0]*a[0] + a[1]*a[1]

func _rho_from_sv() -> void:
	var a: Array = _sv
	_rho["ZI"] = _mag2(a[0]) + _mag2(a[1]) - _mag2(a[2]) - _mag2(a[3])
	_rho["IZ"] = _mag2(a[0]) - _mag2(a[1]) + _mag2(a[2]) - _mag2(a[3])
	_rho["ZZ"] = _mag2(a[0]) - _mag2(a[1]) - _mag2(a[2]) + _mag2(a[3])
	_rho["XI"] = 2.0*(_re_dot(a[0],a[2]) + _re_dot(a[1],a[3]))
	_rho["IX"] = 2.0*(_re_dot(a[0],a[1]) + _re_dot(a[2],a[3]))
	_rho["XX"] = 2.0*(_re_dot(a[0],a[3]) + _re_dot(a[1],a[2]))
	_rho["ZX"] = 2.0*(_re_dot(a[0],a[1]) - _re_dot(a[2],a[3]))
	_rho["XZ"] = 2.0*(_re_dot(a[0],a[2]) - _re_dot(a[1],a[3]))

func _gate(gate_name: String, qubit: String) -> void:
	# MicroMoth uses qubit 0 = LSB; our qubit 0 = MSB, so mm_q = 1 - q.
	var q := int(qubit)
	var qc := MicroMoth.QuantumCircuit.new(2)
	qc.initialize(_sv.duplicate(true))
	match gate_name:
		"x", "NOT": qc.x(1 - q)
		"z":        qc.z(1 - q)
		"h":        qc.h(1 - q)
		"cz":
			qc.h(0); qc.cx(1, 0); qc.h(0)   # CZ = H_t · CX · H_t
	_sv = MicroMoth.simulate(qc, 0, "statevector")

func _satisfied() -> bool:
	var goal: Dictionary = _puzzles[_pidx]["goal"]
	if goal.is_empty(): return false
	for p: String in goal:
		if abs(_rho.get(p, 0.0) - goal[p]) > 0.1:
			return false
	return true

# ── Buttons ────────────────────────────────────────────────────────────────────
# Fixed 7-button layout — always the same positions; grey when not in current puzzle.
const GATE_SLOT_0 := {"z": -3, "h": -2, "x": -1}
const GATE_SLOT_1 := {"z":  3, "h":  2, "x":  1}

const FIXED_BTN_SPECS: Array = [
	{"gate": "z",  "qkey": "0"},
	{"gate": "h",  "qkey": "0"},
	{"gate": "x",  "qkey": "0"},
	{"gate": "x",  "qkey": "1"},
	{"gate": "h",  "qkey": "1"},
	{"gate": "z",  "qkey": "1"},
	{"gate": "cz", "qkey": "both"},
]

# Which diamond cells each button's connection lines reach.
# Z affects X-type observables (top row); X affects Z-type (bottom row); H both.
const H_SWAPS := {
	"0": [["ZI","XI"], ["ZZ","XZ"], ["ZX","XX"]],
	"1": [["IZ","IX"], ["ZZ","ZX"], ["XZ","XX"]],
}
const X_FLIPS := {
	"0": ["ZI", "ZZ", "ZX"],
	"1": ["IZ", "ZZ", "XZ"],
}
const Z_FLIPS := {
	"0": ["XI", "XZ", "XX"],
	"1": ["IX", "ZX", "XX"],
}
const CZ_SWAP_PAIRS := [["XI","XZ"], ["IX","ZX"]]

const BTN_CONNECTS := {
	"0_z":  ["XI","XZ","XX"],     # Z on q0 flips all X-type for q0 (chain up-right)
	"0_x":  ["ZI","ZZ","ZX"],     # X on q0 flips all Z-type for q0 (chain up-right)
	"0_h":  ["ZI","XI"],          # H on q0: two arms to swap partners
	"1_z":  ["IX","ZX","XX"],     # Z on q1 flips all X-type for q1 (chain up-left)
	"1_x":  ["IZ","ZZ","XZ"],     # X on q1 flips all Z-type for q1 (chain up-left)
	"1_h":  ["IZ","IX"],          # H on q1: two arms to swap partners
	"both_cz": ["XZ","ZX"],
}

func _build_btns() -> void:
	_btns.clear()
	for spec: Dictionary in FIXED_BTN_SPECS:
		var qk: String = spec["qkey"]
		var g:  String = spec["gate"]
		var center: Vector2
		if qk == "both":
			center = Vector2(BX, CZ_BTN_Y)
		else:
			var slots: Dictionary = GATE_SLOT_0 if qk == "0" else GATE_SLOT_1
			var btn_y := BTN_Y_H if g == "h" else BTN_Y
			center = Vector2(BX + slots[g] * CELL, btn_y)
		_btns.append({"gate": g, "qkey": qk, "center": center})

func _btn_rect(b: Dictionary) -> Rect2:
	var c: Vector2 = b["center"]
	return Rect2(c.x - BTN_S/2.0, c.y - BTN_S/2.0, BTN_S, BTN_S)

func _btn_enabled(b: Dictionary) -> bool:
	return _uses.get(b["qkey"], {}).get(b["gate"], 0) != 0

# ── Input ──────────────────────────────────────────────────────────────────────
func _input(ev: InputEvent) -> void:
	if _ph == Ph.TITLE:
		if ev is InputEventMouseButton and ev.pressed:
			if TITLE_OPTIONS[1][1].has_point(ev.position):
				get_tree().change_scene_to_file("res://tutorial.tscn")
			elif TITLE_OPTIONS[0][1].has_point(ev.position):
				_load(0)
		return

	if _ph == Ph.SUCCESS:
		if ev is InputEventMouseButton and ev.pressed:
			var nxt := _pidx + 1
			if nxt < _puzzles.size(): _load(nxt)
			else: _ph = Ph.TITLE; queue_redraw()
		return

	if ev is InputEventKey and ev.pressed and ev.keycode == KEY_SPACE:
		var nxt := _pidx + 1
		if nxt < _puzzles.size(): _load(nxt)
		else: _ph = Ph.TITLE; queue_redraw()
		return

	if ev is InputEventMouseMotion:
		var old := _hov; _hov = -1
		for i in _btns.size():
			if _btn_rect(_btns[i]).has_point(ev.position) and _btn_enabled(_btns[i]):
				_hov = i; break
		if _hov != old: queue_redraw()

	if ev is InputEventMouseButton and ev.pressed and ev.button_index == 1:
		for b in _btns:
			if _btn_rect(b).has_point(ev.position) and _btn_enabled(b):
				_press(b); return

func _press(b: Dictionary) -> void:
	if _anim_t < 1.0 or _flip_t < 1.0 or _cz_t < 1.0: return
	var qk: String = b["qkey"]
	var g:  String = b["gate"]
	var q_arg := "0" if qk == "both" else qk
	if g == "h":
		_start_h_anim(q_arg)
		_pending_press = b
		return
	if g == "x":
		_start_x_anim(q_arg)
		_pending_flip = b
		return
	if g == "z":
		_start_z_anim(q_arg)
		_pending_flip = b
		return
	if g == "cz":
		_start_cz_anim()
		_pending_cz = b
		return
	_finish_press(b)

func _finish_press(b: Dictionary) -> void:
	var qk: String = b["qkey"]
	var g:  String = b["gate"]
	var q_arg := "0" if qk == "both" else qk
	_gate(g, q_arg)
	var rem = _uses.get(qk, {}).get(g, -1)
	if rem > 0:
		_uses[qk][g] = rem - 1
	_rho_from_sv()
	_moves += 1
	if _satisfied():
		_ph = Ph.SUCCESS
	queue_redraw()

func _start_h_anim(q: String) -> void:
	_anim_pairs.clear()
	_anim_paulis.clear()
	for pair: Array in H_SWAPS.get(q, []):
		var a: String = pair[0]
		var b: String = pair[1]
		if a not in _visible or b not in _visible: continue
		var pa := _sp(BOXES[a])
		var pb := _sp(BOXES[b])
		var prob_a: float = (1.0 - float(_rho.get(a, 0.0))) / 2.0
		var prob_b: float = (1.0 - float(_rho.get(b, 0.0))) / 2.0
		_anim_pairs.append({"from": pa, "to": pb, "color": Color(prob_a, prob_a, prob_a), "side":  1})
		_anim_pairs.append({"from": pb, "to": pa, "color": Color(prob_b, prob_b, prob_b), "side": -1})
		_anim_paulis.append(a)
		_anim_paulis.append(b)
	_anim_t = 0.0

func _start_x_anim(q: String) -> void:
	_flip_cells.clear()
	_flip_paulis.clear()
	for pauli: String in X_FLIPS.get(q, []):
		if pauli not in _visible: continue
		var pos  := _sp(BOXES[pauli])
		var prob: float = (1.0 - float(_rho.get(pauli, 0.0))) / 2.0
		_flip_cells.append({"pos": pos,
			"start_color": Color(prob, prob, prob),
			"end_color":   Color(1.0 - prob, 1.0 - prob, 1.0 - prob)})
		_flip_paulis.append(pauli)
	_flip_t = 0.0

func _start_z_anim(q: String) -> void:
	_flip_cells.clear()
	_flip_paulis.clear()
	for pauli: String in Z_FLIPS.get(q, []):
		if pauli not in _visible: continue
		var pos  := _sp(BOXES[pauli])
		var prob: float = (1.0 - float(_rho.get(pauli, 0.0))) / 2.0
		_flip_cells.append({"pos": pos,
			"start_color": Color(prob, prob, prob),
			"end_color":   Color(1.0 - prob, 1.0 - prob, 1.0 - prob)})
		_flip_paulis.append(pauli)
	_flip_t = 0.0

func _start_cz_anim() -> void:
	_cz_swaps.clear()
	_cz_cells.clear()
	_cz_paulis.clear()
	# XI↔XZ and IX↔ZX: H-style traveling circles
	for pair: Array in CZ_SWAP_PAIRS:
		var a: String = pair[0];  var b: String = pair[1]
		if a not in _visible or b not in _visible: continue
		var pa := _sp(BOXES[a]);  var pb := _sp(BOXES[b])
		var prob_a: float = (1.0 - float(_rho.get(a, 0.0))) / 2.0
		var prob_b: float = (1.0 - float(_rho.get(b, 0.0))) / 2.0
		_cz_swaps.append({"from": pa, "to": pb, "color": Color(prob_a, prob_a, prob_a)})
		_cz_swaps.append({"from": pb, "to": pa, "color": Color(prob_b, prob_b, prob_b)})
		_cz_paulis.append(a);  _cz_paulis.append(b)
	# XX→−YY: coin flip
	if "XX" in _visible:
		var xx_after: float = 2.0 * (_re_dot(_sv[0], _sv[3]) - _re_dot(_sv[1], _sv[2]))
		var pos := _sp(BOXES["XX"])
		var sp: float = (1.0 - float(_rho.get("XX", 0.0))) / 2.0
		var ep: float = (1.0 - xx_after) / 2.0
		_cz_cells.append({"pos": pos, "start_color": Color(sp, sp, sp), "end_color": Color(ep, ep, ep)})
		_cz_paulis.append("XX")
	_cz_t = 0.0

func _anim_pos(from_pos: Vector2, to_pos: Vector2, t: float, _side: int) -> Vector2:
	return from_pos.lerp(to_pos, t)

func _ease(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)

func _process(delta: float) -> void:
	var redraw := false
	if _anim_t < 1.0:
		_anim_t = minf(_anim_t + delta / ANIM_DUR, 1.0)
		if _anim_t >= 1.0:
			_anim_pairs.clear()
			_anim_paulis.clear()
			if not _pending_press.is_empty():
				_finish_press(_pending_press)
				_pending_press = {}
		else:
			redraw = true
	if _flip_t < 1.0:
		_flip_t = minf(_flip_t + delta / ANIM_DUR, 1.0)
		if _flip_t >= 1.0:
			_flip_cells.clear()
			_flip_paulis.clear()
			if not _pending_flip.is_empty():
				_finish_press(_pending_flip)
				_pending_flip = {}
		else:
			redraw = true
	if _cz_t < 1.0:
		_cz_t = minf(_cz_t + delta / ANIM_DUR, 1.0)
		if _cz_t >= 1.0:
			_cz_swaps.clear()
			_cz_cells.clear()
			_cz_paulis.clear()
			if not _pending_cz.is_empty():
				_finish_press(_pending_cz)
				_pending_cz = {}
		else:
			redraw = true
	if redraw:
		queue_redraw()

# ── Drawing ────────────────────────────────────────────────────────────────────
func _sp(gv: Vector2) -> Vector2:
	# y-axis is inverted vs screen: larger grid-y → higher on screen (smaller pixel-y)
	return Vector2(BX + gv.x * CELL, BY + (3.5 - gv.y) * CELL)

func _draw() -> void:
	draw_rect(Rect2(0,0,W,H), C_BG)
	match _ph:
		Ph.TITLE:   _draw_title()
		Ph.PLAY:    _draw_board(); _draw_target(); _draw_board_buttons(); _draw_panel()
		Ph.SUCCESS: _draw_board(); _draw_target(); _draw_board_buttons(); _draw_panel(); _draw_success()

func _draw_title() -> void:
	var cx := W/2.0
	draw_string(_font, Vector2(cx-160, H/2.0-70), "Hello Qubits",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 52, Color.WHITE)
	draw_string(_font, Vector2(cx-190, H/2.0+10),
		"A two-qubit quantum computing puzzle game",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 20, C_LBL)
	for i in TITLE_OPTIONS.size():
		var r: Rect2 = TITLE_OPTIONS[i][1]
		draw_rect(r, C_BTN_ON)
		var tw := _font.get_string_size(TITLE_OPTIONS[i][0], HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
		draw_string(_font, r.position + Vector2((r.size.x - tw) / 2.0, 30), TITLE_OPTIONS[i][0],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 20, C_BTN_TXT)

func _diamond_pts(center: Vector2, r: float) -> PackedVector2Array:
	return PackedVector2Array([
		center + Vector2(0, -r),
		center + Vector2(r,  0),
		center + Vector2(0,  r),
		center + Vector2(-r, 0),
	])

func _draw_diamond(center: Vector2, r: float, fill: Color,
		outline_col: Color, outline_w: float) -> void:
	var pts := _diamond_pts(center, r)
	draw_polygon(pts, PackedColorArray([fill, fill, fill, fill]))
	draw_polyline(PackedVector2Array([pts[0],pts[1],pts[2],pts[3],pts[0]]),
		outline_col, outline_w)

func _draw_target() -> void:
	var goal: Dictionary = _puzzles[_pidx]["goal"]
	if goal.is_empty(): return
	const MBX  := 85.0    # mini-grid centre x
	const MBY  := 215.0   # mini-grid centre y (same coordinate system as _sp)
	const MS   := 20.0    # cell unit (vs CELL=82)
	const MDR  := 13.0    # half-diagonal (vs DR=52)
	const MCR  :=  8.0    # circle radius (vs CR=30)
	draw_string(_font, Vector2(MBX - 40.0, MBY - MDR - 55.0), "Target",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, C_LBL)
	for pauli: String in BOXES:
		var gv: Vector2 = BOXES[pauli]
		var pos := Vector2(MBX + gv.x * MS, MBY + (3.5 - gv.y) * MS)
		_draw_diamond(pos, MDR, C_CELL_BG, Color(0.55, 0.55, 0.85, 0.3), 0.6)
		if goal.has(pauli):
			var prob := (1.0 - float(goal[pauli])) / 2.0
			_draw_diamond(pos, MDR, C_CELL, C_WIN, 1.2)
			draw_circle(pos, MCR, Color(prob, prob, prob))
			draw_arc(pos, MCR, 0.0, TAU, 32, Color(1.0, 1.0, 1.0, 0.5), 1.0)

func _draw_board() -> void:
	var goal: Dictionary = _puzzles[_pidx]["goal"]

	# All 8 background cells (dim, always visible for context)
	for pauli: String in BOXES:
		var pos := _sp(BOXES[pauli])
		_draw_diamond(pos, DR, C_CELL_BG, Color(0.55,0.55,0.85,0.5), 1.0)

	# Grid connector lines
	for e: Array in EDGES:
		draw_line(_sp(BOXES[e[0]]), _sp(BOXES[e[1]]), C_EDGE, 1.2)

	# Active cells: diamond container + circle inside
	for pauli: String in _visible:
		var pos      := _sp(BOXES[pauli])
		var rv       : float = _rho.get(pauli, 0.0)
		var prob     := (1.0 - rv) / 2.0   # 0=black |0⟩, 1=white |1⟩
		var is_goal  := goal.has(pauli)
		var animating := pauli in _anim_paulis or pauli in _flip_paulis or pauli in _cz_paulis

		# Diamond container
		var oc := C_WIN if is_goal else Color(0.75,0.75,1.0,0.9)
		var ow := 3.0   if is_goal else 1.8
		_draw_diamond(pos, DR, C_CELL, oc, ow)

		# Circle fill inside (hidden while its circle is in flight)
		if not animating:
			draw_circle(pos, CR, Color(prob, prob, prob))
			draw_arc(pos, CR, 0.0, TAU, 40, Color(1,1,1,0.7), 1.5)

		# Pauli label
		var lc := Color(0.1,0.1,0.1) if prob > 0.55 else Color(0.95,0.95,0.95)
		draw_string(_font, pos + Vector2(-14, 6), pauli,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, lc)

	# Animated swap circles (H gate)
	if _anim_t < 1.0:
		var et := _ease(_anim_t)
		for ap: Dictionary in _anim_pairs:
			var p := _anim_pos(ap["from"], ap["to"], et, ap["side"])
			draw_circle(p, CR, ap["color"])
			draw_arc(p, CR, 0.0, TAU, 40, Color(1,1,1,0.7), 1.5)

	# Flip circles (X gate) — coin-flip around Y axis
	if _flip_t < 1.0:
		var fy := absf(cos(_flip_t * PI))
		for fc: Dictionary in _flip_cells:
			var col: Color = fc["start_color"] if _flip_t < 0.5 else fc["end_color"]
			draw_set_transform(fc["pos"], 0.0, Vector2(1.0, fy))
			draw_circle(Vector2.ZERO, CR, col)
			draw_arc(Vector2.ZERO, CR, 0.0, TAU, 40, Color(1.0, 1.0, 1.0, 0.7), 1.5)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# CZ animation — green lines matching button routing, traveling circles, XX flip
	if _cz_t < 1.0:
		var green := Color(0.30, 1.00, 0.45, 0.85)
		var bx: float = BX
		var btn_bottom: float = CZ_BTN_Y + BTN_S / 2.0
		var xx_top: Vector2 = _sp(BOXES["XX"]) + Vector2(0.0, -DR)
		draw_line(Vector2(bx, btn_bottom), Vector2(bx, xx_top.y), green, 2.5)
		for arm: Array in [["XZ", "XI", -1.0], ["ZX", "IX", 1.0]]:
			var mid_top: Vector2 = _sp(BOXES[arm[0]]) + Vector2(0.0, -DR)
			var end_top: Vector2 = _sp(BOXES[arm[1]]) + Vector2(0.0, -DR)
			var sign: float = arm[2]
			draw_line(xx_top, mid_top, green, 2.5)
			draw_line(mid_top, end_top, green, 2.5)
			var cp      := _sp(BOXES[arm[1]])
			var notch_a := end_top + Vector2(sign * DR, 0.0)
			var notch_b := notch_a  + Vector2(0.0, float(DR))
			draw_line(end_top, notch_a, green, 2.5)
			draw_line(notch_a, notch_b, green, 2.5)
			draw_line(notch_b, cp, green, 2.5)
		var et := _ease(_cz_t)
		for sw: Dictionary in _cz_swaps:
			var p := (sw["from"] as Vector2).lerp(sw["to"], et)
			draw_circle(p, CR, sw["color"])
			draw_arc(p, CR, 0.0, TAU, 40, Color(1,1,1,0.7), 1.5)
		if not _cz_cells.is_empty():
			var fy := absf(cos(_cz_t * PI))
			for fc: Dictionary in _cz_cells:
				var col: Color = fc["start_color"] if _cz_t < 0.5 else fc["end_color"]
				draw_set_transform(fc["pos"], 0.0, Vector2(1.0, fy))
				draw_circle(Vector2.ZERO, CR, col)
				draw_arc(Vector2.ZERO, CR, 0.0, TAU, 40, Color(1.0, 1.0, 1.0, 0.7), 1.5)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_board_buttons() -> void:
	for i in _btns.size():
		var b: Dictionary = _btns[i]
		var r  := _btn_rect(b)
		var en := _btn_enabled(b)
		var hov := en and (i == _hov)

		# Connection lines — two independent branches, one per target cell
		var actual_g: String = b["gate"]
		var conn_key: String = b["qkey"] + "_" + actual_g
		if BTN_CONNECTS.has(conn_key):
			var lc: Color = C_CONN if en else Color(C_CONN.r, C_CONN.g, C_CONN.b, C_CONN.a * 0.35)
			var bx: float = b["center"].x
			if b["qkey"] == "both":
				# CZ: down to XX top, two 45° diagonals along outer boundary to XI/IX,
				# then rectangular notch (sideways → down → back to center)
				var btn_bottom: float = r.position.y + BTN_S
				var xx_top: Vector2 = _sp(BOXES["XX"]) + Vector2(0.0, -DR)
				draw_line(Vector2(bx, btn_bottom), Vector2(bx, xx_top.y), lc, 1.5)
				for arm: Array in [["XZ", "XI", -1.0], ["ZX", "IX", 1.0]]:
					var mid_top: Vector2 = _sp(BOXES[arm[0]]) + Vector2(0.0, -DR)
					var end_top: Vector2 = _sp(BOXES[arm[1]]) + Vector2(0.0, -DR)
					var sign: float = arm[2]
					draw_line(xx_top, mid_top, lc, 1.5)
					draw_line(mid_top, end_top, lc, 1.5)
					var cp       := _sp(BOXES[arm[1]])
					var notch_a  := end_top + Vector2(sign * DR, 0.0)
					var notch_b  := notch_a  + Vector2(0.0, float(DR))
					draw_line(end_top, notch_a, lc, 1.5)
					draw_line(notch_a, notch_b, lc, 1.5)
					draw_line(notch_b, cp, lc, 1.5)
			else:
				var start_y: float = r.position.y
				var cells: Array = BTN_CONNECTS[conn_key]
				var actual_gate: String = b["gate"]
				var junc_y: float = BY + 1.5 * CELL + DR
				if actual_gate == "z" or actual_gate == "x":
					# Trunk to junc_y, right to first cell x, up, then center-to-center chain
					draw_line(Vector2(bx, start_y), Vector2(bx, junc_y), lc, 1.5)
					var first := _sp(BOXES[cells[0]])
					draw_line(Vector2(bx, junc_y), Vector2(first.x, junc_y), lc, 1.5)
					draw_line(Vector2(first.x, junc_y), first, lc, 1.5)
					for ci in range(1, cells.size()):
						draw_line(_sp(BOXES[cells[ci-1]]), _sp(BOXES[cells[ci]]), lc, 1.5)
				else:
					# H gate: trunk to junc_y, then one arm per target cell
					draw_line(Vector2(bx, start_y), Vector2(bx, junc_y), lc, 1.5)
					for tp: String in cells:
						var cp := _sp(BOXES[tp])
						draw_line(Vector2(bx, junc_y), Vector2(cp.x, junc_y), lc, 1.5)
						draw_line(Vector2(cp.x, junc_y), cp, lc, 1.5)

		# Button square
		var bg := C_BTN_HOV if hov else (C_BTN_ON if en else C_BTN_OFF)
		draw_rect(r, bg)
		draw_rect(r, Color(1,1,1,0.3) if en else Color(0,0,0,0.1), false, 1.5)

		# Gate letter (large) + "GATE" text below
		var tc := C_BTN_TXT if en else Color(0.35,0.35,0.50)
		var letter: String = (b["gate"] as String).to_upper()
		draw_string(_font, r.position + Vector2(BTN_S/2.0 - 10, BTN_S/2.0 + 4),
			letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, tc)
		draw_string(_font, r.position + Vector2(BTN_S/2.0 - 17, BTN_S/2.0 + 22),
			"GATE", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, tc)

		# Remaining uses badge
		var rem = _uses.get(b["qkey"], {}).get(actual_g, -1)
		if rem > 0:
			draw_string(_font, r.position + Vector2(2, 14), "(%d)" % rem,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, tc)

func _draw_panel() -> void:
	draw_rect(Rect2(PX, 0, W-PX, H), C_PANEL)

	var puz: Dictionary = _puzzles[_pidx]
	draw_string(_font, Vector2(PX+12, 28),
		"Puzzle %d / %d" % [_pidx+1, _puzzles.size()],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 15, C_LBL)
	draw_string(_font, Vector2(PX+12, 58), puz["title"],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)

	var dy := 92.0
	for line: String in puz["desc"].split("\n"):
		draw_string(_font, Vector2(PX+12, dy), line,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 15, C_LBL)
		dy += 22

	var goal_str := ""
	for p: String in puz["goal"]:
		goal_str += "%s=%s  " % [p, str(puz["goal"][p])]
	if goal_str == "": goal_str = "(explore)"
	draw_string(_font, Vector2(PX+12, dy+4),
		"Goal: " + goal_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, C_WIN)

	draw_string(_font, Vector2(PX+12, H-20),
		"Moves: %d" % _moves, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, C_LBL)

func _draw_success() -> void:
	draw_rect(Rect2(0, H/2.0-65, W, 130), Color(0,0,0,0.78))
	draw_string(_font, Vector2(W/2.0-110, H/2.0-12),
		"Puzzle solved!", HORIZONTAL_ALIGNMENT_LEFT, -1, 44, C_WIN)
	draw_string(_font, Vector2(W/2.0-100, H/2.0+42),
		"Click to continue", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, C_LBL)
