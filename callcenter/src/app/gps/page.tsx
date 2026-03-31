'use client'
import useSWR from 'swr'
import { api } from '@/lib/api'

export default function GPSPage() {
  const { data: moving } = useSWR('moving-detail', () => api.getMovingVehicles(), { refreshInterval: 10000 })
  const { data: events } = useSWR('movement-events', () => api.getMovementEvents(20), { refreshInterval: 15000 })

  return (
    <div>
      <h2 className="text-xl font-bold mb-6">📍 GPS & Movement Intelligence</h2>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Moving Vehicles */}
        <div className="bg-white rounded-xl shadow-sm border p-5">
          <h3 className="font-semibold mb-3">🟢 รถกำลังเคลื่อนที่ ({moving?.count ?? 0})</h3>
          <div className="space-y-2 max-h-96 overflow-y-auto">
            {moving?.data?.map((v: any) => (
              <div key={v.vehicle_id} className="p-3 bg-slate-50 rounded-lg text-sm">
                <div className="flex justify-between">
                  <span className="font-medium">{v.plate}</span>
                  <span className="text-blue-600 font-medium">{v.speed_kmh?.toFixed(0)} km/h</span>
                </div>
                <div className="text-slate-500 text-xs mt-1">
                  เคลื่อนที่ {v.distance_m?.toFixed(0)}m | {v.lat?.toFixed(4)},{v.lng?.toFixed(4)}
                </div>
                {v.monitoring_prompt && (
                  <div className="mt-1 px-2 py-1 bg-purple-50 text-purple-700 rounded text-xs">
                    🧠 {v.monitoring_prompt}
                  </div>
                )}
              </div>
            ))}
            {!moving?.data?.length && <p className="text-slate-400 text-sm">ไม่มีรถเคลื่อนที่ในขณะนี้</p>}
          </div>
        </div>

        {/* Movement Events */}
        <div className="bg-white rounded-xl shadow-sm border p-5">
          <h3 className="font-semibold mb-3">📊 Movement Events ล่าสุด ({events?.count ?? 0})</h3>
          <div className="space-y-2 max-h-96 overflow-y-auto">
            {events?.data?.map((e: any) => (
              <div key={e.id} className="p-3 bg-slate-50 rounded-lg text-sm">
                <div className="flex items-center gap-2">
                  <span className={`px-2 py-0.5 rounded text-xs ${
                    e.severity === 'critical' ? 'bg-red-100 text-red-700' :
                    e.severity === 'warning' ? 'bg-yellow-100 text-yellow-700' : 'bg-blue-100 text-blue-700'
                  }`}>{e.event_type}</span>
                  <span className="font-medium">{e.plate}</span>
                </div>
                <p className="text-slate-600 mt-1">{e.analysis}</p>
                <span className="text-xs text-slate-400">by {e.analyzed_by}</span>
              </div>
            ))}
            {!events?.data?.length && <p className="text-slate-400 text-sm">ยังไม่มี events</p>}
          </div>
        </div>
      </div>
    </div>
  )
}
