import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/timestamp_converter.dart';

part 'history_event.freezed.dart';
part 'history_event.g.dart';

@freezed
class HistoryEvent with _$HistoryEvent {
  const factory HistoryEvent({
    required String id,
    required String type, // 'equipment_created' | 'checklist_submitted' | ...
    required String actorUid,
    String? equipmentId,
    String? instanceId,
    @TimestampConverter() DateTime? ts,
    @Default(<String, dynamic>{}) Map<String, dynamic> meta, // extra snapshot data if needed
  }) = _HistoryEvent;

  factory HistoryEvent.fromJson(Map<String, dynamic> json) => _$HistoryEventFromJson(json);

  static HistoryEvent fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return HistoryEvent.fromJson({...data, 'id': doc.id});
  }
}
