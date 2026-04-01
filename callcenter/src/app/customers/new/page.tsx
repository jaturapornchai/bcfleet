'use client'
import { useState } from 'react'
import { api } from '@/lib/api'

export default function NewCustomerPage() {
  const [form, setForm] = useState({
    name: '', company: '', phone: '', email: '', address: '',
    tax_id: '', credit_limit: '', credit_days: '30', notes: '',
  })
  const [contacts, setContacts] = useState([{ name: '', phone: '', position: '', is_primary: true }])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  const set = (k: string, v: string) => setForm(f => ({ ...f, [k]: v }))

  const addContact = () => setContacts(c => [...c, { name: '', phone: '', position: '', is_primary: false }])
  const setContact = (i: number, k: string, v: string | boolean) =>
    setContacts(c => c.map((x, idx) => idx === i ? { ...x, [k]: v } : x))

  const submit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!form.name.trim()) { setError('กรุณากรอกชื่อลูกค้า'); return }
    setLoading(true); setError('')
    try {
      const payload = {
        ...form,
        credit_limit: form.credit_limit ? parseFloat(form.credit_limit) : null,
        credit_days: parseInt(form.credit_days),
        contacts: contacts.filter(c => c.name.trim()),
      }
      await api.createCustomer(payload)
      window.location.href = '/customers'
    } catch (err: any) {
      setError(err.message || 'เกิดข้อผิดพลาด')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="max-w-2xl">
      <div className="flex items-center gap-3 mb-6">
        <a href="/customers" className="text-slate-400 hover:text-slate-600 text-sm">← กลับ</a>
        <h2 className="text-xl font-bold">👤 เพิ่มลูกค้าใหม่</h2>
      </div>

      <form onSubmit={submit} className="space-y-6">
        {error && <div className="p-3 bg-red-50 text-red-700 rounded-lg text-sm">{error}</div>}

        <div className="bg-white rounded-xl border p-5 space-y-4">
          <h3 className="font-semibold text-slate-700">ข้อมูลทั่วไป</h3>
          <div className="grid grid-cols-2 gap-4">
            <Field label="ชื่อ / ชื่อบริษัท *" value={form.name} onChange={v => set('name', v)} placeholder="บริษัท ABC จำกัด" />
            <Field label="ชื่อย่อ / ชื่อเรียก" value={form.company} onChange={v => set('company', v)} placeholder="ABC" />
            <Field label="เบอร์โทร" value={form.phone} onChange={v => set('phone', v)} placeholder="081-234-5678" />
            <Field label="อีเมล" value={form.email} onChange={v => set('email', v)} placeholder="contact@abc.com" />
            <Field label="เลขที่ผู้เสียภาษี" value={form.tax_id} onChange={v => set('tax_id', v)} placeholder="0105564XXXXXX" />
          </div>
          <Field label="ที่อยู่" value={form.address} onChange={v => set('address', v)} placeholder="123 ถ.เชียงใหม่-ลำปาง ต.หนองหอย อ.เมือง จ.เชียงใหม่" />
        </div>

        <div className="bg-white rounded-xl border p-5 space-y-4">
          <h3 className="font-semibold text-slate-700">เครดิต</h3>
          <div className="grid grid-cols-2 gap-4">
            <Field label="วงเงินเครดิต (บาท)" value={form.credit_limit} onChange={v => set('credit_limit', v)} placeholder="50000" type="number" />
            <div>
              <label className="block text-sm text-slate-600 mb-1">เครดิต (วัน)</label>
              <select value={form.credit_days} onChange={e => set('credit_days', e.target.value)}
                className="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:border-blue-400">
                {[0, 7, 15, 30, 45, 60, 90].map(d => (
                  <option key={d} value={d}>{d === 0 ? 'เงินสด' : `${d} วัน`}</option>
                ))}
              </select>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-xl border p-5 space-y-4">
          <div className="flex justify-between items-center">
            <h3 className="font-semibold text-slate-700">ผู้ติดต่อ</h3>
            <button type="button" onClick={addContact} className="text-sm text-blue-600 hover:text-blue-700">+ เพิ่มผู้ติดต่อ</button>
          </div>
          {contacts.map((c, i) => (
            <div key={i} className="p-4 bg-slate-50 rounded-lg space-y-3">
              <div className="grid grid-cols-3 gap-3">
                <Field label="ชื่อ" value={c.name} onChange={v => setContact(i, 'name', v)} placeholder="สมชาย ใจดี" />
                <Field label="เบอร์โทร" value={c.phone} onChange={v => setContact(i, 'phone', v)} placeholder="089-123-4567" />
                <Field label="ตำแหน่ง" value={c.position} onChange={v => setContact(i, 'position', v)} placeholder="ผู้จัดการ" />
              </div>
              <label className="flex items-center gap-2 text-sm cursor-pointer">
                <input type="checkbox" checked={c.is_primary} onChange={e => setContact(i, 'is_primary', e.target.checked)} className="rounded" />
                <span>ผู้ติดต่อหลัก</span>
              </label>
            </div>
          ))}
        </div>

        <div className="bg-white rounded-xl border p-5">
          <Field label="หมายเหตุ" value={form.notes} onChange={v => set('notes', v)} placeholder="ข้อมูลเพิ่มเติม..." textarea />
        </div>

        <div className="flex gap-3">
          <button type="submit" disabled={loading}
            className="flex-1 bg-blue-600 text-white py-3 rounded-xl font-medium hover:bg-blue-700 disabled:opacity-50">
            {loading ? 'กำลังบันทึก...' : '💾 บันทึกลูกค้า'}
          </button>
          <a href="/customers" className="px-6 py-3 border rounded-xl text-slate-600 hover:bg-slate-50 text-center">ยกเลิก</a>
        </div>
      </form>
    </div>
  )
}

function Field({ label, value, onChange, placeholder, type = 'text', textarea }: {
  label: string; value: string; onChange: (v: string) => void;
  placeholder?: string; type?: string; textarea?: boolean
}) {
  const cls = "w-full border border-slate-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:border-blue-400"
  return (
    <div>
      <label className="block text-sm text-slate-600 mb-1">{label}</label>
      {textarea
        ? <textarea value={value} onChange={e => onChange(e.target.value)} placeholder={placeholder} rows={3} className={cls} />
        : <input type={type} value={value} onChange={e => onChange(e.target.value)} placeholder={placeholder} className={cls} />
      }
    </div>
  )
}
