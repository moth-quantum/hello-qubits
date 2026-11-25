import Link from 'next/link'

const OPTIONS = [
  { href: '/puzzles', label: 'Puzzles' },
  { href: '/tutorial', label: 'Interdependency tutorial' },
]

export default function TitlePage() {
  return (
    <main className="flex min-h-dvh flex-col items-center justify-center gap-6 px-6 text-center">
      <h1 className="text-5xl font-medium text-white text-balance">Hello Qubits</h1>
      <p className="text-xl text-label text-pretty">A two-qubit quantum computing puzzle game</p>
      <nav aria-label="Choose a game" className="mt-8 flex w-full max-w-[300px] flex-col gap-3.5">
        {OPTIONS.map((o) => (
          <Link
            key={o.href}
            href={o.href}
            className="flex h-[46px] items-center justify-center bg-btn text-xl text-btn-text transition-colors hover:bg-white focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-hover"
          >
            {o.label}
          </Link>
        ))}
      </nav>
    </main>
  )
}
