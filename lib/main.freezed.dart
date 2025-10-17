// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'main.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$DocumentUploadState {
  String get name => throw _privateConstructorUsedError;
  String get lastName => throw _privateConstructorUsedError;
  List<UploadedFile> get files => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;

  /// Create a copy of DocumentUploadState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DocumentUploadStateCopyWith<DocumentUploadState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DocumentUploadStateCopyWith<$Res> {
  factory $DocumentUploadStateCopyWith(
    DocumentUploadState value,
    $Res Function(DocumentUploadState) then,
  ) = _$DocumentUploadStateCopyWithImpl<$Res, DocumentUploadState>;
  @useResult
  $Res call({
    String name,
    String lastName,
    List<UploadedFile> files,
    bool isLoading,
  });
}

/// @nodoc
class _$DocumentUploadStateCopyWithImpl<$Res, $Val extends DocumentUploadState>
    implements $DocumentUploadStateCopyWith<$Res> {
  _$DocumentUploadStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DocumentUploadState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? lastName = null,
    Object? files = null,
    Object? isLoading = null,
  }) {
    return _then(
      _value.copyWith(
            name:
                null == name
                    ? _value.name
                    : name // ignore: cast_nullable_to_non_nullable
                        as String,
            lastName:
                null == lastName
                    ? _value.lastName
                    : lastName // ignore: cast_nullable_to_non_nullable
                        as String,
            files:
                null == files
                    ? _value.files
                    : files // ignore: cast_nullable_to_non_nullable
                        as List<UploadedFile>,
            isLoading:
                null == isLoading
                    ? _value.isLoading
                    : isLoading // ignore: cast_nullable_to_non_nullable
                        as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DocumentUploadStateImplCopyWith<$Res>
    implements $DocumentUploadStateCopyWith<$Res> {
  factory _$$DocumentUploadStateImplCopyWith(
    _$DocumentUploadStateImpl value,
    $Res Function(_$DocumentUploadStateImpl) then,
  ) = __$$DocumentUploadStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String name,
    String lastName,
    List<UploadedFile> files,
    bool isLoading,
  });
}

/// @nodoc
class __$$DocumentUploadStateImplCopyWithImpl<$Res>
    extends _$DocumentUploadStateCopyWithImpl<$Res, _$DocumentUploadStateImpl>
    implements _$$DocumentUploadStateImplCopyWith<$Res> {
  __$$DocumentUploadStateImplCopyWithImpl(
    _$DocumentUploadStateImpl _value,
    $Res Function(_$DocumentUploadStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DocumentUploadState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? lastName = null,
    Object? files = null,
    Object? isLoading = null,
  }) {
    return _then(
      _$DocumentUploadStateImpl(
        name:
            null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                    as String,
        lastName:
            null == lastName
                ? _value.lastName
                : lastName // ignore: cast_nullable_to_non_nullable
                    as String,
        files:
            null == files
                ? _value._files
                : files // ignore: cast_nullable_to_non_nullable
                    as List<UploadedFile>,
        isLoading:
            null == isLoading
                ? _value.isLoading
                : isLoading // ignore: cast_nullable_to_non_nullable
                    as bool,
      ),
    );
  }
}

/// @nodoc

class _$DocumentUploadStateImpl implements _DocumentUploadState {
  const _$DocumentUploadStateImpl({
    required this.name,
    required this.lastName,
    required final List<UploadedFile> files,
    this.isLoading = false,
  }) : _files = files;

  @override
  final String name;
  @override
  final String lastName;
  final List<UploadedFile> _files;
  @override
  List<UploadedFile> get files {
    if (_files is EqualUnmodifiableListView) return _files;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_files);
  }

  @override
  @JsonKey()
  final bool isLoading;

  @override
  String toString() {
    return 'DocumentUploadState(name: $name, lastName: $lastName, files: $files, isLoading: $isLoading)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DocumentUploadStateImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.lastName, lastName) ||
                other.lastName == lastName) &&
            const DeepCollectionEquality().equals(other._files, _files) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    name,
    lastName,
    const DeepCollectionEquality().hash(_files),
    isLoading,
  );

  /// Create a copy of DocumentUploadState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DocumentUploadStateImplCopyWith<_$DocumentUploadStateImpl> get copyWith =>
      __$$DocumentUploadStateImplCopyWithImpl<_$DocumentUploadStateImpl>(
        this,
        _$identity,
      );
}

abstract class _DocumentUploadState implements DocumentUploadState {
  const factory _DocumentUploadState({
    required final String name,
    required final String lastName,
    required final List<UploadedFile> files,
    final bool isLoading,
  }) = _$DocumentUploadStateImpl;

  @override
  String get name;
  @override
  String get lastName;
  @override
  List<UploadedFile> get files;
  @override
  bool get isLoading;

  /// Create a copy of DocumentUploadState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DocumentUploadStateImplCopyWith<_$DocumentUploadStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
