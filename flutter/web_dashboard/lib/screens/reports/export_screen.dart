import 'package:flutter/material.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  String _filterMonth = '03/2569';
  String _filterVehicle = 'all';
  final Set<String> _selectedReports = {};
  bool _isExporting = false;

  final _reportTemplates = [
    {
      'id': 'kpi_dashboard',
      'name': 'KPI Dashboard',
      'description': 'ภาพรวม KPI กองรถ, ผลงานคนขับ, สุขภาพรถ',
      'icon': 'dashboard',
      'formats': ['PDF'],
      'category': 'รายงานสรุป',
    },
    {
      'id': 'cost_overview',
      'name': 'ภาพรวมต้นทุน',
      'description': 'รายรับ-รายจ่าย กำไร Margin ต่อคัน/เดือน',
      'icon': 'account_balance_wallet',
      'formats': ['PDF', 'Excel'],
      'category': 'รายงานสรุป',
    },
    {
      'id': 'pl_per_vehicle',
      'name': 'P&L ต่อคัน',
      'description': 'กำไร-ขาดทุน แยกตามรถแต่ละคัน',
      'icon': 'bar_chart',
      'formats': ['PDF', 'Excel'],
      'category': 'รายงานสรุป',
    },
    {
      'id': 'trip_report',
      'name': 'รายงานเที่ยววิ่ง',
      'description': 'รายละเอียดเที่ยววิ่งทั้งหมด พร้อมต้นทุนต่อเที่ยว',
      'icon': 'local_shipping',
      'formats': ['PDF', 'Excel'],
      'category': 'รายงานปฏิบัติการ',
    },
    {
      'id': 'fuel_report',
      'name': 'รายงานน้ำมัน',
      'description': 'บันทึกเติมน้ำมัน, อัตราสิ้นเปลือง, ค่าใช้จ่ายรวม',
      'icon': 'local_gas_station',
      'formats': ['PDF', 'Excel'],
      'category': 'รายงานปฏิบัติการ',
    },
    {
      'id': 'maintenance_report',
      'name': 'รายงานซ่อมบำรุง',
      'description': 'ใบสั่งซ่อม, ค่าซ่อมสะสม, กำหนดซ่อมครั้งต่อไป',
      'icon': 'build',
      'formats': ['PDF', 'Excel'],
      'category': 'รายงานปฏิบัติการ',
    },
    {
      'id': 'driver_performance',
      'name': 'ผลงานคนขับ',
      'description': 'คะแนน KPI, เที่ยววิ่ง, ตรงเวลา, ประหยัดน้ำมัน',
      'icon': 'person',
      'formats': ['PDF', 'Excel'],
      'category': 'รายงานบุคลากร',
    },
    {
      'id': 'driver_salary',
      'name': 'สลิปเงินเดือนคนขับ',
      'description': 'เงินเดือน + เบี้ยเลี้ยง + โบนัสเที่ยว + OT',
      'icon': 'payments',
      'formats': ['PDF'],
      'category': 'รายงานบุคลากร',
    },
    {
      'id': 'partner_settlement',
      'name': 'หนังสือจ่ายเงินรถร่วม',
      'description': 'รายการจ่ายเงินรถร่วม พร้อมหัก ณ ที่จ่าย',
      'icon': 'handshake',
      'formats': ['PDF'],
      'category': 'รายงานรถร่วม',
    },
    {
      'id': 'wht_pnd3',
      'name': 'ภ.ง.ด.3 (หัก ณ ที่จ่าย)',
      'description': 'แบบฟอร์ม ภ.ง.ด.3 สำหรับยื่นกรมสรรพากร',
      'icon': 'receipt_long',
      'formats': ['PDF'],
      'category': 'รายงานรถร่วม',
    },
    {
      'id': 'vehicle_history',
      'name': 'ประวัติรถแต่ละคัน',
      'description': 'ประวัติการซ่อม, เที่ยววิ่ง, ค่าใช้จ่าย ทั้งหมด',
      'icon': 'history',
      'formats': ['PDF', 'Excel'],
      'category': 'รายงานทะเบียนรถ',
    },
    {
      'id': 'vehicle_document',
      'name': 'เอกสารทะเบียนรถ',
      'description': 'สรุปวันหมดอายุ พ.ร.บ./ภาษี/ประกัน ทุกคัน',
      'icon': 'description',
      'formats': ['PDF', 'Excel'],
      'category': 'รายงานทะเบียนรถ',
    },
  ];

  final _recentExports = [
    {'name': 'KPI Dashboard มีนาคม 2569', 'type': 'PDF', 'date': '31/03/2569', 'size': '1.2 MB', 'status': 'success'},
    {'name': 'ภาพรวมต้นทุน กุมภาพันธ์ 2569', 'type': 'Excel', 'date': '28/02/2569', 'size': '456 KB', 'status': 'success'},
    {'name': 'รายงานน้ำมัน มีนาคม 2569', 'type': 'Excel', 'date': '31/03/2569', 'size': '234 KB', 'status': 'success'},
    {'name': 'ผลงานคนขับ มีนาคม 2569', 'type': 'PDF', 'date': '31/03/2569', 'size': '890 KB', 'status': 'success'},
    {'name': 'ภ.ง.ด.3 มีนาคม 2569', 'type': 'PDF', 'date': '30/03/2569', 'size': '340 KB', 'status': 'success'},
  ];

  Map<String, List<Map<String, dynamic>>> get _groupedReports {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final r in _reportTemplates) {
      final cat = r['category'] as String;
      grouped.putIfAbsent(cat, () => []);
      grouped[cat]!.add(r);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text('Export รายงาน', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_selectedReports.isNotEmpty) ...[
                Text('เลือกแล้ว ${_selectedReports.length} รายงาน',
                    style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _isExporting ? null : _exportSelected,
                  icon: _isExporting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.download, size: 18),
                  label: Text(_isExporting ? 'กำลัง Export...' : 'Export ที่เลือก'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => setState(() => _selectedReports.clear()),
                  child: const Text('ยกเลิกเลือก'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Filters
          Row(
            children: [
              const Text('ช่วงเวลา:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _filterMonth,
                items: const [
                  DropdownMenuItem(value: '03/2569', child: Text('มีนาคม 2569')),
                  DropdownMenuItem(value: '02/2569', child: Text('กุมภาพันธ์ 2569')),
                  DropdownMenuItem(value: '01/2569', child: Text('มกราคม 2569')),
                  DropdownMenuItem(value: 'Q1/2569', child: Text('ไตรมาส 1/2569')),
                  DropdownMenuItem(value: '2569', child: Text('ทั้งปี 2569')),
                ],
                onChanged: (v) => setState(() => _filterMonth = v!),
              ),
              const SizedBox(width: 24),
              const Text('รถ:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _filterVehicle,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('ทุกคัน')),
                  DropdownMenuItem(value: 'กท-1234', child: Text('กท-1234')),
                  DropdownMenuItem(value: '2กร-5678', child: Text('2กร-5678')),
                  DropdownMenuItem(value: 'ชม-3456', child: Text('ชม-3456')),
                  DropdownMenuItem(value: 'กน-7890', child: Text('กน-7890')),
                  DropdownMenuItem(value: 'ลป-1122', child: Text('ลป-1122')),
                  DropdownMenuItem(value: 'พย-3344', child: Text('พย-3344')),
                ],
                onChanged: (v) => setState(() => _filterVehicle = v!),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Report templates list
                Expanded(
                  flex: 3,
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: cs.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('เลือกรายงานที่ต้องการ Export',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: cs.primary)),
                              const Spacer(),
                              TextButton(
                                onPressed: () => setState(() {
                                  if (_selectedReports.length == _reportTemplates.length) {
                                    _selectedReports.clear();
                                  } else {
                                    _selectedReports.addAll(_reportTemplates.map((r) => r['id'] as String));
                                  }
                                }),
                                child: Text(_selectedReports.length == _reportTemplates.length
                                    ? 'ยกเลิกทั้งหมด'
                                    : 'เลือกทั้งหมด'),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _groupedReports.entries.map((entry) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8, top: 4),
                                        child: Text(entry.key,
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: cs.onSurfaceVariant,
                                                letterSpacing: 0.5)),
                                      ),
                                      ...entry.value.map((r) => _buildReportTile(cs, r)),
                                      const SizedBox(height: 8),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Right panel
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      // Quick export cards
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: cs.outlineVariant),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Export ด่วน',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: cs.primary)),
                              const Divider(height: 20),
                              _buildQuickExportButton(cs, 'KPI Dashboard เดือนนี้', Icons.dashboard_outlined, Colors.blue, 'PDF'),
                              const SizedBox(height: 8),
                              _buildQuickExportButton(cs, 'รายงานต้นทุนเดือนนี้', Icons.account_balance_wallet_outlined, Colors.green, 'Excel'),
                              const SizedBox(height: 8),
                              _buildQuickExportButton(cs, 'รายงานน้ำมันเดือนนี้', Icons.local_gas_station_outlined, Colors.orange, 'Excel'),
                              const SizedBox(height: 8),
                              _buildQuickExportButton(cs, 'ภ.ง.ด.3 เดือนนี้', Icons.receipt_long_outlined, Colors.purple, 'PDF'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Recent exports
                      Expanded(
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: cs.outlineVariant),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Export ล่าสุด',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: cs.primary)),
                                const Divider(height: 20),
                                Expanded(
                                  child: ListView.separated(
                                    itemCount: _recentExports.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1),
                                    itemBuilder: (_, i) {
                                      final e = _recentExports[i];
                                      return ListTile(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        leading: Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: (e['type'] == 'PDF' ? Colors.red : Colors.green).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            e['type'] == 'PDF' ? Icons.picture_as_pdf_outlined : Icons.table_chart_outlined,
                                            color: e['type'] == 'PDF' ? Colors.red[700] : Colors.green[700],
                                            size: 20,
                                          ),
                                        ),
                                        title: Text(e['name']!,
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                            overflow: TextOverflow.ellipsis),
                                        subtitle: Text('${e['date']!} · ${e['size']!}',
                                            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                                        trailing: IconButton(
                                          icon: Icon(Icons.download_outlined, size: 18, color: cs.primary),
                                          onPressed: () => _showDownloadSnackbar(e['name']!),
                                          tooltip: 'ดาวน์โหลดอีกครั้ง',
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTile(ColorScheme cs, Map<String, dynamic> report) {
    final id = report['id'] as String;
    final isSelected = _selectedReports.contains(id);
    final formats = report['formats'] as List<String>;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() {
        if (isSelected) {
          _selectedReports.remove(id);
        } else {
          _selectedReports.add(id);
        }
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? cs.primaryContainer.withValues(alpha: 0.3) : null,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? cs.primary.withValues(alpha: 0.4) : cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (v) => setState(() {
                if (v == true) _selectedReports.add(id);
                else _selectedReports.remove(id);
              }),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(report['name'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(report['description'] as String,
                      style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: formats.map((fmt) => Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (fmt == 'PDF' ? Colors.red : Colors.green).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(fmt,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: fmt == 'PDF' ? Colors.red[700] : Colors.green[700])),
              )).toList(),
            ),
            const SizedBox(width: 8),
            _ExportFormatButtons(
              formats: formats,
              onExport: (fmt) => _exportSingle(report['name'] as String, fmt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickExportButton(ColorScheme cs, String label, IconData icon, Color color, String format) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _exportSingle(label, format),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: color)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(format,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
            ),
          ],
        ),
      ),
    );
  }

  void _exportSingle(String name, String format) {
    setState(() => _isExporting = true);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export "$name" เป็น $format เรียบร้อย'),
            action: SnackBarAction(label: 'ดาวน์โหลด', onPressed: () {}),
          ),
        );
      }
    });
  }

  void _exportSelected() {
    setState(() => _isExporting = true);
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _selectedReports.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export รายงาน ${_selectedReports.length} รายการเรียบร้อย'),
            action: SnackBarAction(label: 'ดาวน์โหลดทั้งหมด', onPressed: () {}),
          ),
        );
      }
    });
  }

  void _showDownloadSnackbar(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('ดาวน์โหลด "$name"')),
    );
  }
}

class _ExportFormatButtons extends StatelessWidget {
  final List<String> formats;
  final void Function(String format) onExport;

  const _ExportFormatButtons({required this.formats, required this.onExport});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: formats.map((fmt) => Tooltip(
        message: 'Export เป็น $fmt',
        child: IconButton(
          icon: Icon(
            fmt == 'PDF' ? Icons.picture_as_pdf_outlined : Icons.table_chart_outlined,
            size: 18,
            color: fmt == 'PDF' ? Colors.red[600] : Colors.green[600],
          ),
          onPressed: () => onExport(fmt),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        ),
      )).toList(),
    );
  }
}
