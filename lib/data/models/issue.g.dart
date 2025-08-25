// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'issue.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$IssueImpl _$$IssueImplFromJson(Map<String, dynamic> json) => _$IssueImpl(
      id: json['id'] as String,
      equipmentId: json['equipmentId'] as String,
      instanceId: json['instanceId'] as String?,
      severity: $enumDecodeNullable(_$IssueSeverityEnumMap, json['severity']) ??
          IssueSeverity.low,
      status: $enumDecodeNullable(_$IssueStatusEnumMap, json['status']) ??
          IssueStatus.open,
      description: json['description'] as String,
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      createdBy: json['createdBy'] as String,
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
      updatedAt: const TimestampConverter().fromJson(json['updatedAt']),
    );

Map<String, dynamic> _$$IssueImplToJson(_$IssueImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'equipmentId': instance.equipmentId,
      'instanceId': instance.instanceId,
      'severity': _$IssueSeverityEnumMap[instance.severity]!,
      'status': _$IssueStatusEnumMap[instance.status]!,
      'description': instance.description,
      'images': instance.images,
      'createdBy': instance.createdBy,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'updatedAt': const TimestampConverter().toJson(instance.updatedAt),
    };

const _$IssueSeverityEnumMap = {
  IssueSeverity.low: 'low',
  IssueSeverity.medium: 'medium',
  IssueSeverity.high: 'high',
  IssueSeverity.critical: 'critical',
};

const _$IssueStatusEnumMap = {
  IssueStatus.open: 'open',
  IssueStatus.closed: 'closed',
};
