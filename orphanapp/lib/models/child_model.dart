import '../core/date_utils.dart';
import 'child_skill_model.dart';

class ChildModel {
  final int? childId;
  final String name;
  final int age;
  final String gender;
  final String education;
  final String healthStatus;
  final DateTime admissionDate;
  final String? guardianDetails;
  final DateTime? dob;
  final int? schoolClass;
  final String? section;
  final String? schoolName;
  final DateTime? joiningDate;
  final String? joiningReason;
  final String? broughtBy;
  final String? medicalNotes;
  final String? childBackground;
  final String? academicStatus;
  final double? attendancePercentage;
  final double? lastExamMarks;
  final List<ChildSkillModel> skills;
  final String syncStatus;

  ChildModel({
    this.childId,
    required this.name,
    required this.age,
    required this.gender,
    required this.education,
    required this.healthStatus,
    required this.admissionDate,
    this.guardianDetails,
    this.dob,
    this.schoolClass,
    this.section,
    this.schoolName,
    this.joiningDate,
    this.joiningReason,
    this.broughtBy,
    this.medicalNotes,
    this.childBackground,
    this.academicStatus,
    this.attendancePercentage,
    this.lastExamMarks,
    this.skills = const [],
    this.syncStatus = 'synced',
  });

  int get currentAge {
    if (dob != null) {
      final today = DateTime.now();
      var calculated = today.year - dob!.year;
      if (today.month < dob!.month ||
          (today.month == dob!.month && today.day < dob!.day)) {
        calculated--;
      }
      return calculated;
    }
    return age;
  }

  String get profileSummary {
    final buffer = StringBuffer();
    buffer.write('Class ${schoolClass ?? '-'}');
    if (section?.isNotEmpty == true) buffer.write(' • Section $section');
    if (schoolName?.isNotEmpty == true) buffer.write(' • $schoolName');
    return buffer.toString();
  }

  Map<String, dynamic> toJson({bool includeSkills = false}) {
    final result = <String, dynamic>{
      if (childId != null) 'child_id': childId,
      'name': name,
      'age': age,
      'gender': gender,
      'education': education,
      'health_status': healthStatus,
      'admission_date': toIsoDate(admissionDate),
      'guardian_details': guardianDetails,
      'dob': dob == null ? null : toIsoDate(dob!),
      'class': schoolClass,
      'section': section,
      'school_name': schoolName,
      'joining_date': joiningDate == null ? null : toIsoDate(joiningDate!),
      'joining_reason': joiningReason,
      'brought_by': broughtBy,
      'medical_notes': medicalNotes,
      'child_background': childBackground,
      'academic_status': academicStatus,
      'attendance_percentage': attendancePercentage,
      'last_exam_marks': lastExamMarks,
    };
    if (includeSkills) {
      result['child_skills'] = skills.map((e) => e.toJson()).toList();
    }
    return result;
  }

  factory ChildModel.fromJson(Map<String, dynamic> json) => ChildModel(
    childId: (json['child_id'] as num?)?.toInt(),
    name: json['name'] as String,
    age: ((json['age'] as num?) ?? 0).toInt(),
    gender: json['gender'] as String,
    education: json['education'] as String,
    healthStatus: json['health_status'] as String,
    admissionDate: fromIsoDate(json['admission_date'] as String),
    guardianDetails: json['guardian_details'] as String?,
    dob: json['dob'] == null ? null : fromIsoDate(json['dob'] as String),
    schoolClass: (json['class'] as num?)?.toInt(),
    section: json['section'] as String?,
    schoolName: json['school_name'] as String?,
    joiningDate: json['joining_date'] == null
        ? null
        : fromIsoDate(json['joining_date'] as String),
    joiningReason: json['joining_reason'] as String?,
    broughtBy: json['brought_by'] as String?,
    medicalNotes: json['medical_notes'] as String?,
    childBackground: json['child_background'] as String?,
    academicStatus: json['academic_status'] as String?,
    attendancePercentage: (json['attendance_percentage'] as num?)?.toDouble(),
    lastExamMarks: (json['last_exam_marks'] as num?)?.toDouble(),
    skills:
        (json['child_skills'] as List?)
            ?.map(
              (e) =>
                  ChildSkillModel.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList() ??
        [],
    syncStatus: (json['sync_status'] as String?) ?? 'synced',
  );
}
