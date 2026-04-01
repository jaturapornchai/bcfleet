'use client'
import useSWR from 'swr'
import Link from 'next/link'
import { api } from '@/lib/api'
import { TRIP_STATUS, formatMoney, formatDate } from '@/lib/constants'

export default function TripDetailPage({ params }: { params: { id: string } }) {
  const { id } = params
  const { data, isLoading } = useSWR(['trip', id], () => api.getTrip(id))

  if (isLoading) return <div className="p-8 text-slate-400">กำลังโหลด...</div>
  if (!data) return <div className="p-8 text-slate-400">ไม่พบเที่ยววิ่ง</div>

  const t = data.data || data
  const st = TRIP_STATUS[t.status] || { label: t.status, color: 'bg-gray-100 text-gray-700' }

  return (
    <div className="max-w-4xl">
      <div className="flex items-center gap-3 mb-6">
        <Link href="/trips" className="text-slate-400 hover:text-slate-600 text-sm">← กลับ</Link>
        <h2 className="text-xl font-bold">📋 {t.trip_no || `เที่ยว #${id.slice(-8)}`}</h2>
        <span className={`px-2.5 py-1 rounded-lg text-sm font-medium ${st.color}`}>{st.label}</span>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
        {/* รายละเอียดเที่ยว */}
        <div className="bg-white rounded-xl border p-5">
          <h3 className="font-semibold text-slate-700 mb-4">ข้อมูลเที่ยววิ่ง</h3>
          <div className="space-y-3 text-sm">
            <Row label="เลขที่เที่ยว" value={t.trip_no || '-'} mono />
            <Row label="สถานะ" value={st.label} />
            <Row label="ต้นทาง" value={t.origin_name || '-'} />
            <Row label="สินค้า" value={t.cargo_description || '-'} />
            <Row label="น้ำหนัก" value={t.cargo_weight_kg ? `${t.cargo_weight_kg.toLocaleString()} กก.` : '-'} />
            <Row label="ระยะทาง" value={t.distance_km ? `${t.distance_km} กม.` : '-'} />
          </div>
        </div>

        {/* รถและคนขับ */}
        <div className="bg-white rounded-xl border p-5">
          <h3 className="font-semibold text-slate-700 mb-4">รถและคนขับ</h3>
          <div className="space-y-3 text-sm">
            <Row label="รถ" value={t.vehicle_plate || t.vehicle_id || '-'} />
            <Row label="คนขับ" value={t.driver_name || t.driver_id || '-'} />
            <Row label="ประเภท" value={t.is_partner ? '🤝 รถร่วม' : '🚛 รถตัวเอง'} />
            <Row label="วางแผนออก" value={formatDate(t.planned_start)} />
            <Row label="วางแผนถึง" value={formatDate(t.planned_end)} />
            <Row label="ออกจริง" value={formatDate(t.actual_start)} />
            <Row label="ถึงจริง" value={formatDate(t.actual_end)} />
          </div>
        </div>
      </div>

      {/* ต้นทุน */}
      <div className="bg-white rounded-xl border p-5 mb-6">
        <h3 className="font-semibold text-slate-700 mb-4">ต้นทุนและรายได้</h3>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <CostCard label="รายได้" value={t.revenue} color="text-green-600" />
          <CostCard label="ค่าน้ำมัน" value={t.fuel_cost} color="text-red-500" />
          <CostCard label="ค่าทางด่วน" value={t.toll_cost} color="text-red-500" />
          <CostCard label="ค่าเบี้ยเลี้ยง" value={t.driver_allowance} color="text-red-500" />
          <CostCard label="ต้นทุนรวม" value={t.total_cost} color="text-red-600 font-bold" />
          <div className="col-span-2 bg-slate-50 rounded-xl p-4">
            <div className="text-xs text-slate-500 mb-1">กำไรสุทธิ</div>
            <div className={`text-2xl font-bold ${(t.profit ?? 0) >= 0 ? 'text-green-600' : 'text-red-600'}`}>
              ฿{formatMoney(t.profit)}
            </div>
          </div>
        </div>
      </div>

      {/* POD */}
      {t.has_pod && (
        <div className="bg-white rounded-xl border p-5 mb-6">
          <h3 className="font-semibold text-slate-700 mb-3">✅ หลักฐานการส่งมอบ (POD)</h3>
          <div className="text-sm text-slate-600 space-y-1">
            <div>ผู้รับ: {t.pod?.receiver_name || '-'}</div>
            <div>หมายเหตุ: {t.pod?.notes || '-'}</div>
            <div>เวลา: {formatDate(t.pod?.timestamp)}</div>
          </div>
        </div>
      )}

      {/* Checklist */}
      {t.checklist?.pre_trip?.items?.length > 0 && (
        <div className="bg-white rounded-xl border overflow-hidden">
          <div className="px-5 py-4 border-b">
            <h3 className="font-semibold text-slate-700">📋 Checklist ก่อนออก</h3>
          </div>
          <div className="p-5 grid grid-cols-2 md:grid-cols-3 gap-3">
            {t.checklist.pre_trip.items.map((item: any, i: number) => (
              <div key={i} className={`flex items-center gap-2 p-2 rounded-lg text-sm ${item.status === 'ok' ? 'bg-green-50' : 'bg-yellow-50'}`}>
                <span>{item.status === 'ok' ? '✅' : '⚠️'}</span>
                <span>{item.item}</span>
              </div>
            ))}
          </div>
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

function CostCard({ label, value, color }: { label: string; value: any; color: string }) {
  return (
    <div className="bg-slate-50 rounded-xl p-4">
      <div className="text-xs text-slate-500 mb-1">{label}</div>
      <div className={`font-semibold ${color}`}>฿{formatMoney(value)}</div>
    </div>
  )
}
