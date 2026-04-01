'use client'
import { useState } from 'react'
import useSWR from 'swr'
import { api } from '@/lib/api'
import { ALERT_SEVERITY } from '@/lib/constants'

const TYPE_LABEL: Record<string, string> = {
  insurance_expiry: '🛡️ ประกัน',
  tax_due: '📄 ภาษี',
  act_due: '📋 พ.ร.บ.',
  license_expiry: '🪪 ใบขับขี่',
  maintenance_due: '🔧 ซ่อมบำรุง',
  geofence_alert: '📍 Geofence',
  speeding: '🚨 ความเร็ว',
}

export default function AlertsPage() {
  const { data, mutate } = useSWR('alerts-full', () => api.getAlerts(1, 100), { refreshInterval: 15000 })
  const [acknowledged, setAcknowledged] = useState<Set<string>>(new Set())
  const [severityFilter, setSeverityFilter] = useState<string>('all')
  const [typeFilter, setTypeFilter] = useState<string>('all')

  const alerts: any[] = data?.data ?? []

  const ack = (id: string) => {
    setAcknowledged(s => new Set([...s, id]))
  }
  const ackAll = () => {
    const ids = filtered.map((a: any) => a.id)
    setAcknowledged(s => new Set([...s, ...ids]))
  }

  const filtered = alerts.filter((a: any) => {
    if (acknowledged.has(a.id)) return false
    if (severityFilter !== 'all' && a.severity !== severityFilter) return false
    if (typeFilter !== 'all' && a.type !== typeFilter) return false
    return true
  })

  const acknowledged_list = alerts.filter((a: any) => acknowledged.has(a.id))

  const criticalCount = filtered.filter((a: any) => a.severity === 'critical').length
  const warningCount = filtered.filter((a: any) => a.severity === 'warning').length
  const infoCount = filtered.filter((a: any) => a.severity === 'info').length

  const types = [...new Set(alerts.map((a: any) => a.type))]

  return (
    <div className="max-w-4xl">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h2 className="text-xl font-bold">🔔 Notification Center</h2>
          <p className="text-sm text-slate-500 mt-1">
            {filtered.length > 0 ? (
              <span>
                <span className="text-red-600 font-medium">{criticalCount} วิกฤต</span>
                {' · '}
                <span className="text-yellow-600 font-medium">{warningCount} เฝ้าระวัง</span>
                {' · '}
                <span className="text-blue-600 font-medium">{infoCount} ข้อมูล</span>
              </span>
            ) : (
              <span className="text-green-600 font-medium">✅ ไม่มีแจ้งเตือนค้างอยู่</span>
            )}
          </p>
        </div>
        {filtered.length > 0 && (
          <button onClick={ackAll}
            className="px-4 py-2 text-sm bg-slate-100 text-slate-600 rounded-lg hover:bg-slate-200 font-medium">
            ✓ รับทราบทั้งหมด ({filtered.length})
          </button>
        )}
      </div>

      {/* Filters */}
      <div className="flex flex-wrap gap-2 mb-4">
        {['all', 'critical', 'warning', 'info'].map(s => (
          <button key={s} onClick={() => setSeverityFilter(s)}
            className={`px-3 py-1.5 rounded-lg text-xs font-medium ${severityFilter === s
              ? s === 'critical' ? 'bg-red-600 text-white'
                : s === 'warning' ? 'bg-yellow-500 text-white'
                : s === 'info' ? 'bg-blue-600 text-white'
                : 'bg-slate-800 text-white'
              : 'bg-white border text-slate-600 hover:bg-slate-50'}`}>
            {s === 'all' ? 'ทั้งหมด' : ALERT_SEVERITY[s]?.label ?? s}
            {s !== 'all' && (
              <span className="ml-1 opacity-80">
                {s === 'critical' ? criticalCount : s === 'warning' ? warningCount : infoCount}
              </span>
            )}
          </button>
        ))}
        <select value={typeFilter} onChange={e => setTypeFilter(e.target.value)}
          className="px-3 py-1.5 rounded-lg text-xs border bg-white text-slate-600 focus:outline-none">
          <option value="all">ทุกประเภท</option>
          {types.map(t => <option key={t} value={t}>{TYPE_LABEL[t] ?? t}</option>)}
        </select>
      </div>

      {/* Alert cards */}
      <div className="space-y-2 mb-8">
        {filtered.length === 0 && (
          <div className="bg-white rounded-xl border p-8 text-center text-slate-400">
            <div className="text-4xl mb-2">✅</div>
            <div className="font-medium">ไม่มีแจ้งเตือน</div>
          </div>
        )}
        {filtered.map((a: any) => {
          const sev = ALERT_SEVERITY[a.severity] || { label: a.severity, color: 'bg-gray-100 text-gray-700' }
          const urgent = a.severity === 'critical' || (a.days_remaining != null && a.days_remaining <= 7)
          return (
            <div key={a.id} className={`bg-white rounded-xl border p-4 flex items-start gap-4 transition-all ${urgent ? 'border-l-4 border-red-400' : ''}`}>
              <div className="shrink-0 text-2xl">{TYPE_LABEL[a.type]?.split(' ')[0] ?? '⚠️'}</div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 flex-wrap">
                  <span className={`px-2 py-0.5 rounded text-xs font-medium ${sev.color}`}>{sev.label}</span>
                  <span className="text-xs text-slate-400">{TYPE_LABEL[a.type] ?? a.type}</span>
                  {urgent && a.days_remaining != null && a.days_remaining <= 0 && (
                    <span className="px-2 py-0.5 rounded text-xs font-bold bg-red-100 text-red-700 animate-pulse">หมดอายุแล้ว!</span>
                  )}
                </div>
                <h4 className="font-semibold text-sm mt-1">{a.title}</h4>
                <p className="text-sm text-slate-500 mt-0.5">{a.message}</p>
              </div>
              <div className="shrink-0 flex flex-col items-end gap-2">
                {a.days_remaining != null && (
                  <span className={`text-sm font-bold ${a.days_remaining <= 0 ? 'text-red-600' : a.days_remaining <= 7 ? 'text-red-500' : a.days_remaining <= 15 ? 'text-yellow-600' : 'text-slate-400'}`}>
                    {a.days_remaining <= 0 ? 'หมดแล้ว' : `${a.days_remaining} วัน`}
                  </span>
                )}
                <button onClick={() => ack(a.id)}
                  className="px-3 py-1 text-xs bg-slate-100 text-slate-600 rounded-lg hover:bg-green-100 hover:text-green-700 font-medium transition-colors">
                  ✓ รับทราบ
                </button>
              </div>
            </div>
          )
        })}
      </div>

      {/* Acknowledged section */}
      {acknowledged_list.length > 0 && (
        <div>
          <h3 className="text-sm font-semibold text-slate-400 mb-3">รับทราบแล้ว ({acknowledged_list.length})</h3>
          <div className="space-y-1.5 opacity-50">
            {acknowledged_list.map((a: any) => (
              <div key={a.id} className="bg-white rounded-lg border px-4 py-2.5 flex items-center gap-3 text-sm">
                <span className="text-green-500">✓</span>
                <span className="flex-1 text-slate-500">{a.title}</span>
                <button onClick={() => setAcknowledged(s => { const n = new Set(s); n.delete(a.id); return n })}
                  className="text-xs text-slate-400 hover:text-slate-600">ยกเลิก</button>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}
