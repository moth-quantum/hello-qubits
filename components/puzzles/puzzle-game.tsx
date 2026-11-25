'use client'

import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { apply, values, ZERO_STATE, type Action, type Psi } from '@/lib/engine'
import { C, shade, smoothstep } from '@/lib/palette'
import { PUZZLES, PUZZLE_TOL, type Gate, type QKey } from '@/lib/puzzles'

const CELL = 82
const BX = 318
const BY = 295
const DR = 52
const CR = 30
const BTN_S = 72
const BTN_Y = 578
const BTN_Y_H = 602
const CZ_BTN_Y = 68
const ANIM_MS = 280

type Pt = [number, number]

const BOXES: Record<string, Pt> = {
  ZI: [-1, 2], XI: [-2, 3], IZ: [1, 2], IX: [2, 3],
  ZZ: [0, 3], ZX: [1, 4], XZ: [-1, 4], XX: [0, 5],
}
const ALL = Object.keys(BOXES)

const EDGES: [string, string][] = [
  ['ZI', 'IZ'], ['ZI', 'ZZ'], ['IZ', 'ZZ'], ['ZI', 'XI'], ['IZ', 'IX'], ['XI', 'XZ'],
  ['IX', 'ZX'], ['ZZ', 'XZ'], ['ZZ', 'ZX'], ['XZ', 'XX'], ['ZX', 'XX'],
]

const BUTTONS: { gate: Gate; qkey: QKey; center: Pt }[] = [
  { gate: 'z', qkey: '0', center: [BX - 3 * CELL, BTN_Y] },
  { gate: 'h', qkey: '0', center: [BX - 2 * CELL, BTN_Y_H] },
  { gate: 'x', qkey: '0', center: [BX - 1 * CELL, BTN_Y] },
  { gate: 'x', qkey: '1', center: [BX + 1 * CELL, BTN_Y] },
  { gate: 'h', qkey: '1', center: [BX + 2 * CELL, BTN_Y_H] },
  { gate: 'z', qkey: '1', center: [BX + 3 * CELL, BTN_Y] },
  { gate: 'cz', qkey: 'both', center: [BX, CZ_BTN_Y] },
]

const H_SWAPS: Record<string, [string, string][]> = {
  '0': [['ZI', 'XI'], ['ZZ', 'XZ'], ['ZX', 'XX']],
  '1': [['IZ', 'IX'], ['ZZ', 'ZX'], ['XZ', 'XX']],
}
const X_FLIPS: Record<string, string[]> = { '0': ['ZI', 'ZZ', 'ZX'], '1': ['IZ', 'ZZ', 'XZ'] }
const Z_FLIPS: Record<string, string[]> = { '0': ['XI', 'XZ', 'XX'], '1': ['IX', 'ZX', 'XX'] }
const CZ_SWAP_PAIRS: [string, string][] = [['XI', 'XZ'], ['IX', 'ZX']]

const BTN_CONNECTS: Record<string, string[]> = {
  '0_z': ['XI', 'XZ', 'XX'], '0_x': ['ZI', 'ZZ', 'ZX'], '0_h': ['ZI', 'XI'],
  '1_z': ['IX', 'ZX', 'XX'], '1_x': ['IZ', 'ZZ', 'XZ'], '1_h': ['IZ', 'IX'],
}

const sp = (w: string): Pt => {
  const [gx, gy] = BOXES[w]
  return [BX + gx * CELL, BY + (3.5 - gy) * CELL]
}
const diamond = ([x, y]: Pt, r: number) => `${x},${y - r} ${x + r},${y} ${x},${y + r} ${x - r},${y}`
const poly = (pts: Pt[]) => pts.map((p) => p.join(',')).join(' ')

function gateAction(gate: Gate, qkey: QKey): Action {
  return gate === 'cz' ? { gate: 'cz' } : { gate, qubit: qkey === '1' ? 2 : 1 }
}

function initialUses(idx: number) {
  const uses: Record<string, number> = {}
  for (const [qk, gs] of Object.entries(PUZZLES[idx].gates)) {
    for (const [g, lim] of Object.entries(gs)) uses[`${qk}_${g}`] = lim === 0 ? -1 : (lim as number)
  }
  return uses
}

function loadState(idx: number): Psi {
  return PUZZLES[idx].init.reduce((p, [g, q]) => apply(p, gateAction(g, q)), ZERO_STATE())
}

interface Anim {
  btn: number
  next: Psi
  swaps: { from: Pt; to: Pt; color: string }[]
  flips: { pos: Pt; start: string; end: string }[]
  hidden: Set<string>
  cz: boolean
}

function czRoute(): Pt[][] {
  const xxTop: Pt = [sp('XX')[0], sp('XX')[1] - DR]
  const paths: Pt[][] = [[[BX, CZ_BTN_Y + BTN_S / 2], xxTop]]
  for (const [mid, end, sign] of [['XZ', 'XI', -1], ['ZX', 'IX', 1]] as const) {
    const midTop: Pt = [sp(mid)[0], sp(mid)[1] - DR]
    const endTop: Pt = [sp(end)[0], sp(end)[1] - DR]
    const notchA: Pt = [endTop[0] + sign * DR, endTop[1]]
    const notchB: Pt = [notchA[0], notchA[1] + DR]
    paths.push([xxTop, midTop, endTop, notchA, notchB, sp(end)])
  }
  return paths
}

function gateRoute(b: (typeof BUTTONS)[number]): Pt[][] {
  const cells = BTN_CONNECTS[`${b.qkey}_${b.gate}`]
  const [bx, by] = b.center
  const startY = by - BTN_S / 2
  const juncY = BY + 1.5 * CELL + DR
  if (b.gate === 'h') {
    return cells.map((w) => [[bx, startY], [bx, juncY], [sp(w)[0], juncY], sp(w)])
  }
  const first = sp(cells[0])
  return [[[bx, startY], [bx, juncY], [first[0], juncY], ...cells.map(sp)]]
}

export function PuzzleGame() {
  const router = useRouter()
  const [idx, setIdx] = useState(0)
  const [psi, setPsi] = useState<Psi>(() => loadState(0))
  const [uses, setUses] = useState(() => initialUses(0))
  const [moves, setMoves] = useState(0)
  const [success, setSuccess] = useState(false)
  const [hover, setHover] = useState<number | null>(null)
  const [anim, setAnim] = useState<Anim | null>(null)
  const [t, setT] = useState(1)
  const frameRef = useRef(0)
  const continueRef = useRef<HTMLButtonElement>(null)

  const puz = PUZZLES[idx]
  const visible = puz.visible === 'all' ? ALL : puz.visible
  const vals = useMemo(() => values(psi), [psi])

  const load = useCallback((i: number) => {
    cancelAnimationFrame(frameRef.current)
    setIdx(i)
    setPsi(loadState(i))
    setUses(initialUses(i))
    setMoves(0)
    setSuccess(false)
    setAnim(null)
    setT(1)
    setHover(null)
  }, [])

  const advance = useCallback(() => {
    if (idx + 1 < PUZZLES.length) load(idx + 1)
    else router.push('/')
  }, [idx, load, router])

  const enabled = (i: number) => (uses[`${BUTTONS[i].qkey}_${BUTTONS[i].gate}`] ?? 0) !== 0

  const finish = (a: Anim) => {
    const b = BUTTONS[a.btn]
    const key = `${b.qkey}_${b.gate}`
    setPsi(a.next)
    setUses((u) => (u[key] > 0 ? { ...u, [key]: u[key] - 1 } : u))
    setMoves((m) => m + 1)
    setAnim(null)
    setT(1)
    const v = values(a.next)
    const goal = Object.entries(puz.goal)
    if (goal.length > 0 && goal.every(([w, g]) => Math.abs((v[w] ?? 0) - g) <= PUZZLE_TOL)) setSuccess(true)
  }

  const press = (i: number) => {
    if (anim || success || !enabled(i)) return
    const b = BUTTONS[i]
    const next = apply(psi, gateAction(b.gate, b.qkey))
    const nv = values(next)
    const isVis = (w: string) => visible.includes(w)
    const a: Anim = { btn: i, next, swaps: [], flips: [], hidden: new Set(), cz: b.gate === 'cz' }
    const swap = (pairs: [string, string][]) => {
      for (const [p, q] of pairs) {
        if (!isVis(p) || !isVis(q)) continue
        a.swaps.push({ from: sp(p), to: sp(q), color: shade(vals[p]) }, { from: sp(q), to: sp(p), color: shade(vals[q]) })
        a.hidden.add(p).add(q)
      }
    }
    const flip = (ws: string[]) => {
      for (const w of ws.filter(isVis)) {
        a.flips.push({ pos: sp(w), start: shade(vals[w]), end: shade(nv[w]) })
        a.hidden.add(w)
      }
    }
    if (b.gate === 'h') swap(H_SWAPS[b.qkey])
    else if (b.gate === 'x') flip(X_FLIPS[b.qkey])
    else if (b.gate === 'z') flip(Z_FLIPS[b.qkey])
    else {
      swap(CZ_SWAP_PAIRS)
      flip(['XX'])
    }

    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
      finish(a)
      return
    }
    setAnim(a)
    setT(0)
    const t0 = performance.now()
    const tick = (now: number) => {
      const nt = Math.min((now - t0) / ANIM_MS, 1)
      if (nt >= 1) {
        finish(a)
        return
      }
      setT(nt)
      frameRef.current = requestAnimationFrame(tick)
    }
    frameRef.current = requestAnimationFrame(tick)
  }

  useEffect(() => () => cancelAnimationFrame(frameRef.current), [])

  useEffect(() => {
    if (success) continueRef.current?.focus()
  }, [success])

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === ' ' && !success && (e.target as HTMLElement | null)?.tagName !== 'BUTTON') {
        e.preventDefault()
        advance()
      }
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [advance, success])

  const goalStr = Object.entries(puz.goal)
    .map(([w, v]) => `${w}=${v}`)
    .join('  ')
  const et = smoothstep(t)
  const fy = Math.abs(Math.cos(t * Math.PI))
  const green = 'rgba(77,255,115,0.85)'

  return (
    <div className="relative flex min-h-dvh flex-col bg-bg lg:flex-row">
      <main className="flex flex-1 items-center justify-center px-2 py-4">
        <svg viewBox="0 0 640 640" className="h-auto w-full max-w-[640px]" role="img" aria-label="Puzzle board">
          {ALL.map((w) => (
            <polygon key={`bg-${w}`} points={diamond(sp(w), DR)} fill={C.cellBg} stroke="rgba(140,140,217,0.5)" strokeWidth={1} />
          ))}
          {EDGES.map(([a, b]) => (
            <line key={a + b} x1={sp(a)[0]} y1={sp(a)[1]} x2={sp(b)[0]} y2={sp(b)[1]} stroke={C.edge} strokeWidth={1.2} />
          ))}

          {visible.map((w) => {
            const pos = sp(w)
            const v = vals[w]
            const prob = (1 - v) / 2
            const isGoal = w in puz.goal
            const lc = prob > 0.55 ? '#1a1a1a' : '#f2f2f2'
            return (
              <g key={w}>
                <title>{`${w} = ${v.toFixed(2)}`}</title>
                <polygon
                  points={diamond(pos, DR)}
                  fill={C.cell}
                  stroke={isGoal ? C.win : 'rgba(191,191,255,0.9)'}
                  strokeWidth={isGoal ? 3 : 1.8}
                />
                {!anim?.hidden.has(w) && (
                  <circle cx={pos[0]} cy={pos[1]} r={CR} fill={shade(v)} stroke="rgba(255,255,255,0.7)" strokeWidth={1.5} />
                )}
                <text x={pos[0]} y={pos[1] + 5} fontSize={13} textAnchor="middle" fill={lc}>
                  {w}
                </text>
              </g>
            )
          })}

          {anim?.swaps.map((s, i) => (
            <circle
              key={`sw-${i}`}
              cx={s.from[0] + (s.to[0] - s.from[0]) * et}
              cy={s.from[1] + (s.to[1] - s.from[1]) * et}
              r={CR}
              fill={s.color}
              stroke="rgba(255,255,255,0.7)"
              strokeWidth={1.5}
            />
          ))}
          {anim?.flips.map((f, i) => (
            <ellipse
              key={`fl-${i}`}
              cx={f.pos[0]}
              cy={f.pos[1]}
              rx={CR}
              ry={CR * fy}
              fill={t < 0.5 ? f.start : f.end}
              stroke="rgba(255,255,255,0.7)"
              strokeWidth={1.5}
            />
          ))}
          {anim?.cz &&
            czRoute().map((pts, i) => (
              <polyline key={`czg-${i}`} points={poly(pts)} fill="none" stroke={green} strokeWidth={2.5} />
            ))}

          {Object.keys(puz.goal).length > 0 && <TargetGrid goal={puz.goal} />}

          {BUTTONS.map((b, i) => {
            const en = enabled(i)
            const hov = en && hover === i
            const lc = en ? C.conn : 'rgba(204,204,255,0.16)'
            const routes = b.qkey === 'both' ? czRoute() : gateRoute(b)
            const rem = uses[`${b.qkey}_${b.gate}`] ?? -1
            const tc = en ? C.btnText : '#595980'
            const [cx, cy] = b.center
            const x = cx - BTN_S / 2
            const y = cy - BTN_S / 2
            const label = `${b.gate.toUpperCase()} gate${b.qkey === 'both' ? '' : ` on q[${b.qkey}]`}${rem > 0 ? `, ${rem} uses left` : ''}`
            return (
              <g key={`${b.qkey}_${b.gate}`}>
                {routes.map((pts, j) => (
                  <polyline key={j} points={poly(pts)} fill="none" stroke={lc} strokeWidth={1.5} />
                ))}
                <g
                  role="button"
                  tabIndex={en ? 0 : -1}
                  aria-label={label}
                  aria-disabled={!en}
                  onClick={() => press(i)}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter' || e.key === ' ') {
                      e.preventDefault()
                      e.stopPropagation()
                      press(i)
                    }
                  }}
                  onMouseEnter={() => setHover(i)}
                  onMouseLeave={() => setHover((h) => (h === i ? null : h))}
                  onFocus={() => setHover(i)}
                  onBlur={() => setHover((h) => (h === i ? null : h))}
                  className={`outline-none focus-visible:[&>rect]:stroke-hover ${en ? 'cursor-pointer' : 'cursor-default'}`}
                >
                  <rect
                    x={x}
                    y={y}
                    width={BTN_S}
                    height={BTN_S}
                    fill={hov ? C.btnHover : en ? C.btn : C.btnOff}
                    stroke={en ? 'rgba(255,255,255,0.3)' : 'rgba(0,0,0,0.1)'}
                    strokeWidth={1.5}
                  />
                  <text x={cx} y={cy + 4} fontSize={26} textAnchor="middle" fill={tc}>
                    {b.gate.toUpperCase()}
                  </text>
                  <text x={cx} y={cy + 22} fontSize={13} textAnchor="middle" fill={tc}>
                    GATE
                  </text>
                  {rem > 0 && (
                    <text x={x + 3} y={y + 14} fontSize={11} fill={tc}>
                      {`(${rem})`}
                    </text>
                  )}
                </g>
              </g>
            )
          })}
        </svg>
      </main>

      <aside className="flex w-full flex-col gap-3 bg-panel px-4 py-5 lg:min-h-dvh lg:w-[320px] lg:shrink-0">
        <p className="text-[15px] text-label">{`Puzzle ${idx + 1} / ${PUZZLES.length}`}</p>
        <h1 className="text-2xl text-white">{puz.title}</h1>
        <p className="whitespace-pre-line text-[15px] leading-relaxed text-label">{puz.desc}</p>
        <p className="text-[15px] text-win">{`Goal: ${goalStr || '(explore)'}`}</p>
        <div className="mt-auto flex flex-col gap-3">
          <p className="text-xs text-muted">Press Space to skip to the next puzzle.</p>
          <div className="flex items-center justify-between gap-4">
            <p className="text-[15px] text-label">{`Moves: ${moves}`}</p>
            <Link
              href="/"
              className="flex h-8 w-[84px] items-center justify-center bg-btn text-sm text-btn-text transition-colors hover:bg-white focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-hover"
            >
              Menu
            </Link>
          </div>
        </div>
      </aside>

      {success && (
        <button
          ref={continueRef}
          type="button"
          onClick={advance}
          className="absolute inset-0 flex items-center justify-center focus-visible:outline-none"
          aria-label="Puzzle solved. Continue"
        >
          <span className="flex w-full flex-col items-center gap-3 bg-black/80 py-6" aria-live="assertive">
            <span className="text-4xl text-win lg:text-[44px]">Puzzle solved!</span>
            <span className="text-xl text-label">Click to continue</span>
          </span>
        </button>
      )}
    </div>
  )
}

function TargetGrid({ goal }: { goal: Record<string, number> }) {
  const MBX = 85
  const MBY = 215
  const MS = 20
  const pos = (w: string): Pt => [MBX + BOXES[w][0] * MS, MBY + (3.5 - BOXES[w][1]) * MS]
  return (
    <g aria-label="Target">
      <text x={MBX - 40} y={MBY - 13 - 55} fontSize={14} fill={C.label}>
        Target
      </text>
      {ALL.map((w) => {
        const p = pos(w)
        const has = w in goal
        return (
          <g key={`t-${w}`}>
            <polygon
              points={diamond(p, 13)}
              fill={has ? C.cell : C.cellBg}
              stroke={has ? C.win : 'rgba(140,140,217,0.3)'}
              strokeWidth={has ? 1.2 : 0.6}
            />
            {has && <circle cx={p[0]} cy={p[1]} r={8} fill={shade(goal[w])} stroke="rgba(255,255,255,0.5)" strokeWidth={1} />}
          </g>
        )
      })}
    </g>
  )
}
