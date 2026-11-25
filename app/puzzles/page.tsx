import type { Metadata } from 'next'
import { PuzzleGame } from '@/components/puzzles/puzzle-game'

export const metadata: Metadata = {
  title: 'Puzzles | Hello Qubits',
  description: 'The original 18 Hello Qubits puzzles: flip, rotate and entangle two qubits to reach each target.',
}

export default function PuzzlesPage() {
  return <PuzzleGame />
}
