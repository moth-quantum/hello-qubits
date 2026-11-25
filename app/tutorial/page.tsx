import type { Metadata } from 'next'
import data from '@/tutorial/tutorial.json'
import { TutorialGame } from '@/components/tutorial/tutorial-game'
import type { Tutorial } from '@/lib/tutorial'

export const metadata: Metadata = {
  title: 'Interdependency tutorial | Hello Qubits',
  description: (data as Tutorial).intro,
}

export default function TutorialPage() {
  return <TutorialGame data={data as Tutorial} />
}
