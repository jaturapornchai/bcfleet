/// Date utilities — จัดรูปแบบวันที่

/// ดูว่าวันนี้หรือไม่
bool isToday(DateTime date) {
  final now = DateTime.now();
  return date.year == now.year && date.month == now.month && date.day == now.day;
}

/// นับจำนวนวันที่เหลือ
int daysRemaining(DateTime dueDate) {
  return dueDate.difference(DateTime.now()).inDays;
}

/// แปลง duration เป็นข้อความ
String formatDuration(int minutes) {
  if (minutes < 60) return '$minutes นาที';
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  if (mins == 0) return '$hours ชม.';
  return '$hours ชม. $mins นาที';
}

/// ดูว่าใกล้หมดอายุหรือไม่ (< 30 วัน)
bool isExpiringSoon(DateTime? expiryDate, {int daysThreshold = 30}) {
  if (expiryDate == null) return false;
  return daysRemaining(expiryDate) <= daysThreshold;
}

/// ดูว่าหมดอายุแล้วหรือไม่
bool isExpired(DateTime? expiryDate) {
  if (expiryDate == null) return false;
  return expiryDate.isBefore(DateTime.now());
}
