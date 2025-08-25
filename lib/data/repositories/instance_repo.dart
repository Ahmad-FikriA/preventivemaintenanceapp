import '../models/checklist_instance.dart';

abstract class InstanceRepo {
  Stream<List<ChecklistInstance>> watchMyWorkToday(String uid, DateTime day);
  Stream<List<ChecklistInstance>> watchDrafts(String uid);
  Future<ChecklistInstance?> getById(String id);

  Future<ChecklistInstance> createFromTemplate({
    required String templateId,
    required String equipmentId,
    required String createdBy,
    DateTime? dueDate,
  });

  Future<ChecklistInstance> createFromTemplateAssigned({
    required String templateId,
    required String equipmentId,
    required String createdBy,
    required List<String> assignees,
    DateTime? dueDate,
  });

  Future<void> updateAssignees(String instanceId, List<String> assignees);

  Future<void> saveAnswers(String instanceId, Map<String, dynamic> patch);
  Future<void> attachImage(String instanceId, String fieldKey, String url);
  Future<void> submit(String instanceId, {String? templateTitle, String? equipmentName});
  Future<void> delete(String instanceId);
}
