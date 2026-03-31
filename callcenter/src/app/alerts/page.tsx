'use client'
import useSWR from 'swr'
import { api } from '@/lib/api'
import { ALERT_SEVERITY } from '@/lib/constants'

export default function AlertsPage() {
  const { data } = useSWR('alerts-full', () => api.getAlerts(1, 100), { refreshInterval: 15000 })
  return (
    <div>
      <h2 className="text-xl font-bold mb-6">⚠️ แจ้งเตือน ({data?.total ?? 0})</h2>
      <div className="space-y-2">
        {data?.data?.map((a: any) => {
          const sev = ALERT_SEVERITY[a.severity] || { label: a.severity, color: 'bg-gray-100' }
          return (
            <div key={a.id} className="bg-white rounded-lg p-4 shadow-sm border flex items-start gap-4">
              <span className={`px-2 py-1 rounded text-xs font-medium shrink-0 ${sev.color}`}>{sev.label}</span>
              <div className="flex-1 min-w-0">
                <h4 className="font-medium text-sm">{a.title}</h4>
                <p className="text-sm text-slate-500 mt-0.5">{a.message}</p>
              </div>
              <div className="text-right shrink-0">
                {a.days_remaining != null && (
                  <span className={`text-sm font-medium ${a.days_remaining <= 7 ? 'text-red-600' : a.days_remaining <= 15 ? 'text-yellow-600' : 'text-slate-500'}`}>
                    {a.days_remaining <= 0 ? 'หมดอายุแล้ว!' : `เหลือ ${a.days_remaining} วัน`}
                  </span>
                )}
              </div>
            </div>
          )
        })}
      </div>
    </div>
  )
}
