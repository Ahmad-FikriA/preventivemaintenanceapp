import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/timestamp_converter.dart';

part 'equipment.freezed.dart';
part 'equipment.g.dart';

@freezed
class Equipment with _$Equipment {
  const factory Equipment({
    required String id,
    required String name,
    required String code,
    String? location,
    @Default(<String>[]) List<String> images, // gs:// or https:// URLs
    String? createdBy,
    @TimestampConverter() DateTime? updatedAt,
    @TimestampConverter() DateTime? createdAt,
  }) = _Equipment;

  factory Equipment.fromJson(Map<String, dynamic> json) => _$EquipmentFromJson(json);

  static Equipment fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Equipment.fromJson({...data, 'id': doc.id});
  }
}
