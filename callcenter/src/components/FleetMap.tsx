'use client'
import 'leaflet/dist/leaflet.css'
import { useState, useMemo, useEffect } from 'react'
import { MapContainer, TileLayer, Marker, Polyline, Tooltip, useMap } from 'react-leaflet'
import L from 'leaflet'
import useSWR from 'swr'
import { api } from '@/lib/api'

// ============ Types ============
interface VehicleOnMap {
  vehicle_id: string
  plate: string
  type: string
  status: string         // 'active' | 'maintenance' | 'inactive'
  lat: number
  lng: number
  speed_kmh: number
  heading: number
  battery_pct: number
  updated_at: string
  trip_id: string | null
  driver_id: string | null
  driver_name?: string
  driver_phone?: string
  trip_no?: string
  trip_status?: string
  origin_name?: string
  origin_lat?: number
  origin_lng?: number
}

type FilterStatus = 'all' | 'moving' | 'parked' | 'maintenance'

// ============ Icon helpers ============
function createVehicleIcon(v: VehicleOnMap, selected: boolean): L.DivIcon {
  const isMoving = (v.speed_kmh ?? 0) > 5
  const bg = v.status === 'maintenance' ? '#f97316'
    : isMoving ? '#22c55e'
    : '#94a3b8'
  const ring = selected ? '4px solid #3b82f6' : '3px solid white'
  const shadow = selected
    ? '0 0 0 3px rgba(59,130,246,0.4), 0 3px 10px rgba(0,0,0,0.4)'
    : '0 2px 8px rgba(0,0,0,0.3)'
  const speedBadge = isMoving
    ? `<div style="position:absolute;top:-10px;right:-10px;background:#1d4ed8;color:white;border-radius:99px;padding:1px 5px;font-size:9px;font-weight:700;white-space:nowrap;line-height:1.4">${Math.round(v.speed_kmh)}</div>`
    : ''

  return L.divIcon({
    html: `<div style="position:relative;width:36px;height:36px;border-radius:50%;background:${bg};border:${ring};box-shadow:${shadow};display:flex;align-items:center;justify-content:center;font-size:17px;cursor:pointer;transition:all 0.2s">🚛${speedBadge}</div>`,
    className: '',
    iconSize: [36, 36],
    iconAnchor: [18, 18],
  })
}

const originIcon = L.divIcon({
  html: `<div style="background:#3b82f6;color:white;border-radius:50%;width:30px;height:30px;display:flex;align-items:center;justify-content:center;border:2px solid white;box-shadow:0 2px 6px rgba(0,0,0,0.3);font-size:14px">📥</div>`,
  className: '', iconSize: [30, 30], iconAnchor: [15, 15],
})

const destIcon = L.divIcon({
  html: `<div style="background:#16a34a;color:white;border-radius:50%;width:30px;height:30px;display:flex;align-items:center;justify-content:center;border:2px solid white;box-shadow:0 2px 6px rgba(0,0,0,0.3);font-size:14px">📤</div>`,
  className: '', iconSize: [30, 30], iconAnchor: [15, 15],
})

// ============ Trip layer (origin marker + route line) ============
function TripLayer({ vehicle: v }: { vehicle: VehicleOnMap }) {
  return (
    <>
      <Marker position={[v.origin_lat!, v.origin_lng!]} icon={originIcon}>
        <Tooltip direction="top" offset={[0, -18]} opacity={0.9}>
          <div className="text-xs font-medium">📥 {v.origin_name ?? 'ต้นทาง'}</div>
          <div className="text-xs text-gray-500">{v.plate}</div>
        </Tooltip>
      </Marker>
      <Polyline
        positions={[[v.origin_lat!, v.origin_lng!], [v.lat, v.lng]]}
        pathOptions={{ color: '#3b82f6', weight: 2, dashArray: '6 4', opacity: 0.7 }}
      />
    </>
  )
}

// ============ FlyTo helper ============
function FlyToVehicle({ vehicle }: { vehicle: VehicleOnMap | null }) {
  const map = useMap()
  useEffect(() => {
    if (vehicle?.lat && vehicle?.lng) {
      map.flyTo([vehicle.lat, vehicle.lng], 14, { duration: 1.2 })
    }
  }, [vehicle?.vehicle_id]) // eslint-disable-line
  return null
}

// ============ Helpers ============
function headingArrow(h: number): string {
  const dirs = ['↑', '↗', '→', '↘', '↓', '↙', '←', '↖']
  return dirs[Math.round(h / 45) % 8]
}

function timeSince(dt: string | null): string {
  if (!dt) return '-'
  const s = Math.floor((Date.now() - new Date(dt).getTime()) / 1000)
  if (s < 60) return `${s}s ago`
  if (s < 3600) return `${Math.floor(s / 60)}m ago`
  return `${Math.floor(s / 3600)}h ago`
}

// ============ Main component ============
export default function FleetMap() {
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const [filter, setFilter] = useState<FilterStatus>('all')
  const [onlyWithTrip, setOnlyWithTrip] = useState(false)
  const [panelOpen, setPanelOpen] = useState(true)

  // Data fetching
  const { data: locData } = useSWR('loc', () => api.getVehicleLocations(), { refreshInterval: 10000 })
  const { data: vehData } = useSWR('veh-all', () => api.getVehicles(1, 200), { refreshInterval: 30000 })
  const { data: drvData } = useSWR('drv-all', () => api.getDrivers(1, 200), { refreshInterval: 60000 })
  const { data: tripData } = useSWR('trips-active', () => api.getTrips(1, 100, 'started'), { refreshInterval: 20000 })

  // Build lookup maps
  const vehicleMap = useMemo(() => {
    const m = new Map<string, any>()
    ;(vehData?.data ?? []).forEach((v: any) => m.set(v.id, v))
    return m
  }, [vehData])

  const driverMap = useMemo(() => {
    const m = new Map<string, any>()
    ;(drvData?.data ?? []).forEach((d: any) => m.set(d.id, d))
    return m
  }, [drvData])

  const tripMap = useMemo(() => {
    const m = new Map<string, any>()
    ;(tripData?.data ?? []).forEach((t: any) => { if (t.vehicle_id) m.set(t.vehicle_id, t) })
    return m
  }, [tripData])

  // Merge into VehicleOnMap[]
  const vehicles = useMemo<VehicleOnMap[]>(() => {
    const locs: any[] = locData?.data ?? locData ?? []
    return locs
      .filter((l: any) => l.lat != null && l.lng != null)
      .map((l: any) => {
        const veh = vehicleMap.get(l.vehicle_id) ?? {}
        const drv = driverMap.get(l.driver_id ?? veh.current_driver_id ?? '')
        const trip = tripMap.get(l.vehicle_id)
        return {
          vehicle_id: l.vehicle_id,
          plate: veh.plate ?? l.vehicle_id?.slice(-6) ?? '—',
          type: veh.type ?? '—',
          status: veh.status ?? 'active',
          lat: l.lat,
          lng: l.lng,
          speed_kmh: l.speed_kmh ?? 0,
          heading: l.heading ?? 0,
          battery_pct: l.battery_pct ?? null,
          updated_at: l.updated_at ?? null,
          trip_id: l.trip_id ?? null,
          driver_id: l.driver_id ?? veh.current_driver_id ?? null,
          driver_name: drv?.name ?? null,
          driver_phone: drv?.phone ?? null,
          trip_no: trip?.trip_no ?? null,
          trip_status: trip?.status ?? null,
          origin_name: trip?.origin_name ?? null,
          origin_lat: trip?.origin_lat ?? null,
          origin_lng: trip?.origin_lng ?? null,
        } as VehicleOnMap
      })
  }, [locData, vehicleMap, driverMap, tripMap])

  // Filter
  const filtered = useMemo(() => {
    return vehicles.filter(v => {
      if (onlyWithTrip && !v.trip_id) return false
      if (filter === 'moving') return (v.speed_kmh ?? 0) > 5
      if (filter === 'parked') return (v.speed_kmh ?? 0) <= 5 && v.status !== 'maintenance'
      if (filter === 'maintenance') return v.status === 'maintenance'
      return true
    })
  }, [vehicles, filter, onlyWithTrip])

  const selectedVehicle = useMemo(
    () => vehicles.find(v => v.vehicle_id === selectedId) ?? null,
    [vehicles, selectedId]
  )

  // Count per status
  const counts = useMemo(() => ({
    all: vehicles.length,
    moving: vehicles.filter(v => (v.speed_kmh ?? 0) > 5).length,
    parked: vehicles.filter(v => (v.speed_kmh ?? 0) <= 5 && v.status !== 'maintenance').length,
    maintenance: vehicles.filter(v => v.status === 'maintenance').length,
  }), [vehicles])

  const CHIPS: { key: FilterStatus; label: string; color: string }[] = [
    { key: 'all', label: 'ทั้งหมด', color: 'bg-slate-700 text-white' },
    { key: 'moving', label: 'กำลังวิ่ง', color: 'bg-green-600 text-white' },
    { key: 'parked', label: 'จอด', color: 'bg-slate-400 text-white' },
    { key: 'maintenance', label: 'ซ่อม', color: 'bg-orange-500 text-white' },
  ]

  return (
    <div className="flex h-full bg-slate-900">
      {/* ===== Left Panel ===== */}
      {panelOpen && (
        <div className="w-72 bg-white flex flex-col shrink-0 border-r border-slate-200 overflow-hidden">
          {/* Header */}
          <div className="px-4 py-3 border-b bg-slate-50 flex items-center justify-between">
            <span className="font-semibold text-sm">🗺️ แผนที่รถ</span>
            <button onClick={() => setPanelOpen(false)} className="text-slate-400 hover:text-slate-600 text-lg leading-none">×</button>
          </div>

          {/* Filter chips */}
          <div className="px-3 py-3 border-b space-y-2">
            <div className="flex flex-wrap gap-1.5">
              {CHIPS.map(c => (
                <button
                  key={c.key}
                  onClick={() => setFilter(c.key)}
                  className={`px-2.5 py-1 rounded-full text-xs font-medium transition-opacity ${filter === c.key ? c.color : 'bg-slate-100 text-slate-600 hover:bg-slate-200'}`}
                >
                  {c.label} <span className="ml-0.5 opacity-80">{counts[c.key]}</span>
                </button>
              ))}
            </div>
            <label className="flex items-center gap-2 text-xs text-slate-600 cursor-pointer">
              <input type="checkbox" checked={onlyWithTrip} onChange={e => setOnlyWithTrip(e.target.checked)} className="rounded" />
              แสดงเฉพาะรถที่มีเที่ยว
            </label>
          </div>

          {/* Vehicle list */}
          <div className="flex-1 overflow-y-auto">
            {filtered.length === 0 && (
              <p className="text-center text-slate-400 text-sm py-8">ไม่พบรถ</p>
            )}
            {filtered.map(v => {
              const isMoving = (v.speed_kmh ?? 0) > 5
              const dot = v.status === 'maintenance' ? 'bg-orange-400'
                : isMoving ? 'bg-green-400 animate-pulse' : 'bg-slate-300'
              const isSelected = v.vehicle_id === selectedId

              return (
                <div
                  key={v.vehicle_id}
                  onClick={() => setSelectedId(v.vehicle_id === selectedId ? null : v.vehicle_id)}
                  className={`px-4 py-3 border-b cursor-pointer transition-colors ${isSelected ? 'bg-blue-50 border-l-2 border-blue-500' : 'hover:bg-slate-50'}`}
                >
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <span className={`w-2 h-2 rounded-full shrink-0 ${dot}`} />
                      <span className="font-semibold text-sm">{v.plate}</span>
                    </div>
                    {isMoving && (
                      <span className="text-xs font-bold text-green-600 bg-green-50 px-1.5 py-0.5 rounded">
                        {Math.round(v.speed_kmh)} km/h
                      </span>
                    )}
                  </div>
                  <div className="mt-0.5 text-xs text-slate-500 flex items-center justify-between">
                    <span>{v.driver_name ?? '— ไม่มีคนขับ'}</span>
                    <span className="text-slate-300">{v.type}</span>
                  </div>
                  {v.trip_no && (
                    <div className="mt-1 text-xs text-blue-600 bg-blue-50 px-1.5 py-0.5 rounded inline-block">
                      {v.trip_no}
                    </div>
                  )}
                </div>
              )
            })}
          </div>

          {/* Footer */}
          <div className="px-4 py-2 text-xs text-slate-400 border-t">
            รีเฟรชทุก 10 วินาที
          </div>
        </div>
      )}

      {/* ===== Map Area ===== */}
      <div className="flex-1 relative">
        {/* Toggle panel button */}
        {!panelOpen && (
          <button
            onClick={() => setPanelOpen(true)}
            className="absolute top-3 left-3 z-[1000] bg-white rounded-lg shadow px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
          >
            ☰ รายการรถ ({filtered.length})
          </button>
        )}

        <MapContainer
          center={[18.79, 98.98]}
          zoom={11}
          style={{ height: '100%', width: '100%' }}
          zoomControl={true}
        >
          <TileLayer
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
          />
          <FlyToVehicle vehicle={selectedVehicle} />

          {/* Vehicle markers */}
          {filtered.map(v => (
            <Marker
              key={v.vehicle_id}
              position={[v.lat, v.lng]}
              icon={createVehicleIcon(v, v.vehicle_id === selectedId)}
              eventHandlers={{ click: () => setSelectedId(v.vehicle_id === selectedId ? null : v.vehicle_id) }}
            >
              <Tooltip direction="top" offset={[0, -20]} opacity={0.9}>
                <div className="text-xs font-medium">{v.plate} {v.speed_kmh > 5 ? `• ${Math.round(v.speed_kmh)} km/h` : '• จอด'}</div>
                {v.driver_name && <div className="text-xs text-gray-600">{v.driver_name}</div>}
              </Tooltip>
            </Marker>
          ))}

          {/* Active trip overlays */}
          {filtered
            .filter(v => v.origin_lat && v.origin_lng)
            .map(v => (
              <TripLayer key={`trip-${v.vehicle_id}`} vehicle={v} />
            ))}
        </MapContainer>

        {/* ===== Selected Vehicle Detail Panel ===== */}
        {selectedVehicle && (
          <div className="absolute top-4 right-4 z-[1000] w-72 bg-white rounded-2xl shadow-2xl border border-slate-200 overflow-hidden">
            {/* Header */}
            <div className={`px-4 py-3 text-white flex items-center justify-between ${
              selectedVehicle.status === 'maintenance' ? 'bg-orange-500'
              : (selectedVehicle.speed_kmh ?? 0) > 5 ? 'bg-green-600'
              : 'bg-slate-500'
            }`}>
              <div>
                <div className="font-bold text-lg">{selectedVehicle.plate}</div>
                <div className="text-xs opacity-80">{selectedVehicle.type}</div>
              </div>
              <button onClick={() => setSelectedId(null)} className="text-white/70 hover:text-white text-xl leading-none">×</button>
            </div>

            <div className="p-4 space-y-3 text-sm">
              {/* Status */}
              <div className="flex items-center gap-3">
                <span className="text-2xl">
                  {selectedVehicle.status === 'maintenance' ? '🟠'
                   : (selectedVehicle.speed_kmh ?? 0) > 5 ? '🟢'
                   : '⚫'}
                </span>
                <div>
                  <div className="font-semibold">
                    {selectedVehicle.status === 'maintenance' ? 'กำลังซ่อม'
                     : (selectedVehicle.speed_kmh ?? 0) > 5 ? `กำลังวิ่ง ${Math.round(selectedVehicle.speed_kmh)} km/h`
                     : 'จอดอยู่'}
                  </div>
                  <div className="text-xs text-slate-500">
                    {headingArrow(selectedVehicle.heading)} ทิศ {selectedVehicle.heading}° &bull; อัปเดต {timeSince(selectedVehicle.updated_at)}
                  </div>
                </div>
              </div>

              {/* Driver */}
              <div className="flex items-start gap-2 p-3 bg-slate-50 rounded-xl">
                <span className="text-lg">👤</span>
                <div className="flex-1 min-w-0">
                  <div className="font-medium truncate">{selectedVehicle.driver_name ?? '— ไม่มีคนขับ'}</div>
                  {selectedVehicle.driver_phone && (
                    <a href={`tel:${selectedVehicle.driver_phone}`} className="text-xs text-blue-600 hover:underline">
                      📞 {selectedVehicle.driver_phone}
                    </a>
                  )}
                </div>
              </div>

              {/* Trip */}
              {selectedVehicle.trip_id ? (
                <div className="p-3 bg-blue-50 rounded-xl">
                  <div className="text-xs text-blue-500 font-medium mb-1">เที่ยวปัจจุบัน</div>
                  <div className="font-semibold text-blue-800">{selectedVehicle.trip_no ?? 'กำลังดำเนินการ'}</div>
                  {selectedVehicle.origin_name && (
                    <div className="text-xs text-blue-600 mt-1 truncate">📍 {selectedVehicle.origin_name}</div>
                  )}
                </div>
              ) : (
                <div className="p-3 bg-slate-50 rounded-xl text-slate-400 text-xs">ไม่มีเที่ยวในขณะนี้</div>
              )}

              {/* GPS Info */}
              <div className="grid grid-cols-3 gap-2 text-xs">
                <div className="bg-slate-50 rounded-lg p-2 text-center">
                  <div className="text-slate-500">lat</div>
                  <div className="font-mono font-medium">{selectedVehicle.lat.toFixed(4)}</div>
                </div>
                <div className="bg-slate-50 rounded-lg p-2 text-center">
                  <div className="text-slate-500">lng</div>
                  <div className="font-mono font-medium">{selectedVehicle.lng.toFixed(4)}</div>
                </div>
                <div className="bg-slate-50 rounded-lg p-2 text-center">
                  <div className="text-slate-500">🔋</div>
                  <div className="font-medium">{selectedVehicle.battery_pct != null ? `${selectedVehicle.battery_pct}%` : '—'}</div>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Legend */}
        <div className="absolute bottom-6 right-4 z-[1000] bg-white rounded-xl shadow px-3 py-2 text-xs text-slate-600 space-y-1">
          <div className="flex items-center gap-2"><span className="w-3 h-3 rounded-full bg-green-500 inline-block" /> กำลังวิ่ง</div>
          <div className="flex items-center gap-2"><span className="w-3 h-3 rounded-full bg-slate-400 inline-block" /> จอด</div>
          <div className="flex items-center gap-2"><span className="w-3 h-3 rounded-full bg-orange-400 inline-block" /> ซ่อม</div>
          <div className="flex items-center gap-2"><span className="text-sm">📥</span> รับสินค้า</div>
          <div className="flex items-center gap-2"><span className="text-sm">📤</span> ส่งสินค้า</div>
        </div>
      </div>
    </div>
  )
}
