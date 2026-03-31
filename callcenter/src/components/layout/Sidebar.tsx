'use client'
import Link from 'next/link'
import { usePathname } from 'next/navigation'

const nav = [
  { href: '/', icon: '📊', label: 'Dashboard' },
  { href: '/customers', icon: '👥', label: 'ลูกค้า' },
  { href: '/trips', icon: '📋', label: 'เที่ยววิ่ง' },
  { href: '/vehicles', icon: '🚛', label: 'รถ' },
  { href: '/drivers', icon: '👤', label: 'คนขับ' },
  { href: '/maintenance', icon: '🔧', label: 'ซ่อมบำรุง' },
  { href: '/partners', icon: '🤝', label: 'รถร่วม' },
  { href: '/expenses', icon: '💰', label: 'ค่าใช้จ่าย' },
  { href: '/alerts', icon: '⚠️', label: 'แจ้งเตือน' },
  { href: '/gps', icon: '📍', label: 'GPS & Movement' },
]

export default function Sidebar() {
  const pathname = usePathname()

  return (
    <aside className="w-56 bg-slate-900 text-white min-h-screen flex flex-col fixed left-0 top-0 z-30">
      <div className="p-4 border-b border-slate-700">
        <h1 className="text-lg font-bold bg-gradient-to-r from-blue-400 to-purple-400 bg-clip-text text-transparent">
          SML Fleet
        </h1>
        <p className="text-xs text-slate-400 mt-1">Call Center Console</p>
      </div>
      <nav className="flex-1 py-2">
        {nav.map((item) => {
          const active = pathname === item.href || (item.href !== '/' && pathname.startsWith(item.href))
          return (
            <Link
              key={item.href}
              href={item.href}
              className={`flex items-center gap-3 px-4 py-2.5 text-sm transition-colors ${
                active
                  ? 'bg-blue-600/20 text-blue-300 border-r-2 border-blue-400'
                  : 'text-slate-300 hover:bg-slate-800 hover:text-white'
              }`}
            >
              <span className="text-base">{item.icon}</span>
              {item.label}
            </Link>
          )
        })}
      </nav>
      <div className="p-4 border-t border-slate-700 text-xs text-slate-500">
        SML Fleet v1.2<br />Call Center
      </div>
    </aside>
  )
}
