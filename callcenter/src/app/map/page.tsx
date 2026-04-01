'use client'
import dynamic from 'next/dynamic'

const FleetMap = dynamic(() => import('@/components/FleetMap'), {
  ssr: false,
  loading: () => (
    <div className="flex items-center justify-center h-full bg-slate-900 text-slate-400">
      <div className="text-center">
        <div className="text-4xl mb-3">🗺️</div>
        <div>กำลังโหลดแผนที่...</div>
      </div>
    </div>
  ),
})

export default function MapPage() {
  // -m-6 removes the p-6 from layout, h-[calc(100vh-56px)] fills to bottom (56px = header h-14)
  return (
    <div className="-m-6 h-[calc(100vh-56px)]">
      <FleetMap />
    </div>
  )
}
