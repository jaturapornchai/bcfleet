import 'package:intl/intl.dart';

/// Currency utilities — จัดรูปแบบเงิน

final _currencyFormat = NumberFormat('#,##0.00', 'th_TH');
final _intFormat = NumberFormat('#,##0', 'th_TH');

/// จัดรูปแบบเงินบาท
String formatBaht(double amount, {bool showSymbol = true}) {
  final formatted = _currencyFormat.format(amount);
  return showSymbol ? '฿$formatted' : formatted;
}

/// จัดรูปแบบตัวเลข (ไม่มีทศนิยม)
String formatNumber(num value) {
  return _intFormat.format(value);
}

/// จัดรูปแบบเปอร์เซ็นต์
String formatPercent(double value) {
  return '${(value * 100).toStringAsFixed(1)}%';
}

/// คำนวณกำไร/ขาดทุน
double calculateProfit(double revenue, double cost) {
  return revenue - cost;
}

/// คำนวณอัตรากำไร
double calculateProfitMargin(double revenue, double cost) {
  if (revenue == 0) return 0;
  return (revenue - cost) / revenue;
}
