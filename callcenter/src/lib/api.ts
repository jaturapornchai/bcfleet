const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'https://smlfleet.satistang.com'
const API_PREFIX = '/api/v1/fleet'

export async function apiFetch<T>(path: string, init?: RequestInit): Promise<T> {
  const url = `${API_BASE}${API_PREFIX}${path}`
  const res = await fetch(url, {
    ...init,
    headers: { 'Content-Type': 'application/json', ...init?.headers },
  })
  if (!res.ok) {
    const err = await res.json().catch(() => ({ error: res.statusText }))
    throw new Error(err.error || res.statusText)
  }
  return res.json()
}

export const api = {
  // Customers
  getCustomers: (page = 1, limit = 20) =>
    apiFetch<any>(`/customers?page=${page}&limit=${limit}`),
  searchCustomers: (q: string) =>
    apiFetch<any>(`/customers/search?q=${encodeURIComponent(q)}`),
  getCustomer: (id: string) => apiFetch<any>(`/customers/${id}`),
  createCustomer: (data: any) =>
    apiFetch<any>('/customers', { method: 'POST', body: JSON.stringify(data) }),

  // Vehicles
  getVehicles: (page = 1, limit = 20) =>
    apiFetch<any>(`/vehicles?page=${page}&limit=${limit}`),
  getVehicle: (id: string) => apiFetch<any>(`/vehicles/${id}`),

  // Drivers
  getDrivers: (page = 1, limit = 20) =>
    apiFetch<any>(`/drivers?page=${page}&limit=${limit}`),
  getDriverPerformance: () => apiFetch<any>('/reports/driver-performance'),

  // Trips
  getTrips: (page = 1, limit = 20, status = '') =>
    apiFetch<any>(`/trips?page=${page}&limit=${limit}${status ? `&status=${status}` : ''}`),
  getTrip: (id: string) => apiFetch<any>(`/trips/${id}`),
  createTrip: (data: any) =>
    apiFetch<any>('/trips', { method: 'POST', body: JSON.stringify(data) }),
  calculateRoute: (data: any) =>
    apiFetch<any>('/trips/calculate-route', { method: 'POST', body: JSON.stringify(data) }),

  // Maintenance
  getWorkOrders: (page = 1, limit = 20) =>
    apiFetch<any>(`/maintenance/work-orders?page=${page}&limit=${limit}`),

  // Partners
  getPartners: (page = 1, limit = 20) =>
    apiFetch<any>(`/partners?page=${page}&limit=${limit}`),

  // Expenses
  getExpenses: (page = 1, limit = 20) =>
    apiFetch<any>(`/expenses?page=${page}&limit=${limit}`),

  // Dashboard
  getSummary: () => apiFetch<any>('/dashboard/summary'),
  getKPI: () => apiFetch<any>('/dashboard/kpi'),
  getAlerts: (page = 1, limit = 20) =>
    apiFetch<any>(`/dashboard/alerts?page=${page}&limit=${limit}`),

  // GPS
  getVehicleLocations: () => apiFetch<any>('/gps/vehicles'),
  getMovingVehicles: () => apiFetch<any>('/gps/moving'),
  getMovementEvents: (limit = 20) =>
    apiFetch<any>(`/gps/movement-events?limit=${limit}`),
}
