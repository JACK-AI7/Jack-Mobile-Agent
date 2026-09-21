// ignore_for_file: constant_identifier_names

class AutomationModel {
  final String id;
  final String name;
  final String schedule;
  final bool isActive;
  final DateTime createdAt;

  AutomationModel({
    required this.id,
    required this.name,
    required this.schedule,
    required this.isActive,
    required this.createdAt,
  });

  factory AutomationModel.fromJson(Map<String, dynamic> json) {
    return AutomationModel(
      id: json['id'],
      name: json['name'],
      schedule: json['schedule'],
      isActive: json['isActive'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
