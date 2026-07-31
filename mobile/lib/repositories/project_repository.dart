import '../database/database_helper.dart';
import '../models/project.dart';

class ProjectRepository {
  final _databaseHelper = DatabaseHelper.instance;

  Future<void> insert(Project project) async {
    final database = await _databaseHelper.database;

    await database.insert(
      'projects',
      {
        'project_id': project.projectId,
        'name': project.name,
        'description': project.description,
        'created_at': project.createdAt.toIso8601String(),
        'updated_at': project.updatedAt.toIso8601String(),
      },
    );
  }

  Future<List<Project>> findAll() async {
    final database = await _databaseHelper.database;

    final maps = await database.query(
      'projects',
      orderBy: 'created_at DESC',
    );

    return maps
        .map(
          Project.fromMap,
        )
        .toList();
  }
}
