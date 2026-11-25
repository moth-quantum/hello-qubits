# Two-qubit Pauli engine for the interdependency tutorial.
# Mirrors tools/tutorial_engine.py exactly (the tutorial's checks run on that file).
#
# Conventions: a word is two letters from I, X, Y, Z; the first letter is qubit 1 (the high bit of the
# statevector index), the second is qubit 2. Complex numbers are Vector2(re, im).
# A turn about pole G by angle theta applies exp(-i theta G / 2); G may be a word or {word: weight}.

const LETTERS := ["I", "Z", "X", "Y"]
const WORDS := ["IZ", "IX", "IY", "ZI", "ZZ", "ZX", "ZY", "XI", "XZ", "XX", "XY", "YI", "YZ", "YX", "YY"]

static func c_mul(a: Vector2, b: Vector2) -> Vector2:
	return Vector2(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x)

static func c_conj(a: Vector2) -> Vector2:
	return Vector2(a.x, -a.y)

static func single(l: String) -> Array:
	match l:
		"X": return [Vector2.ZERO, Vector2(1, 0), Vector2(1, 0), Vector2.ZERO]
		"Y": return [Vector2.ZERO, Vector2(0, -1), Vector2(0, 1), Vector2.ZERO]
		"Z": return [Vector2(1, 0), Vector2.ZERO, Vector2.ZERO, Vector2(-1, 0)]
	return [Vector2(1, 0), Vector2.ZERO, Vector2.ZERO, Vector2(1, 0)]

static func word_matrix(w: String) -> Array:
	var a := single(w[0])
	var b := single(w[1])
	var m: Array = []
	m.resize(16)
	for r in 4:
		for c in 4:
			m[r * 4 + c] = c_mul(a[(r >> 1) * 2 + (c >> 1)], b[(r & 1) * 2 + (c & 1)])
	return m

static func pole_matrix(pole) -> Array:
	if pole is String:
		return word_matrix(pole)
	var m: Array = []
	for i in 16: m.append(Vector2.ZERO)
	for w in pole:
		var wm := word_matrix(w)
		for i in 16: m[i] += wm[i] * float(pole[w])
	return m

static func mat_vec(m: Array, v: Array) -> Array:
	var out: Array = []
	for r in 4:
		var s := Vector2.ZERO
		for c in 4: s += c_mul(m[r * 4 + c], v[c])
		out.append(s)
	return out

static func inner(a: Array, b: Array) -> Vector2:
	var s := Vector2.ZERO
	for i in 4: s += c_mul(c_conj(a[i]), b[i])
	return s

static func normalise(v: Array) -> Array:
	var n := 0.0
	for z in v: n += (z as Vector2).length_squared()
	n = sqrt(n)
	var out: Array = []
	for z in v: out.append(z / n)
	return out

static func value(psi: Array, w: String) -> float:
	return inner(psi, mat_vec(word_matrix(w), psi)).x

static func values(psi: Array) -> Dictionary:
	var d := {}
	for w in WORDS: d[w] = value(psi, w)
	return d

static func turn(psi: Array, pole, angle: float) -> Array:
	var gp := mat_vec(pole_matrix(pole), psi)
	var c := cos(angle / 2.0)
	var s := sin(angle / 2.0)
	var out: Array = []
	for i in 4:
		var z: Vector2 = gp[i]
		out.append(psi[i] * c + Vector2(z.y, -z.x) * s)   # -i * z = (z.y, -z.x)
	return out

static func push_step(psi: Array, w: String, sign: float, step: float) -> Array:
	var hp := mat_vec(word_matrix(w), psi)
	for i in 4: hp[i] = hp[i] * sign
	var e := inner(psi, hp).x
	var out: Array = []
	for i in 4: out.append(psi[i] - (hp[i] - psi[i] * e) * step)
	return normalise(out)

static func covariance(psi: Array, p: String, q: String) -> float:
	var P := word_matrix(p)
	var Q := word_matrix(q)
	var a := inner(psi, mat_vec(P, mat_vec(Q, psi))).x
	var b := inner(psi, mat_vec(Q, mat_vec(P, psi))).x
	return 0.5 * (a + b) - value(psi, p) * value(psi, q)

static func rate(psi: Array, g: String, q: String) -> float:
	# d<Q>/dtheta for a small turn about word g: -Im <psi| G Q |psi>
	return -inner(psi, mat_vec(word_matrix(g), mat_vec(word_matrix(q), psi))).y

static func anticommute(a: String, b: String) -> bool:
	var n := 0
	for i in 2:
		if a[i] != "I" and b[i] != "I" and a[i] != b[i]: n += 1
	return n % 2 == 1

static func product_word(a: String, b: String) -> String:
	var out := ""
	for i in 2:
		var x: String = a[i]
		var y: String = b[i]
		if x == "I": out += y
		elif y == "I": out += x
		elif x == y: out += "I"
		else:
			for l in ["X", "Y", "Z"]:
				if l != x and l != y: out += l
	return out

static func discs(pole: String) -> Array:
	# Pairs [P, Q] with Q = pole * P, ordered as in WORDS.
	var out: Array = []
	for p in WORDS:
		if anticommute(p, pole):
			var q := product_word(pole, p)
			var pair := [p, q] if WORDS.find(p) < WORDS.find(q) else [q, p]
			if not out.has(pair): out.append(pair)
	return out

static func word_name(w: String) -> String:
	var s := ""
	for i in 2:
		if w[i] != "I": s += w[i] + str(i + 1)
	return s

static func angle_of(a: Dictionary) -> float:
	return PI * float(a.get("angle_pi", 0.0)) + float(a.get("angle", 0.0))

# Every gate is a list of commuting turns [pole, angle], applied together.
static func expand(a: Dictionary) -> Array:
	if a.has("turn"):
		var out: Array = []
		for t in a["turn"]: out.append([t["pole"], angle_of(t)])
		return out
	var q := int(a.get("qubit", 1))
	var th := angle_of(a)
	var X := "XI" if q == 1 else "IX"
	var Y := "YI" if q == 1 else "IY"
	var Z := "ZI" if q == 1 else "IZ"
	var r2 := 1.0 / sqrt(2.0)
	match a["gate"]:
		"x": return [[X, PI]]
		"y": return [[Y, PI]]
		"z": return [[Z, PI]]
		"h": return [[{X: r2, Z: r2}, PI]]
		"rx": return [[X, th]]
		"ry": return [[Y, th]]
		"rz": return [[Z, th]]
		"cz": return [["ZZ", -PI / 2.0], ["ZI", PI / 2.0], ["IZ", PI / 2.0]]
		"cx": return [["ZX", -PI / 2.0], ["ZI", PI / 2.0], ["IX", PI / 2.0]]
	return []

# Solve (J^T J + lam I) x = J^T r by Gaussian elimination.
static func least_squares(J: Array, r: Array, k: int) -> Array:
	var A: Array = []
	var b: Array = []
	for i in k:
		var row: Array = []
		for j in k:
			var s := 1e-3 if i == j else 0.0
			for m in J.size(): s += J[m][i] * J[m][j]
			row.append(s)
		A.append(row)
		var t := 0.0
		for m in J.size(): t += J[m][i] * r[m]
		b.append(t)
	for i in k:
		var piv := i
		for j in range(i + 1, k):
			if absf(A[j][i]) > absf(A[piv][i]): piv = j
		var tmp = A[i]; A[i] = A[piv]; A[piv] = tmp
		var tb = b[i]; b[i] = b[piv]; b[piv] = tb
		for j in range(i + 1, k):
			var f: float = A[j][i] / A[i][i]
			for c in range(i, k): A[j][c] -= f * A[i][c]
			b[j] -= f * b[i]
	var x: Array = []
	x.resize(k)
	for i in range(k - 1, -1, -1):
		var s: float = b[i]
		for c in range(i + 1, k): s -= A[i][c] * x[c]
		x[i] = s / A[i][i]
	return x

# One iteration of a relative target. Returns [psi, done].
static func target_step(psi: Array, goal: Dictionary, poles: Array, max_step := 0.05, tol := 0.01) -> Array:
	var words: Array = goal.keys()
	var r: Array = []
	var rn := 0.0
	for w in words:
		var d: float = goal[w] - value(psi, w)
		r.append(d); rn += d * d
	if sqrt(rn) < tol: return [psi, true]
	var J: Array = []
	for w in words:
		var row: Array = []
		for g in poles: row.append(rate(psi, g, w))
		J.append(row)
	var th := least_squares(J, r, poles.size())
	var mx := 0.0
	for t in th: mx = maxf(mx, absf(t))
	if mx < 1e-6: return [psi, true]
	var sc := minf(1.0, max_step / mx)
	for i in poles.size(): psi = turn(psi, poles[i], th[i] * sc)
	return [psi, false]

static func apply(psi: Array, a: Dictionary) -> Array:
	if a.has("push"):
		var n := int(round(float(a.get("amount", 0.1)) / 0.01))
		for i in n: psi = push_step(psi, a["push"], float(a.get("sign", 1)), 0.01)
		return psi
	if a.has("target"):
		var goal := {}
		for w in a["target"]: goal[w] = clampf(value(psi, w) + float(a["target"][w]), -1.0, 1.0)
		for i in 200:
			var res := target_step(psi, goal, a["poles"])
			psi = res[0]
			if res[1]: break
		return psi
	for t in expand(a): psi = turn(psi, t[0], t[1])
	return psi
