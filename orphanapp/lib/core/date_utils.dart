import 'package:intl/intl.dart';

String toIsoDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
DateTime fromIsoDate(String value) => DateTime.parse(value);
