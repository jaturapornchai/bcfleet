import 'package:intl/intl.dart';

/// Thai utility functions — ฟังก์ชันช่วยสำหรับภาษาไทย

/// แปลงเป็นเลขไทย
String toThaiNumber(String input) {
  const thaiDigits = ['๐', '๑', '๒', '๓', '๔', '๕', '๖', '๗', '๘', '๙'];
  return input.split('').map((c) {
    final digit = int.tryParse(c);
    return digit != null ? thaiDigits[digit] : c;
  }).join();
}

/// แปลงวันที่เป็นรูปแบบไทย (วัน/เดือน/พ.ศ.)
String toThaiDate(DateTime date, {bool showTime = false, bool buddhistEra = true}) {
  final months = [
    '', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
    'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
  ];
  final year = buddhistEra ? date.year + 543 : date.year;
  final result = '${date.day} ${months[date.month]} $year';
  if (showTime) {
    return '$result ${DateFormat('HH:mm').format(date)} น.';
  }
  return result;
}

/// แปลงจำนวนเงินเป็นรูปแบบไทย
String toThaiCurrency(double amount) {
  final formatter = NumberFormat('#,##0.00', 'th_TH');
  return '${formatter.format(amount)} บาท';
}

/// แปลงน้ำหนักเป็นรูปแบบไทย
String toThaiWeight(int kg) {
  if (kg >= 1000) {
    return '${(kg / 1000).toStringAsFixed(1)} ตัน';
  }
  return '$kg กก.';
}

/// แปลงระยะทางเป็นรูปแบบไทย
String toThaiDistance(double km) {
  final formatter = NumberFormat('#,##0.0', 'th_TH');
  return '${formatter.format(km)} กม.';
}
