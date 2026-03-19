import '../core/date_utils.dart';

class ChildModel {
  final int? childId;
  final String name;
  final int age;
  final String gender;
  final String education;
  final String healthStatus;
  final DateTime admissionDate;
  final String? guardianDetails;
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
    this.syncStatus = 'synced',
  });

  Map<String, dynamic> toJson() => {
        if (childId != null) 'child_id': childId,
        'name': name,
        'age': age,
        'gender': gender,
        'education': education,
        'health_status': healthStatus,
        'admission_date': toIsoDate(admissionDate),
        'guardian_details': guardianDetails,
      };

  factory ChildModel.fromJson(Map<String, dynamic> json) => ChildModel(
        childId: (json['child_id'] as num?)?.toInt(),
        name: json['name'] as String,
        age: (json['age'] as num).toInt(),
        gender: json['gender'] as String,
        education: json['education'] as String,
        healthStatus: json['health_status'] as String,
        admissionDate: fromIsoDate(json['admission_date'] as String),
        guardianDetails: json['guardian_details'] as String?,
        syncStatus: (json['sync_status'] as String?) ?? 'synced',
      );
}
