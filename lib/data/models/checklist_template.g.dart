// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checklist_template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChecklistTemplateImpl _$$ChecklistTemplateImplFromJson(
        Map<String, dynamic> json) =>
    _$ChecklistTemplateImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      version: (json['version'] as num?)?.toInt() ?? 1,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const <String>[],
      schema:
          json['schema'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      createdBy: json['createdBy'] as String?,
      updatedAt: const TimestampConverter().fromJson(json['updatedAt']),
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
    );

Map<String, dynamic> _$$ChecklistTemplateImplToJson(
        _$ChecklistTemplateImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'version': instance.version,
      'tags': instance.tags,
      'schema': instance.schema,
      'createdBy': instance.createdBy,
      'updatedAt': const TimestampConverter().toJson(instance.updatedAt),
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
    };
