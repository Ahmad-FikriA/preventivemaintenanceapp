// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HistoryEventImpl _$$HistoryEventImplFromJson(Map<String, dynamic> json) =>
    _$HistoryEventImpl(
      id: json['id'] as String,
      type: json['type'] as String,
      actorUid: json['actorUid'] as String,
      equipmentId: json['equipmentId'] as String?,
      instanceId: json['instanceId'] as String?,
      ts: const TimestampConverter().fromJson(json['ts']),
      meta: json['meta'] as Map<String, dynamic>? ?? const <String, dynamic>{},
    );

Map<String, dynamic> _$$HistoryEventImplToJson(_$HistoryEventImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'actorUid': instance.actorUid,
      'equipmentId': instance.equipmentId,
      'instanceId': instance.instanceId,
      'ts': const TimestampConverter().toJson(instance.ts),
      'meta': instance.meta,
    };
