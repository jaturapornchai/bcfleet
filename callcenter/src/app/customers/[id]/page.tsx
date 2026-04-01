'use client'
import useSWR from 'swr'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { api } from '@/lib/api'
import { formatMoney, formatDate, TRIP_STATUS } from '@/lib/constants'

export default function CustomerDetailPage({ params }: { params: { id: string } }) {
  const { id } = params
  const router = useRouter()
  const { data: customer, isLoading } = useSWR(['customer', id], () => api.getCustomer(id))
  const { data: tripsData } = useSWR(['trips-customer', id], () => api.getTrips(1, 10))

  if (isLoading) return <div className="p-8 text-slate-400">กำลังโหลด...</div>
  if (!customer) return <div className="p-8 text-slate-400">ไม่พบข้อมูลลูกค้า</div>

  const c = customer.data || customer

  return (
    <div className="max-w-4xl">
      <div className="flex items-center gap-3 mb-6">
        <Link href="/customers" className="text-slate-400 hover:text-slate-600 text-sm">← กลับ</Link>
        <h2 className="text-xl font-bold">👤 {c.name}</h2>
        <span className={`px-2 py-0.5 rounded text-xs ${c.status === 'active' ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>
          {c.status === 'active' ? 'Active' : 'Inactive'}
        </span>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
        {/* ข้อมูลทั่วไป */}
        <div className="bg-white rounded-xl border p-5">
          <h3 className="font-semibold text-slate-700 mb-4">ข้อมูลทั่วไป</h3>
          <div className="space-y-3 text-sm">
            <Row label="รหัสลูกค้า" value={c.customer_no} mono />
            <Row label="ชื่อ" value={c.name} />
            <Row label="บริษัท" value={c.company || '-'} />
            <Row label="เบอร์โทร" value={c.phone || '-'} />
            <Row label="อีเมล" value={c.email || '-'} />
            <Row label="LINE ID" value={c.line_user_id ? `✅ ${c.line_user_id}` : '❌ ยังไม่เชื่อม'} />
            <Row label="ที่อยู่" value={c.address || '-'} />
          </div>
        </div>

        {/* สถิติ */}
        <div className="bg-white rounded-xl border p-5">
          <h3 className="font-semibold text-slate-700 mb-4">สถิติการใช้บริการ</h3>
          <div className="grid grid-cols-2 gap-4">
            <StatCard label="เที่ยวทั้งหมด" value={c.total_trips ?? 0} unit="เที่ยว" />
            <StatCard label="รายได้รวม" value={`฿${formatMoney(c.total_revenue)}`} />
            <StatCard label="เที่ยวที่แล้ว" value={formatDate(c.last_trip_date) || '-'} />
            <StatCard label="เครดิต" value={c.credit_limit ? `฿${formatMoney(c.credit_limit)}` : '-'} />
          </div>
          {c.notes && (
            <div className="mt-4 p-3 bg-yellow-50 rounded-lg text-sm text-yellow-800">
              📝 {c.notes}
            </div>
          )}
        </div>
      </div>

      {/* ผู้ติดต่อ */}
      {c.contacts?.length > 0 && (
        <div className="bg-white rounded-xl border p-5 mb-6">
          <h3 className="font-semibold text-slate-700 mb-4">ผู้ติดต่อ</h3>
          <div className="space-y-3">
            {c.contacts.map((contact: any, i: number) => (
              <div key={i} className="flex items-center gap-4 text-sm p-3 bg-slate-50 rounded-lg">
                <span className="font-medium">{contact.name}</span>
                <span className="text-slate-500">{contact.position || ''}</span>
                <span className="text-blue-600">{contact.phone}</span>
                {contact.is_primary && <span className="px-1.5 py-0.5 bg-blue-100 text-blue-700 rounded text-xs">หลัก</span>}
              </div>
            ))}
          </div>
        </div>
      )}

      {/* เที่ยววิ่งล่าสุด */}
      <div className="bg-white rounded-xl border overflow-hidden">
        <div className="px-5 py-4 border-b">
          <h3 className="font-semibold text-slate-700">เที่ยววิ่งล่าสุด</h3>
        </div>
        <table className="w-full text-sm">
          <thead className="bg-slate-50 border-b">
            <tr>
              <th className="px-4 py-3 text-left text-slate-500">เลขที่</th>
              <th className="px-4 py-3 text-left text-slate-500">สถานะ</th>
              <th className="px-4 py-3 text-left text-slate-500">ต้นทาง</th>
              <th className="px-4 py-3 text-left text-slate-500">สินค้า</th>
              <th className="px-4 py-3 text-left text-slate-500">รายได้</th>
              <th className="px-4 py-3 text-left text-slate-500">วันที่</th>
            </tr>
          </thead>
          <tbody>
            {tripsData?.data?.slice(0, 10).map((t: any) => {
              const st = TRIP_STATUS[t.status] || { label: t.status, color: 'bg-gray-100' }
              return (
                <tr key={t.id} className="border-b hover:bg-blue-50/50 cursor-pointer" onClick={() => router.push(`/trips/${t.id}`)}>
                  <td className="px-4 py-3 font-mono text-xs">{t.trip_no || t.id?.slice(-8)}</td>
                  <td className="px-4 py-3"><span className={`px-2 py-0.5 rounded text-xs ${st.color}`}>{st.label}</span></td>
                  <td className="px-4 py-3">{t.origin_name || '-'}</td>
                  <td className="px-4 py-3 truncate max-w-[150px]">{t.cargo_description || '-'}</td>
                  <td className="px-4 py-3 text-green-600">฿{formatMoney(t.revenue)}</td>
                  <td className="px-4 py-3 text-slate-500">{formatDate(t.planned_start)}</td>
                </tr>
              )
            })}
            {!tripsData?.data?.length && (
              <tr><td colSpan={6} className="px-4 py-8 text-center text-slate-400">ยังไม่มีเที่ยววิ่ง</td></tr>
            )}
          </tbody>
        </table>
      </div>
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

function StatCard({ label, value, unit }: { label: string; value: any; unit?: string }) {
  return (
    <div className="bg-slate-50 rounded-lg p-3">
      <div className="text-xs text-slate-500 mb-1">{label}</div>
      <div className="font-semibold text-slate-800">{value} {unit && <span className="text-xs font-normal text-slate-500">{unit}</span>}</div>
    </div>
  )
}
