import '../models/checklist_template.dart';

abstract class TemplateRepo {
  Stream<List<ChecklistTemplate>> watchAll();
  Stream<List<ChecklistTemplate>> watchPublished();
  Future<ChecklistTemplate?> getById(String id);
  Future<ChecklistTemplate> create(ChecklistTemplate t);
  Future<void> update(ChecklistTemplate t);
}
