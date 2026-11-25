// The original Godot palette, for SVG drawing.
export const C = {
  bg: '#4d4d9e',
  cell: 'rgba(102,102,191,0.8)',
  cellBg: 'rgba(71,71,148,0.5)',
  cellBgLine: 'rgba(140,140,217,0.35)',
  cellLine: 'rgba(191,191,255,0.9)',
  edge: 'rgba(179,179,255,0.3)',
  label: '#d9e0ff',
  win: '#59ff8c',
  hover: '#ffd94d',
  twin: '#ff8cd9',
  btn: '#f2f2ff',
  btnHover: '#ffffff',
  btnOff: '#8c8cb8',
  btnText: '#262659',
  conn: 'rgba(204,204,255,0.45)',
  covBacking: 'rgba(26,26,64,0.9)',
}

/** Black for +1, grey for 0, white for -1. */
export function shade(v: number): string {
  const p = Math.round(((1 - v) / 2) * 255)
  return `rgb(${p},${p},${p})`
}

export const smoothstep = (t: number) => t * t * (3 - 2 * t)
