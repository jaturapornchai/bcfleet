'use client'
import useSWR from 'swr'
import { api } from '@/lib/api'
import { formatMoney } from '@/lib/constants'

export default function ReportsPage() {
  const { data: kpi } = useSWR('kpi', () => api.getKPI())
  const { data: summary } = useSWR('summary', () => api.getSummary())
  const { data: driverPerf } = useSWR('driver-perf', () => api.getDriverPerformance())
  const { data: vehUtil } = useSWR('veh-util', () => api.getVehicleUtilization())
  const { data: expenses } = useSWR('expenses-report', () => api.getExpenses(1, 100))
  const { data: trips } = useSWR('trips-report', () => api.getTrips(1, 100))

  // Compute daily revenue from trips data
  const revenueByDay = buildDailyRevenue(trips?.data ?? [])
  const topDrivers = (driverPerf?.data ?? []).slice(0, 10)
  const vehicles = vehUtil?.data ?? []

  const totalRevenue = (trips?.data ?? []).reduce((s: number, t: any) => s + (t.revenue ?? 0), 0)
  const totalCost = (trips?.data ?? []).reduce((s: number, t: any) => s + (t.total_cost ?? 0), 0)
  const totalProfit = totalRevenue - totalCost
  const completedTrips = (trips?.data ?? []).filter((t: any) => t.status === 'completed').length
  const totalFuel = (expenses?.data ?? []).filter((e: any) => e.type === 'fuel').reduce((s: number, e: any) => s + (e.amount ?? 0), 0)

  return (
    <div className="max-w-5xl">
      <h2 className="text-xl font-bold mb-6">📈 รายงาน</h2>

      {/* KPI Summary */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
        <KPICard label="รายได้ทั้งหมด" value={`฿${formatMoney(totalRevenue)}`} sub="จาก 100 เที่ยวล่าสุด" color="text-green-600" />
        <KPICard label="ต้นทุนทั้งหมด" value={`฿${formatMoney(totalCost)}`} sub={`ค่าน้ำมัน ฿${formatMoney(totalFuel)}`} color="text-red-500" />
        <KPICard label="กำไรสุทธิ" value={`฿${formatMoney(totalProfit)}`} sub={totalRevenue > 0 ? `Margin ${Math.round(totalProfit / totalRevenue * 100)}%` : '-'} color={totalProfit >= 0 ? 'text-emerald-600' : 'text-red-600'} />
        <KPICard label="เที่ยวสำเร็จ" value={`${completedTrips}`} sub={`จากทั้งหมด ${trips?.data?.length ?? 0} เที่ยว`} color="text-blue-600" />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
        {/* Daily Revenue Chart */}
        <div className="bg-white rounded-xl border p-5">
          <h3 className="font-semibold text-slate-700 mb-4">📊 รายได้รายวัน (7 วันล่าสุด)</h3>
          <DailyChart data={revenueByDay} />
        </div>

        {/* Vehicle Utilization */}
        <div className="bg-white rounded-xl border p-5">
          <h3 className="font-semibold text-slate-700 mb-4">🚛 อัตราการใช้รถ</h3>
          <div className="space-y-2">
            {vehicles.slice(0, 8).map((v: any) => {
              const util = v.utilization_pct ?? Math.min(100, ((v.total_trips ?? 0) / 30) * 100)
              const color = util >= 70 ? '#22c55e' : util >= 40 ? '#f59e0b' : '#ef4444'
              return (
                <div key={v.id} className="flex items-center gap-3 text-sm">
                  <span className="w-24 truncate text-slate-600 shrink-0">{v.plate ?? '—'}</span>
                  <div className="flex-1 h-4 bg-slate-100 rounded-full overflow-hidden">
                    <div className="h-full rounded-full transition-all" style={{ width: `${Math.min(100, util)}%`, background: color }} />
                  </div>
                  <span className="w-12 text-right text-xs font-medium" style={{ color }}>{Math.round(util)}%</span>
                </div>
              )
            })}
            {vehicles.length === 0 && <p className="text-slate-400 text-sm">ยังไม่มีข้อมูล</p>}
          </div>
        </div>
      </div>

      {/* Driver Leaderboard */}
      <div className="bg-white rounded-xl border overflow-hidden">
        <div className="px-5 py-4 border-b bg-slate-50 flex items-center justify-between">
          <h3 className="font-semibold text-slate-700">🏆 อันดับคนขับ</h3>
          <span className="text-xs text-slate-400">ตาม KPI Score</span>
        </div>
        <table className="w-full text-sm">
          <thead className="border-b bg-slate-50">
            <tr>
              <th className="px-4 py-2.5 text-left text-slate-500 font-medium w-10">อันดับ</th>
              <th className="px-4 py-2.5 text-left text-slate-500 font-medium">คนขับ</th>
              <th className="px-4 py-2.5 text-center text-slate-500 font-medium">คะแนน</th>
              <th className="px-4 py-2.5 text-center text-slate-500 font-medium">เที่ยว</th>
              <th className="px-4 py-2.5 text-center text-slate-500 font-medium">ตรงเวลา</th>
              <th className="px-4 py-2.5 text-center text-slate-500 font-medium">น้ำมัน</th>
              <th className="px-4 py-2.5 text-center text-slate-500 font-medium">Rating</th>
            </tr>
          </thead>
          <tbody>
            {topDrivers.map((d: any, i: number) => {
              const rank = i + 1
              const medal = rank === 1 ? '🥇' : rank === 2 ? '🥈' : rank === 3 ? '🥉' : `${rank}.`
              const scoreColor = (d.score ?? 0) >= 80 ? 'text-green-600' : (d.score ?? 0) >= 60 ? 'text-yellow-600' : 'text-red-500'
              const onTime = d.on_time_rate != null ? `${Math.round(d.on_time_rate * 100)}%` : '—'
              const fuel = d.fuel_efficiency != null ? `${d.fuel_efficiency} km/L` : '—'
              return (
                <tr key={d.id} className={`border-b ${rank <= 3 ? 'bg-yellow-50/30' : 'hover:bg-slate-50'}`}>
                  <td className="px-4 py-3 text-center font-bold">{medal}</td>
                  <td className="px-4 py-3">
                    <div className="font-medium">{d.name}</div>
                    <div className="text-xs text-slate-400">{d.employment_type ?? ''}</div>
                  </td>
                  <td className="px-4 py-3 text-center">
                    <span className={`font-bold text-base ${scoreColor}`}>{d.score ?? 0}</span>
                    <span className="text-xs text-slate-400"> /100</span>
                  </td>
                  <td className="px-4 py-3 text-center">{d.total_trips ?? 0}</td>
                  <td className="px-4 py-3 text-center">{onTime}</td>
                  <td className="px-4 py-3 text-center text-xs">{fuel}</td>
                  <td className="px-4 py-3 text-center">
                    {d.customer_rating != null ? (
                      <span className="text-yellow-500 font-medium">{'★'.repeat(Math.round(d.customer_rating))} <span className="text-slate-500 text-xs">{d.customer_rating.toFixed(1)}</span></span>
                    ) : '—'}
                  </td>
                </tr>
              )
            })}
            {topDrivers.length === 0 && (
              <tr><td colSpan={7} className="px-4 py-8 text-center text-slate-400">ยังไม่มีข้อมูล</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  )
}

// ============ Helpers ============
function buildDailyRevenue(trips: any[]): { day: string; revenue: number; cost: number }[] {
  const map = new Map<string, { revenue: number; cost: number }>()
  const now = new Date()
  // Initialize last 7 days
  for (let i = 6; i >= 0; i--) {
    const d = new Date(now)
    d.setDate(d.getDate() - i)
    const key = d.toLocaleDateString('th-TH', { day: 'numeric', month: 'short' })
    map.set(key, { revenue: 0, cost: 0 })
  }
  trips.forEach(t => {
    if (!t.planned_start) return
    const d = new Date(t.planned_start)
    const key = d.toLocaleDateString('th-TH', { day: 'numeric', month: 'short' })
    if (map.has(key)) {
      const cur = map.get(key)!
      map.set(key, { revenue: cur.revenue + (t.revenue ?? 0), cost: cur.cost + (t.total_cost ?? 0) })
    }
  })
  return [...map.entries()].map(([day, v]) => ({ day, ...v }))
}

function KPICard({ label, value, sub, color }: { label: string; value: string; sub?: string; color: string }) {
  return (
    <div className="bg-white rounded-xl border p-4">
      <div className="text-xs text-slate-500 mb-1">{label}</div>
      <div className={`text-2xl font-bold ${color}`}>{value}</div>
      {sub && <div className="text-xs text-slate-400 mt-1">{sub}</div>}
    </div>
  )
}

function DailyChart({ data }: { data: { day: string; revenue: number; cost: number }[] }) {
  const maxVal = Math.max(...data.map(d => Math.max(d.revenue, d.cost)), 1)
  return (
    <div className="space-y-3">
      {data.map(d => (
        <div key={d.day} className="flex items-center gap-3 text-xs">
          <span className="w-14 text-slate-500 shrink-0">{d.day}</span>
          <div className="flex-1 space-y-1">
            <div className="flex items-center gap-1">
              <div className="h-3 rounded bg-green-400" style={{ width: `${(d.revenue / maxVal) * 100}%`, minWidth: d.revenue > 0 ? 4 : 0 }} />
              {d.revenue > 0 && <span className="text-green-600 font-medium">฿{formatMoney(d.revenue)}</span>}
            </div>
            <div className="flex items-center gap-1">
              <div className="h-3 rounded bg-red-300" style={{ width: `${(d.cost / maxVal) * 100}%`, minWidth: d.cost > 0 ? 4 : 0 }} />
              {d.cost > 0 && <span className="text-red-500">฿{formatMoney(d.cost)}</span>}
            </div>
          </div>
        </div>
      ))}
      <div className="flex items-center gap-4 text-xs text-slate-400 pt-1 border-t">
        <span className="flex items-center gap-1"><span className="w-3 h-3 rounded bg-green-400 inline-block" /> รายได้</span>
        <span className="flex items-center gap-1"><span className="w-3 h-3 rounded bg-red-300 inline-block" /> ต้นทุน</span>
      </div>
    </div>
  )
}
