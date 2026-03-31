'use client'
import useSWR from 'swr'
import { api } from '@/lib/api'

export default function DriversPage() {
  const { data } = useSWR('drivers', () => api.getDriverPerformance())
  return (
    <div>
      <h2 className="text-xl font-bold mb-6">👤 คนขับ — อันดับ KPI ({data?.total ?? 0} คน)</h2>
      <div className="bg-white rounded-xl shadow-sm border overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-slate-50 border-b">
            <tr>
              <th className="px-4 py-3 text-left text-slate-500">#</th>
              <th className="px-4 py-3 text-left text-slate-500">ชื่อ</th>
              <th className="px-4 py-3 text-left text-slate-500">Score</th>
              <th className="px-4 py-3 text-left text-slate-500">เที่ยววิ่ง</th>
              <th className="px-4 py-3 text-left text-slate-500">ตรงเวลา</th>
              <th className="px-4 py-3 text-left text-slate-500">น้ำมัน (km/L)</th>
              <th className="px-4 py-3 text-left text-slate-500">Rating</th>
            </tr>
          </thead>
          <tbody>
            {data?.data?.map((d: any, i: number) => (
              <tr key={d.driver_id} className="border-b hover:bg-blue-50/50">
                <td className="px-4 py-3 font-bold text-slate-400">{i + 1}</td>
                <td className="px-4 py-3 font-medium">{d.name}</td>
                <td className="px-4 py-3"><span className={`font-bold ${d.score >= 90 ? 'text-green-600' : d.score >= 70 ? 'text-yellow-600' : 'text-red-600'}`}>{d.score}</span></td>
                <td className="px-4 py-3">{d.total_trips}</td>
                <td className="px-4 py-3">{(d.on_time_rate * 100).toFixed(0)}%</td>
                <td className="px-4 py-3">{d.fuel_efficiency?.toFixed(1)}</td>
                <td className="px-4 py-3">{d.customer_rating?.toFixed(1)} ⭐</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
