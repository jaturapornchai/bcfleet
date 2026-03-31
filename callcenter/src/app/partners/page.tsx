'use client'
import useSWR from 'swr'
import { api } from '@/lib/api'

export default function PartnersPage() {
  const { data } = useSWR('partners', () => api.getPartners())
  return (
    <div>
      <h2 className="text-xl font-bold mb-6">🤝 รถร่วม ({data?.total ?? 0})</h2>
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
        {data?.data?.map((p: any) => (
          <div key={p.id} className="bg-white rounded-xl p-5 shadow-sm border">
            <div className="flex justify-between items-start mb-3">
              <div>
                <h3 className="font-semibold">{p.owner_name}</h3>
                <p className="text-sm text-slate-500">{p.owner_company}</p>
              </div>
              <span className={`px-2 py-0.5 rounded text-xs ${p.status === 'active' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>{p.status}</span>
            </div>
            <div className="text-sm space-y-1 text-slate-600">
              <p>🚛 {p.plate} ({p.vehicle_type}) max {p.max_weight_kg?.toLocaleString()} kg</p>
              <p>📞 {p.owner_phone}</p>
              <p>💰 {p.pricing_model}: ฿{p.base_rate?.toLocaleString()}{p.per_km_rate ? ` + ฿${p.per_km_rate}/km` : ''}</p>
              <p>⭐ {p.rating?.toFixed(1)} ({p.total_trips} เที่ยว)</p>
            </div>
          </div>
        ))}
        {!data?.data?.length && <p className="text-slate-400 col-span-3">ไม่มีรถร่วม</p>}
      </div>
    </div>
  )
}
