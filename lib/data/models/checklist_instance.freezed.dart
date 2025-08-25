// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'checklist_instance.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ChecklistInstance _$ChecklistInstanceFromJson(Map<String, dynamic> json) {
  return _ChecklistInstance.fromJson(json);
}

/// @nodoc
mixin _$ChecklistInstance {
  String get id => throw _privateConstructorUsedError;
  String get templateId => throw _privateConstructorUsedError;
  String get equipmentId => throw _privateConstructorUsedError;
  ChecklistStatus get status => throw _privateConstructorUsedError;
  Map<String, dynamic> get answers =>
      throw _privateConstructorUsedError; // fieldKey -> value/URL
  List<String> get images => throw _privateConstructorUsedError; // extra photos
  List<String> get assignees => throw _privateConstructorUsedError; // uids
  @TimestampConverter()
  DateTime? get dueDate => throw _privateConstructorUsedError;
  String get createdBy => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this ChecklistInstance to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ChecklistInstance
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChecklistInstanceCopyWith<ChecklistInstance> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChecklistInstanceCopyWith<$Res> {
  factory $ChecklistInstanceCopyWith(
          ChecklistInstance value, $Res Function(ChecklistInstance) then) =
      _$ChecklistInstanceCopyWithImpl<$Res, ChecklistInstance>;
  @useResult
  $Res call(
      {String id,
      String templateId,
      String equipmentId,
      ChecklistStatus status,
      Map<String, dynamic> answers,
      List<String> images,
      List<String> assignees,
      @TimestampConverter() DateTime? dueDate,
      String createdBy,
      @TimestampConverter() DateTime? updatedAt,
      @TimestampConverter() DateTime? createdAt});
}

/// @nodoc
class _$ChecklistInstanceCopyWithImpl<$Res, $Val extends ChecklistInstance>
    implements $ChecklistInstanceCopyWith<$Res> {
  _$ChecklistInstanceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChecklistInstance
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? templateId = null,
    Object? equipmentId = null,
    Object? status = null,
    Object? answers = null,
    Object? images = null,
    Object? assignees = null,
    Object? dueDate = freezed,
    Object? createdBy = null,
    Object? updatedAt = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      templateId: null == templateId
          ? _value.templateId
          : templateId // ignore: cast_nullable_to_non_nullable
              as String,
      equipmentId: null == equipmentId
          ? _value.equipmentId
          : equipmentId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as ChecklistStatus,
      answers: null == answers
          ? _value.answers
          : answers // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      images: null == images
          ? _value.images
          : images // ignore: cast_nullable_to_non_nullable
              as List<String>,
      assignees: null == assignees
          ? _value.assignees
          : assignees // ignore: cast_nullable_to_non_nullable
              as List<String>,
      dueDate: freezed == dueDate
          ? _value.dueDate
          : dueDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdBy: null == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String,
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
abstract class _$$ChecklistInstanceImplCopyWith<$Res>
    implements $ChecklistInstanceCopyWith<$Res> {
  factory _$$ChecklistInstanceImplCopyWith(_$ChecklistInstanceImpl value,
          $Res Function(_$ChecklistInstanceImpl) then) =
      __$$ChecklistInstanceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String templateId,
      String equipmentId,
      ChecklistStatus status,
      Map<String, dynamic> answers,
      List<String> images,
      List<String> assignees,
      @TimestampConverter() DateTime? dueDate,
      String createdBy,
      @TimestampConverter() DateTime? updatedAt,
      @TimestampConverter() DateTime? createdAt});
}

/// @nodoc
class __$$ChecklistInstanceImplCopyWithImpl<$Res>
    extends _$ChecklistInstanceCopyWithImpl<$Res, _$ChecklistInstanceImpl>
    implements _$$ChecklistInstanceImplCopyWith<$Res> {
  __$$ChecklistInstanceImplCopyWithImpl(_$ChecklistInstanceImpl _value,
      $Res Function(_$ChecklistInstanceImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChecklistInstance
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? templateId = null,
    Object? equipmentId = null,
    Object? status = null,
    Object? answers = null,
    Object? images = null,
    Object? assignees = null,
    Object? dueDate = freezed,
    Object? createdBy = null,
    Object? updatedAt = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$ChecklistInstanceImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      templateId: null == templateId
          ? _value.templateId
          : templateId // ignore: cast_nullable_to_non_nullable
              as String,
      equipmentId: null == equipmentId
          ? _value.equipmentId
          : equipmentId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as ChecklistStatus,
      answers: null == answers
          ? _value._answers
          : answers // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      images: null == images
          ? _value._images
          : images // ignore: cast_nullable_to_non_nullable
              as List<String>,
      assignees: null == assignees
          ? _value._assignees
          : assignees // ignore: cast_nullable_to_non_nullable
              as List<String>,
      dueDate: freezed == dueDate
          ? _value.dueDate
          : dueDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdBy: null == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String,
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
class _$ChecklistInstanceImpl implements _ChecklistInstance {
  const _$ChecklistInstanceImpl(
      {required this.id,
      required this.templateId,
      required this.equipmentId,
      this.status = ChecklistStatus.draft,
      final Map<String, dynamic> answers = const <String, dynamic>{},
      final List<String> images = const <String>[],
      final List<String> assignees = const <String>[],
      @TimestampConverter() this.dueDate,
      required this.createdBy,
      @TimestampConverter() this.updatedAt,
      @TimestampConverter() this.createdAt})
      : _answers = answers,
        _images = images,
        _assignees = assignees;

  factory _$ChecklistInstanceImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChecklistInstanceImplFromJson(json);

  @override
  final String id;
  @override
  final String templateId;
  @override
  final String equipmentId;
  @override
  @JsonKey()
  final ChecklistStatus status;
  final Map<String, dynamic> _answers;
  @override
  @JsonKey()
  Map<String, dynamic> get answers {
    if (_answers is EqualUnmodifiableMapView) return _answers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_answers);
  }

// fieldKey -> value/URL
  final List<String> _images;
// fieldKey -> value/URL
  @override
  @JsonKey()
  List<String> get images {
    if (_images is EqualUnmodifiableListView) return _images;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_images);
  }

// extra photos
  final List<String> _assignees;
// extra photos
  @override
  @JsonKey()
  List<String> get assignees {
    if (_assignees is EqualUnmodifiableListView) return _assignees;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_assignees);
  }

// uids
  @override
  @TimestampConverter()
  final DateTime? dueDate;
  @override
  final String createdBy;
  @override
  @TimestampConverter()
  final DateTime? updatedAt;
  @override
  @TimestampConverter()
  final DateTime? createdAt;

  @override
  String toString() {
    return 'ChecklistInstance(id: $id, templateId: $templateId, equipmentId: $equipmentId, status: $status, answers: $answers, images: $images, assignees: $assignees, dueDate: $dueDate, createdBy: $createdBy, updatedAt: $updatedAt, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChecklistInstanceImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.templateId, templateId) ||
                other.templateId == templateId) &&
            (identical(other.equipmentId, equipmentId) ||
                other.equipmentId == equipmentId) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(other._answers, _answers) &&
            const DeepCollectionEquality().equals(other._images, _images) &&
            const DeepCollectionEquality()
                .equals(other._assignees, _assignees) &&
            (identical(other.dueDate, dueDate) || other.dueDate == dueDate) &&
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
      templateId,
      equipmentId,
      status,
      const DeepCollectionEquality().hash(_answers),
      const DeepCollectionEquality().hash(_images),
      const DeepCollectionEquality().hash(_assignees),
      dueDate,
      createdBy,
      updatedAt,
      createdAt);

  /// Create a copy of ChecklistInstance
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChecklistInstanceImplCopyWith<_$ChecklistInstanceImpl> get copyWith =>
      __$$ChecklistInstanceImplCopyWithImpl<_$ChecklistInstanceImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChecklistInstanceImplToJson(
      this,
    );
  }
}

abstract class _ChecklistInstance implements ChecklistInstance {
  const factory _ChecklistInstance(
          {required final String id,
          required final String templateId,
          required final String equipmentId,
          final ChecklistStatus status,
          final Map<String, dynamic> answers,
          final List<String> images,
          final List<String> assignees,
          @TimestampConverter() final DateTime? dueDate,
          required final String createdBy,
          @TimestampConverter() final DateTime? updatedAt,
          @TimestampConverter() final DateTime? createdAt}) =
      _$ChecklistInstanceImpl;

  factory _ChecklistInstance.fromJson(Map<String, dynamic> json) =
      _$ChecklistInstanceImpl.fromJson;

  @override
  String get id;
  @override
  String get templateId;
  @override
  String get equipmentId;
  @override
  ChecklistStatus get status;
  @override
  Map<String, dynamic> get answers; // fieldKey -> value/URL
  @override
  List<String> get images; // extra photos
  @override
  List<String> get assignees; // uids
  @override
  @TimestampConverter()
  DateTime? get dueDate;
  @override
  String get createdBy;
  @override
  @TimestampConverter()
  DateTime? get updatedAt;
  @override
  @TimestampConverter()
  DateTime? get createdAt;

  /// Create a copy of ChecklistInstance
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChecklistInstanceImplCopyWith<_$ChecklistInstanceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
