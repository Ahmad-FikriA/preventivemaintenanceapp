import '../models/issue.dart';

abstract class IssueRepo {
  Future<Issue> create({
    required String equipmentId,
    String? instanceId,
    required String description,
    required IssueSeverity severity,
    required String createdBy,
    List<String> imageUrls = const [],
  });
}
