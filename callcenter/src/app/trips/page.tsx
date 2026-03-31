'use client'
import { useState } from 'react'
import useSWR from 'swr'
import { api } from '@/lib/api'
import { TRIP_STATUS, formatMoney, formatDate } from '@/lib/constants'

export default function TripsPage() {
  const [page, setPage] = useState(1)
  const [status, setStatus] = useState('')
  const { data } = useSWR(['trips', page, status], () => api.getTrips(page, 20, status), { refreshInterval: 15000 })

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-xl font-bold">📋 เที่ยววิ่ง</h2>
        <a href="/trips/new" className="bg-blue-600 text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-blue-700">+ สร้างเที่ยว</a>
      </div>
      <div className="flex gap-2 mb-4">
        {['', 'pending', 'started', 'delivering', 'completed'].map(s => (
          <button key={s} onClick={() => { setStatus(s); setPage(1) }}
            className={`px-3 py-1.5 rounded-lg text-sm ${status === s ? 'bg-blue-600 text-white' : 'bg-white border text-slate-600 hover:bg-slate-50'}`}>
            {s ? TRIP_STATUS[s]?.label : 'ทั้งหมด'}
          </button>
        ))}
      </div>
      <div className="bg-white rounded-xl shadow-sm border overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-slate-50 border-b">
            <tr>
              <th className="px-4 py-3 text-left text-slate-500">เลขที่</th>
              <th className="px-4 py-3 text-left text-slate-500">สถานะ</th>
              <th className="px-4 py-3 text-left text-slate-500">ต้นทาง</th>
              <th className="px-4 py-3 text-left text-slate-500">สินค้า</th>
              <th className="px-4 py-3 text-left text-slate-500">ระยะทาง</th>
              <th className="px-4 py-3 text-left text-slate-500">รายได้</th>
              <th className="px-4 py-3 text-left text-slate-500">ต้นทุน</th>
              <th className="px-4 py-3 text-left text-slate-500">กำไร</th>
              <th className="px-4 py-3 text-left text-slate-500">วันที่</th>
            </tr>
          </thead>
          <tbody>
            {data?.data?.map((t: any) => {
              const st = TRIP_STATUS[t.status] || { label: t.status, color: 'bg-gray-100' }
              return (
                <tr key={t.id} className="border-b hover:bg-blue-50/50 cursor-pointer" onClick={() => window.location.href = `/trips/${t.id}`}>
                  <td className="px-4 py-3 font-mono text-xs">{t.trip_no || t.id.slice(-8)}</td>
                  <td className="px-4 py-3"><span className={`px-2 py-0.5 rounded text-xs ${st.color}`}>{st.label}</span></td>
                  <td className="px-4 py-3 truncate max-w-[150px]">{t.origin_name || '-'}</td>
                  <td className="px-4 py-3 truncate max-w-[150px]">{t.cargo_description || '-'}</td>
                  <td className="px-4 py-3">{t.distance_km ? `${t.distance_km} km` : '-'}</td>
                  <td className="px-4 py-3 text-green-600">฿{formatMoney(t.revenue)}</td>
                  <td className="px-4 py-3 text-red-500">฿{formatMoney(t.total_cost)}</td>
                  <td className="px-4 py-3 font-medium" style={{ color: (t.profit ?? 0) >= 0 ? '#059669' : '#DC2626' }}>฿{formatMoney(t.profit)}</td>
                  <td className="px-4 py-3 text-slate-500">{formatDate(t.planned_start)}</td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>
    </div>
  )
}
