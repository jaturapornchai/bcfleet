'use client'
import useSWR from 'swr'
import { api } from '@/lib/api'
import { formatMoney, formatDate } from '@/lib/constants'

export default function ExpensesPage() {
  const { data } = useSWR('expenses', () => api.getExpenses(1, 50))
  return (
    <div>
      <h2 className="text-xl font-bold mb-6">💰 ค่าใช้จ่าย ({data?.total ?? 0})</h2>
      <div className="bg-white rounded-xl shadow-sm border overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-slate-50 border-b">
            <tr>
              <th className="px-4 py-3 text-left text-slate-500">ประเภท</th>
              <th className="px-4 py-3 text-left text-slate-500">รายละเอียด</th>
              <th className="px-4 py-3 text-left text-slate-500">จำนวนเงิน</th>
              <th className="px-4 py-3 text-left text-slate-500">ลิตร</th>
              <th className="px-4 py-3 text-left text-slate-500">ไมล์</th>
              <th className="px-4 py-3 text-left text-slate-500">วันที่</th>
            </tr>
          </thead>
          <tbody>
            {data?.data?.map((e: any) => (
              <tr key={e.id} className="border-b hover:bg-blue-50/50">
                <td className="px-4 py-3"><span className={`px-2 py-0.5 rounded text-xs ${e.type === 'fuel' ? 'bg-blue-100 text-blue-700' : e.type === 'toll' ? 'bg-yellow-100 text-yellow-700' : 'bg-gray-100 text-gray-700'}`}>{e.type}</span></td>
                <td className="px-4 py-3">{e.description}</td>
                <td className="px-4 py-3 font-medium">฿{formatMoney(e.amount)}</td>
                <td className="px-4 py-3">{e.fuel_liters ? `${e.fuel_liters} L` : '-'}</td>
                <td className="px-4 py-3">{e.odometer_km ? `${e.odometer_km.toLocaleString()} km` : '-'}</td>
                <td className="px-4 py-3 text-slate-500">{formatDate(e.recorded_at)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
