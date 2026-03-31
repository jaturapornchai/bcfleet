export const TRIP_STATUS: Record<string, { label: string; color: string }> = {
  draft: { label: 'ร่าง', color: 'bg-gray-100 text-gray-700' },
  pending: { label: 'รอดำเนินการ', color: 'bg-yellow-100 text-yellow-700' },
  accepted: { label: 'รับงานแล้ว', color: 'bg-blue-100 text-blue-700' },
  started: { label: 'ออกเดินทาง', color: 'bg-indigo-100 text-indigo-700' },
  arrived: { label: 'ถึงจุดรับ', color: 'bg-purple-100 text-purple-700' },
  delivering: { label: 'กำลังส่งมอบ', color: 'bg-orange-100 text-orange-700' },
  completed: { label: 'เสร็จสิ้น', color: 'bg-green-100 text-green-700' },
  cancelled: { label: 'ยกเลิก', color: 'bg-red-100 text-red-700' },
}

export const VEHICLE_HEALTH: Record<string, { label: string; color: string }> = {
  green: { label: 'ปกติ', color: 'bg-green-100 text-green-700' },
  yellow: { label: 'เฝ้าระวัง', color: 'bg-yellow-100 text-yellow-700' },
  red: { label: 'ต้องซ่อม', color: 'bg-red-100 text-red-700' },
}

export const ALERT_SEVERITY: Record<string, { label: string; color: string }> = {
  info: { label: 'ข้อมูล', color: 'bg-blue-100 text-blue-700' },
  warning: { label: 'เฝ้าระวัง', color: 'bg-yellow-100 text-yellow-700' },
  critical: { label: 'วิกฤต', color: 'bg-red-100 text-red-700' },
}

export const WO_STATUS: Record<string, { label: string; color: string }> = {
  pending_approval: { label: 'รออนุมัติ', color: 'bg-yellow-100 text-yellow-700' },
  approved: { label: 'อนุมัติแล้ว', color: 'bg-blue-100 text-blue-700' },
  in_progress: { label: 'กำลังซ่อม', color: 'bg-indigo-100 text-indigo-700' },
  completed: { label: 'เสร็จ', color: 'bg-green-100 text-green-700' },
}

export function formatMoney(n: number | null | undefined): string {
  if (n == null) return '0'
  return n.toLocaleString('th-TH', { minimumFractionDigits: 0, maximumFractionDigits: 0 })
}

export function formatDate(d: string | null | undefined): string {
  if (!d) return '-'
  return new Date(d).toLocaleDateString('th-TH', { day: 'numeric', month: 'short', year: '2-digit' })
}
