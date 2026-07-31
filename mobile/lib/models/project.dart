class Project {
  const Project({
    required this.projectId,
    required this.name,
    this.description = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String projectId;
  final String name;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Project.fromMap(Map<String, Object?> map) {
    return Project(
      projectId: map['project_id'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
