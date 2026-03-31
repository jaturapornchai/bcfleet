'use client'
import useSWR from 'swr'
import { api } from '@/lib/api'
import { WO_STATUS, formatMoney } from '@/lib/constants'

export default function MaintenancePage() {
  const { data } = useSWR('work-orders', () => api.getWorkOrders(1, 50))
  return (
    <div>
      <h2 className="text-xl font-bold mb-6">🔧 ใบสั่งซ่อม ({data?.total ?? 0})</h2>
      <div className="bg-white rounded-xl shadow-sm border overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-slate-50 border-b">
            <tr>
              <th className="px-4 py-3 text-left text-slate-500">เลขที่</th>
              <th className="px-4 py-3 text-left text-slate-500">สถานะ</th>
              <th className="px-4 py-3 text-left text-slate-500">ประเภท</th>
              <th className="px-4 py-3 text-left text-slate-500">ลำดับ</th>
              <th className="px-4 py-3 text-left text-slate-500">รายละเอียด</th>
              <th className="px-4 py-3 text-left text-slate-500">ค่าอะไหล่</th>
              <th className="px-4 py-3 text-left text-slate-500">ค่าแรง</th>
              <th className="px-4 py-3 text-left text-slate-500">รวม</th>
            </tr>
          </thead>
          <tbody>
            {data?.data?.map((w: any) => {
              const st = WO_STATUS[w.status] || { label: w.status, color: 'bg-gray-100' }
              return (
                <tr key={w.id} className="border-b hover:bg-blue-50/50">
                  <td className="px-4 py-3 font-mono text-xs">{w.wo_no}</td>
                  <td className="px-4 py-3"><span className={`px-2 py-0.5 rounded text-xs ${st.color}`}>{st.label}</span></td>
                  <td className="px-4 py-3">{w.type}</td>
                  <td className="px-4 py-3">{w.priority}</td>
                  <td className="px-4 py-3 truncate max-w-[200px]">{w.description}</td>
                  <td className="px-4 py-3">฿{formatMoney(w.parts_cost)}</td>
                  <td className="px-4 py-3">฿{formatMoney(w.labor_cost)}</td>
                  <td className="px-4 py-3 font-medium">฿{formatMoney(w.total_cost)}</td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>
    </div>
  )
}
