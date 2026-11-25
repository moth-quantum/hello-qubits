import { discs, wordName, type Word } from '@/lib/engine'
import { C } from '@/lib/palette'

interface DiscViewProps {
  pole: Word
  multiPole: boolean
  visible: Word[]
  vals: Record<Word, number>
}

const W = 360
const R = 34
const CY = 52

export function DiscView({ pole, multiPole, visible, vals }: DiscViewProps) {
  if (multiPole) {
    return <p className="text-[13px] text-label">This button turns about more than one pole at once.</p>
  }
  if (!pole) return null

  const ds = discs(pole).filter(([a, b]) => visible.includes(a) || visible.includes(b))
  const pv = vals[pole]
  const pn = wordName(pole)
  const inner = Math.sqrt(Math.max(0, 1 - pv * pv))
  const span = W / Math.max(ds.length, 1)

  return (
    <figure className="flex flex-col gap-1">
      <figcaption className="text-[13px] text-hover">
        {`Discs turned about pole ${pn}  (${pn} = ${pv >= 0 ? '+' : ''}${pv.toFixed(2)})`}
      </figcaption>
      <svg viewBox={`0 0 ${W} 108`} className="h-auto w-full" aria-hidden="true">
        {ds.map(([a, b], i) => {
          const cx = span * (i + 0.5)
          // vertical axis: first value (up = +1); horizontal: second value (right = +1)
          const px = cx + vals[b] * R
          const py = CY - vals[a] * R
          return (
            <g key={a + b}>
              <circle cx={cx} cy={CY} r={R} fill={C.bg} stroke="rgba(255,255,255,0.8)" strokeWidth={1.5} />
              {inner < 0.995 && (
                <circle
                  cx={cx}
                  cy={CY}
                  r={R * inner}
                  fill="none"
                  stroke="rgba(255,255,255,0.45)"
                  strokeWidth={1}
                  strokeDasharray="3 3"
                />
              )}
              <line x1={cx - R} y1={CY} x2={cx + R} y2={CY} stroke="rgba(255,255,255,0.25)" />
              <line x1={cx} y1={CY - R} x2={cx} y2={CY + R} stroke="rgba(255,255,255,0.25)" />
              <line x1={cx} y1={CY} x2={px} y2={py} stroke={C.hover} strokeWidth={2} />
              <circle cx={px} cy={py} r={5} fill={C.hover} />
              <text x={cx} y={CY - R - 4} fontSize={11} textAnchor="middle" fill={C.label}>
                {wordName(a)}
              </text>
              <text x={cx} y={CY + R + 14} fontSize={11} textAnchor="middle" fill={C.label}>
                {`${wordName(b)} >`}
              </text>
            </g>
          )
        })}
      </svg>
    </figure>
  )
}
