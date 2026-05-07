import '../core/date_utils.dart';

class ChildSkillModel {
  final String? id;
  final int childId;
  final String skillName;
  final String skillLevel;
  final String? description;
  final DateTime createdAt;

  ChildSkillModel({
    this.id,
    required this.childId,
    required this.skillName,
    required this.skillLevel,
    this.description,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'child_id': childId,
    'skill_name': skillName,
    'skill_level': skillLevel,
    'description': description,
    'created_at': toIsoDate(createdAt),
  };

  factory ChildSkillModel.fromJson(Map<String, dynamic> json) {
    return ChildSkillModel(
      id: json['id'] as String?,
      childId: (json['child_id'] as num).toInt(),
      skillName: json['skill_name'] as String,
      skillLevel: json['skill_level'] as String,
      description: json['description'] as String?,
      createdAt: json['created_at'] == null
          ? DateTime.now()
          : DateTime.parse(json['created_at'] as String),
    );
  }
}
