// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ActivitiesTableTable extends ActivitiesTable
    with TableInfo<$ActivitiesTableTable, ActivityEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivitiesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  @override
  late final GeneratedColumn<int> startTime = GeneratedColumn<int>(
      'start_time', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _endTimeMeta =
      const VerificationMeta('endTime');
  @override
  late final GeneratedColumn<int> endTime = GeneratedColumn<int>(
      'end_time', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _distanceMetersMeta =
      const VerificationMeta('distanceMeters');
  @override
  late final GeneratedColumn<double> distanceMeters = GeneratedColumn<double>(
      'distance_meters', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _durationSecondsMeta =
      const VerificationMeta('durationSeconds');
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
      'duration_seconds', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _elevationGainMetersMeta =
      const VerificationMeta('elevationGainMeters');
  @override
  late final GeneratedColumn<double> elevationGainMeters =
      GeneratedColumn<double>('elevation_gain_meters', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(0.0));
  static const VerificationMeta _elevationLossMetersMeta =
      const VerificationMeta('elevationLossMeters');
  @override
  late final GeneratedColumn<double> elevationLossMeters =
      GeneratedColumn<double>('elevation_loss_meters', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(0.0));
  static const VerificationMeta _averagePaceSecondsPerKmMeta =
      const VerificationMeta('averagePaceSecondsPerKm');
  @override
  late final GeneratedColumn<double> averagePaceSecondsPerKm =
      GeneratedColumn<double>('average_pace_seconds_per_km', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _privacyLevelMeta =
      const VerificationMeta('privacyLevel');
  @override
  late final GeneratedColumn<int> privacyLevel = GeneratedColumn<int>(
      'privacy_level', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _coverPhotoIdMeta =
      const VerificationMeta('coverPhotoId');
  @override
  late final GeneratedColumn<String> coverPhotoId = GeneratedColumn<String>(
      'cover_photo_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _syncStateMeta =
      const VerificationMeta('syncState');
  @override
  late final GeneratedColumn<int> syncState = GeneratedColumn<int>(
      'sync_state', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        startTime,
        endTime,
        distanceMeters,
        durationSeconds,
        elevationGainMeters,
        elevationLossMeters,
        averagePaceSecondsPerKm,
        title,
        notes,
        privacyLevel,
        coverPhotoId,
        syncState,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activities';
  @override
  VerificationContext validateIntegrity(Insertable<ActivityEntity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(_endTimeMeta,
          endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta));
    }
    if (data.containsKey('distance_meters')) {
      context.handle(
          _distanceMetersMeta,
          distanceMeters.isAcceptableOrUnknown(
              data['distance_meters']!, _distanceMetersMeta));
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
          _durationSecondsMeta,
          durationSeconds.isAcceptableOrUnknown(
              data['duration_seconds']!, _durationSecondsMeta));
    }
    if (data.containsKey('elevation_gain_meters')) {
      context.handle(
          _elevationGainMetersMeta,
          elevationGainMeters.isAcceptableOrUnknown(
              data['elevation_gain_meters']!, _elevationGainMetersMeta));
    }
    if (data.containsKey('elevation_loss_meters')) {
      context.handle(
          _elevationLossMetersMeta,
          elevationLossMeters.isAcceptableOrUnknown(
              data['elevation_loss_meters']!, _elevationLossMetersMeta));
    }
    if (data.containsKey('average_pace_seconds_per_km')) {
      context.handle(
          _averagePaceSecondsPerKmMeta,
          averagePaceSecondsPerKm.isAcceptableOrUnknown(
              data['average_pace_seconds_per_km']!,
              _averagePaceSecondsPerKmMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('privacy_level')) {
      context.handle(
          _privacyLevelMeta,
          privacyLevel.isAcceptableOrUnknown(
              data['privacy_level']!, _privacyLevelMeta));
    }
    if (data.containsKey('cover_photo_id')) {
      context.handle(
          _coverPhotoIdMeta,
          coverPhotoId.isAcceptableOrUnknown(
              data['cover_photo_id']!, _coverPhotoIdMeta));
    }
    if (data.containsKey('sync_state')) {
      context.handle(_syncStateMeta,
          syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ActivityEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActivityEntity(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}start_time'])!,
      endTime: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}end_time']),
      distanceMeters: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}distance_meters'])!,
      durationSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_seconds'])!,
      elevationGainMeters: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}elevation_gain_meters'])!,
      elevationLossMeters: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}elevation_loss_meters'])!,
      averagePaceSecondsPerKm: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}average_pace_seconds_per_km']),
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      privacyLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}privacy_level'])!,
      coverPhotoId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover_photo_id']),
      syncState: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sync_state'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ActivitiesTableTable createAlias(String alias) {
    return $ActivitiesTableTable(attachedDatabase, alias);
  }
}

class ActivityEntity extends DataClass implements Insertable<ActivityEntity> {
  /// Unique identifier for the activity
  final String id;

  /// When the activity started (milliseconds since epoch)
  final int startTime;

  /// When the activity ended (milliseconds since epoch, null if in progress)
  final int? endTime;

  /// Total distance covered in meters
  final double distanceMeters;

  /// Total duration in seconds (calculated from start/end time)
  final int durationSeconds;

  /// Total elevation gained in meters
  final double elevationGainMeters;

  /// Total elevation lost in meters
  final double elevationLossMeters;

  /// Average pace in seconds per kilometer
  final double? averagePaceSecondsPerKm;

  /// User-provided title for the activity
  final String title;

  /// Optional user notes about the activity
  final String? notes;

  /// Privacy level (0=private, 1=friends, 2=public)
  final int privacyLevel;

  /// ID of the photo to use as cover image
  final String? coverPhotoId;

  /// Current synchronization state (0=local, 1=pending, 2=syncing, 3=synced, 4=failed, 5=conflict)
  final int syncState;

  /// When this record was created (milliseconds since epoch)
  final int createdAt;

  /// When this record was last updated (milliseconds since epoch)
  final int updatedAt;
  const ActivityEntity(
      {required this.id,
      required this.startTime,
      this.endTime,
      required this.distanceMeters,
      required this.durationSeconds,
      required this.elevationGainMeters,
      required this.elevationLossMeters,
      this.averagePaceSecondsPerKm,
      required this.title,
      this.notes,
      required this.privacyLevel,
      this.coverPhotoId,
      required this.syncState,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['start_time'] = Variable<int>(startTime);
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<int>(endTime);
    }
    map['distance_meters'] = Variable<double>(distanceMeters);
    map['duration_seconds'] = Variable<int>(durationSeconds);
    map['elevation_gain_meters'] = Variable<double>(elevationGainMeters);
    map['elevation_loss_meters'] = Variable<double>(elevationLossMeters);
    if (!nullToAbsent || averagePaceSecondsPerKm != null) {
      map['average_pace_seconds_per_km'] =
          Variable<double>(averagePaceSecondsPerKm);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['privacy_level'] = Variable<int>(privacyLevel);
    if (!nullToAbsent || coverPhotoId != null) {
      map['cover_photo_id'] = Variable<String>(coverPhotoId);
    }
    map['sync_state'] = Variable<int>(syncState);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ActivitiesTableCompanion toCompanion(bool nullToAbsent) {
    return ActivitiesTableCompanion(
      id: Value(id),
      startTime: Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      distanceMeters: Value(distanceMeters),
      durationSeconds: Value(durationSeconds),
      elevationGainMeters: Value(elevationGainMeters),
      elevationLossMeters: Value(elevationLossMeters),
      averagePaceSecondsPerKm: averagePaceSecondsPerKm == null && nullToAbsent
          ? const Value.absent()
          : Value(averagePaceSecondsPerKm),
      title: Value(title),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      privacyLevel: Value(privacyLevel),
      coverPhotoId: coverPhotoId == null && nullToAbsent
          ? const Value.absent()
          : Value(coverPhotoId),
      syncState: Value(syncState),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ActivityEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActivityEntity(
      id: serializer.fromJson<String>(json['id']),
      startTime: serializer.fromJson<int>(json['startTime']),
      endTime: serializer.fromJson<int?>(json['endTime']),
      distanceMeters: serializer.fromJson<double>(json['distanceMeters']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      elevationGainMeters:
          serializer.fromJson<double>(json['elevationGainMeters']),
      elevationLossMeters:
          serializer.fromJson<double>(json['elevationLossMeters']),
      averagePaceSecondsPerKm:
          serializer.fromJson<double?>(json['averagePaceSecondsPerKm']),
      title: serializer.fromJson<String>(json['title']),
      notes: serializer.fromJson<String?>(json['notes']),
      privacyLevel: serializer.fromJson<int>(json['privacyLevel']),
      coverPhotoId: serializer.fromJson<String?>(json['coverPhotoId']),
      syncState: serializer.fromJson<int>(json['syncState']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'startTime': serializer.toJson<int>(startTime),
      'endTime': serializer.toJson<int?>(endTime),
      'distanceMeters': serializer.toJson<double>(distanceMeters),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'elevationGainMeters': serializer.toJson<double>(elevationGainMeters),
      'elevationLossMeters': serializer.toJson<double>(elevationLossMeters),
      'averagePaceSecondsPerKm':
          serializer.toJson<double?>(averagePaceSecondsPerKm),
      'title': serializer.toJson<String>(title),
      'notes': serializer.toJson<String?>(notes),
      'privacyLevel': serializer.toJson<int>(privacyLevel),
      'coverPhotoId': serializer.toJson<String?>(coverPhotoId),
      'syncState': serializer.toJson<int>(syncState),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ActivityEntity copyWith(
          {String? id,
          int? startTime,
          Value<int?> endTime = const Value.absent(),
          double? distanceMeters,
          int? durationSeconds,
          double? elevationGainMeters,
          double? elevationLossMeters,
          Value<double?> averagePaceSecondsPerKm = const Value.absent(),
          String? title,
          Value<String?> notes = const Value.absent(),
          int? privacyLevel,
          Value<String?> coverPhotoId = const Value.absent(),
          int? syncState,
          int? createdAt,
          int? updatedAt}) =>
      ActivityEntity(
        id: id ?? this.id,
        startTime: startTime ?? this.startTime,
        endTime: endTime.present ? endTime.value : this.endTime,
        distanceMeters: distanceMeters ?? this.distanceMeters,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        elevationGainMeters: elevationGainMeters ?? this.elevationGainMeters,
        elevationLossMeters: elevationLossMeters ?? this.elevationLossMeters,
        averagePaceSecondsPerKm: averagePaceSecondsPerKm.present
            ? averagePaceSecondsPerKm.value
            : this.averagePaceSecondsPerKm,
        title: title ?? this.title,
        notes: notes.present ? notes.value : this.notes,
        privacyLevel: privacyLevel ?? this.privacyLevel,
        coverPhotoId:
            coverPhotoId.present ? coverPhotoId.value : this.coverPhotoId,
        syncState: syncState ?? this.syncState,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  ActivityEntity copyWithCompanion(ActivitiesTableCompanion data) {
    return ActivityEntity(
      id: data.id.present ? data.id.value : this.id,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      distanceMeters: data.distanceMeters.present
          ? data.distanceMeters.value
          : this.distanceMeters,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      elevationGainMeters: data.elevationGainMeters.present
          ? data.elevationGainMeters.value
          : this.elevationGainMeters,
      elevationLossMeters: data.elevationLossMeters.present
          ? data.elevationLossMeters.value
          : this.elevationLossMeters,
      averagePaceSecondsPerKm: data.averagePaceSecondsPerKm.present
          ? data.averagePaceSecondsPerKm.value
          : this.averagePaceSecondsPerKm,
      title: data.title.present ? data.title.value : this.title,
      notes: data.notes.present ? data.notes.value : this.notes,
      privacyLevel: data.privacyLevel.present
          ? data.privacyLevel.value
          : this.privacyLevel,
      coverPhotoId: data.coverPhotoId.present
          ? data.coverPhotoId.value
          : this.coverPhotoId,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActivityEntity(')
          ..write('id: $id, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('elevationGainMeters: $elevationGainMeters, ')
          ..write('elevationLossMeters: $elevationLossMeters, ')
          ..write('averagePaceSecondsPerKm: $averagePaceSecondsPerKm, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('privacyLevel: $privacyLevel, ')
          ..write('coverPhotoId: $coverPhotoId, ')
          ..write('syncState: $syncState, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      startTime,
      endTime,
      distanceMeters,
      durationSeconds,
      elevationGainMeters,
      elevationLossMeters,
      averagePaceSecondsPerKm,
      title,
      notes,
      privacyLevel,
      coverPhotoId,
      syncState,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActivityEntity &&
          other.id == this.id &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.distanceMeters == this.distanceMeters &&
          other.durationSeconds == this.durationSeconds &&
          other.elevationGainMeters == this.elevationGainMeters &&
          other.elevationLossMeters == this.elevationLossMeters &&
          other.averagePaceSecondsPerKm == this.averagePaceSecondsPerKm &&
          other.title == this.title &&
          other.notes == this.notes &&
          other.privacyLevel == this.privacyLevel &&
          other.coverPhotoId == this.coverPhotoId &&
          other.syncState == this.syncState &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ActivitiesTableCompanion extends UpdateCompanion<ActivityEntity> {
  final Value<String> id;
  final Value<int> startTime;
  final Value<int?> endTime;
  final Value<double> distanceMeters;
  final Value<int> durationSeconds;
  final Value<double> elevationGainMeters;
  final Value<double> elevationLossMeters;
  final Value<double?> averagePaceSecondsPerKm;
  final Value<String> title;
  final Value<String?> notes;
  final Value<int> privacyLevel;
  final Value<String?> coverPhotoId;
  final Value<int> syncState;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const ActivitiesTableCompanion({
    this.id = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.distanceMeters = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.elevationGainMeters = const Value.absent(),
    this.elevationLossMeters = const Value.absent(),
    this.averagePaceSecondsPerKm = const Value.absent(),
    this.title = const Value.absent(),
    this.notes = const Value.absent(),
    this.privacyLevel = const Value.absent(),
    this.coverPhotoId = const Value.absent(),
    this.syncState = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ActivitiesTableCompanion.insert({
    required String id,
    required int startTime,
    this.endTime = const Value.absent(),
    this.distanceMeters = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.elevationGainMeters = const Value.absent(),
    this.elevationLossMeters = const Value.absent(),
    this.averagePaceSecondsPerKm = const Value.absent(),
    required String title,
    this.notes = const Value.absent(),
    this.privacyLevel = const Value.absent(),
    this.coverPhotoId = const Value.absent(),
    this.syncState = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        startTime = Value(startTime),
        title = Value(title),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<ActivityEntity> custom({
    Expression<String>? id,
    Expression<int>? startTime,
    Expression<int>? endTime,
    Expression<double>? distanceMeters,
    Expression<int>? durationSeconds,
    Expression<double>? elevationGainMeters,
    Expression<double>? elevationLossMeters,
    Expression<double>? averagePaceSecondsPerKm,
    Expression<String>? title,
    Expression<String>? notes,
    Expression<int>? privacyLevel,
    Expression<String>? coverPhotoId,
    Expression<int>? syncState,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (distanceMeters != null) 'distance_meters': distanceMeters,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (elevationGainMeters != null)
        'elevation_gain_meters': elevationGainMeters,
      if (elevationLossMeters != null)
        'elevation_loss_meters': elevationLossMeters,
      if (averagePaceSecondsPerKm != null)
        'average_pace_seconds_per_km': averagePaceSecondsPerKm,
      if (title != null) 'title': title,
      if (notes != null) 'notes': notes,
      if (privacyLevel != null) 'privacy_level': privacyLevel,
      if (coverPhotoId != null) 'cover_photo_id': coverPhotoId,
      if (syncState != null) 'sync_state': syncState,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ActivitiesTableCompanion copyWith(
      {Value<String>? id,
      Value<int>? startTime,
      Value<int?>? endTime,
      Value<double>? distanceMeters,
      Value<int>? durationSeconds,
      Value<double>? elevationGainMeters,
      Value<double>? elevationLossMeters,
      Value<double?>? averagePaceSecondsPerKm,
      Value<String>? title,
      Value<String?>? notes,
      Value<int>? privacyLevel,
      Value<String?>? coverPhotoId,
      Value<int>? syncState,
      Value<int>? createdAt,
      Value<int>? updatedAt,
      Value<int>? rowid}) {
    return ActivitiesTableCompanion(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      elevationGainMeters: elevationGainMeters ?? this.elevationGainMeters,
      elevationLossMeters: elevationLossMeters ?? this.elevationLossMeters,
      averagePaceSecondsPerKm:
          averagePaceSecondsPerKm ?? this.averagePaceSecondsPerKm,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      privacyLevel: privacyLevel ?? this.privacyLevel,
      coverPhotoId: coverPhotoId ?? this.coverPhotoId,
      syncState: syncState ?? this.syncState,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<int>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<int>(endTime.value);
    }
    if (distanceMeters.present) {
      map['distance_meters'] = Variable<double>(distanceMeters.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (elevationGainMeters.present) {
      map['elevation_gain_meters'] =
          Variable<double>(elevationGainMeters.value);
    }
    if (elevationLossMeters.present) {
      map['elevation_loss_meters'] =
          Variable<double>(elevationLossMeters.value);
    }
    if (averagePaceSecondsPerKm.present) {
      map['average_pace_seconds_per_km'] =
          Variable<double>(averagePaceSecondsPerKm.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (privacyLevel.present) {
      map['privacy_level'] = Variable<int>(privacyLevel.value);
    }
    if (coverPhotoId.present) {
      map['cover_photo_id'] = Variable<String>(coverPhotoId.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<int>(syncState.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivitiesTableCompanion(')
          ..write('id: $id, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('elevationGainMeters: $elevationGainMeters, ')
          ..write('elevationLossMeters: $elevationLossMeters, ')
          ..write('averagePaceSecondsPerKm: $averagePaceSecondsPerKm, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('privacyLevel: $privacyLevel, ')
          ..write('coverPhotoId: $coverPhotoId, ')
          ..write('syncState: $syncState, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TrackPointsTableTable extends TrackPointsTable
    with TableInfo<$TrackPointsTableTable, TrackPointEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrackPointsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _activityIdMeta =
      const VerificationMeta('activityId');
  @override
  late final GeneratedColumn<String> activityId = GeneratedColumn<String>(
      'activity_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _latitudeMeta =
      const VerificationMeta('latitude');
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
      'latitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _longitudeMeta =
      const VerificationMeta('longitude');
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
      'longitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _elevationMeta =
      const VerificationMeta('elevation');
  @override
  late final GeneratedColumn<double> elevation = GeneratedColumn<double>(
      'elevation', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _accuracyMeta =
      const VerificationMeta('accuracy');
  @override
  late final GeneratedColumn<double> accuracy = GeneratedColumn<double>(
      'accuracy', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<int> source = GeneratedColumn<int>(
      'source', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _sequenceMeta =
      const VerificationMeta('sequence');
  @override
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
      'sequence', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        activityId,
        timestamp,
        latitude,
        longitude,
        elevation,
        accuracy,
        source,
        sequence
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'track_points';
  @override
  VerificationContext validateIntegrity(Insertable<TrackPointEntity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('activity_id')) {
      context.handle(
          _activityIdMeta,
          activityId.isAcceptableOrUnknown(
              data['activity_id']!, _activityIdMeta));
    } else if (isInserting) {
      context.missing(_activityIdMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(_latitudeMeta,
          latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta));
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(_longitudeMeta,
          longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta));
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('elevation')) {
      context.handle(_elevationMeta,
          elevation.isAcceptableOrUnknown(data['elevation']!, _elevationMeta));
    }
    if (data.containsKey('accuracy')) {
      context.handle(_accuracyMeta,
          accuracy.isAcceptableOrUnknown(data['accuracy']!, _accuracyMeta));
    } else if (isInserting) {
      context.missing(_accuracyMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('sequence')) {
      context.handle(_sequenceMeta,
          sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta));
    } else if (isInserting) {
      context.missing(_sequenceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrackPointEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrackPointEntity(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      activityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}activity_id'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}timestamp'])!,
      latitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}latitude'])!,
      longitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}longitude'])!,
      elevation: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}elevation']),
      accuracy: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}accuracy'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}source'])!,
      sequence: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sequence'])!,
    );
  }

  @override
  $TrackPointsTableTable createAlias(String alias) {
    return $TrackPointsTableTable(attachedDatabase, alias);
  }
}

class TrackPointEntity extends DataClass
    implements Insertable<TrackPointEntity> {
  /// Unique identifier for the track point
  final String id;

  /// ID of the activity this point belongs to
  final String activityId;

  /// When this point was recorded (milliseconds since epoch)
  final int timestamp;

  /// Latitude coordinate
  final double latitude;

  /// Longitude coordinate
  final double longitude;

  /// Elevation in meters (nullable if not available)
  final double? elevation;

  /// GPS accuracy in meters (smaller is better)
  final double accuracy;

  /// Source of the location data (0=gps, 1=network, 2=fused, 3=manual, 4=interpolated)
  final int source;

  /// Sequential order within the activity (0-based)
  final int sequence;
  const TrackPointEntity(
      {required this.id,
      required this.activityId,
      required this.timestamp,
      required this.latitude,
      required this.longitude,
      this.elevation,
      required this.accuracy,
      required this.source,
      required this.sequence});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['activity_id'] = Variable<String>(activityId);
    map['timestamp'] = Variable<int>(timestamp);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    if (!nullToAbsent || elevation != null) {
      map['elevation'] = Variable<double>(elevation);
    }
    map['accuracy'] = Variable<double>(accuracy);
    map['source'] = Variable<int>(source);
    map['sequence'] = Variable<int>(sequence);
    return map;
  }

  TrackPointsTableCompanion toCompanion(bool nullToAbsent) {
    return TrackPointsTableCompanion(
      id: Value(id),
      activityId: Value(activityId),
      timestamp: Value(timestamp),
      latitude: Value(latitude),
      longitude: Value(longitude),
      elevation: elevation == null && nullToAbsent
          ? const Value.absent()
          : Value(elevation),
      accuracy: Value(accuracy),
      source: Value(source),
      sequence: Value(sequence),
    );
  }

  factory TrackPointEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrackPointEntity(
      id: serializer.fromJson<String>(json['id']),
      activityId: serializer.fromJson<String>(json['activityId']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      elevation: serializer.fromJson<double?>(json['elevation']),
      accuracy: serializer.fromJson<double>(json['accuracy']),
      source: serializer.fromJson<int>(json['source']),
      sequence: serializer.fromJson<int>(json['sequence']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'activityId': serializer.toJson<String>(activityId),
      'timestamp': serializer.toJson<int>(timestamp),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'elevation': serializer.toJson<double?>(elevation),
      'accuracy': serializer.toJson<double>(accuracy),
      'source': serializer.toJson<int>(source),
      'sequence': serializer.toJson<int>(sequence),
    };
  }

  TrackPointEntity copyWith(
          {String? id,
          String? activityId,
          int? timestamp,
          double? latitude,
          double? longitude,
          Value<double?> elevation = const Value.absent(),
          double? accuracy,
          int? source,
          int? sequence}) =>
      TrackPointEntity(
        id: id ?? this.id,
        activityId: activityId ?? this.activityId,
        timestamp: timestamp ?? this.timestamp,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        elevation: elevation.present ? elevation.value : this.elevation,
        accuracy: accuracy ?? this.accuracy,
        source: source ?? this.source,
        sequence: sequence ?? this.sequence,
      );
  TrackPointEntity copyWithCompanion(TrackPointsTableCompanion data) {
    return TrackPointEntity(
      id: data.id.present ? data.id.value : this.id,
      activityId:
          data.activityId.present ? data.activityId.value : this.activityId,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      elevation: data.elevation.present ? data.elevation.value : this.elevation,
      accuracy: data.accuracy.present ? data.accuracy.value : this.accuracy,
      source: data.source.present ? data.source.value : this.source,
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackPointEntity(')
          ..write('id: $id, ')
          ..write('activityId: $activityId, ')
          ..write('timestamp: $timestamp, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('elevation: $elevation, ')
          ..write('accuracy: $accuracy, ')
          ..write('source: $source, ')
          ..write('sequence: $sequence')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, activityId, timestamp, latitude,
      longitude, elevation, accuracy, source, sequence);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackPointEntity &&
          other.id == this.id &&
          other.activityId == this.activityId &&
          other.timestamp == this.timestamp &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.elevation == this.elevation &&
          other.accuracy == this.accuracy &&
          other.source == this.source &&
          other.sequence == this.sequence);
}

class TrackPointsTableCompanion extends UpdateCompanion<TrackPointEntity> {
  final Value<String> id;
  final Value<String> activityId;
  final Value<int> timestamp;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<double?> elevation;
  final Value<double> accuracy;
  final Value<int> source;
  final Value<int> sequence;
  final Value<int> rowid;
  const TrackPointsTableCompanion({
    this.id = const Value.absent(),
    this.activityId = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.elevation = const Value.absent(),
    this.accuracy = const Value.absent(),
    this.source = const Value.absent(),
    this.sequence = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TrackPointsTableCompanion.insert({
    required String id,
    required String activityId,
    required int timestamp,
    required double latitude,
    required double longitude,
    this.elevation = const Value.absent(),
    required double accuracy,
    required int source,
    required int sequence,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        activityId = Value(activityId),
        timestamp = Value(timestamp),
        latitude = Value(latitude),
        longitude = Value(longitude),
        accuracy = Value(accuracy),
        source = Value(source),
        sequence = Value(sequence);
  static Insertable<TrackPointEntity> custom({
    Expression<String>? id,
    Expression<String>? activityId,
    Expression<int>? timestamp,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? elevation,
    Expression<double>? accuracy,
    Expression<int>? source,
    Expression<int>? sequence,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (activityId != null) 'activity_id': activityId,
      if (timestamp != null) 'timestamp': timestamp,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (elevation != null) 'elevation': elevation,
      if (accuracy != null) 'accuracy': accuracy,
      if (source != null) 'source': source,
      if (sequence != null) 'sequence': sequence,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TrackPointsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? activityId,
      Value<int>? timestamp,
      Value<double>? latitude,
      Value<double>? longitude,
      Value<double?>? elevation,
      Value<double>? accuracy,
      Value<int>? source,
      Value<int>? sequence,
      Value<int>? rowid}) {
    return TrackPointsTableCompanion(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      elevation: elevation ?? this.elevation,
      accuracy: accuracy ?? this.accuracy,
      source: source ?? this.source,
      sequence: sequence ?? this.sequence,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (activityId.present) {
      map['activity_id'] = Variable<String>(activityId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (elevation.present) {
      map['elevation'] = Variable<double>(elevation.value);
    }
    if (accuracy.present) {
      map['accuracy'] = Variable<double>(accuracy.value);
    }
    if (source.present) {
      map['source'] = Variable<int>(source.value);
    }
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrackPointsTableCompanion(')
          ..write('id: $id, ')
          ..write('activityId: $activityId, ')
          ..write('timestamp: $timestamp, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('elevation: $elevation, ')
          ..write('accuracy: $accuracy, ')
          ..write('source: $source, ')
          ..write('sequence: $sequence, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PhotosTableTable extends PhotosTable
    with TableInfo<$PhotosTableTable, PhotoEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PhotosTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _activityIdMeta =
      const VerificationMeta('activityId');
  @override
  late final GeneratedColumn<String> activityId = GeneratedColumn<String>(
      'activity_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _latitudeMeta =
      const VerificationMeta('latitude');
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
      'latitude', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _longitudeMeta =
      const VerificationMeta('longitude');
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
      'longitude', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _elevationMeta =
      const VerificationMeta('elevation');
  @override
  late final GeneratedColumn<double> elevation = GeneratedColumn<double>(
      'elevation', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _filePathMeta =
      const VerificationMeta('filePath');
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
      'file_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _thumbnailPathMeta =
      const VerificationMeta('thumbnailPath');
  @override
  late final GeneratedColumn<String> thumbnailPath = GeneratedColumn<String>(
      'thumbnail_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _hasExifDataMeta =
      const VerificationMeta('hasExifData');
  @override
  late final GeneratedColumn<bool> hasExifData = GeneratedColumn<bool>(
      'has_exif_data', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("has_exif_data" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _curationScoreMeta =
      const VerificationMeta('curationScore');
  @override
  late final GeneratedColumn<double> curationScore = GeneratedColumn<double>(
      'curation_score', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _captionMeta =
      const VerificationMeta('caption');
  @override
  late final GeneratedColumn<String> caption = GeneratedColumn<String>(
      'caption', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        activityId,
        timestamp,
        latitude,
        longitude,
        elevation,
        filePath,
        thumbnailPath,
        hasExifData,
        curationScore,
        caption
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'photos';
  @override
  VerificationContext validateIntegrity(Insertable<PhotoEntity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('activity_id')) {
      context.handle(
          _activityIdMeta,
          activityId.isAcceptableOrUnknown(
              data['activity_id']!, _activityIdMeta));
    } else if (isInserting) {
      context.missing(_activityIdMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(_latitudeMeta,
          latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta));
    }
    if (data.containsKey('longitude')) {
      context.handle(_longitudeMeta,
          longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta));
    }
    if (data.containsKey('elevation')) {
      context.handle(_elevationMeta,
          elevation.isAcceptableOrUnknown(data['elevation']!, _elevationMeta));
    }
    if (data.containsKey('file_path')) {
      context.handle(_filePathMeta,
          filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta));
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('thumbnail_path')) {
      context.handle(
          _thumbnailPathMeta,
          thumbnailPath.isAcceptableOrUnknown(
              data['thumbnail_path']!, _thumbnailPathMeta));
    }
    if (data.containsKey('has_exif_data')) {
      context.handle(
          _hasExifDataMeta,
          hasExifData.isAcceptableOrUnknown(
              data['has_exif_data']!, _hasExifDataMeta));
    }
    if (data.containsKey('curation_score')) {
      context.handle(
          _curationScoreMeta,
          curationScore.isAcceptableOrUnknown(
              data['curation_score']!, _curationScoreMeta));
    }
    if (data.containsKey('caption')) {
      context.handle(_captionMeta,
          caption.isAcceptableOrUnknown(data['caption']!, _captionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PhotoEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PhotoEntity(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      activityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}activity_id'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}timestamp'])!,
      latitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}latitude']),
      longitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}longitude']),
      elevation: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}elevation']),
      filePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_path'])!,
      thumbnailPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}thumbnail_path']),
      hasExifData: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}has_exif_data'])!,
      curationScore: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}curation_score'])!,
      caption: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}caption']),
    );
  }

  @override
  $PhotosTableTable createAlias(String alias) {
    return $PhotosTableTable(attachedDatabase, alias);
  }
}

class PhotoEntity extends DataClass implements Insertable<PhotoEntity> {
  /// Unique identifier for the photo
  final String id;

  /// ID of the activity this photo belongs to
  final String activityId;

  /// When this photo was captured (milliseconds since epoch)
  final int timestamp;

  /// Latitude coordinate where photo was taken (nullable if not available)
  final double? latitude;

  /// Longitude coordinate where photo was taken (nullable if not available)
  final double? longitude;

  /// Elevation where photo was taken (nullable if not available)
  final double? elevation;

  /// File path to the full-size photo
  final String filePath;

  /// File path to the thumbnail (nullable if not generated)
  final String? thumbnailPath;

  /// Whether the photo contains EXIF metadata
  final bool hasExifData;

  /// AI-generated curation score (0.0-1.0, higher is better for highlights)
  final double curationScore;

  /// Optional user-provided caption
  final String? caption;
  const PhotoEntity(
      {required this.id,
      required this.activityId,
      required this.timestamp,
      this.latitude,
      this.longitude,
      this.elevation,
      required this.filePath,
      this.thumbnailPath,
      required this.hasExifData,
      required this.curationScore,
      this.caption});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['activity_id'] = Variable<String>(activityId);
    map['timestamp'] = Variable<int>(timestamp);
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    if (!nullToAbsent || elevation != null) {
      map['elevation'] = Variable<double>(elevation);
    }
    map['file_path'] = Variable<String>(filePath);
    if (!nullToAbsent || thumbnailPath != null) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath);
    }
    map['has_exif_data'] = Variable<bool>(hasExifData);
    map['curation_score'] = Variable<double>(curationScore);
    if (!nullToAbsent || caption != null) {
      map['caption'] = Variable<String>(caption);
    }
    return map;
  }

  PhotosTableCompanion toCompanion(bool nullToAbsent) {
    return PhotosTableCompanion(
      id: Value(id),
      activityId: Value(activityId),
      timestamp: Value(timestamp),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      elevation: elevation == null && nullToAbsent
          ? const Value.absent()
          : Value(elevation),
      filePath: Value(filePath),
      thumbnailPath: thumbnailPath == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailPath),
      hasExifData: Value(hasExifData),
      curationScore: Value(curationScore),
      caption: caption == null && nullToAbsent
          ? const Value.absent()
          : Value(caption),
    );
  }

  factory PhotoEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PhotoEntity(
      id: serializer.fromJson<String>(json['id']),
      activityId: serializer.fromJson<String>(json['activityId']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      elevation: serializer.fromJson<double?>(json['elevation']),
      filePath: serializer.fromJson<String>(json['filePath']),
      thumbnailPath: serializer.fromJson<String?>(json['thumbnailPath']),
      hasExifData: serializer.fromJson<bool>(json['hasExifData']),
      curationScore: serializer.fromJson<double>(json['curationScore']),
      caption: serializer.fromJson<String?>(json['caption']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'activityId': serializer.toJson<String>(activityId),
      'timestamp': serializer.toJson<int>(timestamp),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'elevation': serializer.toJson<double?>(elevation),
      'filePath': serializer.toJson<String>(filePath),
      'thumbnailPath': serializer.toJson<String?>(thumbnailPath),
      'hasExifData': serializer.toJson<bool>(hasExifData),
      'curationScore': serializer.toJson<double>(curationScore),
      'caption': serializer.toJson<String?>(caption),
    };
  }

  PhotoEntity copyWith(
          {String? id,
          String? activityId,
          int? timestamp,
          Value<double?> latitude = const Value.absent(),
          Value<double?> longitude = const Value.absent(),
          Value<double?> elevation = const Value.absent(),
          String? filePath,
          Value<String?> thumbnailPath = const Value.absent(),
          bool? hasExifData,
          double? curationScore,
          Value<String?> caption = const Value.absent()}) =>
      PhotoEntity(
        id: id ?? this.id,
        activityId: activityId ?? this.activityId,
        timestamp: timestamp ?? this.timestamp,
        latitude: latitude.present ? latitude.value : this.latitude,
        longitude: longitude.present ? longitude.value : this.longitude,
        elevation: elevation.present ? elevation.value : this.elevation,
        filePath: filePath ?? this.filePath,
        thumbnailPath:
            thumbnailPath.present ? thumbnailPath.value : this.thumbnailPath,
        hasExifData: hasExifData ?? this.hasExifData,
        curationScore: curationScore ?? this.curationScore,
        caption: caption.present ? caption.value : this.caption,
      );
  PhotoEntity copyWithCompanion(PhotosTableCompanion data) {
    return PhotoEntity(
      id: data.id.present ? data.id.value : this.id,
      activityId:
          data.activityId.present ? data.activityId.value : this.activityId,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      elevation: data.elevation.present ? data.elevation.value : this.elevation,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      thumbnailPath: data.thumbnailPath.present
          ? data.thumbnailPath.value
          : this.thumbnailPath,
      hasExifData:
          data.hasExifData.present ? data.hasExifData.value : this.hasExifData,
      curationScore: data.curationScore.present
          ? data.curationScore.value
          : this.curationScore,
      caption: data.caption.present ? data.caption.value : this.caption,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PhotoEntity(')
          ..write('id: $id, ')
          ..write('activityId: $activityId, ')
          ..write('timestamp: $timestamp, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('elevation: $elevation, ')
          ..write('filePath: $filePath, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('hasExifData: $hasExifData, ')
          ..write('curationScore: $curationScore, ')
          ..write('caption: $caption')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      activityId,
      timestamp,
      latitude,
      longitude,
      elevation,
      filePath,
      thumbnailPath,
      hasExifData,
      curationScore,
      caption);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PhotoEntity &&
          other.id == this.id &&
          other.activityId == this.activityId &&
          other.timestamp == this.timestamp &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.elevation == this.elevation &&
          other.filePath == this.filePath &&
          other.thumbnailPath == this.thumbnailPath &&
          other.hasExifData == this.hasExifData &&
          other.curationScore == this.curationScore &&
          other.caption == this.caption);
}

class PhotosTableCompanion extends UpdateCompanion<PhotoEntity> {
  final Value<String> id;
  final Value<String> activityId;
  final Value<int> timestamp;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<double?> elevation;
  final Value<String> filePath;
  final Value<String?> thumbnailPath;
  final Value<bool> hasExifData;
  final Value<double> curationScore;
  final Value<String?> caption;
  final Value<int> rowid;
  const PhotosTableCompanion({
    this.id = const Value.absent(),
    this.activityId = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.elevation = const Value.absent(),
    this.filePath = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.hasExifData = const Value.absent(),
    this.curationScore = const Value.absent(),
    this.caption = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PhotosTableCompanion.insert({
    required String id,
    required String activityId,
    required int timestamp,
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.elevation = const Value.absent(),
    required String filePath,
    this.thumbnailPath = const Value.absent(),
    this.hasExifData = const Value.absent(),
    this.curationScore = const Value.absent(),
    this.caption = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        activityId = Value(activityId),
        timestamp = Value(timestamp),
        filePath = Value(filePath);
  static Insertable<PhotoEntity> custom({
    Expression<String>? id,
    Expression<String>? activityId,
    Expression<int>? timestamp,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? elevation,
    Expression<String>? filePath,
    Expression<String>? thumbnailPath,
    Expression<bool>? hasExifData,
    Expression<double>? curationScore,
    Expression<String>? caption,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (activityId != null) 'activity_id': activityId,
      if (timestamp != null) 'timestamp': timestamp,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (elevation != null) 'elevation': elevation,
      if (filePath != null) 'file_path': filePath,
      if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
      if (hasExifData != null) 'has_exif_data': hasExifData,
      if (curationScore != null) 'curation_score': curationScore,
      if (caption != null) 'caption': caption,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PhotosTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? activityId,
      Value<int>? timestamp,
      Value<double?>? latitude,
      Value<double?>? longitude,
      Value<double?>? elevation,
      Value<String>? filePath,
      Value<String?>? thumbnailPath,
      Value<bool>? hasExifData,
      Value<double>? curationScore,
      Value<String?>? caption,
      Value<int>? rowid}) {
    return PhotosTableCompanion(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      elevation: elevation ?? this.elevation,
      filePath: filePath ?? this.filePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      hasExifData: hasExifData ?? this.hasExifData,
      curationScore: curationScore ?? this.curationScore,
      caption: caption ?? this.caption,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (activityId.present) {
      map['activity_id'] = Variable<String>(activityId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (elevation.present) {
      map['elevation'] = Variable<double>(elevation.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (thumbnailPath.present) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath.value);
    }
    if (hasExifData.present) {
      map['has_exif_data'] = Variable<bool>(hasExifData.value);
    }
    if (curationScore.present) {
      map['curation_score'] = Variable<double>(curationScore.value);
    }
    if (caption.present) {
      map['caption'] = Variable<String>(caption.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PhotosTableCompanion(')
          ..write('id: $id, ')
          ..write('activityId: $activityId, ')
          ..write('timestamp: $timestamp, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('elevation: $elevation, ')
          ..write('filePath: $filePath, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('hasExifData: $hasExifData, ')
          ..write('curationScore: $curationScore, ')
          ..write('caption: $caption, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SplitsTableTable extends SplitsTable
    with TableInfo<$SplitsTableTable, SplitEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SplitsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _activityIdMeta =
      const VerificationMeta('activityId');
  @override
  late final GeneratedColumn<String> activityId = GeneratedColumn<String>(
      'activity_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _splitNumberMeta =
      const VerificationMeta('splitNumber');
  @override
  late final GeneratedColumn<int> splitNumber = GeneratedColumn<int>(
      'split_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  @override
  late final GeneratedColumn<int> startTime = GeneratedColumn<int>(
      'start_time', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _endTimeMeta =
      const VerificationMeta('endTime');
  @override
  late final GeneratedColumn<int> endTime = GeneratedColumn<int>(
      'end_time', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _distanceMetersMeta =
      const VerificationMeta('distanceMeters');
  @override
  late final GeneratedColumn<double> distanceMeters = GeneratedColumn<double>(
      'distance_meters', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _paceSecondsPerKmMeta =
      const VerificationMeta('paceSecondsPerKm');
  @override
  late final GeneratedColumn<double> paceSecondsPerKm = GeneratedColumn<double>(
      'pace_seconds_per_km', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _elevationGainMetersMeta =
      const VerificationMeta('elevationGainMeters');
  @override
  late final GeneratedColumn<double> elevationGainMeters =
      GeneratedColumn<double>('elevation_gain_meters', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(0.0));
  static const VerificationMeta _elevationLossMetersMeta =
      const VerificationMeta('elevationLossMeters');
  @override
  late final GeneratedColumn<double> elevationLossMeters =
      GeneratedColumn<double>('elevation_loss_meters', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(0.0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        activityId,
        splitNumber,
        startTime,
        endTime,
        distanceMeters,
        paceSecondsPerKm,
        elevationGainMeters,
        elevationLossMeters
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'splits';
  @override
  VerificationContext validateIntegrity(Insertable<SplitEntity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('activity_id')) {
      context.handle(
          _activityIdMeta,
          activityId.isAcceptableOrUnknown(
              data['activity_id']!, _activityIdMeta));
    } else if (isInserting) {
      context.missing(_activityIdMeta);
    }
    if (data.containsKey('split_number')) {
      context.handle(
          _splitNumberMeta,
          splitNumber.isAcceptableOrUnknown(
              data['split_number']!, _splitNumberMeta));
    } else if (isInserting) {
      context.missing(_splitNumberMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(_endTimeMeta,
          endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta));
    } else if (isInserting) {
      context.missing(_endTimeMeta);
    }
    if (data.containsKey('distance_meters')) {
      context.handle(
          _distanceMetersMeta,
          distanceMeters.isAcceptableOrUnknown(
              data['distance_meters']!, _distanceMetersMeta));
    } else if (isInserting) {
      context.missing(_distanceMetersMeta);
    }
    if (data.containsKey('pace_seconds_per_km')) {
      context.handle(
          _paceSecondsPerKmMeta,
          paceSecondsPerKm.isAcceptableOrUnknown(
              data['pace_seconds_per_km']!, _paceSecondsPerKmMeta));
    } else if (isInserting) {
      context.missing(_paceSecondsPerKmMeta);
    }
    if (data.containsKey('elevation_gain_meters')) {
      context.handle(
          _elevationGainMetersMeta,
          elevationGainMeters.isAcceptableOrUnknown(
              data['elevation_gain_meters']!, _elevationGainMetersMeta));
    }
    if (data.containsKey('elevation_loss_meters')) {
      context.handle(
          _elevationLossMetersMeta,
          elevationLossMeters.isAcceptableOrUnknown(
              data['elevation_loss_meters']!, _elevationLossMetersMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SplitEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SplitEntity(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      activityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}activity_id'])!,
      splitNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}split_number'])!,
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}start_time'])!,
      endTime: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}end_time'])!,
      distanceMeters: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}distance_meters'])!,
      paceSecondsPerKm: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}pace_seconds_per_km'])!,
      elevationGainMeters: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}elevation_gain_meters'])!,
      elevationLossMeters: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}elevation_loss_meters'])!,
    );
  }

  @override
  $SplitsTableTable createAlias(String alias) {
    return $SplitsTableTable(attachedDatabase, alias);
  }
}

class SplitEntity extends DataClass implements Insertable<SplitEntity> {
  /// Unique identifier for the split
  final String id;

  /// ID of the activity this split belongs to
  final String activityId;

  /// Split number (1-based, e.g., 1st km, 2nd km)
  final int splitNumber;

  /// When this split started (milliseconds since epoch)
  final int startTime;

  /// When this split ended (milliseconds since epoch)
  final int endTime;

  /// Distance covered in this split (meters)
  final double distanceMeters;

  /// Average pace for this split (seconds per kilometer)
  final double paceSecondsPerKm;

  /// Elevation gained during this split (meters)
  final double elevationGainMeters;

  /// Elevation lost during this split (meters)
  final double elevationLossMeters;
  const SplitEntity(
      {required this.id,
      required this.activityId,
      required this.splitNumber,
      required this.startTime,
      required this.endTime,
      required this.distanceMeters,
      required this.paceSecondsPerKm,
      required this.elevationGainMeters,
      required this.elevationLossMeters});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['activity_id'] = Variable<String>(activityId);
    map['split_number'] = Variable<int>(splitNumber);
    map['start_time'] = Variable<int>(startTime);
    map['end_time'] = Variable<int>(endTime);
    map['distance_meters'] = Variable<double>(distanceMeters);
    map['pace_seconds_per_km'] = Variable<double>(paceSecondsPerKm);
    map['elevation_gain_meters'] = Variable<double>(elevationGainMeters);
    map['elevation_loss_meters'] = Variable<double>(elevationLossMeters);
    return map;
  }

  SplitsTableCompanion toCompanion(bool nullToAbsent) {
    return SplitsTableCompanion(
      id: Value(id),
      activityId: Value(activityId),
      splitNumber: Value(splitNumber),
      startTime: Value(startTime),
      endTime: Value(endTime),
      distanceMeters: Value(distanceMeters),
      paceSecondsPerKm: Value(paceSecondsPerKm),
      elevationGainMeters: Value(elevationGainMeters),
      elevationLossMeters: Value(elevationLossMeters),
    );
  }

  factory SplitEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SplitEntity(
      id: serializer.fromJson<String>(json['id']),
      activityId: serializer.fromJson<String>(json['activityId']),
      splitNumber: serializer.fromJson<int>(json['splitNumber']),
      startTime: serializer.fromJson<int>(json['startTime']),
      endTime: serializer.fromJson<int>(json['endTime']),
      distanceMeters: serializer.fromJson<double>(json['distanceMeters']),
      paceSecondsPerKm: serializer.fromJson<double>(json['paceSecondsPerKm']),
      elevationGainMeters:
          serializer.fromJson<double>(json['elevationGainMeters']),
      elevationLossMeters:
          serializer.fromJson<double>(json['elevationLossMeters']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'activityId': serializer.toJson<String>(activityId),
      'splitNumber': serializer.toJson<int>(splitNumber),
      'startTime': serializer.toJson<int>(startTime),
      'endTime': serializer.toJson<int>(endTime),
      'distanceMeters': serializer.toJson<double>(distanceMeters),
      'paceSecondsPerKm': serializer.toJson<double>(paceSecondsPerKm),
      'elevationGainMeters': serializer.toJson<double>(elevationGainMeters),
      'elevationLossMeters': serializer.toJson<double>(elevationLossMeters),
    };
  }

  SplitEntity copyWith(
          {String? id,
          String? activityId,
          int? splitNumber,
          int? startTime,
          int? endTime,
          double? distanceMeters,
          double? paceSecondsPerKm,
          double? elevationGainMeters,
          double? elevationLossMeters}) =>
      SplitEntity(
        id: id ?? this.id,
        activityId: activityId ?? this.activityId,
        splitNumber: splitNumber ?? this.splitNumber,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        distanceMeters: distanceMeters ?? this.distanceMeters,
        paceSecondsPerKm: paceSecondsPerKm ?? this.paceSecondsPerKm,
        elevationGainMeters: elevationGainMeters ?? this.elevationGainMeters,
        elevationLossMeters: elevationLossMeters ?? this.elevationLossMeters,
      );
  SplitEntity copyWithCompanion(SplitsTableCompanion data) {
    return SplitEntity(
      id: data.id.present ? data.id.value : this.id,
      activityId:
          data.activityId.present ? data.activityId.value : this.activityId,
      splitNumber:
          data.splitNumber.present ? data.splitNumber.value : this.splitNumber,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      distanceMeters: data.distanceMeters.present
          ? data.distanceMeters.value
          : this.distanceMeters,
      paceSecondsPerKm: data.paceSecondsPerKm.present
          ? data.paceSecondsPerKm.value
          : this.paceSecondsPerKm,
      elevationGainMeters: data.elevationGainMeters.present
          ? data.elevationGainMeters.value
          : this.elevationGainMeters,
      elevationLossMeters: data.elevationLossMeters.present
          ? data.elevationLossMeters.value
          : this.elevationLossMeters,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SplitEntity(')
          ..write('id: $id, ')
          ..write('activityId: $activityId, ')
          ..write('splitNumber: $splitNumber, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('paceSecondsPerKm: $paceSecondsPerKm, ')
          ..write('elevationGainMeters: $elevationGainMeters, ')
          ..write('elevationLossMeters: $elevationLossMeters')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      activityId,
      splitNumber,
      startTime,
      endTime,
      distanceMeters,
      paceSecondsPerKm,
      elevationGainMeters,
      elevationLossMeters);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SplitEntity &&
          other.id == this.id &&
          other.activityId == this.activityId &&
          other.splitNumber == this.splitNumber &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.distanceMeters == this.distanceMeters &&
          other.paceSecondsPerKm == this.paceSecondsPerKm &&
          other.elevationGainMeters == this.elevationGainMeters &&
          other.elevationLossMeters == this.elevationLossMeters);
}

class SplitsTableCompanion extends UpdateCompanion<SplitEntity> {
  final Value<String> id;
  final Value<String> activityId;
  final Value<int> splitNumber;
  final Value<int> startTime;
  final Value<int> endTime;
  final Value<double> distanceMeters;
  final Value<double> paceSecondsPerKm;
  final Value<double> elevationGainMeters;
  final Value<double> elevationLossMeters;
  final Value<int> rowid;
  const SplitsTableCompanion({
    this.id = const Value.absent(),
    this.activityId = const Value.absent(),
    this.splitNumber = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.distanceMeters = const Value.absent(),
    this.paceSecondsPerKm = const Value.absent(),
    this.elevationGainMeters = const Value.absent(),
    this.elevationLossMeters = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SplitsTableCompanion.insert({
    required String id,
    required String activityId,
    required int splitNumber,
    required int startTime,
    required int endTime,
    required double distanceMeters,
    required double paceSecondsPerKm,
    this.elevationGainMeters = const Value.absent(),
    this.elevationLossMeters = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        activityId = Value(activityId),
        splitNumber = Value(splitNumber),
        startTime = Value(startTime),
        endTime = Value(endTime),
        distanceMeters = Value(distanceMeters),
        paceSecondsPerKm = Value(paceSecondsPerKm);
  static Insertable<SplitEntity> custom({
    Expression<String>? id,
    Expression<String>? activityId,
    Expression<int>? splitNumber,
    Expression<int>? startTime,
    Expression<int>? endTime,
    Expression<double>? distanceMeters,
    Expression<double>? paceSecondsPerKm,
    Expression<double>? elevationGainMeters,
    Expression<double>? elevationLossMeters,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (activityId != null) 'activity_id': activityId,
      if (splitNumber != null) 'split_number': splitNumber,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (distanceMeters != null) 'distance_meters': distanceMeters,
      if (paceSecondsPerKm != null) 'pace_seconds_per_km': paceSecondsPerKm,
      if (elevationGainMeters != null)
        'elevation_gain_meters': elevationGainMeters,
      if (elevationLossMeters != null)
        'elevation_loss_meters': elevationLossMeters,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SplitsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? activityId,
      Value<int>? splitNumber,
      Value<int>? startTime,
      Value<int>? endTime,
      Value<double>? distanceMeters,
      Value<double>? paceSecondsPerKm,
      Value<double>? elevationGainMeters,
      Value<double>? elevationLossMeters,
      Value<int>? rowid}) {
    return SplitsTableCompanion(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      splitNumber: splitNumber ?? this.splitNumber,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      paceSecondsPerKm: paceSecondsPerKm ?? this.paceSecondsPerKm,
      elevationGainMeters: elevationGainMeters ?? this.elevationGainMeters,
      elevationLossMeters: elevationLossMeters ?? this.elevationLossMeters,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (activityId.present) {
      map['activity_id'] = Variable<String>(activityId.value);
    }
    if (splitNumber.present) {
      map['split_number'] = Variable<int>(splitNumber.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<int>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<int>(endTime.value);
    }
    if (distanceMeters.present) {
      map['distance_meters'] = Variable<double>(distanceMeters.value);
    }
    if (paceSecondsPerKm.present) {
      map['pace_seconds_per_km'] = Variable<double>(paceSecondsPerKm.value);
    }
    if (elevationGainMeters.present) {
      map['elevation_gain_meters'] =
          Variable<double>(elevationGainMeters.value);
    }
    if (elevationLossMeters.present) {
      map['elevation_loss_meters'] =
          Variable<double>(elevationLossMeters.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SplitsTableCompanion(')
          ..write('id: $id, ')
          ..write('activityId: $activityId, ')
          ..write('splitNumber: $splitNumber, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('paceSecondsPerKm: $paceSecondsPerKm, ')
          ..write('elevationGainMeters: $elevationGainMeters, ')
          ..write('elevationLossMeters: $elevationLossMeters, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTableTable extends SyncQueueTable
    with TableInfo<$SyncQueueTableTable, SyncQueueEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityTypeMeta =
      const VerificationMeta('entityType');
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
      'entity_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
      'entity_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _operationMeta =
      const VerificationMeta('operation');
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
      'operation', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _priorityMeta =
      const VerificationMeta('priority');
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
      'priority', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _retryCountMeta =
      const VerificationMeta('retryCount');
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _maxRetriesMeta =
      const VerificationMeta('maxRetries');
  @override
  late final GeneratedColumn<int> maxRetries = GeneratedColumn<int>(
      'max_retries', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(3));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _lastAttemptAtMeta =
      const VerificationMeta('lastAttemptAt');
  @override
  late final GeneratedColumn<int> lastAttemptAt = GeneratedColumn<int>(
      'last_attempt_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nextAttemptAtMeta =
      const VerificationMeta('nextAttemptAt');
  @override
  late final GeneratedColumn<int> nextAttemptAt = GeneratedColumn<int>(
      'next_attempt_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _lastErrorMeta =
      const VerificationMeta('lastError');
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
      'last_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        entityType,
        entityId,
        operation,
        payload,
        priority,
        retryCount,
        maxRetries,
        createdAt,
        lastAttemptAt,
        nextAttemptAt,
        lastError
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(Insertable<SyncQueueEntity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
          _entityTypeMeta,
          entityType.isAcceptableOrUnknown(
              data['entity_type']!, _entityTypeMeta));
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(_operationMeta,
          operation.isAcceptableOrUnknown(data['operation']!, _operationMeta));
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    }
    if (data.containsKey('retry_count')) {
      context.handle(
          _retryCountMeta,
          retryCount.isAcceptableOrUnknown(
              data['retry_count']!, _retryCountMeta));
    }
    if (data.containsKey('max_retries')) {
      context.handle(
          _maxRetriesMeta,
          maxRetries.isAcceptableOrUnknown(
              data['max_retries']!, _maxRetriesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
          _lastAttemptAtMeta,
          lastAttemptAt.isAcceptableOrUnknown(
              data['last_attempt_at']!, _lastAttemptAtMeta));
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
          _nextAttemptAtMeta,
          nextAttemptAt.isAcceptableOrUnknown(
              data['next_attempt_at']!, _nextAttemptAtMeta));
    } else if (isInserting) {
      context.missing(_nextAttemptAtMeta);
    }
    if (data.containsKey('last_error')) {
      context.handle(_lastErrorMeta,
          lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueEntity(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      entityType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_type'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_id'])!,
      operation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operation'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      priority: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}priority'])!,
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
      maxRetries: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}max_retries'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      lastAttemptAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_attempt_at']),
      nextAttemptAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}next_attempt_at'])!,
      lastError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_error']),
    );
  }

  @override
  $SyncQueueTableTable createAlias(String alias) {
    return $SyncQueueTableTable(attachedDatabase, alias);
  }
}

class SyncQueueEntity extends DataClass implements Insertable<SyncQueueEntity> {
  /// Unique identifier for the sync operation
  final String id;

  /// Type of entity to sync (activity, photo, etc.)
  final String entityType;

  /// ID of the entity to sync
  final String entityId;

  /// Type of operation (create, update, delete)
  final String operation;

  /// JSON payload for the sync operation
  final String payload;

  /// Priority of the sync operation (higher number = higher priority)
  final int priority;

  /// Number of retry attempts made
  final int retryCount;

  /// Maximum number of retry attempts allowed
  final int maxRetries;

  /// When this sync operation was created (milliseconds since epoch)
  final int createdAt;

  /// When this sync operation was last attempted (milliseconds since epoch, nullable if never attempted)
  final int? lastAttemptAt;

  /// When to next attempt this sync operation (milliseconds since epoch)
  final int nextAttemptAt;

  /// Error message from last failed attempt (nullable if no error)
  final String? lastError;
  const SyncQueueEntity(
      {required this.id,
      required this.entityType,
      required this.entityId,
      required this.operation,
      required this.payload,
      required this.priority,
      required this.retryCount,
      required this.maxRetries,
      required this.createdAt,
      this.lastAttemptAt,
      required this.nextAttemptAt,
      this.lastError});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['operation'] = Variable<String>(operation);
    map['payload'] = Variable<String>(payload);
    map['priority'] = Variable<int>(priority);
    map['retry_count'] = Variable<int>(retryCount);
    map['max_retries'] = Variable<int>(maxRetries);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<int>(lastAttemptAt);
    }
    map['next_attempt_at'] = Variable<int>(nextAttemptAt);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  SyncQueueTableCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueTableCompanion(
      id: Value(id),
      entityType: Value(entityType),
      entityId: Value(entityId),
      operation: Value(operation),
      payload: Value(payload),
      priority: Value(priority),
      retryCount: Value(retryCount),
      maxRetries: Value(maxRetries),
      createdAt: Value(createdAt),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      nextAttemptAt: Value(nextAttemptAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory SyncQueueEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueEntity(
      id: serializer.fromJson<String>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      operation: serializer.fromJson<String>(json['operation']),
      payload: serializer.fromJson<String>(json['payload']),
      priority: serializer.fromJson<int>(json['priority']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      maxRetries: serializer.fromJson<int>(json['maxRetries']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      lastAttemptAt: serializer.fromJson<int?>(json['lastAttemptAt']),
      nextAttemptAt: serializer.fromJson<int>(json['nextAttemptAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'operation': serializer.toJson<String>(operation),
      'payload': serializer.toJson<String>(payload),
      'priority': serializer.toJson<int>(priority),
      'retryCount': serializer.toJson<int>(retryCount),
      'maxRetries': serializer.toJson<int>(maxRetries),
      'createdAt': serializer.toJson<int>(createdAt),
      'lastAttemptAt': serializer.toJson<int?>(lastAttemptAt),
      'nextAttemptAt': serializer.toJson<int>(nextAttemptAt),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  SyncQueueEntity copyWith(
          {String? id,
          String? entityType,
          String? entityId,
          String? operation,
          String? payload,
          int? priority,
          int? retryCount,
          int? maxRetries,
          int? createdAt,
          Value<int?> lastAttemptAt = const Value.absent(),
          int? nextAttemptAt,
          Value<String?> lastError = const Value.absent()}) =>
      SyncQueueEntity(
        id: id ?? this.id,
        entityType: entityType ?? this.entityType,
        entityId: entityId ?? this.entityId,
        operation: operation ?? this.operation,
        payload: payload ?? this.payload,
        priority: priority ?? this.priority,
        retryCount: retryCount ?? this.retryCount,
        maxRetries: maxRetries ?? this.maxRetries,
        createdAt: createdAt ?? this.createdAt,
        lastAttemptAt:
            lastAttemptAt.present ? lastAttemptAt.value : this.lastAttemptAt,
        nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
        lastError: lastError.present ? lastError.value : this.lastError,
      );
  SyncQueueEntity copyWithCompanion(SyncQueueTableCompanion data) {
    return SyncQueueEntity(
      id: data.id.present ? data.id.value : this.id,
      entityType:
          data.entityType.present ? data.entityType.value : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      operation: data.operation.present ? data.operation.value : this.operation,
      payload: data.payload.present ? data.payload.value : this.payload,
      priority: data.priority.present ? data.priority.value : this.priority,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
      maxRetries:
          data.maxRetries.present ? data.maxRetries.value : this.maxRetries,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueEntity(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('priority: $priority, ')
          ..write('retryCount: $retryCount, ')
          ..write('maxRetries: $maxRetries, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      entityType,
      entityId,
      operation,
      payload,
      priority,
      retryCount,
      maxRetries,
      createdAt,
      lastAttemptAt,
      nextAttemptAt,
      lastError);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueEntity &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.operation == this.operation &&
          other.payload == this.payload &&
          other.priority == this.priority &&
          other.retryCount == this.retryCount &&
          other.maxRetries == this.maxRetries &&
          other.createdAt == this.createdAt &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.lastError == this.lastError);
}

class SyncQueueTableCompanion extends UpdateCompanion<SyncQueueEntity> {
  final Value<String> id;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> operation;
  final Value<String> payload;
  final Value<int> priority;
  final Value<int> retryCount;
  final Value<int> maxRetries;
  final Value<int> createdAt;
  final Value<int?> lastAttemptAt;
  final Value<int> nextAttemptAt;
  final Value<String?> lastError;
  final Value<int> rowid;
  const SyncQueueTableCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.operation = const Value.absent(),
    this.payload = const Value.absent(),
    this.priority = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.maxRetries = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncQueueTableCompanion.insert({
    required String id,
    required String entityType,
    required String entityId,
    required String operation,
    required String payload,
    this.priority = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.maxRetries = const Value.absent(),
    required int createdAt,
    this.lastAttemptAt = const Value.absent(),
    required int nextAttemptAt,
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        entityType = Value(entityType),
        entityId = Value(entityId),
        operation = Value(operation),
        payload = Value(payload),
        createdAt = Value(createdAt),
        nextAttemptAt = Value(nextAttemptAt);
  static Insertable<SyncQueueEntity> custom({
    Expression<String>? id,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? operation,
    Expression<String>? payload,
    Expression<int>? priority,
    Expression<int>? retryCount,
    Expression<int>? maxRetries,
    Expression<int>? createdAt,
    Expression<int>? lastAttemptAt,
    Expression<int>? nextAttemptAt,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (operation != null) 'operation': operation,
      if (payload != null) 'payload': payload,
      if (priority != null) 'priority': priority,
      if (retryCount != null) 'retry_count': retryCount,
      if (maxRetries != null) 'max_retries': maxRetries,
      if (createdAt != null) 'created_at': createdAt,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncQueueTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? entityType,
      Value<String>? entityId,
      Value<String>? operation,
      Value<String>? payload,
      Value<int>? priority,
      Value<int>? retryCount,
      Value<int>? maxRetries,
      Value<int>? createdAt,
      Value<int?>? lastAttemptAt,
      Value<int>? nextAttemptAt,
      Value<String?>? lastError,
      Value<int>? rowid}) {
    return SyncQueueTableCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      priority: priority ?? this.priority,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries ?? this.maxRetries,
      createdAt: createdAt ?? this.createdAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (maxRetries.present) {
      map['max_retries'] = Variable<int>(maxRetries.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<int>(lastAttemptAt.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<int>(nextAttemptAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueTableCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('priority: $priority, ')
          ..write('retryCount: $retryCount, ')
          ..write('maxRetries: $maxRetries, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$TrailRunDatabase extends GeneratedDatabase {
  _$TrailRunDatabase(QueryExecutor e) : super(e);
  $TrailRunDatabaseManager get managers => $TrailRunDatabaseManager(this);
  late final $ActivitiesTableTable activitiesTable =
      $ActivitiesTableTable(this);
  late final $TrackPointsTableTable trackPointsTable =
      $TrackPointsTableTable(this);
  late final $PhotosTableTable photosTable = $PhotosTableTable(this);
  late final $SplitsTableTable splitsTable = $SplitsTableTable(this);
  late final $SyncQueueTableTable syncQueueTable = $SyncQueueTableTable(this);
  late final ActivityDao activityDao = ActivityDao(this as TrailRunDatabase);
  late final TrackPointDao trackPointDao =
      TrackPointDao(this as TrailRunDatabase);
  late final PhotoDao photoDao = PhotoDao(this as TrailRunDatabase);
  late final SplitDao splitDao = SplitDao(this as TrailRunDatabase);
  late final SyncQueueDao syncQueueDao = SyncQueueDao(this as TrailRunDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        activitiesTable,
        trackPointsTable,
        photosTable,
        splitsTable,
        syncQueueTable
      ];
}

typedef $$ActivitiesTableTableCreateCompanionBuilder = ActivitiesTableCompanion
    Function({
  required String id,
  required int startTime,
  Value<int?> endTime,
  Value<double> distanceMeters,
  Value<int> durationSeconds,
  Value<double> elevationGainMeters,
  Value<double> elevationLossMeters,
  Value<double?> averagePaceSecondsPerKm,
  required String title,
  Value<String?> notes,
  Value<int> privacyLevel,
  Value<String?> coverPhotoId,
  Value<int> syncState,
  required int createdAt,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$ActivitiesTableTableUpdateCompanionBuilder = ActivitiesTableCompanion
    Function({
  Value<String> id,
  Value<int> startTime,
  Value<int?> endTime,
  Value<double> distanceMeters,
  Value<int> durationSeconds,
  Value<double> elevationGainMeters,
  Value<double> elevationLossMeters,
  Value<double?> averagePaceSecondsPerKm,
  Value<String> title,
  Value<String?> notes,
  Value<int> privacyLevel,
  Value<String?> coverPhotoId,
  Value<int> syncState,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int> rowid,
});

class $$ActivitiesTableTableFilterComposer
    extends Composer<_$TrailRunDatabase, $ActivitiesTableTable> {
  $$ActivitiesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get distanceMeters => $composableBuilder(
      column: $table.distanceMeters,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get elevationGainMeters => $composableBuilder(
      column: $table.elevationGainMeters,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get elevationLossMeters => $composableBuilder(
      column: $table.elevationLossMeters,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get averagePaceSecondsPerKm => $composableBuilder(
      column: $table.averagePaceSecondsPerKm,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get privacyLevel => $composableBuilder(
      column: $table.privacyLevel, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coverPhotoId => $composableBuilder(
      column: $table.coverPhotoId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get syncState => $composableBuilder(
      column: $table.syncState, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$ActivitiesTableTableOrderingComposer
    extends Composer<_$TrailRunDatabase, $ActivitiesTableTable> {
  $$ActivitiesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get distanceMeters => $composableBuilder(
      column: $table.distanceMeters,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get elevationGainMeters => $composableBuilder(
      column: $table.elevationGainMeters,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get elevationLossMeters => $composableBuilder(
      column: $table.elevationLossMeters,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get averagePaceSecondsPerKm => $composableBuilder(
      column: $table.averagePaceSecondsPerKm,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get privacyLevel => $composableBuilder(
      column: $table.privacyLevel,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coverPhotoId => $composableBuilder(
      column: $table.coverPhotoId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get syncState => $composableBuilder(
      column: $table.syncState, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ActivitiesTableTableAnnotationComposer
    extends Composer<_$TrailRunDatabase, $ActivitiesTableTable> {
  $$ActivitiesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<int> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<double> get distanceMeters => $composableBuilder(
      column: $table.distanceMeters, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds, builder: (column) => column);

  GeneratedColumn<double> get elevationGainMeters => $composableBuilder(
      column: $table.elevationGainMeters, builder: (column) => column);

  GeneratedColumn<double> get elevationLossMeters => $composableBuilder(
      column: $table.elevationLossMeters, builder: (column) => column);

  GeneratedColumn<double> get averagePaceSecondsPerKm => $composableBuilder(
      column: $table.averagePaceSecondsPerKm, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get privacyLevel => $composableBuilder(
      column: $table.privacyLevel, builder: (column) => column);

  GeneratedColumn<String> get coverPhotoId => $composableBuilder(
      column: $table.coverPhotoId, builder: (column) => column);

  GeneratedColumn<int> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ActivitiesTableTableTableManager extends RootTableManager<
    _$TrailRunDatabase,
    $ActivitiesTableTable,
    ActivityEntity,
    $$ActivitiesTableTableFilterComposer,
    $$ActivitiesTableTableOrderingComposer,
    $$ActivitiesTableTableAnnotationComposer,
    $$ActivitiesTableTableCreateCompanionBuilder,
    $$ActivitiesTableTableUpdateCompanionBuilder,
    (
      ActivityEntity,
      BaseReferences<_$TrailRunDatabase, $ActivitiesTableTable, ActivityEntity>
    ),
    ActivityEntity,
    PrefetchHooks Function()> {
  $$ActivitiesTableTableTableManager(
      _$TrailRunDatabase db, $ActivitiesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActivitiesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActivitiesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActivitiesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<int> startTime = const Value.absent(),
            Value<int?> endTime = const Value.absent(),
            Value<double> distanceMeters = const Value.absent(),
            Value<int> durationSeconds = const Value.absent(),
            Value<double> elevationGainMeters = const Value.absent(),
            Value<double> elevationLossMeters = const Value.absent(),
            Value<double?> averagePaceSecondsPerKm = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<int> privacyLevel = const Value.absent(),
            Value<String?> coverPhotoId = const Value.absent(),
            Value<int> syncState = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ActivitiesTableCompanion(
            id: id,
            startTime: startTime,
            endTime: endTime,
            distanceMeters: distanceMeters,
            durationSeconds: durationSeconds,
            elevationGainMeters: elevationGainMeters,
            elevationLossMeters: elevationLossMeters,
            averagePaceSecondsPerKm: averagePaceSecondsPerKm,
            title: title,
            notes: notes,
            privacyLevel: privacyLevel,
            coverPhotoId: coverPhotoId,
            syncState: syncState,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required int startTime,
            Value<int?> endTime = const Value.absent(),
            Value<double> distanceMeters = const Value.absent(),
            Value<int> durationSeconds = const Value.absent(),
            Value<double> elevationGainMeters = const Value.absent(),
            Value<double> elevationLossMeters = const Value.absent(),
            Value<double?> averagePaceSecondsPerKm = const Value.absent(),
            required String title,
            Value<String?> notes = const Value.absent(),
            Value<int> privacyLevel = const Value.absent(),
            Value<String?> coverPhotoId = const Value.absent(),
            Value<int> syncState = const Value.absent(),
            required int createdAt,
            required int updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ActivitiesTableCompanion.insert(
            id: id,
            startTime: startTime,
            endTime: endTime,
            distanceMeters: distanceMeters,
            durationSeconds: durationSeconds,
            elevationGainMeters: elevationGainMeters,
            elevationLossMeters: elevationLossMeters,
            averagePaceSecondsPerKm: averagePaceSecondsPerKm,
            title: title,
            notes: notes,
            privacyLevel: privacyLevel,
            coverPhotoId: coverPhotoId,
            syncState: syncState,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ActivitiesTableTableProcessedTableManager = ProcessedTableManager<
    _$TrailRunDatabase,
    $ActivitiesTableTable,
    ActivityEntity,
    $$ActivitiesTableTableFilterComposer,
    $$ActivitiesTableTableOrderingComposer,
    $$ActivitiesTableTableAnnotationComposer,
    $$ActivitiesTableTableCreateCompanionBuilder,
    $$ActivitiesTableTableUpdateCompanionBuilder,
    (
      ActivityEntity,
      BaseReferences<_$TrailRunDatabase, $ActivitiesTableTable, ActivityEntity>
    ),
    ActivityEntity,
    PrefetchHooks Function()>;
typedef $$TrackPointsTableTableCreateCompanionBuilder
    = TrackPointsTableCompanion Function({
  required String id,
  required String activityId,
  required int timestamp,
  required double latitude,
  required double longitude,
  Value<double?> elevation,
  required double accuracy,
  required int source,
  required int sequence,
  Value<int> rowid,
});
typedef $$TrackPointsTableTableUpdateCompanionBuilder
    = TrackPointsTableCompanion Function({
  Value<String> id,
  Value<String> activityId,
  Value<int> timestamp,
  Value<double> latitude,
  Value<double> longitude,
  Value<double?> elevation,
  Value<double> accuracy,
  Value<int> source,
  Value<int> sequence,
  Value<int> rowid,
});

class $$TrackPointsTableTableFilterComposer
    extends Composer<_$TrailRunDatabase, $TrackPointsTableTable> {
  $$TrackPointsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get activityId => $composableBuilder(
      column: $table.activityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get elevation => $composableBuilder(
      column: $table.elevation, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get accuracy => $composableBuilder(
      column: $table.accuracy, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sequence => $composableBuilder(
      column: $table.sequence, builder: (column) => ColumnFilters(column));
}

class $$TrackPointsTableTableOrderingComposer
    extends Composer<_$TrailRunDatabase, $TrackPointsTableTable> {
  $$TrackPointsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get activityId => $composableBuilder(
      column: $table.activityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get elevation => $composableBuilder(
      column: $table.elevation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get accuracy => $composableBuilder(
      column: $table.accuracy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sequence => $composableBuilder(
      column: $table.sequence, builder: (column) => ColumnOrderings(column));
}

class $$TrackPointsTableTableAnnotationComposer
    extends Composer<_$TrailRunDatabase, $TrackPointsTableTable> {
  $$TrackPointsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get activityId => $composableBuilder(
      column: $table.activityId, builder: (column) => column);

  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<double> get elevation =>
      $composableBuilder(column: $table.elevation, builder: (column) => column);

  GeneratedColumn<double> get accuracy =>
      $composableBuilder(column: $table.accuracy, builder: (column) => column);

  GeneratedColumn<int> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<int> get sequence =>
      $composableBuilder(column: $table.sequence, builder: (column) => column);
}

class $$TrackPointsTableTableTableManager extends RootTableManager<
    _$TrailRunDatabase,
    $TrackPointsTableTable,
    TrackPointEntity,
    $$TrackPointsTableTableFilterComposer,
    $$TrackPointsTableTableOrderingComposer,
    $$TrackPointsTableTableAnnotationComposer,
    $$TrackPointsTableTableCreateCompanionBuilder,
    $$TrackPointsTableTableUpdateCompanionBuilder,
    (
      TrackPointEntity,
      BaseReferences<_$TrailRunDatabase, $TrackPointsTableTable,
          TrackPointEntity>
    ),
    TrackPointEntity,
    PrefetchHooks Function()> {
  $$TrackPointsTableTableTableManager(
      _$TrailRunDatabase db, $TrackPointsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrackPointsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrackPointsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrackPointsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> activityId = const Value.absent(),
            Value<int> timestamp = const Value.absent(),
            Value<double> latitude = const Value.absent(),
            Value<double> longitude = const Value.absent(),
            Value<double?> elevation = const Value.absent(),
            Value<double> accuracy = const Value.absent(),
            Value<int> source = const Value.absent(),
            Value<int> sequence = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TrackPointsTableCompanion(
            id: id,
            activityId: activityId,
            timestamp: timestamp,
            latitude: latitude,
            longitude: longitude,
            elevation: elevation,
            accuracy: accuracy,
            source: source,
            sequence: sequence,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String activityId,
            required int timestamp,
            required double latitude,
            required double longitude,
            Value<double?> elevation = const Value.absent(),
            required double accuracy,
            required int source,
            required int sequence,
            Value<int> rowid = const Value.absent(),
          }) =>
              TrackPointsTableCompanion.insert(
            id: id,
            activityId: activityId,
            timestamp: timestamp,
            latitude: latitude,
            longitude: longitude,
            elevation: elevation,
            accuracy: accuracy,
            source: source,
            sequence: sequence,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TrackPointsTableTableProcessedTableManager = ProcessedTableManager<
    _$TrailRunDatabase,
    $TrackPointsTableTable,
    TrackPointEntity,
    $$TrackPointsTableTableFilterComposer,
    $$TrackPointsTableTableOrderingComposer,
    $$TrackPointsTableTableAnnotationComposer,
    $$TrackPointsTableTableCreateCompanionBuilder,
    $$TrackPointsTableTableUpdateCompanionBuilder,
    (
      TrackPointEntity,
      BaseReferences<_$TrailRunDatabase, $TrackPointsTableTable,
          TrackPointEntity>
    ),
    TrackPointEntity,
    PrefetchHooks Function()>;
typedef $$PhotosTableTableCreateCompanionBuilder = PhotosTableCompanion
    Function({
  required String id,
  required String activityId,
  required int timestamp,
  Value<double?> latitude,
  Value<double?> longitude,
  Value<double?> elevation,
  required String filePath,
  Value<String?> thumbnailPath,
  Value<bool> hasExifData,
  Value<double> curationScore,
  Value<String?> caption,
  Value<int> rowid,
});
typedef $$PhotosTableTableUpdateCompanionBuilder = PhotosTableCompanion
    Function({
  Value<String> id,
  Value<String> activityId,
  Value<int> timestamp,
  Value<double?> latitude,
  Value<double?> longitude,
  Value<double?> elevation,
  Value<String> filePath,
  Value<String?> thumbnailPath,
  Value<bool> hasExifData,
  Value<double> curationScore,
  Value<String?> caption,
  Value<int> rowid,
});

class $$PhotosTableTableFilterComposer
    extends Composer<_$TrailRunDatabase, $PhotosTableTable> {
  $$PhotosTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get activityId => $composableBuilder(
      column: $table.activityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get elevation => $composableBuilder(
      column: $table.elevation, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get thumbnailPath => $composableBuilder(
      column: $table.thumbnailPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get hasExifData => $composableBuilder(
      column: $table.hasExifData, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get curationScore => $composableBuilder(
      column: $table.curationScore, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get caption => $composableBuilder(
      column: $table.caption, builder: (column) => ColumnFilters(column));
}

class $$PhotosTableTableOrderingComposer
    extends Composer<_$TrailRunDatabase, $PhotosTableTable> {
  $$PhotosTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get activityId => $composableBuilder(
      column: $table.activityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get elevation => $composableBuilder(
      column: $table.elevation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get thumbnailPath => $composableBuilder(
      column: $table.thumbnailPath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get hasExifData => $composableBuilder(
      column: $table.hasExifData, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get curationScore => $composableBuilder(
      column: $table.curationScore,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get caption => $composableBuilder(
      column: $table.caption, builder: (column) => ColumnOrderings(column));
}

class $$PhotosTableTableAnnotationComposer
    extends Composer<_$TrailRunDatabase, $PhotosTableTable> {
  $$PhotosTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get activityId => $composableBuilder(
      column: $table.activityId, builder: (column) => column);

  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<double> get elevation =>
      $composableBuilder(column: $table.elevation, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get thumbnailPath => $composableBuilder(
      column: $table.thumbnailPath, builder: (column) => column);

  GeneratedColumn<bool> get hasExifData => $composableBuilder(
      column: $table.hasExifData, builder: (column) => column);

  GeneratedColumn<double> get curationScore => $composableBuilder(
      column: $table.curationScore, builder: (column) => column);

  GeneratedColumn<String> get caption =>
      $composableBuilder(column: $table.caption, builder: (column) => column);
}

class $$PhotosTableTableTableManager extends RootTableManager<
    _$TrailRunDatabase,
    $PhotosTableTable,
    PhotoEntity,
    $$PhotosTableTableFilterComposer,
    $$PhotosTableTableOrderingComposer,
    $$PhotosTableTableAnnotationComposer,
    $$PhotosTableTableCreateCompanionBuilder,
    $$PhotosTableTableUpdateCompanionBuilder,
    (
      PhotoEntity,
      BaseReferences<_$TrailRunDatabase, $PhotosTableTable, PhotoEntity>
    ),
    PhotoEntity,
    PrefetchHooks Function()> {
  $$PhotosTableTableTableManager(_$TrailRunDatabase db, $PhotosTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PhotosTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PhotosTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PhotosTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> activityId = const Value.absent(),
            Value<int> timestamp = const Value.absent(),
            Value<double?> latitude = const Value.absent(),
            Value<double?> longitude = const Value.absent(),
            Value<double?> elevation = const Value.absent(),
            Value<String> filePath = const Value.absent(),
            Value<String?> thumbnailPath = const Value.absent(),
            Value<bool> hasExifData = const Value.absent(),
            Value<double> curationScore = const Value.absent(),
            Value<String?> caption = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PhotosTableCompanion(
            id: id,
            activityId: activityId,
            timestamp: timestamp,
            latitude: latitude,
            longitude: longitude,
            elevation: elevation,
            filePath: filePath,
            thumbnailPath: thumbnailPath,
            hasExifData: hasExifData,
            curationScore: curationScore,
            caption: caption,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String activityId,
            required int timestamp,
            Value<double?> latitude = const Value.absent(),
            Value<double?> longitude = const Value.absent(),
            Value<double?> elevation = const Value.absent(),
            required String filePath,
            Value<String?> thumbnailPath = const Value.absent(),
            Value<bool> hasExifData = const Value.absent(),
            Value<double> curationScore = const Value.absent(),
            Value<String?> caption = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PhotosTableCompanion.insert(
            id: id,
            activityId: activityId,
            timestamp: timestamp,
            latitude: latitude,
            longitude: longitude,
            elevation: elevation,
            filePath: filePath,
            thumbnailPath: thumbnailPath,
            hasExifData: hasExifData,
            curationScore: curationScore,
            caption: caption,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PhotosTableTableProcessedTableManager = ProcessedTableManager<
    _$TrailRunDatabase,
    $PhotosTableTable,
    PhotoEntity,
    $$PhotosTableTableFilterComposer,
    $$PhotosTableTableOrderingComposer,
    $$PhotosTableTableAnnotationComposer,
    $$PhotosTableTableCreateCompanionBuilder,
    $$PhotosTableTableUpdateCompanionBuilder,
    (
      PhotoEntity,
      BaseReferences<_$TrailRunDatabase, $PhotosTableTable, PhotoEntity>
    ),
    PhotoEntity,
    PrefetchHooks Function()>;
typedef $$SplitsTableTableCreateCompanionBuilder = SplitsTableCompanion
    Function({
  required String id,
  required String activityId,
  required int splitNumber,
  required int startTime,
  required int endTime,
  required double distanceMeters,
  required double paceSecondsPerKm,
  Value<double> elevationGainMeters,
  Value<double> elevationLossMeters,
  Value<int> rowid,
});
typedef $$SplitsTableTableUpdateCompanionBuilder = SplitsTableCompanion
    Function({
  Value<String> id,
  Value<String> activityId,
  Value<int> splitNumber,
  Value<int> startTime,
  Value<int> endTime,
  Value<double> distanceMeters,
  Value<double> paceSecondsPerKm,
  Value<double> elevationGainMeters,
  Value<double> elevationLossMeters,
  Value<int> rowid,
});

class $$SplitsTableTableFilterComposer
    extends Composer<_$TrailRunDatabase, $SplitsTableTable> {
  $$SplitsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get activityId => $composableBuilder(
      column: $table.activityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get splitNumber => $composableBuilder(
      column: $table.splitNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get distanceMeters => $composableBuilder(
      column: $table.distanceMeters,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get paceSecondsPerKm => $composableBuilder(
      column: $table.paceSecondsPerKm,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get elevationGainMeters => $composableBuilder(
      column: $table.elevationGainMeters,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get elevationLossMeters => $composableBuilder(
      column: $table.elevationLossMeters,
      builder: (column) => ColumnFilters(column));
}

class $$SplitsTableTableOrderingComposer
    extends Composer<_$TrailRunDatabase, $SplitsTableTable> {
  $$SplitsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get activityId => $composableBuilder(
      column: $table.activityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get splitNumber => $composableBuilder(
      column: $table.splitNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get distanceMeters => $composableBuilder(
      column: $table.distanceMeters,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get paceSecondsPerKm => $composableBuilder(
      column: $table.paceSecondsPerKm,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get elevationGainMeters => $composableBuilder(
      column: $table.elevationGainMeters,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get elevationLossMeters => $composableBuilder(
      column: $table.elevationLossMeters,
      builder: (column) => ColumnOrderings(column));
}

class $$SplitsTableTableAnnotationComposer
    extends Composer<_$TrailRunDatabase, $SplitsTableTable> {
  $$SplitsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get activityId => $composableBuilder(
      column: $table.activityId, builder: (column) => column);

  GeneratedColumn<int> get splitNumber => $composableBuilder(
      column: $table.splitNumber, builder: (column) => column);

  GeneratedColumn<int> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<int> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<double> get distanceMeters => $composableBuilder(
      column: $table.distanceMeters, builder: (column) => column);

  GeneratedColumn<double> get paceSecondsPerKm => $composableBuilder(
      column: $table.paceSecondsPerKm, builder: (column) => column);

  GeneratedColumn<double> get elevationGainMeters => $composableBuilder(
      column: $table.elevationGainMeters, builder: (column) => column);

  GeneratedColumn<double> get elevationLossMeters => $composableBuilder(
      column: $table.elevationLossMeters, builder: (column) => column);
}

class $$SplitsTableTableTableManager extends RootTableManager<
    _$TrailRunDatabase,
    $SplitsTableTable,
    SplitEntity,
    $$SplitsTableTableFilterComposer,
    $$SplitsTableTableOrderingComposer,
    $$SplitsTableTableAnnotationComposer,
    $$SplitsTableTableCreateCompanionBuilder,
    $$SplitsTableTableUpdateCompanionBuilder,
    (
      SplitEntity,
      BaseReferences<_$TrailRunDatabase, $SplitsTableTable, SplitEntity>
    ),
    SplitEntity,
    PrefetchHooks Function()> {
  $$SplitsTableTableTableManager(_$TrailRunDatabase db, $SplitsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SplitsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SplitsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SplitsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> activityId = const Value.absent(),
            Value<int> splitNumber = const Value.absent(),
            Value<int> startTime = const Value.absent(),
            Value<int> endTime = const Value.absent(),
            Value<double> distanceMeters = const Value.absent(),
            Value<double> paceSecondsPerKm = const Value.absent(),
            Value<double> elevationGainMeters = const Value.absent(),
            Value<double> elevationLossMeters = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SplitsTableCompanion(
            id: id,
            activityId: activityId,
            splitNumber: splitNumber,
            startTime: startTime,
            endTime: endTime,
            distanceMeters: distanceMeters,
            paceSecondsPerKm: paceSecondsPerKm,
            elevationGainMeters: elevationGainMeters,
            elevationLossMeters: elevationLossMeters,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String activityId,
            required int splitNumber,
            required int startTime,
            required int endTime,
            required double distanceMeters,
            required double paceSecondsPerKm,
            Value<double> elevationGainMeters = const Value.absent(),
            Value<double> elevationLossMeters = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SplitsTableCompanion.insert(
            id: id,
            activityId: activityId,
            splitNumber: splitNumber,
            startTime: startTime,
            endTime: endTime,
            distanceMeters: distanceMeters,
            paceSecondsPerKm: paceSecondsPerKm,
            elevationGainMeters: elevationGainMeters,
            elevationLossMeters: elevationLossMeters,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SplitsTableTableProcessedTableManager = ProcessedTableManager<
    _$TrailRunDatabase,
    $SplitsTableTable,
    SplitEntity,
    $$SplitsTableTableFilterComposer,
    $$SplitsTableTableOrderingComposer,
    $$SplitsTableTableAnnotationComposer,
    $$SplitsTableTableCreateCompanionBuilder,
    $$SplitsTableTableUpdateCompanionBuilder,
    (
      SplitEntity,
      BaseReferences<_$TrailRunDatabase, $SplitsTableTable, SplitEntity>
    ),
    SplitEntity,
    PrefetchHooks Function()>;
typedef $$SyncQueueTableTableCreateCompanionBuilder = SyncQueueTableCompanion
    Function({
  required String id,
  required String entityType,
  required String entityId,
  required String operation,
  required String payload,
  Value<int> priority,
  Value<int> retryCount,
  Value<int> maxRetries,
  required int createdAt,
  Value<int?> lastAttemptAt,
  required int nextAttemptAt,
  Value<String?> lastError,
  Value<int> rowid,
});
typedef $$SyncQueueTableTableUpdateCompanionBuilder = SyncQueueTableCompanion
    Function({
  Value<String> id,
  Value<String> entityType,
  Value<String> entityId,
  Value<String> operation,
  Value<String> payload,
  Value<int> priority,
  Value<int> retryCount,
  Value<int> maxRetries,
  Value<int> createdAt,
  Value<int?> lastAttemptAt,
  Value<int> nextAttemptAt,
  Value<String?> lastError,
  Value<int> rowid,
});

class $$SyncQueueTableTableFilterComposer
    extends Composer<_$TrailRunDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maxRetries => $composableBuilder(
      column: $table.maxRetries, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastAttemptAt => $composableBuilder(
      column: $table.lastAttemptAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get nextAttemptAt => $composableBuilder(
      column: $table.nextAttemptAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnFilters(column));
}

class $$SyncQueueTableTableOrderingComposer
    extends Composer<_$TrailRunDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxRetries => $composableBuilder(
      column: $table.maxRetries, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastAttemptAt => $composableBuilder(
      column: $table.lastAttemptAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get nextAttemptAt => $composableBuilder(
      column: $table.nextAttemptAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnOrderings(column));
}

class $$SyncQueueTableTableAnnotationComposer
    extends Composer<_$TrailRunDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => column);

  GeneratedColumn<int> get maxRetries => $composableBuilder(
      column: $table.maxRetries, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get lastAttemptAt => $composableBuilder(
      column: $table.lastAttemptAt, builder: (column) => column);

  GeneratedColumn<int> get nextAttemptAt => $composableBuilder(
      column: $table.nextAttemptAt, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$SyncQueueTableTableTableManager extends RootTableManager<
    _$TrailRunDatabase,
    $SyncQueueTableTable,
    SyncQueueEntity,
    $$SyncQueueTableTableFilterComposer,
    $$SyncQueueTableTableOrderingComposer,
    $$SyncQueueTableTableAnnotationComposer,
    $$SyncQueueTableTableCreateCompanionBuilder,
    $$SyncQueueTableTableUpdateCompanionBuilder,
    (
      SyncQueueEntity,
      BaseReferences<_$TrailRunDatabase, $SyncQueueTableTable, SyncQueueEntity>
    ),
    SyncQueueEntity,
    PrefetchHooks Function()> {
  $$SyncQueueTableTableTableManager(
      _$TrailRunDatabase db, $SyncQueueTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> entityType = const Value.absent(),
            Value<String> entityId = const Value.absent(),
            Value<String> operation = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<int> priority = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<int> maxRetries = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int?> lastAttemptAt = const Value.absent(),
            Value<int> nextAttemptAt = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncQueueTableCompanion(
            id: id,
            entityType: entityType,
            entityId: entityId,
            operation: operation,
            payload: payload,
            priority: priority,
            retryCount: retryCount,
            maxRetries: maxRetries,
            createdAt: createdAt,
            lastAttemptAt: lastAttemptAt,
            nextAttemptAt: nextAttemptAt,
            lastError: lastError,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String entityType,
            required String entityId,
            required String operation,
            required String payload,
            Value<int> priority = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<int> maxRetries = const Value.absent(),
            required int createdAt,
            Value<int?> lastAttemptAt = const Value.absent(),
            required int nextAttemptAt,
            Value<String?> lastError = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncQueueTableCompanion.insert(
            id: id,
            entityType: entityType,
            entityId: entityId,
            operation: operation,
            payload: payload,
            priority: priority,
            retryCount: retryCount,
            maxRetries: maxRetries,
            createdAt: createdAt,
            lastAttemptAt: lastAttemptAt,
            nextAttemptAt: nextAttemptAt,
            lastError: lastError,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncQueueTableTableProcessedTableManager = ProcessedTableManager<
    _$TrailRunDatabase,
    $SyncQueueTableTable,
    SyncQueueEntity,
    $$SyncQueueTableTableFilterComposer,
    $$SyncQueueTableTableOrderingComposer,
    $$SyncQueueTableTableAnnotationComposer,
    $$SyncQueueTableTableCreateCompanionBuilder,
    $$SyncQueueTableTableUpdateCompanionBuilder,
    (
      SyncQueueEntity,
      BaseReferences<_$TrailRunDatabase, $SyncQueueTableTable, SyncQueueEntity>
    ),
    SyncQueueEntity,
    PrefetchHooks Function()>;

class $TrailRunDatabaseManager {
  final _$TrailRunDatabase _db;
  $TrailRunDatabaseManager(this._db);
  $$ActivitiesTableTableTableManager get activitiesTable =>
      $$ActivitiesTableTableTableManager(_db, _db.activitiesTable);
  $$TrackPointsTableTableTableManager get trackPointsTable =>
      $$TrackPointsTableTableTableManager(_db, _db.trackPointsTable);
  $$PhotosTableTableTableManager get photosTable =>
      $$PhotosTableTableTableManager(_db, _db.photosTable);
  $$SplitsTableTableTableManager get splitsTable =>
      $$SplitsTableTableTableManager(_db, _db.splitsTable);
  $$SyncQueueTableTableTableManager get syncQueueTable =>
      $$SyncQueueTableTableTableManager(_db, _db.syncQueueTable);
}
