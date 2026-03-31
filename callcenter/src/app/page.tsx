'use client'
import useSWR from 'swr'
import { api } from '@/lib/api'
import { formatMoney } from '@/lib/constants'

function StatCard({ icon, label, value, sub, color }: any) {
  return (
    <div className="bg-white rounded-xl p-5 shadow-sm border">
      <div className="flex items-center gap-3 mb-2">
        <span className="text-2xl">{icon}</span>
        <span className="text-sm text-slate-500">{label}</span>
      </div>
      <div className={`text-2xl font-bold ${color || 'text-slate-800'}`}>{value}</div>
      {sub && <div className="text-xs text-slate-400 mt-1">{sub}</div>}
    </div>
  )
}

export default function Dashboard() {
  const { data: summary } = useSWR('summary', () => api.getSummary(), { refreshInterval: 30000 })
  const { data: kpi } = useSWR('kpi', () => api.getKPI(), { refreshInterval: 30000 })
  const { data: alerts } = useSWR('alerts', () => api.getAlerts(1, 10), { refreshInterval: 30000 })
  const { data: moving } = useSWR('moving', () => api.getMovingVehicles(), { refreshInterval: 10000 })

  const s = summary?.data
  const k = kpi?.data

  return (
    <div>
      <h2 className="text-xl font-bold mb-6">Dashboard — สรุปภาพรวม</h2>

      <div className="grid grid-cols-2 lg:grid-cols-4 xl:grid-cols-6 gap-4 mb-8">
        <StatCard icon="🚛" label="รถ Active" value={s?.active_vehicles ?? '-'} color="text-blue-600" />
        <StatCard icon="🔧" label="ซ่อมอยู่" value={s?.vehicles_in_maintenance ?? 0} color="text-orange-500" />
        <StatCard icon="📋" label="เที่ยววันนี้" value={s?.today_trips ?? 0} sub={`สำเร็จ ${s?.completed_trips ?? 0}`} />
        <StatCard icon="📍" label="รถเคลื่อนที่" value={moving?.count ?? 0} color="text-green-600" />
        <StatCard icon="💰" label="รายได้วันนี้" value={`฿${formatMoney(s?.total_revenue)}`} color="text-green-600" />
        <StatCard icon="📈" label="กำไรวันนี้" value={`฿${formatMoney(s?.total_profit)}`} color="text-emerald-600" />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 mb-8">
        <div className="bg-white rounded-xl p-5 shadow-sm border">
          <h3 className="font-semibold mb-3">KPI ภาพรวม</h3>
          <div className="space-y-3 text-sm">
            <div className="flex justify-between"><span className="text-slate-500">Vehicle Utilization</span><span className="font-semibold">{k ? (k.vehicle_utilization_rate * 100).toFixed(1) : 0}%</span></div>
            <div className="flex justify-between"><span className="text-slate-500">On-time Delivery</span><span className="font-semibold">{k ? (k.on_time_delivery_rate * 100).toFixed(1) : 0}%</span></div>
            <div className="flex justify-between"><span className="text-slate-500">Avg Fuel Efficiency</span><span className="font-semibold">{k?.avg_fuel_efficiency?.toFixed(1) ?? 0} km/L</span></div>
          </div>
        </div>

        <div className="bg-white rounded-xl p-5 shadow-sm border col-span-2">
          <h3 className="font-semibold mb-3">⚠️ แจ้งเตือนล่าสุด ({alerts?.total ?? 0})</h3>
          <div className="space-y-2 max-h-60 overflow-y-auto">
            {alerts?.data?.slice(0, 8).map((a: any) => (
              <div key={a.id} className="flex items-center gap-2 text-sm p-2 rounded bg-slate-50">
                <span className={`px-2 py-0.5 rounded text-xs font-medium ${
                  a.severity === 'critical' ? 'bg-red-100 text-red-700' :
                  a.severity === 'warning' ? 'bg-yellow-100 text-yellow-700' : 'bg-blue-100 text-blue-700'
                }`}>{a.severity}</span>
                <span className="text-slate-600 truncate">{a.message}</span>
              </div>
            ))}
            {!alerts?.data?.length && <p className="text-slate-400 text-sm">ไม่มีแจ้งเตือน</p>}
          </div>
        </div>
      </div>
    </div>
  )
}
