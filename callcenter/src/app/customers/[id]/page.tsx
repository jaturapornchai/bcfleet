'use client'
import { useState } from 'react'
import useSWR from 'swr'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { api } from '@/lib/api'
import { formatMoney, formatDate, TRIP_STATUS } from '@/lib/constants'

type Tab = 'info' | 'timeline' | 'trips'

export default function CustomerDetailPage({ params }: { params: { id: string } }) {
  const { id } = params
  const router = useRouter()
  const [tab, setTab] = useState<Tab>('info')
  const { data: customer, isLoading } = useSWR(['customer', id], () => api.getCustomer(id))
  const { data: tripsData } = useSWR(['trips-customer', id], () => api.getTrips(1, 50))

  if (isLoading) return <div className="p-8 text-slate-400">กำลังโหลด...</div>
  if (!customer) return <div className="p-8 text-slate-400">ไม่พบข้อมูลลูกค้า</div>

  const c = customer.data || customer
  const trips: any[] = tripsData?.data ?? []

  const TABS: { key: Tab; label: string }[] = [
    { key: 'info', label: '📋 ข้อมูล' },
    { key: 'timeline', label: '⏱️ Timeline' },
    { key: 'trips', label: `🚚 เที่ยว (${trips.length})` },
  ]

  return (
    <div className="max-w-4xl">
      {/* Header */}
      <div className="flex items-center gap-3 mb-4">
        <Link href="/customers" className="text-slate-400 hover:text-slate-600 text-sm">← กลับ</Link>
        <h2 className="text-xl font-bold">{c.name}</h2>
        <span className={`px-2 py-0.5 rounded text-xs ${c.status === 'active' ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>
          {c.status === 'active' ? 'Active' : 'Inactive'}
        </span>
        <Link href="/trips/new" className="ml-auto bg-blue-600 text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-blue-700">
          ⚡ สร้างเที่ยวให้ลูกค้า
        </Link>
      </div>

      {/* Tabs */}
      <div className="flex gap-1 mb-6 border-b">
        {TABS.map(t => (
          <button key={t.key} onClick={() => setTab(t.key)}
            className={`px-4 py-2.5 text-sm font-medium transition-colors ${tab === t.key
              ? 'text-blue-600 border-b-2 border-blue-600 -mb-px'
              : 'text-slate-500 hover:text-slate-700'}`}>
            {t.label}
          </button>
        ))}
      </div>

      {/* ===== Tab: Info ===== */}
      {tab === 'info' && (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="bg-white rounded-xl border p-5">
            <h3 className="font-semibold text-slate-700 mb-4">ข้อมูลทั่วไป</h3>
            <div className="space-y-3 text-sm">
              <Row label="รหัสลูกค้า" value={c.customer_no} mono />
              <Row label="ชื่อ" value={c.name} />
              <Row label="บริษัท" value={c.company || '-'} />
              <Row label="เบอร์โทร" value={c.phone || '-'} />
              <Row label="อีเมล" value={c.email || '-'} />
              <Row label="เลขผู้เสียภาษี" value={c.tax_id || '-'} />
              <Row label="LINE" value={c.line_user_id ? `✅ เชื่อมแล้ว` : '❌ ยังไม่เชื่อม'} />
              <Row label="ที่อยู่" value={c.address || '-'} />
            </div>
          </div>

          <div className="space-y-4">
            <div className="bg-white rounded-xl border p-5">
              <h3 className="font-semibold text-slate-700 mb-4">สถิติ</h3>
              <div className="grid grid-cols-2 gap-3">
                <Stat label="เที่ยวทั้งหมด" value={`${c.total_trips ?? 0} เที่ยว`} />
                <Stat label="รายได้รวม" value={`฿${formatMoney(c.total_revenue)}`} />
                <Stat label="เที่ยวล่าสุด" value={formatDate(c.last_trip_date) || '-'} />
                <Stat label="เครดิต" value={c.credit_limit ? `฿${formatMoney(c.credit_limit)}/${c.credit_days ?? 0}วัน` : 'เงินสด'} />
              </div>
            </div>

            {c.contacts?.length > 0 && (
              <div className="bg-white rounded-xl border p-5">
                <h3 className="font-semibold text-slate-700 mb-3">ผู้ติดต่อ</h3>
                {c.contacts.map((ct: any, i: number) => (
                  <div key={i} className="flex items-center gap-3 py-2 border-b last:border-0 text-sm">
                    <div className="flex-1">
                      <span className="font-medium">{ct.name}</span>
                      {ct.position && <span className="text-slate-400 text-xs ml-2">{ct.position}</span>}
                    </div>
                    {ct.phone && (
                      <a href={`tel:${ct.phone}`} className="text-blue-600 text-xs hover:underline">📞 {ct.phone}</a>
                    )}
                    {ct.is_primary && <span className="px-1.5 py-0.5 bg-blue-100 text-blue-700 rounded text-xs">หลัก</span>}
                  </div>
                ))}
              </div>
            )}

            {c.notes && (
              <div className="bg-yellow-50 rounded-xl border border-yellow-100 p-4 text-sm text-yellow-800">
                📝 {c.notes}
              </div>
            )}
          </div>
        </div>
      )}

      {/* ===== Tab: Timeline ===== */}
      {tab === 'timeline' && (
        <div className="max-w-2xl">
          <div className="relative">
            {/* Timeline line */}
            <div className="absolute left-5 top-0 bottom-0 w-0.5 bg-slate-200" />

            <div className="space-y-0">
              {trips.length === 0 && (
                <div className="pl-14 py-8 text-slate-400">ยังไม่มีประวัติการใช้บริการ</div>
              )}
              {trips.map((t: any, i: number) => {
                const st = TRIP_STATUS[t.status] || { label: t.status, color: 'bg-gray-100 text-gray-700' }
                const isRecent = i === 0
                const profit = (t.profit ?? 0)
                return (
                  <div key={t.id} className="relative pl-14 pb-6">
                    {/* Dot */}
                    <div className={`absolute left-3 top-1 w-5 h-5 rounded-full border-2 border-white z-10 flex items-center justify-center ${
                      t.status === 'completed' ? 'bg-green-500'
                      : t.status === 'cancelled' ? 'bg-red-400'
                      : t.status === 'delivering' || t.status === 'started' ? 'bg-blue-500 animate-pulse'
                      : 'bg-slate-300'
                    }`}>
                      {t.status === 'completed' && <span className="text-white text-xs">✓</span>}
                      {(t.status === 'delivering' || t.status === 'started') && <span className="w-2 h-2 bg-white rounded-full" />}
                    </div>

                    {/* Card */}
                    <div className={`bg-white rounded-xl border p-4 cursor-pointer hover:shadow-sm transition-shadow ${isRecent ? 'border-blue-200 ring-1 ring-blue-100' : ''}`}
                      onClick={() => router.push(`/trips/${t.id}`)}>
                      <div className="flex items-start justify-between gap-2">
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2 flex-wrap">
                            <span className="font-mono text-xs text-slate-500">{t.trip_no ?? t.id?.slice(-8)}</span>
                            <span className={`px-2 py-0.5 rounded text-xs ${st.color}`}>{st.label}</span>
                            {isRecent && <span className="px-1.5 py-0.5 bg-blue-100 text-blue-700 rounded text-xs">ล่าสุด</span>}
                          </div>
                          <div className="mt-1.5 text-sm font-medium text-slate-700 truncate">
                            {t.origin_name ?? '—'} {t.destination_count > 0 ? `→ ${t.destination_count} จุด` : ''}
                          </div>
                          {t.cargo_description && (
                            <div className="text-xs text-slate-500 mt-0.5 truncate">📦 {t.cargo_description}</div>
                          )}
                        </div>
                        <div className="text-right shrink-0">
                          <div className="text-xs text-slate-400">{formatDate(t.planned_start)}</div>
                          {t.revenue > 0 && (
                            <div className="text-sm font-semibold text-green-600 mt-1">฿{formatMoney(t.revenue)}</div>
                          )}
                          {profit !== 0 && (
                            <div className={`text-xs ${profit >= 0 ? 'text-emerald-600' : 'text-red-500'}`}>
                              {profit >= 0 ? '+' : ''}฿{formatMoney(profit)}
                            </div>
                          )}
                        </div>
                      </div>

                      {t.has_pod && (
                        <div className="mt-2 flex items-center gap-1 text-xs text-green-600">
                          <span>✅ มี POD</span>
                          <span className="text-slate-300">·</span>
                          <span className="text-slate-400">รับสินค้าเรียบร้อย</span>
                        </div>
                      )}
                    </div>
                  </div>
                )
              })}

              {/* End dot */}
              {trips.length > 0 && (
                <div className="relative pl-14 pb-2">
                  <div className="absolute left-3 top-1 w-5 h-5 rounded-full bg-slate-100 border-2 border-slate-200 flex items-center justify-center">
                    <span className="text-slate-400 text-xs">+</span>
                  </div>
                  <div className="text-sm text-slate-400 py-1">เริ่มใช้บริการ</div>
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* ===== Tab: Trips table ===== */}
      {tab === 'trips' && (
        <div className="bg-white rounded-xl border overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-slate-50 border-b">
              <tr>
                <th className="px-4 py-3 text-left text-slate-500">เลขที่</th>
                <th className="px-4 py-3 text-left text-slate-500">สถานะ</th>
                <th className="px-4 py-3 text-left text-slate-500">ต้นทาง</th>
                <th className="px-4 py-3 text-left text-slate-500">สินค้า</th>
                <th className="px-4 py-3 text-right text-slate-500">รายได้</th>
                <th className="px-4 py-3 text-right text-slate-500">กำไร</th>
                <th className="px-4 py-3 text-left text-slate-500">วันที่</th>
              </tr>
            </thead>
            <tbody>
              {trips.map((t: any) => {
                const st = TRIP_STATUS[t.status] || { label: t.status, color: 'bg-gray-100' }
                return (
                  <tr key={t.id} className="border-b hover:bg-blue-50/50 cursor-pointer" onClick={() => router.push(`/trips/${t.id}`)}>
                    <td className="px-4 py-3 font-mono text-xs">{t.trip_no ?? t.id?.slice(-8)}</td>
                    <td className="px-4 py-3"><span className={`px-2 py-0.5 rounded text-xs ${st.color}`}>{st.label}</span></td>
                    <td className="px-4 py-3 truncate max-w-[140px]">{t.origin_name || '-'}</td>
                    <td className="px-4 py-3 truncate max-w-[140px]">{t.cargo_description || '-'}</td>
                    <td className="px-4 py-3 text-right text-green-600">฿{formatMoney(t.revenue)}</td>
                    <td className="px-4 py-3 text-right font-medium" style={{ color: (t.profit ?? 0) >= 0 ? '#059669' : '#DC2626' }}>
                      ฿{formatMoney(t.profit)}
                    </td>
                    <td className="px-4 py-3 text-slate-500">{formatDate(t.planned_start)}</td>
                  </tr>
                )
              })}
              {trips.length === 0 && (
                <tr><td colSpan={7} className="px-4 py-8 text-center text-slate-400">ยังไม่มีเที่ยววิ่ง</td></tr>
              )}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}

function Row({ label, value, mono }: { label: string; value: string; mono?: boolean }) {
  return (
    <div className="flex justify-between gap-2">
      <span className="text-slate-500 shrink-0">{label}</span>
      <span className={`text-right ${mono ? 'font-mono text-xs' : ''}`}>{value}</span>
    </div>
  )
}
function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div className="bg-slate-50 rounded-lg p-3">
      <div className="text-xs text-slate-500 mb-0.5">{label}</div>
      <div className="font-semibold text-slate-800 text-sm">{value}</div>
    </div>
  )
}
