// Two-qubit Pauli engine. A line-for-line port of tools/tutorial_engine.py (and pauli2.gd).
//
// A word is two letters from I, X, Y, Z; the first letter is qubit 1 (the high bit of the
// statevector index), the second is qubit 2. Complex numbers are [re, im].
// A turn about pole G by angle theta applies exp(-i theta G / 2); G may be a word or {word: weight}.

export type Complex = [number, number]
export type Psi = Complex[]
export type Word = string
export type Pole = Word | Record<Word, number>

export interface TurnSpec {
  pole: Pole
  angle_pi?: number
  angle?: number
}

export interface Action {
  label?: string
  gate?: string
  qubit?: number
  angle_pi?: number
  angle?: number
  turn?: TurnSpec[]
  push?: Word
  sign?: number
  amount?: number
  target?: Record<Word, number>
  poles?: Word[]
}

export const LETTERS = ['I', 'Z', 'X', 'Y'] as const
export const WORDS: Word[] = [
  'IZ', 'IX', 'IY', 'ZI', 'ZZ', 'ZX', 'ZY', 'XI', 'XZ', 'XX', 'XY', 'YI', 'YZ', 'YX', 'YY',
]

const SINGLE: Record<string, Complex[]> = {
  I: [[1, 0], [0, 0], [0, 0], [1, 0]],
  X: [[0, 0], [1, 0], [1, 0], [0, 0]],
  Y: [[0, 0], [0, -1], [0, 1], [0, 0]],
  Z: [[1, 0], [0, 0], [0, 0], [-1, 0]],
}

const cMul = (a: Complex, b: Complex): Complex => [a[0] * b[0] - a[1] * b[1], a[0] * b[1] + a[1] * b[0]]

const matrixCache = new Map<Word, Complex[]>()

export function wordMatrix(w: Word): Complex[] {
  const cached = matrixCache.get(w)
  if (cached) return cached
  const a = SINGLE[w[0]]
  const b = SINGLE[w[1]]
  const m: Complex[] = []
  for (let r = 0; r < 4; r++) {
    for (let c = 0; c < 4; c++) {
      m.push(cMul(a[(r >> 1) * 2 + (c >> 1)], b[(r & 1) * 2 + (c & 1)]))
    }
  }
  matrixCache.set(w, m)
  return m
}

export function poleMatrix(pole: Pole): Complex[] {
  if (typeof pole === 'string') return wordMatrix(pole)
  const m: Complex[] = Array.from({ length: 16 }, () => [0, 0] as Complex)
  for (const [w, weight] of Object.entries(pole)) {
    const wm = wordMatrix(w)
    for (let i = 0; i < 16; i++) {
      m[i][0] += wm[i][0] * weight
      m[i][1] += wm[i][1] * weight
    }
  }
  return m
}

function matVec(m: Complex[], v: Psi): Psi {
  const out: Psi = []
  for (let r = 0; r < 4; r++) {
    let re = 0
    let im = 0
    for (let c = 0; c < 4; c++) {
      const [mr, mi] = m[r * 4 + c]
      const [vr, vi] = v[c]
      re += mr * vr - mi * vi
      im += mr * vi + mi * vr
    }
    out.push([re, im])
  }
  return out
}

/** <a|b> */
function inner(a: Psi, b: Psi): Complex {
  let re = 0
  let im = 0
  for (let i = 0; i < 4; i++) {
    re += a[i][0] * b[i][0] + a[i][1] * b[i][1]
    im += a[i][0] * b[i][1] - a[i][1] * b[i][0]
  }
  return [re, im]
}

function normalise(v: Psi): Psi {
  let n = 0
  for (const z of v) n += z[0] * z[0] + z[1] * z[1]
  n = Math.sqrt(n)
  return v.map(([re, im]) => [re / n, im / n] as Complex)
}

export const ZERO_STATE = (): Psi => [[1, 0], [0, 0], [0, 0], [0, 0]]

export function value(psi: Psi, w: Word): number {
  return inner(psi, matVec(wordMatrix(w), psi))[0]
}

export function values(psi: Psi): Record<Word, number> {
  const d: Record<Word, number> = {}
  for (const w of WORDS) d[w] = value(psi, w)
  return d
}

export function turn(psi: Psi, pole: Pole, angle: number): Psi {
  const gp = matVec(poleMatrix(pole), psi)
  const c = Math.cos(angle / 2)
  const s = Math.sin(angle / 2)
  // -i * z = (z.im, -z.re)
  return psi.map((z, i) => [z[0] * c + gp[i][1] * s, z[1] * c - gp[i][0] * s] as Complex)
}

export function pushStep(psi: Psi, w: Word, sign: number, step: number): Psi {
  const hp = matVec(wordMatrix(w), psi).map(([re, im]) => [re * sign, im * sign] as Complex)
  const e = inner(psi, hp)[0]
  return normalise(
    psi.map((z, i) => [z[0] - (hp[i][0] - z[0] * e) * step, z[1] - (hp[i][1] - z[1] * e) * step] as Complex),
  )
}

export const pushSteps = (amount = 0.1, step = 0.01) => Math.round(amount / step)

/** How much q moves (per unit) when p is pushed: 1/2 <{P,Q}> - <P><Q>. */
export function covariance(psi: Psi, p: Word, q: Word): number {
  const P = wordMatrix(p)
  const Q = wordMatrix(q)
  const a = inner(psi, matVec(P, matVec(Q, psi)))[0]
  const b = inner(psi, matVec(Q, matVec(P, psi)))[0]
  return 0.5 * (a + b) - value(psi, p) * value(psi, q)
}

/** d<Q>/d theta for a small turn about word g: -Im <psi| G Q |psi>. */
export function rate(psi: Psi, g: Word, q: Word): number {
  return -inner(psi, matVec(wordMatrix(g), matVec(wordMatrix(q), psi)))[1]
}

export function anticommute(a: Word, b: Word): boolean {
  let n = 0
  for (let i = 0; i < 2; i++) if (a[i] !== 'I' && b[i] !== 'I' && a[i] !== b[i]) n++
  return n % 2 === 1
}

/** Letter-wise product, ignoring the sign. */
export function productWord(a: Word, b: Word): Word {
  let out = ''
  for (let i = 0; i < 2; i++) {
    const x = a[i]
    const y = b[i]
    if (x === 'I') out += y
    else if (y === 'I') out += x
    else if (x === y) out += 'I'
    else out += ['X', 'Y', 'Z'].find((l) => l !== x && l !== y)
  }
  return out
}

/** Pairs [P, Q] with Q = pole * P, ordered as in WORDS. */
export function discs(pole: Word): [Word, Word][] {
  const out: [Word, Word][] = []
  for (const p of WORDS) {
    if (!anticommute(p, pole)) continue
    const q = productWord(pole, p)
    const pair: [Word, Word] = WORDS.indexOf(p) < WORDS.indexOf(q) ? [p, q] : [q, p]
    if (!out.some(([a, b]) => a === pair[0] && b === pair[1])) out.push(pair)
  }
  return out
}

/** 'XZ' -> 'X1Z2', 'IY' -> 'Y2'. */
export function wordName(w: Word): string {
  let s = ''
  for (let i = 0; i < 2; i++) if (w[i] !== 'I') s += w[i] + String(i + 1)
  return s
}

const angleOf = (a: { angle_pi?: number; angle?: number }) => Math.PI * (a.angle_pi ?? 0) + (a.angle ?? 0)

export const isGateAction = (a: Action) => a.push === undefined && a.target === undefined

/** Every gate is a list of commuting turns [pole, angle], applied together. */
export function expand(a: Action): [Pole, number][] {
  if (a.turn) return a.turn.map((t) => [t.pole, angleOf(t)])
  const q = a.qubit ?? 1
  const th = angleOf(a)
  const X = q === 1 ? 'XI' : 'IX'
  const Y = q === 1 ? 'YI' : 'IY'
  const Z = q === 1 ? 'ZI' : 'IZ'
  const r2 = 1 / Math.sqrt(2)
  switch (a.gate) {
    case 'x': return [[X, Math.PI]]
    case 'y': return [[Y, Math.PI]]
    case 'z': return [[Z, Math.PI]]
    case 'h': return [[{ [X]: r2, [Z]: r2 }, Math.PI]]
    case 'rx': return [[X, th]]
    case 'ry': return [[Y, th]]
    case 'rz': return [[Z, th]]
    case 'cz': return [['ZZ', -Math.PI / 2], ['ZI', Math.PI / 2], ['IZ', Math.PI / 2]]
    case 'cx': return [['ZX', -Math.PI / 2], ['ZI', Math.PI / 2], ['IX', Math.PI / 2]]
  }
  return []
}

/** The single word pole of a gate button, or null when it turns about several poles at once. */
export function singlePole(a: Action): Word | null {
  if (!isGateAction(a)) return null
  const ex = expand(a)
  return ex.length === 1 && typeof ex[0][0] === 'string' ? ex[0][0] : null
}

/** Words a gate button can move: those anticommuting with one of its poles. */
export function movedBy(a: Action | null): Word[] {
  if (!a || !isGateAction(a)) return []
  const poleWords = expand(a).flatMap(([pole]) => (typeof pole === 'string' ? [pole] : Object.keys(pole)))
  return WORDS.filter((w) => poleWords.some((g) => anticommute(w, g)))
}

/** Solve (J^T J + lam I) x = J^T r by Gaussian elimination with partial pivoting. */
function leastSquares(J: number[][], r: number[], k: number): number[] {
  const A: number[][] = []
  const b: number[] = []
  for (let i = 0; i < k; i++) {
    const row: number[] = []
    for (let j = 0; j < k; j++) {
      let s = i === j ? 1e-3 : 0
      for (let m = 0; m < J.length; m++) s += J[m][i] * J[m][j]
      row.push(s)
    }
    A.push(row)
    let t = 0
    for (let m = 0; m < J.length; m++) t += J[m][i] * r[m]
    b.push(t)
  }
  for (let i = 0; i < k; i++) {
    let piv = i
    for (let j = i + 1; j < k; j++) if (Math.abs(A[j][i]) > Math.abs(A[piv][i])) piv = j
    ;[A[i], A[piv]] = [A[piv], A[i]]
    ;[b[i], b[piv]] = [b[piv], b[i]]
    for (let j = i + 1; j < k; j++) {
      const f = A[j][i] / A[i][i]
      for (let c = i; c < k; c++) A[j][c] -= f * A[i][c]
      b[j] -= f * b[i]
    }
  }
  const x = new Array<number>(k)
  for (let i = k - 1; i >= 0; i--) {
    let s = b[i]
    for (let c = i + 1; c < k; c++) s -= A[i][c] * x[c]
    x[i] = s / A[i][i]
  }
  return x
}

export const TARGET_ITERS = 200

/** Goal of a relative target: current value + change, clipped to [-1, 1]. */
export function targetGoal(psi: Psi, change: Record<Word, number>): Record<Word, number> {
  const goal: Record<Word, number> = {}
  for (const [w, d] of Object.entries(change)) goal[w] = Math.min(1, Math.max(-1, value(psi, w) + d))
  return goal
}

/** One iteration of a relative target. */
export function targetStep(
  psi: Psi,
  goal: Record<Word, number>,
  poles: Word[],
  maxStep = 0.05,
  tol = 0.01,
): { psi: Psi; done: boolean } {
  const words = Object.keys(goal)
  const r = words.map((w) => goal[w] - value(psi, w))
  if (Math.hypot(...r) < tol) return { psi, done: true }
  const J = words.map((w) => poles.map((g) => rate(psi, g, w)))
  const th = leastSquares(J, r, poles.length)
  const mx = Math.max(...th.map(Math.abs))
  if (mx < 1e-6) return { psi, done: true }
  const sc = Math.min(1, maxStep / mx)
  poles.forEach((g, i) => {
    psi = turn(psi, g, th[i] * sc)
  })
  return { psi, done: false }
}

export function apply(psi: Psi, a: Action): Psi {
  if (a.push !== undefined) {
    const n = pushSteps(a.amount)
    for (let i = 0; i < n; i++) psi = pushStep(psi, a.push, a.sign ?? 1, 0.01)
    return psi
  }
  if (a.target !== undefined) {
    const goal = targetGoal(psi, a.target)
    for (let i = 0; i < TARGET_ITERS; i++) {
      const res = targetStep(psi, goal, a.poles ?? [])
      psi = res.psi
      if (res.done) break
    }
    return psi
  }
  for (const [pole, angle] of expand(a)) psi = turn(psi, pole, angle)
  return psi
}

export function startState(actions: Action[]): Psi {
  return actions.reduce(apply, ZERO_STATE())
}

export function goalMet(vals: Record<Word, number>, goal: Record<Word, number>, tol: number): boolean {
  const entries = Object.entries(goal)
  return entries.length > 0 && entries.every(([w, v]) => Math.abs(vals[w] - v) <= tol)
}
