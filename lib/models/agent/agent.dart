// ignore_for_file: constant_identifier_names
class Agent {
  final String id;
  final String name;
  final String description;
  final String goal;
  final String trigger;
  final String? schedule;
  final List<String> tools;
  final List<String> permissions;

  Agent({
    required this.id,
    required this.name,
    required this.description,
    required this.goal,
    required this.trigger,
    this.schedule,
    required this.tools,
    required this.permissions,
  });

  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      goal: json['goal'] as String? ?? '',
      trigger: json['trigger'] as String? ?? '',
      schedule: json['schedule'] as String?,
      tools: (json['tools'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      permissions: (json['permissions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'goal': goal,
      'trigger': trigger,
      if (schedule != null) 'schedule': schedule,
      'tools': tools,
      'permissions': permissions,
    };
  }
}
