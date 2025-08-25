// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'history_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

HistoryEvent _$HistoryEventFromJson(Map<String, dynamic> json) {
  return _HistoryEvent.fromJson(json);
}

/// @nodoc
mixin _$HistoryEvent {
  String get id => throw _privateConstructorUsedError;
  String get type =>
      throw _privateConstructorUsedError; // 'equipment_created' | 'checklist_submitted' | ...
  String get actorUid => throw _privateConstructorUsedError;
  String? get equipmentId => throw _privateConstructorUsedError;
  String? get instanceId => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime? get ts => throw _privateConstructorUsedError;
  Map<String, dynamic> get meta => throw _privateConstructorUsedError;

  /// Serializes this HistoryEvent to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HistoryEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HistoryEventCopyWith<HistoryEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HistoryEventCopyWith<$Res> {
  factory $HistoryEventCopyWith(
          HistoryEvent value, $Res Function(HistoryEvent) then) =
      _$HistoryEventCopyWithImpl<$Res, HistoryEvent>;
  @useResult
  $Res call(
      {String id,
      String type,
      String actorUid,
      String? equipmentId,
      String? instanceId,
      @TimestampConverter() DateTime? ts,
      Map<String, dynamic> meta});
}

/// @nodoc
class _$HistoryEventCopyWithImpl<$Res, $Val extends HistoryEvent>
    implements $HistoryEventCopyWith<$Res> {
  _$HistoryEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HistoryEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? actorUid = null,
    Object? equipmentId = freezed,
    Object? instanceId = freezed,
    Object? ts = freezed,
    Object? meta = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      actorUid: null == actorUid
          ? _value.actorUid
          : actorUid // ignore: cast_nullable_to_non_nullable
              as String,
      equipmentId: freezed == equipmentId
          ? _value.equipmentId
          : equipmentId // ignore: cast_nullable_to_non_nullable
              as String?,
      instanceId: freezed == instanceId
          ? _value.instanceId
          : instanceId // ignore: cast_nullable_to_non_nullable
              as String?,
      ts: freezed == ts
          ? _value.ts
          : ts // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      meta: null == meta
          ? _value.meta
          : meta // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HistoryEventImplCopyWith<$Res>
    implements $HistoryEventCopyWith<$Res> {
  factory _$$HistoryEventImplCopyWith(
          _$HistoryEventImpl value, $Res Function(_$HistoryEventImpl) then) =
      __$$HistoryEventImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String type,
      String actorUid,
      String? equipmentId,
      String? instanceId,
      @TimestampConverter() DateTime? ts,
      Map<String, dynamic> meta});
}

/// @nodoc
class __$$HistoryEventImplCopyWithImpl<$Res>
    extends _$HistoryEventCopyWithImpl<$Res, _$HistoryEventImpl>
    implements _$$HistoryEventImplCopyWith<$Res> {
  __$$HistoryEventImplCopyWithImpl(
      _$HistoryEventImpl _value, $Res Function(_$HistoryEventImpl) _then)
      : super(_value, _then);

  /// Create a copy of HistoryEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? actorUid = null,
    Object? equipmentId = freezed,
    Object? instanceId = freezed,
    Object? ts = freezed,
    Object? meta = null,
  }) {
    return _then(_$HistoryEventImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      actorUid: null == actorUid
          ? _value.actorUid
          : actorUid // ignore: cast_nullable_to_non_nullable
              as String,
      equipmentId: freezed == equipmentId
          ? _value.equipmentId
          : equipmentId // ignore: cast_nullable_to_non_nullable
              as String?,
      instanceId: freezed == instanceId
          ? _value.instanceId
          : instanceId // ignore: cast_nullable_to_non_nullable
              as String?,
      ts: freezed == ts
          ? _value.ts
          : ts // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      meta: null == meta
          ? _value._meta
          : meta // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HistoryEventImpl implements _HistoryEvent {
  const _$HistoryEventImpl(
      {required this.id,
      required this.type,
      required this.actorUid,
      this.equipmentId,
      this.instanceId,
      @TimestampConverter() this.ts,
      final Map<String, dynamic> meta = const <String, dynamic>{}})
      : _meta = meta;

  factory _$HistoryEventImpl.fromJson(Map<String, dynamic> json) =>
      _$$HistoryEventImplFromJson(json);

  @override
  final String id;
  @override
  final String type;
// 'equipment_created' | 'checklist_submitted' | ...
  @override
  final String actorUid;
  @override
  final String? equipmentId;
  @override
  final String? instanceId;
  @override
  @TimestampConverter()
  final DateTime? ts;
  final Map<String, dynamic> _meta;
  @override
  @JsonKey()
  Map<String, dynamic> get meta {
    if (_meta is EqualUnmodifiableMapView) return _meta;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_meta);
  }

  @override
  String toString() {
    return 'HistoryEvent(id: $id, type: $type, actorUid: $actorUid, equipmentId: $equipmentId, instanceId: $instanceId, ts: $ts, meta: $meta)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HistoryEventImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.actorUid, actorUid) ||
                other.actorUid == actorUid) &&
            (identical(other.equipmentId, equipmentId) ||
                other.equipmentId == equipmentId) &&
            (identical(other.instanceId, instanceId) ||
                other.instanceId == instanceId) &&
            (identical(other.ts, ts) || other.ts == ts) &&
            const DeepCollectionEquality().equals(other._meta, _meta));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, type, actorUid, equipmentId,
      instanceId, ts, const DeepCollectionEquality().hash(_meta));

  /// Create a copy of HistoryEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HistoryEventImplCopyWith<_$HistoryEventImpl> get copyWith =>
      __$$HistoryEventImplCopyWithImpl<_$HistoryEventImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HistoryEventImplToJson(
      this,
    );
  }
}

abstract class _HistoryEvent implements HistoryEvent {
  const factory _HistoryEvent(
      {required final String id,
      required final String type,
      required final String actorUid,
      final String? equipmentId,
      final String? instanceId,
      @TimestampConverter() final DateTime? ts,
      final Map<String, dynamic> meta}) = _$HistoryEventImpl;

  factory _HistoryEvent.fromJson(Map<String, dynamic> json) =
      _$HistoryEventImpl.fromJson;

  @override
  String get id;
  @override
  String get type; // 'equipment_created' | 'checklist_submitted' | ...
  @override
  String get actorUid;
  @override
  String? get equipmentId;
  @override
  String? get instanceId;
  @override
  @TimestampConverter()
  DateTime? get ts;
  @override
  Map<String, dynamic> get meta;

  /// Create a copy of HistoryEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HistoryEventImplCopyWith<_$HistoryEventImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
