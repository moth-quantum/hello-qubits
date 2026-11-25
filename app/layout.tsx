import type { Metadata, Viewport } from 'next'
import { Noto_Sans } from 'next/font/google'
import './globals.css'

const noto = Noto_Sans({ subsets: ['latin'], variable: '--font-noto' })

export const metadata: Metadata = {
  title: 'Hello Qubits',
  description:
    'A two-qubit quantum computing puzzle game, with an interdependency tutorial on how the 15 values of two qubits depend on each other.',
}

export const viewport: Viewport = {
  themeColor: '#4d4d9e',
}

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en" className={noto.variable}>
      <body className="font-sans antialiased">{children}</body>
    </html>
  )
}
