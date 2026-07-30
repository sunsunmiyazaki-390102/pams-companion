import '../models/project.dart';

abstract class ProjectRepository {
  Future<List<Project>> getProjects();

  Future<Project?> getProject(String projectId);

  Future<void> saveProject(Project project);

  Future<void> deleteProject(String projectId);
}
