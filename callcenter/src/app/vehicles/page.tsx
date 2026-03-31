'use client'
import useSWR from 'swr'
import { api } from '@/lib/api'
import { VEHICLE_HEALTH } from '@/lib/constants'

export default function VehiclesPage() {
  const { data } = useSWR('vehicles', () => api.getVehicles(1, 100))

  return (
    <div>
      <h2 className="text-xl font-bold mb-6">🚛 ทะเบียนรถ ({data?.total ?? 0} คัน)</h2>
      <div className="bg-white rounded-xl shadow-sm border overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-slate-50 border-b">
            <tr>
              <th className="px-4 py-3 text-left text-slate-500">ทะเบียน</th>
              <th className="px-4 py-3 text-left text-slate-500">ยี่ห้อ/รุ่น</th>
              <th className="px-4 py-3 text-left text-slate-500">ประเภท</th>
              <th className="px-4 py-3 text-left text-slate-500">สุขภาพ</th>
              <th className="px-4 py-3 text-left text-slate-500">สถานะ</th>
              <th className="px-4 py-3 text-left text-slate-500">ไมล์</th>
              <th className="px-4 py-3 text-left text-slate-500">ความเป็นเจ้าของ</th>
            </tr>
          </thead>
          <tbody>
            {data?.data?.map((v: any) => {
              const h = VEHICLE_HEALTH[v.health_status] || { label: '-', color: 'bg-gray-100' }
              return (
                <tr key={v.id} className="border-b hover:bg-blue-50/50">
                  <td className="px-4 py-3 font-medium">{v.plate}</td>
                  <td className="px-4 py-3">{v.brand} {v.model}</td>
                  <td className="px-4 py-3">{v.type}</td>
                  <td className="px-4 py-3"><span className={`px-2 py-0.5 rounded text-xs ${h.color}`}>{h.label}</span></td>
                  <td className="px-4 py-3"><span className={`px-2 py-0.5 rounded text-xs ${v.status === 'active' ? 'bg-green-100 text-green-700' : 'bg-orange-100 text-orange-700'}`}>{v.status}</span></td>
                  <td className="px-4 py-3">{v.mileage_km?.toLocaleString()} km</td>
                  <td className="px-4 py-3">{v.ownership === 'own' ? 'ของบริษัท' : v.ownership === 'partner' ? 'รถร่วม' : v.ownership}</td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>
    </div>
  )
}
