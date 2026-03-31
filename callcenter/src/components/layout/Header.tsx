'use client'
import { useState } from 'react'
import { useRouter } from 'next/navigation'

export default function Header() {
  const [search, setSearch] = useState('')
  const router = useRouter()

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault()
    if (search.trim()) {
      router.push(`/customers?q=${encodeURIComponent(search.trim())}`)
    }
  }

  return (
    <header className="h-14 bg-white border-b flex items-center justify-between px-6 sticky top-0 z-20">
      <form onSubmit={handleSearch} className="flex items-center gap-2">
        <span className="text-slate-400">🔍</span>
        <input
          type="text"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="ค้นหาลูกค้า: ชื่อ / เบอร์โทร / LINE ID"
          className="w-80 border border-slate-200 rounded-lg px-3 py-1.5 text-sm focus:outline-none focus:border-blue-400"
        />
      </form>
      <div className="flex items-center gap-4 text-sm text-slate-500">
        <span>👤 Call Center Agent</span>
      </div>
    </header>
  )
}
