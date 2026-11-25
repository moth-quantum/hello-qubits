'use client'

import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import {
  WORDS,
  apply,
  expand,
  isGateAction,
  pushStep,
  pushSteps,
  singlePole,
  startState,
  targetGoal,
  targetStep,
  turn,
  values,
  wordName,
  goalMet,
  TARGET_ITERS,
  type Action,
  type Psi,
  type Word,
} from '@/lib/engine'
import { smoothstep } from '@/lib/palette'
import { GOAL_TOL, flatten, type Tutorial } from '@/lib/tutorial'
import { NavButtons } from '@/components/nav-buttons'
import { TutorialBoard } from './board'
import { DiscView } from './disc-view'

const ANIM_MS = 700

interface Anim {
  action: Action
  t: number
  done: number
  goal: Record<Word, number>
  last: number
}

const signed = (v: number) => `${v >= 0 ? '+' : ''}${v.toFixed(2)}`

export function TutorialGame({ data }: { data: Tutorial }) {
  const list = useMemo(() => flatten(data), [data])
  const [idx, setIdx] = useState(0)
  const { chapter, puzzle } = list[idx]
  const visible = puzzle.visible === 'all' ? WORDS : puzzle.visible

  const [psi, setPsi] = useState<Psi>(() => startState(list[0].puzzle.start))
  const [solved, setSolved] = useState(false)
  const [moves, setMoves] = useState(0)
  const [status, setStatus] = useState('')
  const [discPole, setDiscPole] = useState<Word>(list[0].puzzle.discs_pole ?? '')
  const [busy, setBusy] = useState(false)
  const [hover, setHover] = useState<number | null>(null)

  const psiRef = useRef(psi)
  const animRef = useRef<Anim | null>(null)
  const frameRef = useRef(0)
  const solvedRef = useRef(false)

  const vals = useMemo(() => values(psi), [psi])

  const load = useCallback(
    (i: number) => {
      cancelAnimationFrame(frameRef.current)
      animRef.current = null
      const next = Math.min(Math.max(i, 0), list.length - 1)
      const p = startState(list[next].puzzle.start)
      psiRef.current = p
      solvedRef.current = false
      setIdx(next)
      setPsi(p)
      setSolved(false)
      setMoves(0)
      setStatus('')
      setBusy(false)
      setHover(null)
      setDiscPole(list[next].puzzle.discs_pole ?? '')
    },
    [list],
  )

  /** Apply the part of the running action between anim.done and frac (0..1). Returns the fraction reached. */
  const advance = (anim: Anim, frac: number): number => {
    const a = anim.action
    let p = psiRef.current
    if (a.push !== undefined) {
      const total = pushSteps(a.amount)
      const n = Math.round(frac * total) - Math.round(anim.done * total)
      for (let i = 0; i < n; i++) p = pushStep(p, a.push, a.sign ?? 1, 0.01)
    } else if (a.target !== undefined) {
      const n = Math.round(frac * TARGET_ITERS) - Math.round(anim.done * TARGET_ITERS)
      for (let i = 0; i < n; i++) {
        const res = targetStep(p, anim.goal, a.poles ?? [])
        p = res.psi
        if (res.done) {
          frac = 1
          break
        }
      }
    } else {
      for (const [pole, angle] of expand(a)) p = turn(p, pole, angle * (frac - anim.done))
    }
    anim.done = frac
    psiRef.current = p
    setPsi(p)
    return frac
  }

  const finish = (anim: Anim) => {
    const v = values(psiRef.current)
    setMoves((m) => m + 1)
    if (anim.action.target !== undefined) {
      setStatus(
        Object.entries(anim.goal)
          .map(([w, g]) => `${wordName(w)}: wanted ${signed(g)}, reached ${signed(v[w])}`)
          .join('  '),
      )
    }
    if (!solvedRef.current && goalMet(v, puzzle.goal, GOAL_TOL)) {
      solvedRef.current = true
      setSolved(true)
    }
    animRef.current = null
    setBusy(false)
  }

  const tick = (now: number) => {
    const anim = animRef.current
    if (!anim) return
    anim.t = Math.min(anim.t + (now - anim.last) / ANIM_MS, 1)
    anim.last = now
    const f = anim.action.target !== undefined ? anim.t : smoothstep(anim.t)
    const reached = advance(anim, anim.t >= 1 ? 1 : f)
    if (reached >= 1 || anim.t >= 1) {
      finish(anim)
      return
    }
    frameRef.current = requestAnimationFrame(tick)
  }

  const start = (a: Action) => {
    if (animRef.current) return
    const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches
    const goal = a.target !== undefined ? targetGoal(psiRef.current, a.target) : {}
    const pole = singlePole(a)
    if (pole) setDiscPole(pole)
    setStatus('')
    const anim: Anim = { action: a, t: 0, done: 0, goal, last: performance.now() }
    if (reduceMotion) {
      psiRef.current = apply(psiRef.current, a)
      setPsi(psiRef.current)
      finish(anim)
      return
    }
    animRef.current = anim
    setBusy(true)
    frameRef.current = requestAnimationFrame(tick)
  }

  useEffect(() => () => cancelAnimationFrame(frameRef.current), [])

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.metaKey || e.ctrlKey || e.altKey) return
      const tag = (e.target as HTMLElement | null)?.tagName
      if (tag === 'INPUT' || tag === 'TEXTAREA') return
      const k = e.key.toLowerCase()
      if (k === 'arrowright' || k === 'n') {
        if (idx + 1 < list.length) load(idx + 1)
      } else if (k === 'arrowleft' || k === 'b') load(idx - 1)
      else if (k === 'r') load(idx)
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [idx, list.length, load])

  const hoverAction = hover !== null ? puzzle.buttons[hover] : null
  const hoverIsGate = hoverAction !== null && isGateAction(hoverAction)
  const shownPole = hoverIsGate ? (singlePole(hoverAction) ?? '') : discPole
  const multiPole = hoverIsGate && singlePole(hoverAction) === null

  const goalEntries = Object.entries(puzzle.goal)
  const goalText =
    goalEntries.length === 0
      ? idx === list.length - 1
        ? 'Goal: explore'
        : 'Goal: explore, then press Next'
      : `Goal: ${goalEntries.map(([w, v]) => `${wordName(w)} = ${signed(v)}`).join(',  ')}`
  const sumSquares = WORDS.reduce((s, w) => s + vals[w] * vals[w], 0)

  return (
    <div className="flex min-h-dvh flex-col bg-bg lg:flex-row">
      <main className="flex flex-1 flex-col items-center justify-center gap-4 px-4 py-6">
        <div className="w-full max-w-[560px]">
          <TutorialBoard
            visible={visible}
            vals={vals}
            psi={psi}
            goal={puzzle.goal}
            highlight={puzzle.highlight ?? []}
            hoverAction={hoverAction}
          />
        </div>
        <div role="group" aria-label="Moves" className="flex max-w-[536px] flex-wrap justify-center gap-2">
          {puzzle.buttons.map((b, i) => (
            <button
              key={`${idx}-${i}`}
              type="button"
              onClick={() => start(b)}
              onMouseEnter={() => setHover(i)}
              onMouseLeave={() => setHover((h) => (h === i ? null : h))}
              onFocus={() => setHover(i)}
              onBlur={() => setHover((h) => (h === i ? null : h))}
              aria-disabled={busy}
              className={`flex min-h-11 w-32 items-center justify-center border-[1.5px] border-white/30 px-1.5 py-1 text-center text-[13px] leading-4 text-btn-text transition-colors focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-hover ${
                hover === i ? 'bg-white' : busy ? 'bg-btn-off' : 'bg-btn'
              }`}
            >
              {b.label}
            </button>
          ))}
        </div>
      </main>

      <aside className="flex w-full flex-col gap-4 bg-panel px-4 py-5 lg:min-h-dvh lg:w-[388px] lg:shrink-0">
        <header className="flex flex-col gap-1">
          <h1 className="text-xl font-semibold text-white">{puzzle.title}</h1>
          <p className="text-sm text-muted">
            {chapter.title}
            <span className="ml-3">{`(${idx + 1} / ${list.length})`}</span>
          </p>
        </header>

        <div className="flex flex-col gap-3 text-sm leading-relaxed text-label" aria-live="polite">
          {puzzle.text.split('\n\n').map((para, i) => (
            <p key={i} className="whitespace-pre-line">
              {para}
            </p>
          ))}
          {solved && puzzle.after && (
            <p className="whitespace-pre-line">
              <span className="font-semibold text-win">Solved!</span> {puzzle.after}
            </p>
          )}
        </div>

        <div className="mt-auto flex flex-col gap-4">
          <div className="flex flex-col gap-1">
            <p className="text-sm text-win">{goalText}</p>
            <p className="text-xs text-label">
              {`Moves: ${moves}`}
              <span className="ml-4">{`Sum of squares of all 15 values: ${sumSquares.toFixed(2)}`}</span>
            </p>
            {status && <p className="text-xs text-hover">{status}</p>}
          </div>

          <DiscView pole={shownPole} multiPole={multiPole} visible={visible} vals={vals} />

          <NavButtons
            onBack={() => load(idx - 1)}
            onReset={() => load(idx)}
            onNext={() => idx + 1 < list.length && load(idx + 1)}
            solved={solved}
          />
        </div>
      </aside>
    </div>
  )
}
