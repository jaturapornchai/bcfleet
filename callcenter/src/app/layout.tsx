import type { Metadata } from 'next'
import './globals.css'
import Sidebar from '@/components/layout/Sidebar'
import Header from '@/components/layout/Header'

export const metadata: Metadata = {
  title: 'SML Fleet — Call Center',
  description: 'ระบบ Call Center สำหรับ SML Fleet',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="th">
      <body className="bg-slate-50">
        <Sidebar />
        <div className="ml-56 min-h-screen">
          <Header />
          <main className="p-6">{children}</main>
        </div>
      </body>
    </html>
  )
}
