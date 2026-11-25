import Link from 'next/link'

const base =
  'flex h-8 w-full items-center justify-center text-sm text-btn-text transition-colors focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-hover'

interface NavButtonsProps {
  onBack: () => void
  onReset: () => void
  onNext: () => void
  solved: boolean
}

export function NavButtons({ onBack, onReset, onNext, solved }: NavButtonsProps) {
  return (
    <nav aria-label="Puzzle navigation" className="grid grid-cols-4 gap-2">
      <Link href="/" className={`${base} bg-btn hover:bg-white`}>
        Menu
      </Link>
      <button type="button" onClick={onBack} className={`${base} bg-btn hover:bg-white`} aria-keyshortcuts="ArrowLeft B">
        Back
      </button>
      <button type="button" onClick={onReset} className={`${base} bg-btn hover:bg-white`} aria-keyshortcuts="R">
        Reset
      </button>
      <button
        type="button"
        onClick={onNext}
        className={`${base} ${solved ? 'bg-win' : 'bg-btn hover:bg-white'}`}
        aria-keyshortcuts="ArrowRight N"
      >
        Next
      </button>
    </nav>
  )
}
