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
}
