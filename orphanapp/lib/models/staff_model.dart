import '../core/date_utils.dart';

class StaffModel {
  final int? staffId;
  final String name;
  final String role;
  final String contactNumber;
  final String email;
  final DateTime joiningDate;
  final String department;
  final String syncStatus;

  StaffModel({
    this.staffId,
    required this.name,
    required this.role,
    required this.contactNumber,
    required this.email,
    required this.joiningDate,
    required this.department,
    this.syncStatus = 'synced',
  });

  Map<String, dynamic> toJson() => {
        if (staffId != null) 'staff_id': staffId,
        'name': name,
        'role': role,
        'contact_number': contactNumber,
        'email': email,
        'joining_date': toIsoDate(joiningDate),
        'department': department,
      };

  factory StaffModel.fromJson(Map<String, dynamic> json) => StaffModel(
        staffId: (json['staff_id'] as num?)?.toInt(),
        name: json['name'] as String,
        role: json['role'] as String,
        contactNumber: json['contact_number'] as String,
        email: json['email'] as String,
        joiningDate: fromIsoDate(json['joining_date'] as String),
        department: json['department'] as String,
        syncStatus: (json['sync_status'] as String?) ?? 'synced',
      );
}
