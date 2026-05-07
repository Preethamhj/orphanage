import '../core/date_utils.dart';

class AcademicRecordModel {
  final String? id;
  final int childId;
  final int schoolClass;
  final int year;
  final double marks;
  final double attendance;
  final String performanceLevel;
  final DateTime? createdAt;

  AcademicRecordModel({
    this.id,
    required this.childId,
    required this.schoolClass,
    required this.year,
    required this.marks,
    required this.attendance,
    required this.performanceLevel,
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'child_id': childId,
        'class': schoolClass,
        'year': year,
        'marks': marks,
        'attendance': attendance,
        'performance_level': performanceLevel,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };

  factory AcademicRecordModel.fromJson(Map<String, dynamic> json) {
    return AcademicRecordModel(
      id: json['id'] as String?,
      childId: (json['child_id'] as num).toInt(),
      schoolClass: (json['class'] as num).toInt(),
      year: (json['year'] as num).toInt(),
      marks: (json['marks'] as num).toDouble(),
      attendance: (json['attendance'] as num).toDouble(),
      performanceLevel: json['performance_level'] as String,
      createdAt: json['created_at'] == null ? null : DateTime.parse(json['created_at'] as String),
    );
  }

  static Map<String, dynamic> exampleJson() => {
        'id': '8cdb47dc-0d0f-4ef2-99a6-7d7b375f3fd4',
        'child_id': 1,
        'class': 6,
        'year': 2026,
        'marks': 82.5,
        'attendance': 94.0,
        'performance_level': 'Good',
        'created_at': toIsoDate(DateTime.now()),
      };
}
