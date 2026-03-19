import '../core/date_utils.dart';

class AdoptionModel {
  final int? adoptionId;
  final int childId;
  final String adopterName;
  final String contactInformation;
  final DateTime applicationDate;
  final String approvalStatus;
  final DateTime? completionDate;
  final String syncStatus;

  AdoptionModel({
    this.adoptionId,
    required this.childId,
    required this.adopterName,
    required this.contactInformation,
    required this.applicationDate,
    required this.approvalStatus,
    this.completionDate,
    this.syncStatus = 'synced',
  });

  Map<String, dynamic> toJson() => {
        if (adoptionId != null) 'adoption_id': adoptionId,
        'child_id': childId,
        'adopter_name': adopterName,
        'contact_information': contactInformation,
        'application_date': toIsoDate(applicationDate),
        'approval_status': approvalStatus,
        'completion_date': completionDate == null ? null : toIsoDate(completionDate!),
      };

  factory AdoptionModel.fromJson(Map<String, dynamic> json) => AdoptionModel(
        adoptionId: (json['adoption_id'] as num?)?.toInt(),
        childId: (json['child_id'] as num).toInt(),
        adopterName: json['adopter_name'] as String,
        contactInformation: json['contact_information'] as String,
        applicationDate: fromIsoDate(json['application_date'] as String),
        approvalStatus: json['approval_status'] as String,
        completionDate: json['completion_date'] == null
            ? null
            : fromIsoDate(json['completion_date'] as String),
        syncStatus: (json['sync_status'] as String?) ?? 'synced',
      );
}
