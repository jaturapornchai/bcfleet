import 'package:flutter/material.dart';

class TripPlanningScreen extends StatefulWidget {
  const TripPlanningScreen({super.key});

  @override
  State<TripPlanningScreen> createState() => _TripPlanningScreenState();
}

class _TripPlanningScreenState extends State<TripPlanningScreen> {
  String _selectedVehicle = '';
  String _selectedDriver = '';

  final _pendingOrders = [
    {'id': 'ORD-001', 'customer': 'ร้าน XYZ ลำพูน', 'cargo': 'ปูนซีเมนต์ 200 ถุง', 'weight': '10,000', 'dest': 'ลำพูน', 'dist': '45'},
    {'id': 'ORD-002', 'customer': 'ห้าง ABC เชียงราย', 'cargo': 'เหล็กเส้น', 'weight': '8,000', 'dest': 'เชียงราย', 'dist': '180'},
    {'id': 'ORD-003', 'customer': 'โรงงาน DEF ลำปาง', 'cargo': 'วัตถุดิบพลาสติก', 'weight': '5,000', 'dest': 'ลำปาง', 'dist': '100'},
    {'id': 'ORD-004', 'customer': 'ลูกค้า GHI พะเยา', 'cargo': 'เฟอร์นิเจอร์', 'weight': '3,000', 'dest': 'พะเยา', 'dist': '130'},
    {'id': 'ORD-005', 'customer': 'ศูนย์กระจายสินค้า', 'cargo': 'สินค้าอุปโภค', 'weight': '6,500', 'dest': 'เชียงใหม่ใน', 'dist': '15'},
  ];

  final _availableVehicles = [
    {'id': 'v1', 'plate': 'กท-1234', 'type': '6ล้อ', 'driver': 'สมชาย ใจดี', 'status': 'ว่าง'},
    {'id': 'v2', 'plate': 'ชม-3456', 'type': '6ล้อ', 'driver': 'สมศักดิ์ รักงาน', 'status': 'ว่าง'},
    {'id': 'v3', 'plate': 'กน-7890', 'type': '10ล้อ', 'driver': 'ประสิทธิ์ มีน้ำใจ', 'status': 'ว่าง'},
  ];

  List<Map<String, String>> _tripOrders = [];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('วางแผนเที่ยววิ่ง', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.auto_fix_high, size: 16),
                label: const Text('AI จัดเส้นทางอัตโนมัติ'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _tripOrders.isNotEmpty ? _confirmTrip : null,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('ยืนยันสร้างเที่ยว'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: คำสั่งซื้อรอจัดส่ง
                SizedBox(
                  width: 300,
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: cs.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.inbox, color: cs.primary, size: 20),
                              const SizedBox(width: 8),
                              Text('คำสั่งซื้อรอจัดส่ง',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: cs.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text('${_pendingOrders.length}',
                                    style: TextStyle(fontSize: 12, color: cs.onPrimaryContainer, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _pendingOrders.length,
                            itemBuilder: (context, index) {
                              final order = _pendingOrders[index];
                              final isAlreadyAdded = _tripOrders.any((o) => o['id'] == order['id']);
                              return Draggable<Map<String, String>>(
                                data: order,
                                onDragStarted: () => setState(() {}),
                                onDragEnd: (_) => setState(() {}),
                                feedback: Material(
                                  elevation: 6,
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 280,
                                    child: _buildOrderCard(order, cs, isDragging: true),
                                  ),
                                ),
                                childWhenDragging: Opacity(opacity: 0.4, child: _buildOrderCard(order, cs)),
                                child: Opacity(
                                  opacity: isAlreadyAdded ? 0.4 : 1.0,
                                  child: _buildOrderCard(order, cs, isAdded: isAlreadyAdded),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Center: Drop zone — เที่ยววิ่งที่จะสร้าง
                Expanded(
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: cs.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.route, color: cs.primary, size: 20),
                              const SizedBox(width: 8),
                              Text('เที่ยววิ่งใหม่',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary)),
                              const Spacer(),
                              if (_tripOrders.isNotEmpty)
                                TextButton.icon(
                                  onPressed: () => setState(() => _tripOrders.clear()),
                                  icon: const Icon(Icons.clear_all, size: 16),
                                  label: const Text('ล้างทั้งหมด'),
                                ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),

                        // Vehicle + Driver selection
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _selectedVehicle.isEmpty ? null : _selectedVehicle,
                                  decoration: InputDecoration(
                                    labelText: 'เลือกรถ',
                                    prefixIcon: const Icon(Icons.local_shipping, size: 18),
                                    border: const OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  hint: const Text('-- เลือกรถ --'),
                                  items: _availableVehicles.map((v) => DropdownMenuItem(
                                    value: v['id'],
                                    child: Text('${v['plate']} (${v['type']}) — ${v['status']}'),
                                  )).toList(),
                                  onChanged: (v) => setState(() => _selectedVehicle = v ?? ''),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _selectedDriver.isEmpty ? null : _selectedDriver,
                                  decoration: InputDecoration(
                                    labelText: 'เลือกคนขับ',
                                    prefixIcon: const Icon(Icons.person, size: 18),
                                    border: const OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  hint: const Text('-- เลือกคนขับ --'),
                                  items: _availableVehicles.map((v) => DropdownMenuItem(
                                    value: v['id'],
                                    child: Text(v['driver']!),
                                  )).toList(),
                                  onChanged: (v) => setState(() => _selectedDriver = v ?? ''),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),

                        // Drop target
                        Expanded(
                          child: DragTarget<Map<String, String>>(
                            onAcceptWithDetails: (details) {
                              final order = details.data;
                              if (!_tripOrders.any((o) => o['id'] == order['id'])) {
                                setState(() => _tripOrders.add(order));
                              }
                            },
                            builder: (context, candidateData, rejectedData) {
                              if (_tripOrders.isEmpty) {
                                return Container(
                                  margin: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: candidateData.isNotEmpty
                                          ? cs.primary
                                          : cs.outlineVariant,
                                      width: 2,
                                      style: BorderStyle.solid,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    color: candidateData.isNotEmpty
                                        ? cs.primaryContainer.withValues(alpha: 0.3)
                                        : null,
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.drag_indicator,
                                            size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                                        const SizedBox(height: 12),
                                        Text('ลากคำสั่งซื้อมาวางที่นี่',
                                            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15)),
                                        const SizedBox(height: 4),
                                        Text('เพื่อเพิ่มในเที่ยววิ่ง',
                                            style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: candidateData.isNotEmpty
                                      ? cs.primaryContainer.withValues(alpha: 0.2)
                                      : null,
                                ),
                                child: ReorderableListView.builder(
                                  padding: const EdgeInsets.all(12),
                                  itemCount: _tripOrders.length,
                                  onReorder: (oldIndex, newIndex) {
                                    setState(() {
                                      if (newIndex > oldIndex) newIndex--;
                                      final item = _tripOrders.removeAt(oldIndex);
                                      _tripOrders.insert(newIndex, item);
                                    });
                                  },
                                  itemBuilder: (context, index) {
                                    final order = _tripOrders[index];
                                    return Card(
                                      key: ValueKey(order['id']),
                                      margin: const EdgeInsets.only(bottom: 8),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: BorderSide(color: cs.primary.withValues(alpha: 0.3)),
                                      ),
                                      child: ListTile(
                                        dense: true,
                                        leading: CircleAvatar(
                                          radius: 14,
                                          backgroundColor: cs.primaryContainer,
                                          child: Text('${index + 1}',
                                              style: TextStyle(fontSize: 12, color: cs.onPrimaryContainer, fontWeight: FontWeight.bold)),
                                        ),
                                        title: Text('${order['id']} — ${order['customer']}',
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                        subtitle: Text('${order['cargo']} • ${order['dist']} กม. • ${order['weight']} กก.',
                                            style: const TextStyle(fontSize: 11)),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.drag_handle, color: Colors.grey[400]),
                                            IconButton(
                                              icon: const Icon(Icons.close, size: 16),
                                              onPressed: () => setState(() => _tripOrders.removeAt(index)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),

                        // Summary footer
                        if (_tripOrders.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerLow,
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                            ),
                            child: Row(
                              children: [
                                _summaryChip(cs, Icons.place, '${_tripOrders.length} จุดส่ง'),
                                const SizedBox(width: 12),
                                _summaryChip(cs, Icons.route, '${_tripOrders.fold(0, (sum, o) => sum + int.parse(o['dist']!))} กม.'),
                                const SizedBox(width: 12),
                                _summaryChip(cs, Icons.scale, '${_tripOrders.fold(0, (sum, o) => sum + int.parse(o['weight']!.replaceAll(',', '')))} กก.'),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Right: รถว่าง
                SizedBox(
                  width: 240,
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: cs.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.local_shipping, color: Colors.green, size: 20),
                              const SizedBox(width: 8),
                              Text('รถว่างวันนี้',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _availableVehicles.length,
                            itemBuilder: (context, index) {
                              final v = _availableVehicles[index];
                              return Card(
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: Colors.green.withValues(alpha: 0.3)),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(v['plate']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(v['type']!, style: const TextStyle(fontSize: 10, color: Colors.green)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(v['driver']!, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.warning_amber, color: Colors.orange, size: 16),
                                  const SizedBox(width: 6),
                                  Text('รถในซ่อม: 1 คัน', style: TextStyle(fontSize: 11, color: Colors.orange[700])),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.directions_car, color: Colors.blue, size: 16),
                                  const SizedBox(width: 6),
                                  Text('วิ่งอยู่: 2 คัน', style: TextStyle(fontSize: 11, color: Colors.blue[700])),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, String> order, ColorScheme cs, {bool isDragging = false, bool isAdded = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDragging ? cs.primaryContainer : (isAdded ? Colors.grey.shade50 : cs.surface),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isAdded ? Colors.grey.shade300 : cs.outlineVariant),
        boxShadow: isDragging ? [BoxShadow(color: Colors.black26, blurRadius: 8)] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(order['id']!, style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: cs.primary, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (isAdded) const Icon(Icons.check_circle, size: 14, color: Colors.green),
            ],
          ),
          const SizedBox(height: 4),
          Text(order['customer']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(order['cargo']!, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.place, size: 11, color: Colors.grey[500]),
              const SizedBox(width: 3),
              Text(order['dest']!, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              const SizedBox(width: 8),
              Icon(Icons.route, size: 11, color: Colors.grey[500]),
              const SizedBox(width: 3),
              Text('${order['dist']} กม.', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(ColorScheme cs, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: cs.primary),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: cs.primary, fontWeight: FontWeight.w600)),
      ],
    );
  }

  void _confirmTrip() {
    if (_tripOrders.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันสร้างเที่ยววิ่ง'),
        content: Text('จะสร้างเที่ยววิ่งพร้อม ${_tripOrders.length} จุดส่งสินค้า ใช่ไหม?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _tripOrders.clear());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('สร้างเที่ยววิ่งสำเร็จ')),
              );
            },
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );
  }
}
