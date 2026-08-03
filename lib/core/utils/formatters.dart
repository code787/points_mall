import 'package:intl/intl.dart';

final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');
final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
final DateFormat _monthFormat = DateFormat('yyyy-MM');

String formatDateTime(DateTime time) => _dateTimeFormat.format(time);

String formatDate(DateTime time) => _dateFormat.format(time);

String formatMonth(DateTime time) => _monthFormat.format(time);

String formatPoints(int points) => points >= 0 ? '+$points' : '$points';

String formatPointsPlain(int points) {
  final abs = points.abs();
  return (points < 0 ? '-$abs' : '$abs');
}
