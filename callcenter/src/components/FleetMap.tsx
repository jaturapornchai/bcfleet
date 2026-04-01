'use client'
import 'leaflet/dist/leaflet.css'
import { useState, useMemo, useEffect, useCallback } from 'react'
import { MapContainer, TileLayer, Marker, Polyline, Tooltip, useMap } from 'react-leaflet'
import L from 'leaflet'
import useSWR from 'swr'
import { api } from '@/lib/api'

// ============ Types ============
interface VehicleOnMap {
  vehicle_id: string; plate: string; type: string; status: string
  lat: number; lng: number; speed_kmh: number; heading: number
  battery_pct: number | null; updated_at: string | null
  trip_id: string | null; driver_id: string | null
  driver_name?: string | null; driver_phone?: string | null
  trip_no?: string | null; trip_status?: string | null
  origin_name?: string | null; origin_lat?: number | null; origin_lng?: number | null
  dest_name?: string | null; dest_lat?: number | null; dest_lng?: number | null
  planned_end?: string | null; distance_km?: number | null
}

type FilterStatus = 'all' | 'moving' | 'parked' | 'maintenance'
type MapLayer = 'osm' | 'satellite' | 'traffic'

// ============ Haversine ETA ============
function haversineKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const R = 6371
  const dLat = (lat2 - lat1) * Math.PI / 180
  const dLng = (lng2 - lng1) * Math.PI / 180
  const a = Math.sin(dLat / 2) ** 2 + Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * Math.sin(dLng / 2) ** 2
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
}

function calcETA(v: VehicleOnMap): { km: number; minutes: number; label: string } | null {
  if (!v.dest_lat || !v.dest_lng) return null
  const km = haversineKm(v.lat, v.lng, v.dest_lat, v.dest_lng)
  const speed = (v.speed_kmh ?? 0) > 10 ? v.speed_kmh : 40
  const minutes = Math.round((km / speed) * 60)
  const h = Math.floor(minutes / 60)
  const m = minutes % 60
  const label = h > 0 ? `${h}ชม. ${m}น.` : `${m} นาที`
  return { km: Math.round(km * 10) / 10, minutes, label }
}

// ============ Traffic simulation from vehicle speed data ============
function getTrafficInfo(vehicles: VehicleOnMap[]): { color: string; label: string } {
  if (vehicles.length === 0) return { color: '#94a3b8', label: 'ไม่มีข้อมูล' }
  const movingCount = vehicles.filter(v => (v.speed_kmh ?? 0) > 5).length
  const ratio = movingCount / vehicles.length
  if (ratio < 0.3) return { color: '#ef4444', label: 'ติดมาก' }
  if (ratio < 0.6) return { color: '#f97316', label: 'ค่อนข้างติด' }
  return { color: '#22c55e', label: 'คล่องตัว' }
}

// ============ Icon helpers ============
function createVehicleIcon(v: VehicleOnMap, selected: boolean): L.DivIcon {
  const isMoving = (v.speed_kmh ?? 0) > 5
  const bg = v.status === 'maintenance' ? '#f97316' : isMoving ? '#22c55e' : '#94a3b8'
  const ring = selected ? '4px solid #3b82f6' : '3px solid white'
  const shadow = selected
    ? '0 0 0 3px rgba(59,130,246,0.4), 0 3px 10px rgba(0,0,0,0.4)'
    : '0 2px 8px rgba(0,0,0,0.3)'
  const badge = isMoving
    ? `<div style="position:absolute;top:-10px;right:-10px;background:#1d4ed8;color:white;border-radius:99px;padding:1px 5px;font-size:9px;font-weight:700;white-space:nowrap;line-height:1.4">${Math.round(v.speed_kmh)}</div>`
    : ''
  return L.divIcon({
    html: `<div style="position:relative;width:36px;height:36px;border-radius:50%;background:${bg};border:${ring};box-shadow:${shadow};display:flex;align-items:center;justify-content:center;font-size:17px;cursor:pointer">🚛${badge}</div>`,
    className: '',
    iconSize: [36, 36],
    iconAnchor: [18, 18],
  })
}

function mkPointIcon(emoji: string, bg: string): L.DivIcon {
  return L.divIcon({
    html: `<div style="background:${bg};color:white;border-radius:50%;width:28px;height:28px;display:flex;align-items:center;justify-content:center;border:2px solid white;box-shadow:0 2px 6px rgba(0,0,0,0.3);font-size:13px">${emoji}</div>`,
    className: '',
    iconSize: [28, 28],
    iconAnchor: [14, 14],
  })
}

// ============ Sub-components ============
function FlyToVehicle({ vehicle }: { vehicle: VehicleOnMap | null }) {
  const map = useMap()
  useEffect(() => {
    if (vehicle?.lat && vehicle?.lng) map.flyTo([vehicle.lat, vehicle.lng], 14, { duration: 1.2 })
  }, [vehicle?.vehicle_id]) // eslint-disable-line
  return null
}

function TripLayer({ vehicle: v }: { vehicle: VehicleOnMap }) {
  return (
    <>
      <Marker position={[v.origin_lat!, v.origin_lng!]} icon={mkPointIcon('📥', '#3b82f6')}>
        <Tooltip direction="top" offset={[0, -16]} opacity={0.95}>
          <div style={{ fontSize: 12, fontWeight: 600 }}>📥 {v.origin_name ?? 'ต้นทาง'}</div>
          <div style={{ fontSize: 11, color: '#6b7280' }}>{v.plate}</div>
        </Tooltip>
      </Marker>
      {v.dest_lat && v.dest_lng && (
        <Marker position={[v.dest_lat, v.dest_lng]} icon={mkPointIcon('📤', '#16a34a')}>
          <Tooltip direction="top" offset={[0, -16]} opacity={0.95}>
            <div style={{ fontSize: 12, fontWeight: 600 }}>📤 {v.dest_name ?? 'ปลายทาง'}</div>
          </Tooltip>
        </Marker>
      )}
      <Polyline
        positions={[[v.origin_lat!, v.origin_lng!], [v.lat, v.lng]]}
        pathOptions={{ color: '#3b82f6', weight: 2.5, dashArray: '8 4', opacity: 0.75 }}
      />
      {v.dest_lat && v.dest_lng && (
        <Polyline
          positions={[[v.lat, v.lng], [v.dest_lat, v.dest_lng]]}
          pathOptions={{ color: '#16a34a', weight: 2.5, dashArray: '4 4', opacity: 0.5 }}
        />
      )}
    </>
  )
}

// ============ Helpers ============
function headingArrow(h: number): string {
  const dirs = ['↑', '↗', '→', '↘', '↓', '↙', '←', '↖']
  return dirs[Math.round(h / 45) % 8]
}
function timeSince(dt: string | null): string {
  if (!dt) return '-'
  const s = Math.floor((Date.now() - new Date(dt).getTime()) / 1000)
  if (s < 60) return `${s}s`
  if (s < 3600) return `${Math.floor(s / 60)}m`
  return `${Math.floor(s / 3600)}h`
}

const TILE_URLS: Record<MapLayer, { url: string; attr: string; label: string }> = {
  osm: {
    url: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
    attr: '© OpenStreetMap',
    label: '🗺️ แผนที่',
  },
  satellite: {
    url: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    attr: '© Esri',
    label: '🛰️ ดาวเทียม',
  },
  traffic: {
    url: 'https://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png',
    attr: '© OpenStreetMap FR',
    label: '🚦 จราจร',
  },
}

// ============ Main Component ============
export default function FleetMap() {
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const [filter, setFilter] = useState<FilterStatus>('all')
  const [onlyWithTrip, setOnlyWithTrip] = useState(false)
  const [panelOpen, setPanelOpen] = useState(true)
  const [mapLayer, setMapLayer] = useState<MapLayer>('osm')
  const [calling, setCalling] = useState(false)

  const { data: locData } = useSWR('loc', () => api.getVehicleLocations(), { refreshInterval: 10000 })
  const { data: vehData } = useSWR('veh-all', () => api.getVehicles(1, 200), { refreshInterval: 30000 })
  const { data: drvData } = useSWR('drv-all', () => api.getDrivers(1, 200), { refreshInterval: 60000 })
  const { data: tripStarted } = useSWR('trips-started', () => api.getTrips(1, 100, 'started'), { refreshInterval: 20000 })
  const { data: tripDeliv } = useSWR('trips-deliv', () => api.getTrips(1, 100, 'delivering'), { refreshInterval: 20000 })

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
    const all = [...(tripStarted?.data ?? []), ...(tripDeliv?.data ?? [])]
    all.forEach((t: any) => { if (t.vehicle_id) m.set(t.vehicle_id, t) })
    return m
  }, [tripStarted, tripDeliv])

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
          plate: veh.plate ?? '—',
          type: veh.type ?? '—',
          status: veh.status ?? 'active',
          lat: l.lat, lng: l.lng,
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
          dest_name: null,
          dest_lat: null,
          dest_lng: null,
          planned_end: trip?.planned_end ?? null,
          distance_km: trip?.distance_km ?? null,
        } as VehicleOnMap
      })
  }, [locData, vehicleMap, driverMap, tripMap])

  const filtered = useMemo(() => vehicles.filter(v => {
    if (onlyWithTrip && !v.trip_id) return false
    if (filter === 'moving') return (v.speed_kmh ?? 0) > 5
    if (filter === 'parked') return (v.speed_kmh ?? 0) <= 5 && v.status !== 'maintenance'
    if (filter === 'maintenance') return v.status === 'maintenance'
    return true
  }), [vehicles, filter, onlyWithTrip])

  const selectedVehicle = useMemo(
    () => vehicles.find(v => v.vehicle_id === selectedId) ?? null,
    [vehicles, selectedId]
  )
  const eta = useMemo(() => selectedVehicle ? calcETA(selectedVehicle) : null, [selectedVehicle])
  const traffic = useMemo(() => getTrafficInfo(vehicles), [vehicles])

  const counts = useMemo(() => ({
    all: vehicles.length,
    moving: vehicles.filter(v => (v.speed_kmh ?? 0) > 5).length,
    parked: vehicles.filter(v => (v.speed_kmh ?? 0) <= 5 && v.status !== 'maintenance').length,
    maintenance: vehicles.filter(v => v.status === 'maintenance').length,
  }), [vehicles])

  const handleCall = useCallback((phone: string) => {
    setCalling(true)
    setTimeout(() => setCalling(false), 2000)
    window.location.href = `tel:${phone}`
  }, [])

  const CHIPS: { key: FilterStatus; label: string; active: string }[] = [
    { key: 'all', label: 'ทั้งหมด', active: 'bg-slate-700 text-white' },
    { key: 'moving', label: '🟢 วิ่ง', active: 'bg-green-600 text-white' },
    { key: 'parked', label: '⚫ จอด', active: 'bg-slate-400 text-white' },
    { key: 'maintenance', label: '🟠 ซ่อม', active: 'bg-orange-500 text-white' },
  ]

  const tile = TILE_URLS[mapLayer]

  return (
    <div className="flex h-full bg-slate-900">
      {/* ===== Left Panel ===== */}
      {panelOpen && (
        <div className="w-72 bg-white flex flex-col shrink-0 border-r overflow-hidden">
          <div className="px-4 py-3 border-b bg-slate-50 flex items-center justify-between">
            <span className="font-semibold text-sm">🗺️ แผนที่รถ</span>
            <button onClick={() => setPanelOpen(false)} className="text-slate-400 hover:text-slate-600 text-lg leading-none">×</button>
          </div>

          {/* Traffic summary bar */}
          <div className="px-4 py-2 border-b flex items-center gap-2 text-xs">
            <span className="text-slate-500 font-medium">สภาพจราจร:</span>
            <span className="flex items-center gap-1">
              <span className="w-2.5 h-2.5 rounded-full inline-block" style={{ background: traffic.color }} />
              <span className="font-semibold" style={{ color: traffic.color }}>{traffic.label}</span>
            </span>
            <span className="text-slate-400 ml-auto">{counts.moving}/{counts.all} วิ่ง</span>
          </div>

          <div className="px-3 py-3 border-b space-y-2">
            <div className="flex flex-wrap gap-1.5">
              {CHIPS.map(c => (
                <button key={c.key} onClick={() => setFilter(c.key)}
                  className={`px-2.5 py-1 rounded-full text-xs font-medium transition-colors ${filter === c.key ? c.active : 'bg-slate-100 text-slate-600 hover:bg-slate-200'}`}>
                  {c.label} <span className="opacity-75">{counts[c.key]}</span>
                </button>
              ))}
            </div>
            <label className="flex items-center gap-2 text-xs text-slate-600 cursor-pointer">
              <input type="checkbox" checked={onlyWithTrip} onChange={e => setOnlyWithTrip(e.target.checked)} className="rounded" />
              แสดงเฉพาะรถที่มีเที่ยว
            </label>
          </div>

          <div className="flex-1 overflow-y-auto">
            {filtered.length === 0 && <p className="text-center text-slate-400 text-sm py-8">ไม่พบรถ</p>}
            {filtered.map(v => {
              const isMoving = (v.speed_kmh ?? 0) > 5
              const dot = v.status === 'maintenance' ? 'bg-orange-400'
                : isMoving ? 'bg-green-400 animate-pulse' : 'bg-slate-300'
              const isSelected = v.vehicle_id === selectedId
              const veta = calcETA(v)
              return (
                <div key={v.vehicle_id}
                  onClick={() => setSelectedId(v.vehicle_id === selectedId ? null : v.vehicle_id)}
                  className={`px-4 py-3 border-b cursor-pointer transition-colors ${isSelected ? 'bg-blue-50 border-l-2 border-blue-500' : 'hover:bg-slate-50'}`}>
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
                  <div className="mt-0.5 text-xs text-slate-500 flex justify-between">
                    <span>{v.driver_name ?? '— ไม่มีคนขับ'}</span>
                    <span className="text-slate-300">{v.type}</span>
                  </div>
                  {v.trip_no && <div className="mt-1 text-xs text-blue-600 bg-blue-50 px-1.5 py-0.5 rounded inline-block">{v.trip_no}</div>}
                  {veta && <div className="mt-1 text-xs text-emerald-600">⏱ ETA ~{veta.label} ({veta.km}km)</div>}
                </div>
              )
            })}
          </div>

          <div className="px-4 py-2 text-xs text-slate-400 border-t">รีเฟรชทุก 10 วินาที</div>
        </div>
      )}

      {/* ===== Map Area ===== */}
      <div className="flex-1 relative">
        {!panelOpen && (
          <button onClick={() => setPanelOpen(true)}
            className="absolute top-3 left-3 z-[1000] bg-white rounded-lg shadow px-3 py-2 text-sm font-medium hover:bg-slate-50">
            ☰ รายการรถ ({filtered.length})
          </button>
        )}

        {/* Map layer switcher */}
        <div className="absolute top-3 right-4 z-[1000] flex bg-white rounded-lg shadow overflow-hidden border">
          {(Object.keys(TILE_URLS) as MapLayer[]).map(k => (
            <button key={k} onClick={() => setMapLayer(k)}
              className={`px-3 py-1.5 text-xs font-medium transition-colors ${mapLayer === k ? 'bg-blue-600 text-white' : 'text-slate-600 hover:bg-slate-50'}`}>
              {TILE_URLS[k].label}
            </button>
          ))}
        </div>

        <MapContainer center={[18.79, 98.98]} zoom={11} style={{ height: '100%', width: '100%' }}>
          <TileLayer key={mapLayer} url={tile.url} attribution={tile.attr} />
          <FlyToVehicle vehicle={selectedVehicle} />

          {filtered.map(v => (
            <Marker key={v.vehicle_id} position={[v.lat, v.lng]}
              icon={createVehicleIcon(v, v.vehicle_id === selectedId)}
              eventHandlers={{ click: () => setSelectedId(v.vehicle_id === selectedId ? null : v.vehicle_id) }}>
              <Tooltip direction="top" offset={[0, -20]} opacity={0.92}>
                <div style={{ fontSize: 12, fontWeight: 600 }}>{v.plate} {v.speed_kmh > 5 ? `• ${Math.round(v.speed_kmh)} km/h` : '• จอด'}</div>
                {v.driver_name && <div style={{ fontSize: 11, color: '#6b7280' }}>{v.driver_name}</div>}
              </Tooltip>
            </Marker>
          ))}

          {filtered.filter(v => v.origin_lat && v.origin_lng).map(v => (
            <TripLayer key={`trip-${v.vehicle_id}`} vehicle={v} />
          ))}
        </MapContainer>

        {/* ===== Vehicle Detail Panel ===== */}
        {selectedVehicle && (
          <div className="absolute top-14 right-4 z-[1000] w-80 bg-white rounded-2xl shadow-2xl border overflow-hidden" style={{ maxHeight: 'calc(100vh - 130px)', overflowY: 'auto' }}>
            {/* Header */}
            <div className={`px-4 py-3 text-white flex items-center justify-between ${
              selectedVehicle.status === 'maintenance' ? 'bg-orange-500'
              : (selectedVehicle.speed_kmh ?? 0) > 5 ? 'bg-green-600' : 'bg-slate-600'
            }`}>
              <div>
                <div className="font-bold text-lg leading-tight">{selectedVehicle.plate}</div>
                <div className="text-xs opacity-75">{selectedVehicle.type}</div>
              </div>
              <button onClick={() => setSelectedId(null)} className="text-white/70 hover:text-white text-2xl leading-none w-8 h-8 flex items-center justify-center">×</button>
            </div>

            <div className="p-4 space-y-3">
              {/* ===== CALL BUTTON ===== */}
              {selectedVehicle.driver_phone ? (
                <button onClick={() => handleCall(selectedVehicle.driver_phone!)}
                  className={`w-full py-3 rounded-xl font-bold text-base flex items-center justify-center gap-2 transition-all shadow-md ${
                    calling ? 'bg-green-700 text-white scale-95' : 'bg-green-500 hover:bg-green-600 text-white hover:shadow-lg active:scale-95'
                  }`}>
                  <span className="text-xl">📞</span>
                  {calling ? 'กำลังโทร...' : 'โทรหาคนขับทันที'}
                </button>
              ) : (
                <div className="w-full py-3 rounded-xl bg-slate-100 text-slate-400 text-sm text-center">ไม่มีเบอร์คนขับ</div>
              )}

              {/* Status row */}
              <div className="flex items-center gap-2 text-sm">
                <span className="text-xl">
                  {selectedVehicle.status === 'maintenance' ? '🟠'
                   : (selectedVehicle.speed_kmh ?? 0) > 5 ? '🟢' : '⚫'}
                </span>
                <div>
                  <div className="font-semibold">
                    {selectedVehicle.status === 'maintenance' ? 'กำลังซ่อม'
                     : (selectedVehicle.speed_kmh ?? 0) > 5 ? `กำลังวิ่ง ${Math.round(selectedVehicle.speed_kmh)} km/h`
                     : 'จอดอยู่'}
                  </div>
                  <div className="text-xs text-slate-500">
                    {headingArrow(selectedVehicle.heading)} {selectedVehicle.heading}° · อัปเดต {timeSince(selectedVehicle.updated_at)} · 🔋 {selectedVehicle.battery_pct != null ? `${selectedVehicle.battery_pct}%` : '—'}
                  </div>
                </div>
              </div>

              {/* Driver */}
              <div className="flex items-center gap-2 p-3 bg-slate-50 rounded-xl text-sm">
                <span className="text-lg">👤</span>
                <div className="flex-1 min-w-0">
                  <div className="font-medium truncate">{selectedVehicle.driver_name ?? '— ไม่มีคนขับ'}</div>
                  {selectedVehicle.driver_phone && (
                    <div className="text-xs text-slate-500">{selectedVehicle.driver_phone}</div>
                  )}
                </div>
              </div>

              {/* ===== ETA Section ===== */}
              {selectedVehicle.trip_id ? (
                <div className="p-3 bg-blue-50 rounded-xl border border-blue-100">
                  <div className="text-xs text-blue-500 font-semibold mb-2">🚚 เที่ยวปัจจุบัน</div>
                  <div className="font-bold text-blue-800">{selectedVehicle.trip_no ?? 'กำลังดำเนินการ'}</div>
                  {selectedVehicle.origin_name && (
                    <div className="text-xs text-blue-600 mt-1 truncate">📍 {selectedVehicle.origin_name}</div>
                  )}
                  {eta ? (
                    <div className="mt-3 grid grid-cols-2 gap-2">
                      <div className="bg-white rounded-lg p-2 text-center">
                        <div className="text-xs text-slate-500">ระยะถึงปลายทาง</div>
                        <div className="font-bold text-slate-800">{eta.km} <span className="text-xs font-normal text-slate-400">km</span></div>
                      </div>
                      <div className="bg-emerald-50 rounded-lg p-2 text-center">
                        <div className="text-xs text-emerald-600 font-medium">ETA ถึงจุดส่ง</div>
                        <div className="font-bold text-emerald-700">~{eta.label}</div>
                      </div>
                    </div>
                  ) : selectedVehicle.planned_end ? (
                    <div className="mt-2 text-xs text-blue-600">
                      ⏰ กำหนดถึง: {new Date(selectedVehicle.planned_end).toLocaleTimeString('th-TH', { hour: '2-digit', minute: '2-digit' })}
                    </div>
                  ) : (
                    <div className="mt-2 text-xs text-blue-400">ยังไม่มีข้อมูลปลายทาง</div>
                  )}
                </div>
              ) : (
                <div className="p-3 bg-slate-50 rounded-xl text-slate-400 text-xs text-center">ไม่มีเที่ยวในขณะนี้</div>
              )}

              {/* ===== Traffic Status ===== */}
              <div className="p-3 bg-slate-50 rounded-xl">
                <div className="text-xs text-slate-500 font-semibold mb-2">🚦 สภาพจราจร (ประมาณการจากรถในระบบ)</div>
                <div className="flex items-center gap-3 mb-2">
                  <div className="flex-1 h-2 rounded-full bg-slate-200 overflow-hidden">
                    <div className="h-full rounded-full transition-all duration-500"
                      style={{ background: traffic.color, width: `${Math.min(100, (counts.moving / Math.max(counts.all, 1)) * 100)}%` }} />
                  </div>
                  <span className="text-xs font-semibold" style={{ color: traffic.color }}>{traffic.label}</span>
                </div>
                <div className="text-xs text-slate-400">
                  {counts.moving}/{counts.all} คัน เคลื่อนที่ ({Math.round(counts.moving / Math.max(counts.all, 1) * 100)}%) · เลเยอร์: {TILE_URLS[mapLayer].label}
                </div>
              </div>

              {/* Coords */}
              <div className="grid grid-cols-2 gap-2 text-xs">
                <div className="bg-slate-50 rounded-lg p-2 text-center">
                  <div className="text-slate-400">lat</div>
                  <div className="font-mono text-slate-700">{selectedVehicle.lat.toFixed(5)}</div>
                </div>
                <div className="bg-slate-50 rounded-lg p-2 text-center">
                  <div className="text-slate-400">lng</div>
                  <div className="font-mono text-slate-700">{selectedVehicle.lng.toFixed(5)}</div>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Legend */}
        <div className="absolute bottom-6 right-4 z-[1000] bg-white/90 backdrop-blur rounded-xl shadow px-3 py-2 text-xs text-slate-600 space-y-1">
          <div className="flex items-center gap-2"><span className="w-3 h-3 rounded-full bg-green-500 inline-block" /> กำลังวิ่ง</div>
          <div className="flex items-center gap-2"><span className="w-3 h-3 rounded-full bg-slate-400 inline-block" /> จอด</div>
          <div className="flex items-center gap-2"><span className="w-3 h-3 rounded-full bg-orange-400 inline-block" /> ซ่อม</div>
          <div className="flex items-center gap-2">📥 รับสินค้า</div>
          <div className="flex items-center gap-2">📤 ส่งสินค้า</div>
        </div>
      </div>
    </div>
  )
}
