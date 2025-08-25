// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'checklist_template.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ChecklistTemplate _$ChecklistTemplateFromJson(Map<String, dynamic> json) {
  return _ChecklistTemplate.fromJson(json);
}

/// @nodoc
mixin _$ChecklistTemplate {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  int get version => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;
  Map<String, dynamic> get schema =>
      throw _privateConstructorUsedError; // sections/fields JSON
  String? get createdBy => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this ChecklistTemplate to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ChecklistTemplate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChecklistTemplateCopyWith<ChecklistTemplate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChecklistTemplateCopyWith<$Res> {
  factory $ChecklistTemplateCopyWith(
          ChecklistTemplate value, $Res Function(ChecklistTemplate) then) =
      _$ChecklistTemplateCopyWithImpl<$Res, ChecklistTemplate>;
  @useResult
  $Res call(
      {String id,
      String title,
      int version,
      List<String> tags,
      Map<String, dynamic> schema,
      String? createdBy,
      @TimestampConverter() DateTime? updatedAt,
      @TimestampConverter() DateTime? createdAt});
}

/// @nodoc
class _$ChecklistTemplateCopyWithImpl<$Res, $Val extends ChecklistTemplate>
    implements $ChecklistTemplateCopyWith<$Res> {
  _$ChecklistTemplateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChecklistTemplate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? version = null,
    Object? tags = null,
    Object? schema = null,
    Object? createdBy = freezed,
    Object? updatedAt = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as int,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      schema: null == schema
          ? _value.schema
          : schema // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      createdBy: freezed == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ChecklistTemplateImplCopyWith<$Res>
    implements $ChecklistTemplateCopyWith<$Res> {
  factory _$$ChecklistTemplateImplCopyWith(_$ChecklistTemplateImpl value,
          $Res Function(_$ChecklistTemplateImpl) then) =
      __$$ChecklistTemplateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      int version,
      List<String> tags,
      Map<String, dynamic> schema,
      String? createdBy,
      @TimestampConverter() DateTime? updatedAt,
      @TimestampConverter() DateTime? createdAt});
}

/// @nodoc
class __$$ChecklistTemplateImplCopyWithImpl<$Res>
    extends _$ChecklistTemplateCopyWithImpl<$Res, _$ChecklistTemplateImpl>
    implements _$$ChecklistTemplateImplCopyWith<$Res> {
  __$$ChecklistTemplateImplCopyWithImpl(_$ChecklistTemplateImpl _value,
      $Res Function(_$ChecklistTemplateImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChecklistTemplate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? version = null,
    Object? tags = null,
    Object? schema = null,
    Object? createdBy = freezed,
    Object? updatedAt = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$ChecklistTemplateImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as int,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      schema: null == schema
          ? _value._schema
          : schema // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      createdBy: freezed == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ChecklistTemplateImpl implements _ChecklistTemplate {
  const _$ChecklistTemplateImpl(
      {required this.id,
      required this.title,
      this.version = 1,
      final List<String> tags = const <String>[],
      final Map<String, dynamic> schema = const <String, dynamic>{},
      this.createdBy,
      @TimestampConverter() this.updatedAt,
      @TimestampConverter() this.createdAt})
      : _tags = tags,
        _schema = schema;

  factory _$ChecklistTemplateImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChecklistTemplateImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  @JsonKey()
  final int version;
  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  final Map<String, dynamic> _schema;
  @override
  @JsonKey()
  Map<String, dynamic> get schema {
    if (_schema is EqualUnmodifiableMapView) return _schema;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_schema);
  }

// sections/fields JSON
  @override
  final String? createdBy;
  @override
  @TimestampConverter()
  final DateTime? updatedAt;
  @override
  @TimestampConverter()
  final DateTime? createdAt;

  @override
  String toString() {
    return 'ChecklistTemplate(id: $id, title: $title, version: $version, tags: $tags, schema: $schema, createdBy: $createdBy, updatedAt: $updatedAt, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChecklistTemplateImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.version, version) || other.version == version) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            const DeepCollectionEquality().equals(other._schema, _schema) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      version,
      const DeepCollectionEquality().hash(_tags),
      const DeepCollectionEquality().hash(_schema),
      createdBy,
      updatedAt,
      createdAt);

  /// Create a copy of ChecklistTemplate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChecklistTemplateImplCopyWith<_$ChecklistTemplateImpl> get copyWith =>
      __$$ChecklistTemplateImplCopyWithImpl<_$ChecklistTemplateImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChecklistTemplateImplToJson(
      this,
    );
  }
}

abstract class _ChecklistTemplate implements ChecklistTemplate {
  const factory _ChecklistTemplate(
          {required final String id,
          required final String title,
          final int version,
          final List<String> tags,
          final Map<String, dynamic> schema,
          final String? createdBy,
          @TimestampConverter() final DateTime? updatedAt,
          @TimestampConverter() final DateTime? createdAt}) =
      _$ChecklistTemplateImpl;

  factory _ChecklistTemplate.fromJson(Map<String, dynamic> json) =
      _$ChecklistTemplateImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  int get version;
  @override
  List<String> get tags;
  @override
  Map<String, dynamic> get schema; // sections/fields JSON
  @override
  String? get createdBy;
  @override
  @TimestampConverter()
  DateTime? get updatedAt;
  @override
  @TimestampConverter()
  DateTime? get createdAt;

  /// Create a copy of ChecklistTemplate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChecklistTemplateImplCopyWith<_$ChecklistTemplateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
