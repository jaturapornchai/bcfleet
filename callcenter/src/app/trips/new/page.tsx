'use client'
import { useState, useEffect } from 'react'
import { api } from '@/lib/api'
import { formatMoney } from '@/lib/constants'

export default function NewTripPage() {
  const [vehicles, setVehicles] = useState<any[]>([])
  const [drivers, setDrivers] = useState<any[]>([])
  const [form, setForm] = useState({
    origin_name: '', origin_lat: '', origin_lng: '',
    dest_name: '', dest_lat: '', dest_lng: '',
    cargo_description: '', cargo_weight_kg: '',
    vehicle_id: '', driver_id: '',
    planned_start: '', planned_end: '',
    revenue: '',
  })
  const [route, setRoute] = useState<any>(null)
  const [calcLoading, setCalcLoading] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    api.getVehicles(1, 100).then((r: any) => setVehicles(r.data || []))
    api.getDrivers(1, 100).then((r: any) => setDrivers(r.data || []))
  }, [])

  const set = (k: string, v: string) => setForm(f => ({ ...f, [k]: v }))

  const calcRoute = async () => {
    if (!form.origin_lat || !form.dest_lat) {
      setError('กรุณากรอกพิกัด GPS ต้นทางและปลายทาง'); return
    }
    setCalcLoading(true); setError('')
    try {
      const result = await api.calculateRoute({
        origin: { lat: parseFloat(form.origin_lat), lng: parseFloat(form.origin_lng) },
        destination: { lat: parseFloat(form.dest_lat), lng: parseFloat(form.dest_lng) },
      })
      setRoute(result.data || result)
    } catch (err: any) {
      setError('คำนวณเส้นทางไม่ได้: ' + err.message)
    } finally {
      setCalcLoading(false)
    }
  }

  const submit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!form.origin_name || !form.dest_name) { setError('กรุณากรอกต้นทางและปลายทาง'); return }
    setLoading(true); setError('')
    try {
      const payload = {
        origin: {
          name: form.origin_name,
          lat: form.origin_lat ? parseFloat(form.origin_lat) : null,
          lng: form.origin_lng ? parseFloat(form.origin_lng) : null,
        },
        destinations: [{
          seq: 1,
          name: form.dest_name,
          lat: form.dest_lat ? parseFloat(form.dest_lat) : null,
          lng: form.dest_lng ? parseFloat(form.dest_lng) : null,
          status: 'pending',
        }],
        cargo: {
          description: form.cargo_description,
          weight_kg: form.cargo_weight_kg ? parseInt(form.cargo_weight_kg) : null,
        },
        vehicle_id: form.vehicle_id || null,
        driver_id: form.driver_id || null,
        planned_start: form.planned_start || null,
        planned_end: form.planned_end || null,
        revenue: form.revenue ? parseFloat(form.revenue) : null,
        distance_km: route?.distance_km || null,
      }
      await api.createTrip(payload)
      window.location.href = '/trips'
    } catch (err: any) {
      setError(err.message || 'เกิดข้อผิดพลาด')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="max-w-2xl">
      <div className="flex items-center gap-3 mb-6">
        <a href="/trips" className="text-slate-400 hover:text-slate-600 text-sm">← กลับ</a>
        <h2 className="text-xl font-bold">📋 สร้างเที่ยววิ่งใหม่</h2>
      </div>

      <form onSubmit={submit} className="space-y-6">
        {error && <div className="p-3 bg-red-50 text-red-700 rounded-lg text-sm">{error}</div>}

        {/* ต้นทาง */}
        <div className="bg-white rounded-xl border p-5 space-y-4">
          <h3 className="font-semibold text-slate-700">📍 ต้นทาง</h3>
          <Field label="ชื่อสถานที่ *" value={form.origin_name} onChange={v => set('origin_name', v)} placeholder="คลังสินค้า ABC เชียงใหม่" />
          <div className="grid grid-cols-2 gap-3">
            <Field label="Latitude" value={form.origin_lat} onChange={v => set('origin_lat', v)} placeholder="18.7883" type="number" />
            <Field label="Longitude" value={form.origin_lng} onChange={v => set('origin_lng', v)} placeholder="98.9853" type="number" />
          </div>
        </div>

        {/* ปลายทาง */}
        <div className="bg-white rounded-xl border p-5 space-y-4">
          <h3 className="font-semibold text-slate-700">🏁 ปลายทาง</h3>
          <Field label="ชื่อสถานที่ *" value={form.dest_name} onChange={v => set('dest_name', v)} placeholder="ร้าน XYZ วัสดุ ลำพูน" />
          <div className="grid grid-cols-2 gap-3">
            <Field label="Latitude" value={form.dest_lat} onChange={v => set('dest_lat', v)} placeholder="18.5741" type="number" />
            <Field label="Longitude" value={form.dest_lng} onChange={v => set('dest_lng', v)} placeholder="98.9847" type="number" />
          </div>
          <button type="button" onClick={calcRoute} disabled={calcLoading}
            className="w-full py-2 border-2 border-dashed border-blue-300 rounded-lg text-sm text-blue-600 hover:bg-blue-50 disabled:opacity-50">
            {calcLoading ? 'กำลังคำนวณ...' : '🗺️ คำนวณเส้นทาง (OSRM)'}
          </button>
          {route && (
            <div className="p-3 bg-blue-50 rounded-lg text-sm grid grid-cols-2 gap-2">
              <div><span className="text-slate-500">ระยะทาง: </span><strong>{route.distance_km} กม.</strong></div>
              <div><span className="text-slate-500">เวลา: </span><strong>~{route.duration_minutes} นาที</strong></div>
            </div>
          )}
        </div>

        {/* สินค้า */}
        <div className="bg-white rounded-xl border p-5 space-y-4">
          <h3 className="font-semibold text-slate-700">📦 สินค้า</h3>
          <Field label="รายละเอียดสินค้า" value={form.cargo_description} onChange={v => set('cargo_description', v)} placeholder="ปูนซีเมนต์ 200 ถุง" />
          <Field label="น้ำหนัก (กก.)" value={form.cargo_weight_kg} onChange={v => set('cargo_weight_kg', v)} placeholder="10000" type="number" />
        </div>

        {/* รถและคนขับ */}
        <div className="bg-white rounded-xl border p-5 space-y-4">
          <h3 className="font-semibold text-slate-700">🚛 รถและคนขับ</h3>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm text-slate-600 mb-1">รถ</label>
              <select value={form.vehicle_id} onChange={e => set('vehicle_id', e.target.value)}
                className="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:border-blue-400">
                <option value="">-- เลือกรถ --</option>
                {vehicles.map((v: any) => (
                  <option key={v.id} value={v.id}>{v.plate} ({v.type})</option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-sm text-slate-600 mb-1">คนขับ</label>
              <select value={form.driver_id} onChange={e => set('driver_id', e.target.value)}
                className="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:border-blue-400">
                <option value="">-- เลือกคนขับ --</option>
                {drivers.map((d: any) => (
                  <option key={d.id} value={d.id}>{d.name} ({d.score ?? 0} คะแนน)</option>
                ))}
              </select>
            </div>
          </div>
        </div>

        {/* เวลาและค่าขนส่ง */}
        <div className="bg-white rounded-xl border p-5 space-y-4">
          <h3 className="font-semibold text-slate-700">⏰ เวลาและค่าขนส่ง</h3>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm text-slate-600 mb-1">วันเวลาออก</label>
              <input type="datetime-local" value={form.planned_start} onChange={e => set('planned_start', e.target.value)}
                className="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:border-blue-400" />
            </div>
            <div>
              <label className="block text-sm text-slate-600 mb-1">วันเวลาถึง</label>
              <input type="datetime-local" value={form.planned_end} onChange={e => set('planned_end', e.target.value)}
                className="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:border-blue-400" />
            </div>
          </div>
          <Field label="ค่าขนส่ง (บาท)" value={form.revenue} onChange={v => set('revenue', v)} placeholder="2500" type="number" />
        </div>

        <div className="flex gap-3">
          <button type="submit" disabled={loading}
            className="flex-1 bg-blue-600 text-white py-3 rounded-xl font-medium hover:bg-blue-700 disabled:opacity-50">
            {loading ? 'กำลังสร้าง...' : '🚚 สร้างเที่ยววิ่ง'}
          </button>
          <a href="/trips" className="px-6 py-3 border rounded-xl text-slate-600 hover:bg-slate-50 text-center">ยกเลิก</a>
        </div>
      </form>
    </div>
  )
}

function Field({ label, value, onChange, placeholder, type = 'text' }: {
  label: string; value: string; onChange: (v: string) => void;
  placeholder?: string; type?: string
}) {
  return (
    <div>
      <label className="block text-sm text-slate-600 mb-1">{label}</label>
      <input type={type} value={value} onChange={e => onChange(e.target.value)} placeholder={placeholder}
        className="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:border-blue-400" />
    </div>
  )
}
