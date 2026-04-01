'use client'
import { useState, Suspense } from 'react'
import useSWR from 'swr'
import Link from 'next/link'
import { api } from '@/lib/api'
import { useSearchParams, useRouter } from 'next/navigation'

function CustomersContent() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const initialQ = searchParams.get('q') || ''
  const [search, setSearch] = useState(initialQ)
  const [page, setPage] = useState(1)

  const { data: list } = useSWR(
    search ? null : ['customers', page],
    () => api.getCustomers(page)
  )
  const { data: searchResult } = useSWR(
    search ? ['search', search] : null,
    () => api.searchCustomers(search)
  )

  const customers = search ? searchResult?.data : list?.data
  const total = search ? searchResult?.count : list?.total

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-xl font-bold">👥 ฐานข้อมูลลูกค้า</h2>
        <Link href="/customers/new" className="bg-blue-600 text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-blue-700">
          + เพิ่มลูกค้าใหม่
        </Link>
      </div>

      <div className="mb-4">
        <input
          type="text"
          value={search}
          onChange={(e) => { setSearch(e.target.value); setPage(1) }}
          placeholder="🔍 ค้นหา: ชื่อ / เบอร์โทร / LINE ID / รหัสลูกค้า"
          className="w-full max-w-lg border border-slate-200 rounded-lg px-4 py-2 text-sm focus:outline-none focus:border-blue-400"
        />
      </div>

      <div className="bg-white rounded-xl shadow-sm border overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-slate-50 border-b">
            <tr>
              <th className="px-4 py-3 text-left text-slate-500 font-medium">รหัส</th>
              <th className="px-4 py-3 text-left text-slate-500 font-medium">ชื่อ</th>
              <th className="px-4 py-3 text-left text-slate-500 font-medium">เบอร์โทร</th>
              <th className="px-4 py-3 text-left text-slate-500 font-medium">บริษัท</th>
              <th className="px-4 py-3 text-left text-slate-500 font-medium">LINE</th>
              <th className="px-4 py-3 text-left text-slate-500 font-medium">เที่ยววิ่ง</th>
              <th className="px-4 py-3 text-left text-slate-500 font-medium">รายได้รวม</th>
              <th className="px-4 py-3 text-left text-slate-500 font-medium">สถานะ</th>
            </tr>
          </thead>
          <tbody>
            {customers?.map((c: any) => (
              <tr key={c.id} className="border-b hover:bg-blue-50/50 cursor-pointer" onClick={() => router.push(`/customers/${c.id}`)}>
                <td className="px-4 py-3 font-mono text-xs text-slate-500">{c.customer_no}</td>
                <td className="px-4 py-3 font-medium">{c.name}</td>
                <td className="px-4 py-3">{c.phone || '-'}</td>
                <td className="px-4 py-3 text-slate-500">{c.company || '-'}</td>
                <td className="px-4 py-3">{c.line_user_id ? '✅' : '-'}</td>
                <td className="px-4 py-3">{c.total_trips ?? 0}</td>
                <td className="px-4 py-3">{c.total_revenue ? `฿${c.total_revenue.toLocaleString()}` : '-'}</td>
                <td className="px-4 py-3">
                  <span className={`px-2 py-0.5 rounded text-xs ${c.status === 'active' ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>
                    {c.status === 'active' ? 'Active' : 'Inactive'}
                  </span>
                </td>
              </tr>
            ))}
            {!customers?.length && (
              <tr><td colSpan={8} className="px-4 py-8 text-center text-slate-400">
                {search ? 'ไม่พบลูกค้า' : 'ยังไม่มีข้อมูลลูกค้า'}
              </td></tr>
            )}
          </tbody>
        </table>
      </div>

      {!search && total > 20 && (
        <div className="flex justify-center gap-2 mt-4">
          <button disabled={page <= 1} onClick={() => setPage(p => p - 1)} className="px-3 py-1 border rounded text-sm disabled:opacity-30">ก่อนหน้า</button>
          <span className="px-3 py-1 text-sm text-slate-500">หน้า {page} / {Math.ceil(total / 20)}</span>
          <button disabled={page >= Math.ceil(total / 20)} onClick={() => setPage(p => p + 1)} className="px-3 py-1 border rounded text-sm disabled:opacity-30">ถัดไป</button>
        </div>
      )}
    </div>
  )
}

export default function CustomersPage() {
  return (
    <Suspense fallback={<div className="p-8 text-slate-400">กำลังโหลด...</div>}>
      <CustomersContent />
    </Suspense>
  )
}
