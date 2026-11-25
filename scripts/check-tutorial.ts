// Replays every tutorial puzzle's solution with the web engine and prints the end values, in the
// same format as `python3 tools/build_tutorial.py --check`, so the two can be compared line by line.
//
//   node scripts/check-tutorial.ts

import { readFileSync } from 'node:fs'
import { WORDS, apply, goalMet, startState, values, wordName, type Psi } from '../lib/engine.ts'
import { GOAL_TOL, type Tutorial } from '../lib/tutorial.ts'

const data: Tutorial = JSON.parse(readFileSync(new URL('../tutorial/tutorial.json', import.meta.url), 'utf8'))

function fmtValues(psi: Psi): string {
  const v = values(psi)
  const items = WORDS.filter((w) => Math.abs(v[w]) > 5e-4).map(
    (w) => `${wordName(w)} = ${v[w] >= 0 ? '+' : ''}${v[w].toFixed(3)}`,
  )
  return items.length ? items.join(', ') : 'all 0'
}

let ok = true
for (const ch of data.chapters) {
  for (const p of ch.puzzles) {
    const tag = `${ch.title} / ${p.title}`
    const start = startState(p.start)
    if (goalMet(values(start), p.goal, GOAL_TOL)) {
      console.log('GOAL MET AT START:', tag)
      ok = false
    }
    const end = p.solution.reduce((psi, i) => apply(psi, p.buttons[i]), start)
    if (Object.keys(p.goal).length && !goalMet(values(end), p.goal, GOAL_TOL)) {
      console.log('SOLUTION FAILS:', tag, fmtValues(end))
      ok = false
    }
    console.log(`== ${tag}\n after solution: ${fmtValues(end)}`)
  }
}
console.log(ok ? 'all puzzles OK' : 'PROBLEMS FOUND')
process.exitCode = ok ? 0 : 1
