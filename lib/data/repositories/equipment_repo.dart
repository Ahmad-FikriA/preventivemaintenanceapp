import 'dart:io';
import '../models/equipment.dart';

abstract class EquipmentRepo {
  Stream<List<Equipment>> watchAll();
  Future<Equipment?> getById(String id);
  Future<Equipment> create(Equipment e);
  Future<void> update(Equipment e);
  Future<void> delete(String id);
  Future<String> uploadImage({required String equipmentId, required File file});
}
