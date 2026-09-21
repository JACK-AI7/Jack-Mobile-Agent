// ignore_for_file: constant_identifier_names
class ToolDefinition {
  final String name;
  final String description;
  final String category;
  final String riskLevel;
  final String availability;

  ToolDefinition({
    required this.name,
    required this.description,
    required this.category,
    required this.riskLevel,
    required this.availability,
  });

  factory ToolDefinition.fromJson(Map<String, dynamic> json) {
    return ToolDefinition(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      riskLevel: json['riskLevel'] as String? ?? 'LOW',
      availability: json['availability'] as String? ?? 'UNAVAILABLE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'riskLevel': riskLevel,
      'availability': availability,
    };
  }
}
