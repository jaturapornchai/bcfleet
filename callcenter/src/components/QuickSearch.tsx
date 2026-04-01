'use client'
import { useState, useEffect, useRef, useCallback } from 'react'
import { useRouter } from 'next/navigation'
import { api } from '@/lib/api'

interface SearchResult {
  type: 'customer' | 'trip' | 'vehicle' | 'action'
  id?: string
  title: string
  subtitle?: string
  icon: string
  href?: string
  action?: () => void
}

export default function QuickSearch() {
  const [open, setOpen] = useState(false)
  const [query, setQuery] = useState('')
  const [results, setResults] = useState<SearchResult[]>([])
  const [loading, setLoading] = useState(false)
  const [selected, setSelected] = useState(0)
  const router = useRouter()
  const inputRef = useRef<HTMLInputElement>(null)
  const debounceRef = useRef<any>(null)

  // Global keyboard shortcut
  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
        e.preventDefault()
        setOpen(o => !o)
      }
      if (e.key === 'Escape') setOpen(false)
    }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [])

  useEffect(() => {
    if (open) {
      setQuery('')
      setResults(getDefaultResults())
      setSelected(0)
      setTimeout(() => inputRef.current?.focus(), 50)
    }
  }, [open])

  function getDefaultResults(): SearchResult[] {
    return [
      { type: 'action', icon: '👤', title: 'เพิ่มลูกค้าใหม่', href: '/customers/new' },
      { type: 'action', icon: '🚚', title: 'สร้างเที่ยววิ่งใหม่', href: '/trips/new' },
      { type: 'action', icon: '📊', title: 'Dashboard', href: '/' },
      { type: 'action', icon: '🗺️', title: 'แผนที่รถ', href: '/map' },
      { type: 'action', icon: '⚠️', title: 'แจ้งเตือน', href: '/alerts' },
      { type: 'action', icon: '📈', title: 'รายงาน', href: '/reports' },
    ]
  }

  const search = useCallback(async (q: string) => {
    if (!q.trim()) { setResults(getDefaultResults()); return }
    setLoading(true)
    try {
      const [customers, trips] = await Promise.allSettled([
        api.searchCustomers(q),
        api.getTrips(1, 5, ''),
      ])

      const items: SearchResult[] = []

      if (customers.status === 'fulfilled') {
        const cList = customers.value?.data ?? []
        cList.slice(0, 4).forEach((c: any) => {
          items.push({
            type: 'customer', id: c.id, icon: '👥',
            title: c.name,
            subtitle: `${c.customer_no} · ${c.phone ?? '—'} · ${c.company ?? ''}`,
            href: `/customers/${c.id}`,
          })
        })
      }

      if (trips.status === 'fulfilled') {
        const tList = trips.value?.data ?? []
        tList.filter((t: any) => t.trip_no?.includes(q) || t.cargo_description?.toLowerCase().includes(q.toLowerCase()))
          .slice(0, 3).forEach((t: any) => {
            items.push({
              type: 'trip', id: t.id, icon: '📋',
              title: t.trip_no ?? t.id?.slice(-8),
              subtitle: t.cargo_description ?? t.origin_name ?? '',
              href: `/trips/${t.id}`,
            })
          })
      }

      if (items.length === 0) {
        items.push({ type: 'action', icon: '🔍', title: `ไม่พบ "${q}"`, subtitle: 'ลองค้นหาด้วยคำอื่น' })
      }

      // Quick action for creating trip for searched customer
      if (customers.status === 'fulfilled' && (customers.value?.data ?? []).length > 0) {
        const c = customers.value.data[0]
        items.push({
          type: 'action', icon: '⚡', title: `สร้างเที่ยวให้ ${c.name}`,
          subtitle: 'Quick Action',
          href: `/trips/new`,
        })
      }

      setResults(items)
      setSelected(0)
    } catch { setResults(getDefaultResults()) }
    finally { setLoading(false) }
  }, [])

  useEffect(() => {
    clearTimeout(debounceRef.current)
    debounceRef.current = setTimeout(() => search(query), 300)
  }, [query, search])

  const go = (item: SearchResult) => {
    setOpen(false)
    if (item.action) { item.action(); return }
    if (item.href) router.push(item.href)
  }

  const onKey = (e: React.KeyboardEvent) => {
    if (e.key === 'ArrowDown') { e.preventDefault(); setSelected(s => Math.min(s + 1, results.length - 1)) }
    if (e.key === 'ArrowUp') { e.preventDefault(); setSelected(s => Math.max(s - 1, 0)) }
    if (e.key === 'Enter' && results[selected]) go(results[selected])
  }

  if (!open) return null

  return (
    <div className="fixed inset-0 z-[9999] flex items-start justify-center pt-20 px-4" onClick={() => setOpen(false)}>
      {/* Backdrop */}
      <div className="absolute inset-0 bg-black/50 backdrop-blur-sm" />

      {/* Modal */}
      <div className="relative w-full max-w-xl bg-white rounded-2xl shadow-2xl overflow-hidden" onClick={e => e.stopPropagation()}>
        {/* Input */}
        <div className="flex items-center gap-3 px-4 py-3 border-b">
          <span className="text-xl">{loading ? '⏳' : '🔍'}</span>
          <input
            ref={inputRef}
            value={query}
            onChange={e => setQuery(e.target.value)}
            onKeyDown={onKey}
            placeholder="ค้นหาลูกค้า, เที่ยว, หรือพิมพ์คำสั่ง..."
            className="flex-1 text-base focus:outline-none placeholder:text-slate-400"
          />
          <kbd className="hidden sm:flex items-center gap-1 px-1.5 py-0.5 text-xs text-slate-400 border rounded">Esc</kbd>
        </div>

        {/* Results */}
        <div className="max-h-80 overflow-y-auto py-1">
          {results.map((r, i) => (
            <div
              key={`${r.type}-${r.id ?? i}`}
              onClick={() => go(r)}
              onMouseEnter={() => setSelected(i)}
              className={`flex items-center gap-3 px-4 py-2.5 cursor-pointer transition-colors ${i === selected ? 'bg-blue-50' : 'hover:bg-slate-50'}`}
            >
              <span className="text-xl w-7 text-center shrink-0">{r.icon}</span>
              <div className="flex-1 min-w-0">
                <div className="text-sm font-medium truncate">{r.title}</div>
                {r.subtitle && <div className="text-xs text-slate-500 truncate">{r.subtitle}</div>}
              </div>
              {r.type !== 'action' && (
                <span className="text-xs text-slate-300 shrink-0 capitalize">{r.type}</span>
              )}
              {i === selected && <span className="text-xs text-slate-300 shrink-0">↵</span>}
            </div>
          ))}
        </div>

        {/* Footer */}
        <div className="px-4 py-2 border-t bg-slate-50 flex items-center gap-4 text-xs text-slate-400">
          <span>↑↓ เลือก</span>
          <span>↵ เปิด</span>
          <span>Esc ปิด</span>
          <span className="ml-auto">Ctrl+K เปิด/ปิด</span>
        </div>
      </div>
    </div>
  )
}
