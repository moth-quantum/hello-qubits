import { LETTERS, WORDS, covariance, movedBy, wordName, type Action, type Psi, type Word } from '@/lib/engine'
import { C, shade } from '@/lib/palette'

const U = 58
const BX = 286
const BY0 = 404
const DR = 46
const CR = 25

function grid(w: Word): [number, number] {
  const a = LETTERS.indexOf(w[0] as (typeof LETTERS)[number])
  const b = LETTERS.indexOf(w[1] as (typeof LETTERS)[number])
  return [b - a, a + b]
}

function sp(w: Word): [number, number] {
  const [gx, gy] = grid(w)
  return [BX + gx * U, BY0 - (gy - 1) * U]
}

const diamond = (x: number, y: number, r: number) => `${x},${y - r} ${x + r},${y} ${x},${y + r} ${x - r},${y}`

export const formatValue = (v: number) => (Math.abs(v) > 0.005 ? `${v >= 0 ? '+' : ''}${v.toFixed(2)}` : '0')

interface BoardProps {
  visible: Word[]
  vals: Record<Word, number>
  psi: Psi
  goal: Record<Word, number>
  highlight: Word[]
  hoverAction: Action | null
}

export function TutorialBoard({ visible, vals, psi, goal, highlight, hoverAction }: BoardProps) {
  const moved = movedBy(hoverAction)
  const isVisible = (w: Word) => visible.includes(w)

  const edges: [Word, Word][] = []
  for (const w of WORDS) {
    for (const v of WORDS) {
      const [wx, wy] = grid(w)
      const [vx, vy] = grid(v)
      if (Math.abs(vx - wx) === 1 && vy - wy === 1 && isVisible(w) && isVisible(v)) edges.push([w, v])
    }
  }

  const [z1x, z1y] = sp('ZI')
  const [z2x, z2y] = sp('IZ')
  const pushWord = hoverAction?.push

  return (
    <svg
      viewBox="50 56 472 404"
      className="h-auto w-full"
      role="img"
      aria-label="Board of the 15 values of two qubits"
    >
      {edges.map(([w, v]) => {
        const [x1, y1] = sp(w)
        const [x2, y2] = sp(v)
        return <line key={w + v} x1={x1} y1={y1} x2={x2} y2={y2} stroke={C.edge} strokeWidth={1} />
      })}

      <text x={z1x - 122} y={z1y + 6} fontSize={14} fill={C.label}>
        qubit 1
      </text>
      <text x={z2x + 56} y={z2y + 6} fontSize={14} fill={C.label}>
        qubit 2
      </text>

      {WORDS.map((w) => {
        const [x, y] = sp(w)
        if (!isVisible(w)) {
          return <polygon key={w} points={diamond(x, y, DR)} fill={C.cellBg} stroke={C.cellBgLine} strokeWidth={1} />
        }
        let line = C.cellLine
        let lw = 1.6
        if (highlight.includes(w)) [line, lw] = [C.twin, 3]
        if (w in goal) [line, lw] = [C.win, 3]
        if (moved.includes(w)) [line, lw] = [C.hover, 3.5]
        const v = vals[w]
        const tc = v < -0.1 ? '#14141f' : '#f2f2fa'
        return (
          <g key={w}>
            <title>{`${wordName(w)} = ${formatValue(v)}`}</title>
            <polygon points={diamond(x, y, DR)} fill={C.cell} stroke={line} strokeWidth={lw} strokeLinejoin="round" />
            {w in goal && line !== C.win && (
              <polygon points={diamond(x, y, DR - 6)} fill="none" stroke={C.win} strokeWidth={2} />
            )}
            <circle cx={x} cy={y} r={CR} fill={shade(v)} stroke="rgba(255,255,255,0.7)" strokeWidth={1.4} />
            <text x={x} y={y - 3} fontSize={12} textAnchor="middle" fill={tc}>
              {wordName(w)}
            </text>
            <text x={x} y={y + 12} fontSize={11} textAnchor="middle" fill={tc}>
              {formatValue(v)}
            </text>
          </g>
        )
      })}

      {pushWord &&
        visible.map((w) => {
          const cv = covariance(psi, pushWord, w)
          if (Math.abs(cv) <= 0.005) return null
          const [x, y] = sp(w)
          const s = `follows x${cv.toFixed(2)}`
          const sw = s.length * 6.1
          return (
            <g key={`cov-${w}`}>
              <rect x={x - sw / 2 - 3} y={y + CR + 3} width={sw + 6} height={14} fill={C.covBacking} />
              <text x={x} y={y + CR + 14} fontSize={11} textAnchor="middle" fill={C.hover}>
                {s}
              </text>
            </g>
          )
        })}
    </svg>
  )
}
