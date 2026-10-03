// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $VehiclesTable extends Vehicles with TableInfo<$VehiclesTable, Vehicle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VehiclesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _registrationNumberMeta =
      const VerificationMeta('registrationNumber');
  @override
  late final GeneratedColumn<String> registrationNumber =
      GeneratedColumn<String>(
        'registration_number',
        aliasedName,
        true,
        additionalChecks: GeneratedColumn.checkTextLength(
          minTextLength: 1,
          maxTextLength: 32,
        ),
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _startingOdometerKmMeta =
      const VerificationMeta('startingOdometerKm');
  @override
  late final GeneratedColumn<double> startingOdometerKm =
      GeneratedColumn<double>(
        'starting_odometer_km',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0.0),
      );
  static const VerificationMeta _photoPathMeta = const VerificationMeta(
    'photoPath',
  );
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
    'photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _retiredAtMeta = const VerificationMeta(
    'retiredAt',
  );
  @override
  late final GeneratedColumn<DateTime> retiredAt = GeneratedColumn<DateTime>(
    'retired_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    createdAt,
    updatedAt,
    id,
    displayName,
    registrationNumber,
    startingOdometerKm,
    photoPath,
    isActive,
    retiredAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vehicles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Vehicle> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('registration_number')) {
      context.handle(
        _registrationNumberMeta,
        registrationNumber.isAcceptableOrUnknown(
          data['registration_number']!,
          _registrationNumberMeta,
        ),
      );
    }
    if (data.containsKey('starting_odometer_km')) {
      context.handle(
        _startingOdometerKmMeta,
        startingOdometerKm.isAcceptableOrUnknown(
          data['starting_odometer_km']!,
          _startingOdometerKmMeta,
        ),
      );
    }
    if (data.containsKey('photo_path')) {
      context.handle(
        _photoPathMeta,
        photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('retired_at')) {
      context.handle(
        _retiredAtMeta,
        retiredAt.isAcceptableOrUnknown(data['retired_at']!, _retiredAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Vehicle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Vehicle(
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      registrationNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}registration_number'],
      ),
      startingOdometerKm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}starting_odometer_km'],
      )!,
      photoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_path'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      retiredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}retired_at'],
      ),
    );
  }

  @override
  $VehiclesTable createAlias(String alias) {
    return $VehiclesTable(attachedDatabase, alias);
  }
}

class Vehicle extends DataClass implements Insertable<Vehicle> {
  final DateTime createdAt;
  final DateTime updatedAt;
  final int id;
  final String displayName;
  final String? registrationNumber;
  final double startingOdometerKm;
  final String? photoPath;
  final bool isActive;
  final DateTime? retiredAt;
  const Vehicle({
    required this.createdAt,
    required this.updatedAt,
    required this.id,
    required this.displayName,
    this.registrationNumber,
    required this.startingOdometerKm,
    this.photoPath,
    required this.isActive,
    this.retiredAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['id'] = Variable<int>(id);
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || registrationNumber != null) {
      map['registration_number'] = Variable<String>(registrationNumber);
    }
    map['starting_odometer_km'] = Variable<double>(startingOdometerKm);
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || retiredAt != null) {
      map['retired_at'] = Variable<DateTime>(retiredAt);
    }
    return map;
  }

  VehiclesCompanion toCompanion(bool nullToAbsent) {
    return VehiclesCompanion(
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      id: Value(id),
      displayName: Value(displayName),
      registrationNumber: registrationNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(registrationNumber),
      startingOdometerKm: Value(startingOdometerKm),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
      isActive: Value(isActive),
      retiredAt: retiredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(retiredAt),
    );
  }

  factory Vehicle.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Vehicle(
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      id: serializer.fromJson<int>(json['id']),
      displayName: serializer.fromJson<String>(json['displayName']),
      registrationNumber: serializer.fromJson<String?>(
        json['registrationNumber'],
      ),
      startingOdometerKm: serializer.fromJson<double>(
        json['startingOdometerKm'],
      ),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      retiredAt: serializer.fromJson<DateTime?>(json['retiredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'id': serializer.toJson<int>(id),
      'displayName': serializer.toJson<String>(displayName),
      'registrationNumber': serializer.toJson<String?>(registrationNumber),
      'startingOdometerKm': serializer.toJson<double>(startingOdometerKm),
      'photoPath': serializer.toJson<String?>(photoPath),
      'isActive': serializer.toJson<bool>(isActive),
      'retiredAt': serializer.toJson<DateTime?>(retiredAt),
    };
  }

  Vehicle copyWith({
    DateTime? createdAt,
    DateTime? updatedAt,
    int? id,
    String? displayName,
    Value<String?> registrationNumber = const Value.absent(),
    double? startingOdometerKm,
    Value<String?> photoPath = const Value.absent(),
    bool? isActive,
    Value<DateTime?> retiredAt = const Value.absent(),
  }) => Vehicle(
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    id: id ?? this.id,
    displayName: displayName ?? this.displayName,
    registrationNumber: registrationNumber.present
        ? registrationNumber.value
        : this.registrationNumber,
    startingOdometerKm: startingOdometerKm ?? this.startingOdometerKm,
    photoPath: photoPath.present ? photoPath.value : this.photoPath,
    isActive: isActive ?? this.isActive,
    retiredAt: retiredAt.present ? retiredAt.value : this.retiredAt,
  );
  Vehicle copyWithCompanion(VehiclesCompanion data) {
    return Vehicle(
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      id: data.id.present ? data.id.value : this.id,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      registrationNumber: data.registrationNumber.present
          ? data.registrationNumber.value
          : this.registrationNumber,
      startingOdometerKm: data.startingOdometerKm.present
          ? data.startingOdometerKm.value
          : this.startingOdometerKm,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      retiredAt: data.retiredAt.present ? data.retiredAt.value : this.retiredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Vehicle(')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('registrationNumber: $registrationNumber, ')
          ..write('startingOdometerKm: $startingOdometerKm, ')
          ..write('photoPath: $photoPath, ')
          ..write('isActive: $isActive, ')
          ..write('retiredAt: $retiredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    createdAt,
    updatedAt,
    id,
    displayName,
    registrationNumber,
    startingOdometerKm,
    photoPath,
    isActive,
    retiredAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Vehicle &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.registrationNumber == this.registrationNumber &&
          other.startingOdometerKm == this.startingOdometerKm &&
          other.photoPath == this.photoPath &&
          other.isActive == this.isActive &&
          other.retiredAt == this.retiredAt);
}

class VehiclesCompanion extends UpdateCompanion<Vehicle> {
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> id;
  final Value<String> displayName;
  final Value<String?> registrationNumber;
  final Value<double> startingOdometerKm;
  final Value<String?> photoPath;
  final Value<bool> isActive;
  final Value<DateTime?> retiredAt;
  const VehiclesCompanion({
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.registrationNumber = const Value.absent(),
    this.startingOdometerKm = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.isActive = const Value.absent(),
    this.retiredAt = const Value.absent(),
  });
  VehiclesCompanion.insert({
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.id = const Value.absent(),
    required String displayName,
    this.registrationNumber = const Value.absent(),
    this.startingOdometerKm = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.isActive = const Value.absent(),
    this.retiredAt = const Value.absent(),
  }) : displayName = Value(displayName);
  static Insertable<Vehicle> custom({
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? id,
    Expression<String>? displayName,
    Expression<String>? registrationNumber,
    Expression<double>? startingOdometerKm,
    Expression<String>? photoPath,
    Expression<bool>? isActive,
    Expression<DateTime>? retiredAt,
  }) {
    return RawValuesInsertable({
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (registrationNumber != null) 'registration_number': registrationNumber,
      if (startingOdometerKm != null)
        'starting_odometer_km': startingOdometerKm,
      if (photoPath != null) 'photo_path': photoPath,
      if (isActive != null) 'is_active': isActive,
      if (retiredAt != null) 'retired_at': retiredAt,
    });
  }

  VehiclesCompanion copyWith({
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? id,
    Value<String>? displayName,
    Value<String?>? registrationNumber,
    Value<double>? startingOdometerKm,
    Value<String?>? photoPath,
    Value<bool>? isActive,
    Value<DateTime?>? retiredAt,
  }) {
    return VehiclesCompanion(
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      startingOdometerKm: startingOdometerKm ?? this.startingOdometerKm,
      photoPath: photoPath ?? this.photoPath,
      isActive: isActive ?? this.isActive,
      retiredAt: retiredAt ?? this.retiredAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (registrationNumber.present) {
      map['registration_number'] = Variable<String>(registrationNumber.value);
    }
    if (startingOdometerKm.present) {
      map['starting_odometer_km'] = Variable<double>(startingOdometerKm.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (retiredAt.present) {
      map['retired_at'] = Variable<DateTime>(retiredAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VehiclesCompanion(')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('registrationNumber: $registrationNumber, ')
          ..write('startingOdometerKm: $startingOdometerKm, ')
          ..write('photoPath: $photoPath, ')
          ..write('isActive: $isActive, ')
          ..write('retiredAt: $retiredAt')
          ..write(')'))
        .toString();
  }
}

class $FuelEventsTable extends FuelEvents
    with TableInfo<$FuelEventsTable, FuelEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FuelEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _vehicleIdMeta = const VerificationMeta(
    'vehicleId',
  );
  @override
  late final GeneratedColumn<int> vehicleId = GeneratedColumn<int>(
    'vehicle_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES vehicles (id) ON UPDATE CASCADE ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _odometerKmMeta = const VerificationMeta(
    'odometerKm',
  );
  @override
  late final GeneratedColumn<double> odometerKm = GeneratedColumn<double>(
    'odometer_km',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fuelBrandMeta = const VerificationMeta(
    'fuelBrand',
  );
  @override
  late final GeneratedColumn<String> fuelBrand = GeneratedColumn<String>(
    'fuel_brand',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 80,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fuelVolumeMillilitresMeta =
      const VerificationMeta('fuelVolumeMillilitres');
  @override
  late final GeneratedColumn<int> fuelVolumeMillilitres = GeneratedColumn<int>(
    'fuel_volume_millilitres',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _costSenMeta = const VerificationMeta(
    'costSen',
  );
  @override
  late final GeneratedColumn<int> costSen = GeneratedColumn<int>(
    'cost_sen',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isFullTankMeta = const VerificationMeta(
    'isFullTank',
  );
  @override
  late final GeneratedColumn<bool> isFullTank = GeneratedColumn<bool>(
    'is_full_tank',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_full_tank" IN (0, 1))',
    ),
  );
  static const VerificationMeta _tripDistanceMetresMeta =
      const VerificationMeta('tripDistanceMetres');
  @override
  late final GeneratedColumn<int> tripDistanceMetres = GeneratedColumn<int>(
    'trip_distance_metres',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    createdAt,
    updatedAt,
    id,
    vehicleId,
    occurredAt,
    odometerKm,
    fuelBrand,
    fuelVolumeMillilitres,
    costSen,
    isFullTank,
    tripDistanceMetres,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fuel_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<FuelEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('vehicle_id')) {
      context.handle(
        _vehicleIdMeta,
        vehicleId.isAcceptableOrUnknown(data['vehicle_id']!, _vehicleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_vehicleIdMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('odometer_km')) {
      context.handle(
        _odometerKmMeta,
        odometerKm.isAcceptableOrUnknown(data['odometer_km']!, _odometerKmMeta),
      );
    } else if (isInserting) {
      context.missing(_odometerKmMeta);
    }
    if (data.containsKey('fuel_brand')) {
      context.handle(
        _fuelBrandMeta,
        fuelBrand.isAcceptableOrUnknown(data['fuel_brand']!, _fuelBrandMeta),
      );
    } else if (isInserting) {
      context.missing(_fuelBrandMeta);
    }
    if (data.containsKey('fuel_volume_millilitres')) {
      context.handle(
        _fuelVolumeMillilitresMeta,
        fuelVolumeMillilitres.isAcceptableOrUnknown(
          data['fuel_volume_millilitres']!,
          _fuelVolumeMillilitresMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fuelVolumeMillilitresMeta);
    }
    if (data.containsKey('cost_sen')) {
      context.handle(
        _costSenMeta,
        costSen.isAcceptableOrUnknown(data['cost_sen']!, _costSenMeta),
      );
    } else if (isInserting) {
      context.missing(_costSenMeta);
    }
    if (data.containsKey('is_full_tank')) {
      context.handle(
        _isFullTankMeta,
        isFullTank.isAcceptableOrUnknown(
          data['is_full_tank']!,
          _isFullTankMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isFullTankMeta);
    }
    if (data.containsKey('trip_distance_metres')) {
      context.handle(
        _tripDistanceMetresMeta,
        tripDistanceMetres.isAcceptableOrUnknown(
          data['trip_distance_metres']!,
          _tripDistanceMetresMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FuelEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FuelEvent(
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      vehicleId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}vehicle_id'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      odometerKm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}odometer_km'],
      )!,
      fuelBrand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fuel_brand'],
      )!,
      fuelVolumeMillilitres: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fuel_volume_millilitres'],
      )!,
      costSen: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cost_sen'],
      )!,
      isFullTank: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_full_tank'],
      )!,
      tripDistanceMetres: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}trip_distance_metres'],
      ),
    );
  }

  @override
  $FuelEventsTable createAlias(String alias) {
    return $FuelEventsTable(attachedDatabase, alias);
  }
}

class FuelEvent extends DataClass implements Insertable<FuelEvent> {
  final DateTime createdAt;
  final DateTime updatedAt;
  final int id;
  final int vehicleId;
  final DateTime occurredAt;
  final double odometerKm;
  final String fuelBrand;

  /// Litres are persisted as millilitres so sums remain exact.
  final int fuelVolumeMillilitres;

  /// Malaysian Ringgit values are persisted as sen so sums remain exact.
  final int costSen;
  final bool isFullTank;

  /// Optional Trip B reading in metres, preserving up to 0.001 km.
  final int? tripDistanceMetres;
  const FuelEvent({
    required this.createdAt,
    required this.updatedAt,
    required this.id,
    required this.vehicleId,
    required this.occurredAt,
    required this.odometerKm,
    required this.fuelBrand,
    required this.fuelVolumeMillilitres,
    required this.costSen,
    required this.isFullTank,
    this.tripDistanceMetres,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['id'] = Variable<int>(id);
    map['vehicle_id'] = Variable<int>(vehicleId);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    map['odometer_km'] = Variable<double>(odometerKm);
    map['fuel_brand'] = Variable<String>(fuelBrand);
    map['fuel_volume_millilitres'] = Variable<int>(fuelVolumeMillilitres);
    map['cost_sen'] = Variable<int>(costSen);
    map['is_full_tank'] = Variable<bool>(isFullTank);
    if (!nullToAbsent || tripDistanceMetres != null) {
      map['trip_distance_metres'] = Variable<int>(tripDistanceMetres);
    }
    return map;
  }

  FuelEventsCompanion toCompanion(bool nullToAbsent) {
    return FuelEventsCompanion(
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      id: Value(id),
      vehicleId: Value(vehicleId),
      occurredAt: Value(occurredAt),
      odometerKm: Value(odometerKm),
      fuelBrand: Value(fuelBrand),
      fuelVolumeMillilitres: Value(fuelVolumeMillilitres),
      costSen: Value(costSen),
      isFullTank: Value(isFullTank),
      tripDistanceMetres: tripDistanceMetres == null && nullToAbsent
          ? const Value.absent()
          : Value(tripDistanceMetres),
    );
  }

  factory FuelEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FuelEvent(
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      id: serializer.fromJson<int>(json['id']),
      vehicleId: serializer.fromJson<int>(json['vehicleId']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      odometerKm: serializer.fromJson<double>(json['odometerKm']),
      fuelBrand: serializer.fromJson<String>(json['fuelBrand']),
      fuelVolumeMillilitres: serializer.fromJson<int>(
        json['fuelVolumeMillilitres'],
      ),
      costSen: serializer.fromJson<int>(json['costSen']),
      isFullTank: serializer.fromJson<bool>(json['isFullTank']),
      tripDistanceMetres: serializer.fromJson<int?>(json['tripDistanceMetres']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'id': serializer.toJson<int>(id),
      'vehicleId': serializer.toJson<int>(vehicleId),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'odometerKm': serializer.toJson<double>(odometerKm),
      'fuelBrand': serializer.toJson<String>(fuelBrand),
      'fuelVolumeMillilitres': serializer.toJson<int>(fuelVolumeMillilitres),
      'costSen': serializer.toJson<int>(costSen),
      'isFullTank': serializer.toJson<bool>(isFullTank),
      'tripDistanceMetres': serializer.toJson<int?>(tripDistanceMetres),
    };
  }

  FuelEvent copyWith({
    DateTime? createdAt,
    DateTime? updatedAt,
    int? id,
    int? vehicleId,
    DateTime? occurredAt,
    double? odometerKm,
    String? fuelBrand,
    int? fuelVolumeMillilitres,
    int? costSen,
    bool? isFullTank,
    Value<int?> tripDistanceMetres = const Value.absent(),
  }) => FuelEvent(
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    id: id ?? this.id,
    vehicleId: vehicleId ?? this.vehicleId,
    occurredAt: occurredAt ?? this.occurredAt,
    odometerKm: odometerKm ?? this.odometerKm,
    fuelBrand: fuelBrand ?? this.fuelBrand,
    fuelVolumeMillilitres: fuelVolumeMillilitres ?? this.fuelVolumeMillilitres,
    costSen: costSen ?? this.costSen,
    isFullTank: isFullTank ?? this.isFullTank,
    tripDistanceMetres: tripDistanceMetres.present
        ? tripDistanceMetres.value
        : this.tripDistanceMetres,
  );
  FuelEvent copyWithCompanion(FuelEventsCompanion data) {
    return FuelEvent(
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      id: data.id.present ? data.id.value : this.id,
      vehicleId: data.vehicleId.present ? data.vehicleId.value : this.vehicleId,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      odometerKm: data.odometerKm.present
          ? data.odometerKm.value
          : this.odometerKm,
      fuelBrand: data.fuelBrand.present ? data.fuelBrand.value : this.fuelBrand,
      fuelVolumeMillilitres: data.fuelVolumeMillilitres.present
          ? data.fuelVolumeMillilitres.value
          : this.fuelVolumeMillilitres,
      costSen: data.costSen.present ? data.costSen.value : this.costSen,
      isFullTank: data.isFullTank.present
          ? data.isFullTank.value
          : this.isFullTank,
      tripDistanceMetres: data.tripDistanceMetres.present
          ? data.tripDistanceMetres.value
          : this.tripDistanceMetres,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FuelEvent(')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('id: $id, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('odometerKm: $odometerKm, ')
          ..write('fuelBrand: $fuelBrand, ')
          ..write('fuelVolumeMillilitres: $fuelVolumeMillilitres, ')
          ..write('costSen: $costSen, ')
          ..write('isFullTank: $isFullTank, ')
          ..write('tripDistanceMetres: $tripDistanceMetres')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    createdAt,
    updatedAt,
    id,
    vehicleId,
    occurredAt,
    odometerKm,
    fuelBrand,
    fuelVolumeMillilitres,
    costSen,
    isFullTank,
    tripDistanceMetres,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FuelEvent &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.id == this.id &&
          other.vehicleId == this.vehicleId &&
          other.occurredAt == this.occurredAt &&
          other.odometerKm == this.odometerKm &&
          other.fuelBrand == this.fuelBrand &&
          other.fuelVolumeMillilitres == this.fuelVolumeMillilitres &&
          other.costSen == this.costSen &&
          other.isFullTank == this.isFullTank &&
          other.tripDistanceMetres == this.tripDistanceMetres);
}

class FuelEventsCompanion extends UpdateCompanion<FuelEvent> {
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> id;
  final Value<int> vehicleId;
  final Value<DateTime> occurredAt;
  final Value<double> odometerKm;
  final Value<String> fuelBrand;
  final Value<int> fuelVolumeMillilitres;
  final Value<int> costSen;
  final Value<bool> isFullTank;
  final Value<int?> tripDistanceMetres;
  const FuelEventsCompanion({
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.vehicleId = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.odometerKm = const Value.absent(),
    this.fuelBrand = const Value.absent(),
    this.fuelVolumeMillilitres = const Value.absent(),
    this.costSen = const Value.absent(),
    this.isFullTank = const Value.absent(),
    this.tripDistanceMetres = const Value.absent(),
  });
  FuelEventsCompanion.insert({
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.id = const Value.absent(),
    required int vehicleId,
    required DateTime occurredAt,
    required double odometerKm,
    required String fuelBrand,
    required int fuelVolumeMillilitres,
    required int costSen,
    required bool isFullTank,
    this.tripDistanceMetres = const Value.absent(),
  }) : vehicleId = Value(vehicleId),
       occurredAt = Value(occurredAt),
       odometerKm = Value(odometerKm),
       fuelBrand = Value(fuelBrand),
       fuelVolumeMillilitres = Value(fuelVolumeMillilitres),
       costSen = Value(costSen),
       isFullTank = Value(isFullTank);
  static Insertable<FuelEvent> custom({
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? id,
    Expression<int>? vehicleId,
    Expression<DateTime>? occurredAt,
    Expression<double>? odometerKm,
    Expression<String>? fuelBrand,
    Expression<int>? fuelVolumeMillilitres,
    Expression<int>? costSen,
    Expression<bool>? isFullTank,
    Expression<int>? tripDistanceMetres,
  }) {
    return RawValuesInsertable({
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (id != null) 'id': id,
      if (vehicleId != null) 'vehicle_id': vehicleId,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (odometerKm != null) 'odometer_km': odometerKm,
      if (fuelBrand != null) 'fuel_brand': fuelBrand,
      if (fuelVolumeMillilitres != null)
        'fuel_volume_millilitres': fuelVolumeMillilitres,
      if (costSen != null) 'cost_sen': costSen,
      if (isFullTank != null) 'is_full_tank': isFullTank,
      if (tripDistanceMetres != null)
        'trip_distance_metres': tripDistanceMetres,
    });
  }

  FuelEventsCompanion copyWith({
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? id,
    Value<int>? vehicleId,
    Value<DateTime>? occurredAt,
    Value<double>? odometerKm,
    Value<String>? fuelBrand,
    Value<int>? fuelVolumeMillilitres,
    Value<int>? costSen,
    Value<bool>? isFullTank,
    Value<int?>? tripDistanceMetres,
  }) {
    return FuelEventsCompanion(
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      occurredAt: occurredAt ?? this.occurredAt,
      odometerKm: odometerKm ?? this.odometerKm,
      fuelBrand: fuelBrand ?? this.fuelBrand,
      fuelVolumeMillilitres:
          fuelVolumeMillilitres ?? this.fuelVolumeMillilitres,
      costSen: costSen ?? this.costSen,
      isFullTank: isFullTank ?? this.isFullTank,
      tripDistanceMetres: tripDistanceMetres ?? this.tripDistanceMetres,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (vehicleId.present) {
      map['vehicle_id'] = Variable<int>(vehicleId.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (odometerKm.present) {
      map['odometer_km'] = Variable<double>(odometerKm.value);
    }
    if (fuelBrand.present) {
      map['fuel_brand'] = Variable<String>(fuelBrand.value);
    }
    if (fuelVolumeMillilitres.present) {
      map['fuel_volume_millilitres'] = Variable<int>(
        fuelVolumeMillilitres.value,
      );
    }
    if (costSen.present) {
      map['cost_sen'] = Variable<int>(costSen.value);
    }
    if (isFullTank.present) {
      map['is_full_tank'] = Variable<bool>(isFullTank.value);
    }
    if (tripDistanceMetres.present) {
      map['trip_distance_metres'] = Variable<int>(tripDistanceMetres.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FuelEventsCompanion(')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('id: $id, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('odometerKm: $odometerKm, ')
          ..write('fuelBrand: $fuelBrand, ')
          ..write('fuelVolumeMillilitres: $fuelVolumeMillilitres, ')
          ..write('costSen: $costSen, ')
          ..write('isFullTank: $isFullTank, ')
          ..write('tripDistanceMetres: $tripDistanceMetres')
          ..write(')'))
        .toString();
  }
}

class $MaintenanceRecordsTable extends MaintenanceRecords
    with TableInfo<$MaintenanceRecordsTable, MaintenanceRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MaintenanceRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _vehicleIdMeta = const VerificationMeta(
    'vehicleId',
  );
  @override
  late final GeneratedColumn<int> vehicleId = GeneratedColumn<int>(
    'vehicle_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES vehicles (id) ON UPDATE CASCADE ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _odometerKmMeta = const VerificationMeta(
    'odometerKm',
  );
  @override
  late final GeneratedColumn<double> odometerKm = GeneratedColumn<double>(
    'odometer_km',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<MaintenanceCategory, String>
  category =
      GeneratedColumn<String>(
        'category',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<MaintenanceCategory>(
        $MaintenanceRecordsTable.$convertercategory,
      );
  static const VerificationMeta _workshopMeta = const VerificationMeta(
    'workshop',
  );
  @override
  late final GeneratedColumn<String> workshop = GeneratedColumn<String>(
    'workshop',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 160,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serviceTitleMeta = const VerificationMeta(
    'serviceTitle',
  );
  @override
  late final GeneratedColumn<String> serviceTitle = GeneratedColumn<String>(
    'service_title',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalCostSenMeta = const VerificationMeta(
    'totalCostSen',
  );
  @override
  late final GeneratedColumn<int> totalCostSen = GeneratedColumn<int>(
    'total_cost_sen',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    createdAt,
    updatedAt,
    id,
    vehicleId,
    occurredAt,
    odometerKm,
    category,
    workshop,
    serviceTitle,
    totalCostSen,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'maintenance_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<MaintenanceRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('vehicle_id')) {
      context.handle(
        _vehicleIdMeta,
        vehicleId.isAcceptableOrUnknown(data['vehicle_id']!, _vehicleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_vehicleIdMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('odometer_km')) {
      context.handle(
        _odometerKmMeta,
        odometerKm.isAcceptableOrUnknown(data['odometer_km']!, _odometerKmMeta),
      );
    } else if (isInserting) {
      context.missing(_odometerKmMeta);
    }
    if (data.containsKey('workshop')) {
      context.handle(
        _workshopMeta,
        workshop.isAcceptableOrUnknown(data['workshop']!, _workshopMeta),
      );
    }
    if (data.containsKey('service_title')) {
      context.handle(
        _serviceTitleMeta,
        serviceTitle.isAcceptableOrUnknown(
          data['service_title']!,
          _serviceTitleMeta,
        ),
      );
    }
    if (data.containsKey('total_cost_sen')) {
      context.handle(
        _totalCostSenMeta,
        totalCostSen.isAcceptableOrUnknown(
          data['total_cost_sen']!,
          _totalCostSenMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalCostSenMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {id, vehicleId},
  ];
  @override
  MaintenanceRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MaintenanceRecord(
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      vehicleId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}vehicle_id'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      odometerKm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}odometer_km'],
      )!,
      category: $MaintenanceRecordsTable.$convertercategory.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}category'],
        )!,
      ),
      workshop: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workshop'],
      ),
      serviceTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}service_title'],
      ),
      totalCostSen: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_cost_sen'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $MaintenanceRecordsTable createAlias(String alias) {
    return $MaintenanceRecordsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MaintenanceCategory, String, String>
  $convertercategory = const EnumNameConverter<MaintenanceCategory>(
    MaintenanceCategory.values,
  );
}

class MaintenanceRecord extends DataClass
    implements Insertable<MaintenanceRecord> {
  final DateTime createdAt;
  final DateTime updatedAt;
  final int id;
  final int vehicleId;
  final DateTime occurredAt;
  final double odometerKm;
  final MaintenanceCategory category;
  final String? workshop;

  /// Optional user-facing title for Service visits and their reminders.
  final String? serviceTitle;
  final int totalCostSen;
  final String? notes;
  const MaintenanceRecord({
    required this.createdAt,
    required this.updatedAt,
    required this.id,
    required this.vehicleId,
    required this.occurredAt,
    required this.odometerKm,
    required this.category,
    this.workshop,
    this.serviceTitle,
    required this.totalCostSen,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['id'] = Variable<int>(id);
    map['vehicle_id'] = Variable<int>(vehicleId);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    map['odometer_km'] = Variable<double>(odometerKm);
    {
      map['category'] = Variable<String>(
        $MaintenanceRecordsTable.$convertercategory.toSql(category),
      );
    }
    if (!nullToAbsent || workshop != null) {
      map['workshop'] = Variable<String>(workshop);
    }
    if (!nullToAbsent || serviceTitle != null) {
      map['service_title'] = Variable<String>(serviceTitle);
    }
    map['total_cost_sen'] = Variable<int>(totalCostSen);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  MaintenanceRecordsCompanion toCompanion(bool nullToAbsent) {
    return MaintenanceRecordsCompanion(
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      id: Value(id),
      vehicleId: Value(vehicleId),
      occurredAt: Value(occurredAt),
      odometerKm: Value(odometerKm),
      category: Value(category),
      workshop: workshop == null && nullToAbsent
          ? const Value.absent()
          : Value(workshop),
      serviceTitle: serviceTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(serviceTitle),
      totalCostSen: Value(totalCostSen),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory MaintenanceRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MaintenanceRecord(
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      id: serializer.fromJson<int>(json['id']),
      vehicleId: serializer.fromJson<int>(json['vehicleId']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      odometerKm: serializer.fromJson<double>(json['odometerKm']),
      category: $MaintenanceRecordsTable.$convertercategory.fromJson(
        serializer.fromJson<String>(json['category']),
      ),
      workshop: serializer.fromJson<String?>(json['workshop']),
      serviceTitle: serializer.fromJson<String?>(json['serviceTitle']),
      totalCostSen: serializer.fromJson<int>(json['totalCostSen']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'id': serializer.toJson<int>(id),
      'vehicleId': serializer.toJson<int>(vehicleId),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'odometerKm': serializer.toJson<double>(odometerKm),
      'category': serializer.toJson<String>(
        $MaintenanceRecordsTable.$convertercategory.toJson(category),
      ),
      'workshop': serializer.toJson<String?>(workshop),
      'serviceTitle': serializer.toJson<String?>(serviceTitle),
      'totalCostSen': serializer.toJson<int>(totalCostSen),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  MaintenanceRecord copyWith({
    DateTime? createdAt,
    DateTime? updatedAt,
    int? id,
    int? vehicleId,
    DateTime? occurredAt,
    double? odometerKm,
    MaintenanceCategory? category,
    Value<String?> workshop = const Value.absent(),
    Value<String?> serviceTitle = const Value.absent(),
    int? totalCostSen,
    Value<String?> notes = const Value.absent(),
  }) => MaintenanceRecord(
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    id: id ?? this.id,
    vehicleId: vehicleId ?? this.vehicleId,
    occurredAt: occurredAt ?? this.occurredAt,
    odometerKm: odometerKm ?? this.odometerKm,
    category: category ?? this.category,
    workshop: workshop.present ? workshop.value : this.workshop,
    serviceTitle: serviceTitle.present ? serviceTitle.value : this.serviceTitle,
    totalCostSen: totalCostSen ?? this.totalCostSen,
    notes: notes.present ? notes.value : this.notes,
  );
  MaintenanceRecord copyWithCompanion(MaintenanceRecordsCompanion data) {
    return MaintenanceRecord(
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      id: data.id.present ? data.id.value : this.id,
      vehicleId: data.vehicleId.present ? data.vehicleId.value : this.vehicleId,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      odometerKm: data.odometerKm.present
          ? data.odometerKm.value
          : this.odometerKm,
      category: data.category.present ? data.category.value : this.category,
      workshop: data.workshop.present ? data.workshop.value : this.workshop,
      serviceTitle: data.serviceTitle.present
          ? data.serviceTitle.value
          : this.serviceTitle,
      totalCostSen: data.totalCostSen.present
          ? data.totalCostSen.value
          : this.totalCostSen,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MaintenanceRecord(')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('id: $id, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('odometerKm: $odometerKm, ')
          ..write('category: $category, ')
          ..write('workshop: $workshop, ')
          ..write('serviceTitle: $serviceTitle, ')
          ..write('totalCostSen: $totalCostSen, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    createdAt,
    updatedAt,
    id,
    vehicleId,
    occurredAt,
    odometerKm,
    category,
    workshop,
    serviceTitle,
    totalCostSen,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MaintenanceRecord &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.id == this.id &&
          other.vehicleId == this.vehicleId &&
          other.occurredAt == this.occurredAt &&
          other.odometerKm == this.odometerKm &&
          other.category == this.category &&
          other.workshop == this.workshop &&
          other.serviceTitle == this.serviceTitle &&
          other.totalCostSen == this.totalCostSen &&
          other.notes == this.notes);
}

class MaintenanceRecordsCompanion extends UpdateCompanion<MaintenanceRecord> {
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> id;
  final Value<int> vehicleId;
  final Value<DateTime> occurredAt;
  final Value<double> odometerKm;
  final Value<MaintenanceCategory> category;
  final Value<String?> workshop;
  final Value<String?> serviceTitle;
  final Value<int> totalCostSen;
  final Value<String?> notes;
  const MaintenanceRecordsCompanion({
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.vehicleId = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.odometerKm = const Value.absent(),
    this.category = const Value.absent(),
    this.workshop = const Value.absent(),
    this.serviceTitle = const Value.absent(),
    this.totalCostSen = const Value.absent(),
    this.notes = const Value.absent(),
  });
  MaintenanceRecordsCompanion.insert({
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.id = const Value.absent(),
    required int vehicleId,
    required DateTime occurredAt,
    required double odometerKm,
    required MaintenanceCategory category,
    this.workshop = const Value.absent(),
    this.serviceTitle = const Value.absent(),
    required int totalCostSen,
    this.notes = const Value.absent(),
  }) : vehicleId = Value(vehicleId),
       occurredAt = Value(occurredAt),
       odometerKm = Value(odometerKm),
       category = Value(category),
       totalCostSen = Value(totalCostSen);
  static Insertable<MaintenanceRecord> custom({
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? id,
    Expression<int>? vehicleId,
    Expression<DateTime>? occurredAt,
    Expression<double>? odometerKm,
    Expression<String>? category,
    Expression<String>? workshop,
    Expression<String>? serviceTitle,
    Expression<int>? totalCostSen,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (id != null) 'id': id,
      if (vehicleId != null) 'vehicle_id': vehicleId,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (odometerKm != null) 'odometer_km': odometerKm,
      if (category != null) 'category': category,
      if (workshop != null) 'workshop': workshop,
      if (serviceTitle != null) 'service_title': serviceTitle,
      if (totalCostSen != null) 'total_cost_sen': totalCostSen,
      if (notes != null) 'notes': notes,
    });
  }

  MaintenanceRecordsCompanion copyWith({
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? id,
    Value<int>? vehicleId,
    Value<DateTime>? occurredAt,
    Value<double>? odometerKm,
    Value<MaintenanceCategory>? category,
    Value<String?>? workshop,
    Value<String?>? serviceTitle,
    Value<int>? totalCostSen,
    Value<String?>? notes,
  }) {
    return MaintenanceRecordsCompanion(
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      occurredAt: occurredAt ?? this.occurredAt,
      odometerKm: odometerKm ?? this.odometerKm,
      category: category ?? this.category,
      workshop: workshop ?? this.workshop,
      serviceTitle: serviceTitle ?? this.serviceTitle,
      totalCostSen: totalCostSen ?? this.totalCostSen,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (vehicleId.present) {
      map['vehicle_id'] = Variable<int>(vehicleId.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (odometerKm.present) {
      map['odometer_km'] = Variable<double>(odometerKm.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(
        $MaintenanceRecordsTable.$convertercategory.toSql(category.value),
      );
    }
    if (workshop.present) {
      map['workshop'] = Variable<String>(workshop.value);
    }
    if (serviceTitle.present) {
      map['service_title'] = Variable<String>(serviceTitle.value);
    }
    if (totalCostSen.present) {
      map['total_cost_sen'] = Variable<int>(totalCostSen.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MaintenanceRecordsCompanion(')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('id: $id, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('odometerKm: $odometerKm, ')
          ..write('category: $category, ')
          ..write('workshop: $workshop, ')
          ..write('serviceTitle: $serviceTitle, ')
          ..write('totalCostSen: $totalCostSen, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class $MaintenanceItemsTable extends MaintenanceItems
    with TableInfo<$MaintenanceItemsTable, MaintenanceItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MaintenanceItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _vehicleIdMeta = const VerificationMeta(
    'vehicleId',
  );
  @override
  late final GeneratedColumn<int> vehicleId = GeneratedColumn<int>(
    'vehicle_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maintenanceRecordIdMeta =
      const VerificationMeta('maintenanceRecordId');
  @override
  late final GeneratedColumn<int> maintenanceRecordId = GeneratedColumn<int>(
    'maintenance_record_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 160,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _costSenMeta = const VerificationMeta(
    'costSen',
  );
  @override
  late final GeneratedColumn<int> costSen = GeneratedColumn<int>(
    'cost_sen',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    createdAt,
    updatedAt,
    id,
    vehicleId,
    maintenanceRecordId,
    name,
    description,
    costSen,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'maintenance_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<MaintenanceItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('vehicle_id')) {
      context.handle(
        _vehicleIdMeta,
        vehicleId.isAcceptableOrUnknown(data['vehicle_id']!, _vehicleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_vehicleIdMeta);
    }
    if (data.containsKey('maintenance_record_id')) {
      context.handle(
        _maintenanceRecordIdMeta,
        maintenanceRecordId.isAcceptableOrUnknown(
          data['maintenance_record_id']!,
          _maintenanceRecordIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_maintenanceRecordIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('cost_sen')) {
      context.handle(
        _costSenMeta,
        costSen.isAcceptableOrUnknown(data['cost_sen']!, _costSenMeta),
      );
    } else if (isInserting) {
      context.missing(_costSenMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MaintenanceItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MaintenanceItem(
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      vehicleId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}vehicle_id'],
      )!,
      maintenanceRecordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}maintenance_record_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      costSen: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cost_sen'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $MaintenanceItemsTable createAlias(String alias) {
    return $MaintenanceItemsTable(attachedDatabase, alias);
  }
}

class MaintenanceItem extends DataClass implements Insertable<MaintenanceItem> {
  final DateTime createdAt;
  final DateTime updatedAt;
  final int id;
  final int vehicleId;
  final int maintenanceRecordId;
  final String name;
  final String? description;
  final int costSen;
  final int position;
  const MaintenanceItem({
    required this.createdAt,
    required this.updatedAt,
    required this.id,
    required this.vehicleId,
    required this.maintenanceRecordId,
    required this.name,
    this.description,
    required this.costSen,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['id'] = Variable<int>(id);
    map['vehicle_id'] = Variable<int>(vehicleId);
    map['maintenance_record_id'] = Variable<int>(maintenanceRecordId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['cost_sen'] = Variable<int>(costSen);
    map['position'] = Variable<int>(position);
    return map;
  }

  MaintenanceItemsCompanion toCompanion(bool nullToAbsent) {
    return MaintenanceItemsCompanion(
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      id: Value(id),
      vehicleId: Value(vehicleId),
      maintenanceRecordId: Value(maintenanceRecordId),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      costSen: Value(costSen),
      position: Value(position),
    );
  }

  factory MaintenanceItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MaintenanceItem(
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      id: serializer.fromJson<int>(json['id']),
      vehicleId: serializer.fromJson<int>(json['vehicleId']),
      maintenanceRecordId: serializer.fromJson<int>(
        json['maintenanceRecordId'],
      ),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      costSen: serializer.fromJson<int>(json['costSen']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'id': serializer.toJson<int>(id),
      'vehicleId': serializer.toJson<int>(vehicleId),
      'maintenanceRecordId': serializer.toJson<int>(maintenanceRecordId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'costSen': serializer.toJson<int>(costSen),
      'position': serializer.toJson<int>(position),
    };
  }

  MaintenanceItem copyWith({
    DateTime? createdAt,
    DateTime? updatedAt,
    int? id,
    int? vehicleId,
    int? maintenanceRecordId,
    String? name,
    Value<String?> description = const Value.absent(),
    int? costSen,
    int? position,
  }) => MaintenanceItem(
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    id: id ?? this.id,
    vehicleId: vehicleId ?? this.vehicleId,
    maintenanceRecordId: maintenanceRecordId ?? this.maintenanceRecordId,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    costSen: costSen ?? this.costSen,
    position: position ?? this.position,
  );
  MaintenanceItem copyWithCompanion(MaintenanceItemsCompanion data) {
    return MaintenanceItem(
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      id: data.id.present ? data.id.value : this.id,
      vehicleId: data.vehicleId.present ? data.vehicleId.value : this.vehicleId,
      maintenanceRecordId: data.maintenanceRecordId.present
          ? data.maintenanceRecordId.value
          : this.maintenanceRecordId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      costSen: data.costSen.present ? data.costSen.value : this.costSen,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MaintenanceItem(')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('id: $id, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('maintenanceRecordId: $maintenanceRecordId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('costSen: $costSen, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    createdAt,
    updatedAt,
    id,
    vehicleId,
    maintenanceRecordId,
    name,
    description,
    costSen,
    position,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MaintenanceItem &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.id == this.id &&
          other.vehicleId == this.vehicleId &&
          other.maintenanceRecordId == this.maintenanceRecordId &&
          other.name == this.name &&
          other.description == this.description &&
          other.costSen == this.costSen &&
          other.position == this.position);
}

class MaintenanceItemsCompanion extends UpdateCompanion<MaintenanceItem> {
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> id;
  final Value<int> vehicleId;
  final Value<int> maintenanceRecordId;
  final Value<String> name;
  final Value<String?> description;
  final Value<int> costSen;
  final Value<int> position;
  const MaintenanceItemsCompanion({
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.vehicleId = const Value.absent(),
    this.maintenanceRecordId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.costSen = const Value.absent(),
    this.position = const Value.absent(),
  });
  MaintenanceItemsCompanion.insert({
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.id = const Value.absent(),
    required int vehicleId,
    required int maintenanceRecordId,
    required String name,
    this.description = const Value.absent(),
    required int costSen,
    this.position = const Value.absent(),
  }) : vehicleId = Value(vehicleId),
       maintenanceRecordId = Value(maintenanceRecordId),
       name = Value(name),
       costSen = Value(costSen);
  static Insertable<MaintenanceItem> custom({
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? id,
    Expression<int>? vehicleId,
    Expression<int>? maintenanceRecordId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<int>? costSen,
    Expression<int>? position,
  }) {
    return RawValuesInsertable({
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (id != null) 'id': id,
      if (vehicleId != null) 'vehicle_id': vehicleId,
      if (maintenanceRecordId != null)
        'maintenance_record_id': maintenanceRecordId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (costSen != null) 'cost_sen': costSen,
      if (position != null) 'position': position,
    });
  }

  MaintenanceItemsCompanion copyWith({
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? id,
    Value<int>? vehicleId,
    Value<int>? maintenanceRecordId,
    Value<String>? name,
    Value<String?>? description,
    Value<int>? costSen,
    Value<int>? position,
  }) {
    return MaintenanceItemsCompanion(
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      maintenanceRecordId: maintenanceRecordId ?? this.maintenanceRecordId,
      name: name ?? this.name,
      description: description ?? this.description,
      costSen: costSen ?? this.costSen,
      position: position ?? this.position,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (vehicleId.present) {
      map['vehicle_id'] = Variable<int>(vehicleId.value);
    }
    if (maintenanceRecordId.present) {
      map['maintenance_record_id'] = Variable<int>(maintenanceRecordId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (costSen.present) {
      map['cost_sen'] = Variable<int>(costSen.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MaintenanceItemsCompanion(')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('id: $id, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('maintenanceRecordId: $maintenanceRecordId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('costSen: $costSen, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }
}

class $AttachmentsTable extends Attachments
    with TableInfo<$AttachmentsTable, Attachment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _vehicleIdMeta = const VerificationMeta(
    'vehicleId',
  );
  @override
  late final GeneratedColumn<int> vehicleId = GeneratedColumn<int>(
    'vehicle_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maintenanceRecordIdMeta =
      const VerificationMeta('maintenanceRecordId');
  @override
  late final GeneratedColumn<int> maintenanceRecordId = GeneratedColumn<int>(
    'maintenance_record_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AttachmentKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AttachmentKind>($AttachmentsTable.$converterkind);
  static const VerificationMeta _originalFileNameMeta = const VerificationMeta(
    'originalFileName',
  );
  @override
  late final GeneratedColumn<String> originalFileName = GeneratedColumn<String>(
    'original_file_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relativePathMeta = const VerificationMeta(
    'relativePath',
  );
  @override
  late final GeneratedColumn<String> relativePath = GeneratedColumn<String>(
    'relative_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _byteSizeMeta = const VerificationMeta(
    'byteSize',
  );
  @override
  late final GeneratedColumn<int> byteSize = GeneratedColumn<int>(
    'byte_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    createdAt,
    updatedAt,
    id,
    vehicleId,
    maintenanceRecordId,
    kind,
    originalFileName,
    relativePath,
    mimeType,
    byteSize,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attachments';
  @override
  VerificationContext validateIntegrity(
    Insertable<Attachment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('vehicle_id')) {
      context.handle(
        _vehicleIdMeta,
        vehicleId.isAcceptableOrUnknown(data['vehicle_id']!, _vehicleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_vehicleIdMeta);
    }
    if (data.containsKey('maintenance_record_id')) {
      context.handle(
        _maintenanceRecordIdMeta,
        maintenanceRecordId.isAcceptableOrUnknown(
          data['maintenance_record_id']!,
          _maintenanceRecordIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_maintenanceRecordIdMeta);
    }
    if (data.containsKey('original_file_name')) {
      context.handle(
        _originalFileNameMeta,
        originalFileName.isAcceptableOrUnknown(
          data['original_file_name']!,
          _originalFileNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalFileNameMeta);
    }
    if (data.containsKey('relative_path')) {
      context.handle(
        _relativePathMeta,
        relativePath.isAcceptableOrUnknown(
          data['relative_path']!,
          _relativePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relativePathMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('byte_size')) {
      context.handle(
        _byteSizeMeta,
        byteSize.isAcceptableOrUnknown(data['byte_size']!, _byteSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_byteSizeMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Attachment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Attachment(
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      vehicleId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}vehicle_id'],
      )!,
      maintenanceRecordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}maintenance_record_id'],
      )!,
      kind: $AttachmentsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      originalFileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_file_name'],
      )!,
      relativePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relative_path'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      )!,
      byteSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}byte_size'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $AttachmentsTable createAlias(String alias) {
    return $AttachmentsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AttachmentKind, String, String> $converterkind =
      const EnumNameConverter<AttachmentKind>(AttachmentKind.values);
}

class Attachment extends DataClass implements Insertable<Attachment> {
  final DateTime createdAt;
  final DateTime updatedAt;
  final int id;
  final int vehicleId;
  final int maintenanceRecordId;
  final AttachmentKind kind;
  final String originalFileName;
  final String relativePath;
  final String mimeType;
  final int byteSize;
  final int position;
  const Attachment({
    required this.createdAt,
    required this.updatedAt,
    required this.id,
    required this.vehicleId,
    required this.maintenanceRecordId,
    required this.kind,
    required this.originalFileName,
    required this.relativePath,
    required this.mimeType,
    required this.byteSize,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['id'] = Variable<int>(id);
    map['vehicle_id'] = Variable<int>(vehicleId);
    map['maintenance_record_id'] = Variable<int>(maintenanceRecordId);
    {
      map['kind'] = Variable<String>(
        $AttachmentsTable.$converterkind.toSql(kind),
      );
    }
    map['original_file_name'] = Variable<String>(originalFileName);
    map['relative_path'] = Variable<String>(relativePath);
    map['mime_type'] = Variable<String>(mimeType);
    map['byte_size'] = Variable<int>(byteSize);
    map['position'] = Variable<int>(position);
    return map;
  }

  AttachmentsCompanion toCompanion(bool nullToAbsent) {
    return AttachmentsCompanion(
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      id: Value(id),
      vehicleId: Value(vehicleId),
      maintenanceRecordId: Value(maintenanceRecordId),
      kind: Value(kind),
      originalFileName: Value(originalFileName),
      relativePath: Value(relativePath),
      mimeType: Value(mimeType),
      byteSize: Value(byteSize),
      position: Value(position),
    );
  }

  factory Attachment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Attachment(
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      id: serializer.fromJson<int>(json['id']),
      vehicleId: serializer.fromJson<int>(json['vehicleId']),
      maintenanceRecordId: serializer.fromJson<int>(
        json['maintenanceRecordId'],
      ),
      kind: $AttachmentsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      originalFileName: serializer.fromJson<String>(json['originalFileName']),
      relativePath: serializer.fromJson<String>(json['relativePath']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      byteSize: serializer.fromJson<int>(json['byteSize']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'id': serializer.toJson<int>(id),
      'vehicleId': serializer.toJson<int>(vehicleId),
      'maintenanceRecordId': serializer.toJson<int>(maintenanceRecordId),
      'kind': serializer.toJson<String>(
        $AttachmentsTable.$converterkind.toJson(kind),
      ),
      'originalFileName': serializer.toJson<String>(originalFileName),
      'relativePath': serializer.toJson<String>(relativePath),
      'mimeType': serializer.toJson<String>(mimeType),
      'byteSize': serializer.toJson<int>(byteSize),
      'position': serializer.toJson<int>(position),
    };
  }

  Attachment copyWith({
    DateTime? createdAt,
    DateTime? updatedAt,
    int? id,
    int? vehicleId,
    int? maintenanceRecordId,
    AttachmentKind? kind,
    String? originalFileName,
    String? relativePath,
    String? mimeType,
    int? byteSize,
    int? position,
  }) => Attachment(
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    id: id ?? this.id,
    vehicleId: vehicleId ?? this.vehicleId,
    maintenanceRecordId: maintenanceRecordId ?? this.maintenanceRecordId,
    kind: kind ?? this.kind,
    originalFileName: originalFileName ?? this.originalFileName,
    relativePath: relativePath ?? this.relativePath,
    mimeType: mimeType ?? this.mimeType,
    byteSize: byteSize ?? this.byteSize,
    position: position ?? this.position,
  );
  Attachment copyWithCompanion(AttachmentsCompanion data) {
    return Attachment(
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      id: data.id.present ? data.id.value : this.id,
      vehicleId: data.vehicleId.present ? data.vehicleId.value : this.vehicleId,
      maintenanceRecordId: data.maintenanceRecordId.present
          ? data.maintenanceRecordId.value
          : this.maintenanceRecordId,
      kind: data.kind.present ? data.kind.value : this.kind,
      originalFileName: data.originalFileName.present
          ? data.originalFileName.value
          : this.originalFileName,
      relativePath: data.relativePath.present
          ? data.relativePath.value
          : this.relativePath,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      byteSize: data.byteSize.present ? data.byteSize.value : this.byteSize,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Attachment(')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('id: $id, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('maintenanceRecordId: $maintenanceRecordId, ')
          ..write('kind: $kind, ')
          ..write('originalFileName: $originalFileName, ')
          ..write('relativePath: $relativePath, ')
          ..write('mimeType: $mimeType, ')
          ..write('byteSize: $byteSize, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    createdAt,
    updatedAt,
    id,
    vehicleId,
    maintenanceRecordId,
    kind,
    originalFileName,
    relativePath,
    mimeType,
    byteSize,
    position,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Attachment &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.id == this.id &&
          other.vehicleId == this.vehicleId &&
          other.maintenanceRecordId == this.maintenanceRecordId &&
          other.kind == this.kind &&
          other.originalFileName == this.originalFileName &&
          other.relativePath == this.relativePath &&
          other.mimeType == this.mimeType &&
          other.byteSize == this.byteSize &&
          other.position == this.position);
}

class AttachmentsCompanion extends UpdateCompanion<Attachment> {
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> id;
  final Value<int> vehicleId;
  final Value<int> maintenanceRecordId;
  final Value<AttachmentKind> kind;
  final Value<String> originalFileName;
  final Value<String> relativePath;
  final Value<String> mimeType;
  final Value<int> byteSize;
  final Value<int> position;
  const AttachmentsCompanion({
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.vehicleId = const Value.absent(),
    this.maintenanceRecordId = const Value.absent(),
    this.kind = const Value.absent(),
    this.originalFileName = const Value.absent(),
    this.relativePath = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.byteSize = const Value.absent(),
    this.position = const Value.absent(),
  });
  AttachmentsCompanion.insert({
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.id = const Value.absent(),
    required int vehicleId,
    required int maintenanceRecordId,
    required AttachmentKind kind,
    required String originalFileName,
    required String relativePath,
    required String mimeType,
    required int byteSize,
    this.position = const Value.absent(),
  }) : vehicleId = Value(vehicleId),
       maintenanceRecordId = Value(maintenanceRecordId),
       kind = Value(kind),
       originalFileName = Value(originalFileName),
       relativePath = Value(relativePath),
       mimeType = Value(mimeType),
       byteSize = Value(byteSize);
  static Insertable<Attachment> custom({
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? id,
    Expression<int>? vehicleId,
    Expression<int>? maintenanceRecordId,
    Expression<String>? kind,
    Expression<String>? originalFileName,
    Expression<String>? relativePath,
    Expression<String>? mimeType,
    Expression<int>? byteSize,
    Expression<int>? position,
  }) {
    return RawValuesInsertable({
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (id != null) 'id': id,
      if (vehicleId != null) 'vehicle_id': vehicleId,
      if (maintenanceRecordId != null)
        'maintenance_record_id': maintenanceRecordId,
      if (kind != null) 'kind': kind,
      if (originalFileName != null) 'original_file_name': originalFileName,
      if (relativePath != null) 'relative_path': relativePath,
      if (mimeType != null) 'mime_type': mimeType,
      if (byteSize != null) 'byte_size': byteSize,
      if (position != null) 'position': position,
    });
  }

  AttachmentsCompanion copyWith({
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? id,
    Value<int>? vehicleId,
    Value<int>? maintenanceRecordId,
    Value<AttachmentKind>? kind,
    Value<String>? originalFileName,
    Value<String>? relativePath,
    Value<String>? mimeType,
    Value<int>? byteSize,
    Value<int>? position,
  }) {
    return AttachmentsCompanion(
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      maintenanceRecordId: maintenanceRecordId ?? this.maintenanceRecordId,
      kind: kind ?? this.kind,
      originalFileName: originalFileName ?? this.originalFileName,
      relativePath: relativePath ?? this.relativePath,
      mimeType: mimeType ?? this.mimeType,
      byteSize: byteSize ?? this.byteSize,
      position: position ?? this.position,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (vehicleId.present) {
      map['vehicle_id'] = Variable<int>(vehicleId.value);
    }
    if (maintenanceRecordId.present) {
      map['maintenance_record_id'] = Variable<int>(maintenanceRecordId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $AttachmentsTable.$converterkind.toSql(kind.value),
      );
    }
    if (originalFileName.present) {
      map['original_file_name'] = Variable<String>(originalFileName.value);
    }
    if (relativePath.present) {
      map['relative_path'] = Variable<String>(relativePath.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (byteSize.present) {
      map['byte_size'] = Variable<int>(byteSize.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentsCompanion(')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('id: $id, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('maintenanceRecordId: $maintenanceRecordId, ')
          ..write('kind: $kind, ')
          ..write('originalFileName: $originalFileName, ')
          ..write('relativePath: $relativePath, ')
          ..write('mimeType: $mimeType, ')
          ..write('byteSize: $byteSize, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }
}

class $ServiceRemindersTable extends ServiceReminders
    with TableInfo<$ServiceRemindersTable, ServiceReminder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ServiceRemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _vehicleIdMeta = const VerificationMeta(
    'vehicleId',
  );
  @override
  late final GeneratedColumn<int> vehicleId = GeneratedColumn<int>(
    'vehicle_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maintenanceRecordIdMeta =
      const VerificationMeta('maintenanceRecordId');
  @override
  late final GeneratedColumn<int> maintenanceRecordId = GeneratedColumn<int>(
    'maintenance_record_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetDateMeta = const VerificationMeta(
    'targetDate',
  );
  @override
  late final GeneratedColumn<DateTime> targetDate = GeneratedColumn<DateTime>(
    'target_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetOdometerKmMeta = const VerificationMeta(
    'targetOdometerKm',
  );
  @override
  late final GeneratedColumn<double> targetOdometerKm = GeneratedColumn<double>(
    'target_odometer_km',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastMileageNotificationPercentMeta =
      const VerificationMeta('lastMileageNotificationPercent');
  @override
  late final GeneratedColumn<int> lastMileageNotificationPercent =
      GeneratedColumn<int>(
        'last_mileage_notification_percent',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    createdAt,
    updatedAt,
    id,
    vehicleId,
    maintenanceRecordId,
    targetDate,
    targetOdometerKm,
    completedAt,
    lastMileageNotificationPercent,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'service_reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<ServiceReminder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('vehicle_id')) {
      context.handle(
        _vehicleIdMeta,
        vehicleId.isAcceptableOrUnknown(data['vehicle_id']!, _vehicleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_vehicleIdMeta);
    }
    if (data.containsKey('maintenance_record_id')) {
      context.handle(
        _maintenanceRecordIdMeta,
        maintenanceRecordId.isAcceptableOrUnknown(
          data['maintenance_record_id']!,
          _maintenanceRecordIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_maintenanceRecordIdMeta);
    }
    if (data.containsKey('target_date')) {
      context.handle(
        _targetDateMeta,
        targetDate.isAcceptableOrUnknown(data['target_date']!, _targetDateMeta),
      );
    }
    if (data.containsKey('target_odometer_km')) {
      context.handle(
        _targetOdometerKmMeta,
        targetOdometerKm.isAcceptableOrUnknown(
          data['target_odometer_km']!,
          _targetOdometerKmMeta,
        ),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('last_mileage_notification_percent')) {
      context.handle(
        _lastMileageNotificationPercentMeta,
        lastMileageNotificationPercent.isAcceptableOrUnknown(
          data['last_mileage_notification_percent']!,
          _lastMileageNotificationPercentMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {maintenanceRecordId},
  ];
  @override
  ServiceReminder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ServiceReminder(
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      vehicleId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}vehicle_id'],
      )!,
      maintenanceRecordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}maintenance_record_id'],
      )!,
      targetDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}target_date'],
      ),
      targetOdometerKm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_odometer_km'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      lastMileageNotificationPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_mileage_notification_percent'],
      ),
    );
  }

  @override
  $ServiceRemindersTable createAlias(String alias) {
    return $ServiceRemindersTable(attachedDatabase, alias);
  }
}

class ServiceReminder extends DataClass implements Insertable<ServiceReminder> {
  final DateTime createdAt;
  final DateTime updatedAt;
  final int id;
  final int vehicleId;
  final int maintenanceRecordId;
  final DateTime? targetDate;
  final double? targetOdometerKm;
  final DateTime? completedAt;
  final int? lastMileageNotificationPercent;
  const ServiceReminder({
    required this.createdAt,
    required this.updatedAt,
    required this.id,
    required this.vehicleId,
    required this.maintenanceRecordId,
    this.targetDate,
    this.targetOdometerKm,
    this.completedAt,
    this.lastMileageNotificationPercent,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['id'] = Variable<int>(id);
    map['vehicle_id'] = Variable<int>(vehicleId);
    map['maintenance_record_id'] = Variable<int>(maintenanceRecordId);
    if (!nullToAbsent || targetDate != null) {
      map['target_date'] = Variable<DateTime>(targetDate);
    }
    if (!nullToAbsent || targetOdometerKm != null) {
      map['target_odometer_km'] = Variable<double>(targetOdometerKm);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || lastMileageNotificationPercent != null) {
      map['last_mileage_notification_percent'] = Variable<int>(
        lastMileageNotificationPercent,
      );
    }
    return map;
  }

  ServiceRemindersCompanion toCompanion(bool nullToAbsent) {
    return ServiceRemindersCompanion(
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      id: Value(id),
      vehicleId: Value(vehicleId),
      maintenanceRecordId: Value(maintenanceRecordId),
      targetDate: targetDate == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDate),
      targetOdometerKm: targetOdometerKm == null && nullToAbsent
          ? const Value.absent()
          : Value(targetOdometerKm),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      lastMileageNotificationPercent:
          lastMileageNotificationPercent == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMileageNotificationPercent),
    );
  }

  factory ServiceReminder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ServiceReminder(
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      id: serializer.fromJson<int>(json['id']),
      vehicleId: serializer.fromJson<int>(json['vehicleId']),
      maintenanceRecordId: serializer.fromJson<int>(
        json['maintenanceRecordId'],
      ),
      targetDate: serializer.fromJson<DateTime?>(json['targetDate']),
      targetOdometerKm: serializer.fromJson<double?>(json['targetOdometerKm']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      lastMileageNotificationPercent: serializer.fromJson<int?>(
        json['lastMileageNotificationPercent'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'id': serializer.toJson<int>(id),
      'vehicleId': serializer.toJson<int>(vehicleId),
      'maintenanceRecordId': serializer.toJson<int>(maintenanceRecordId),
      'targetDate': serializer.toJson<DateTime?>(targetDate),
      'targetOdometerKm': serializer.toJson<double?>(targetOdometerKm),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'lastMileageNotificationPercent': serializer.toJson<int?>(
        lastMileageNotificationPercent,
      ),
    };
  }

  ServiceReminder copyWith({
    DateTime? createdAt,
    DateTime? updatedAt,
    int? id,
    int? vehicleId,
    int? maintenanceRecordId,
    Value<DateTime?> targetDate = const Value.absent(),
    Value<double?> targetOdometerKm = const Value.absent(),
    Value<DateTime?> completedAt = const Value.absent(),
    Value<int?> lastMileageNotificationPercent = const Value.absent(),
  }) => ServiceReminder(
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    id: id ?? this.id,
    vehicleId: vehicleId ?? this.vehicleId,
    maintenanceRecordId: maintenanceRecordId ?? this.maintenanceRecordId,
    targetDate: targetDate.present ? targetDate.value : this.targetDate,
    targetOdometerKm: targetOdometerKm.present
        ? targetOdometerKm.value
        : this.targetOdometerKm,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    lastMileageNotificationPercent: lastMileageNotificationPercent.present
        ? lastMileageNotificationPercent.value
        : this.lastMileageNotificationPercent,
  );
  ServiceReminder copyWithCompanion(ServiceRemindersCompanion data) {
    return ServiceReminder(
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      id: data.id.present ? data.id.value : this.id,
      vehicleId: data.vehicleId.present ? data.vehicleId.value : this.vehicleId,
      maintenanceRecordId: data.maintenanceRecordId.present
          ? data.maintenanceRecordId.value
          : this.maintenanceRecordId,
      targetDate: data.targetDate.present
          ? data.targetDate.value
          : this.targetDate,
      targetOdometerKm: data.targetOdometerKm.present
          ? data.targetOdometerKm.value
          : this.targetOdometerKm,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      lastMileageNotificationPercent:
          data.lastMileageNotificationPercent.present
          ? data.lastMileageNotificationPercent.value
          : this.lastMileageNotificationPercent,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ServiceReminder(')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('id: $id, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('maintenanceRecordId: $maintenanceRecordId, ')
          ..write('targetDate: $targetDate, ')
          ..write('targetOdometerKm: $targetOdometerKm, ')
          ..write('completedAt: $completedAt, ')
          ..write(
            'lastMileageNotificationPercent: $lastMileageNotificationPercent',
          )
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    createdAt,
    updatedAt,
    id,
    vehicleId,
    maintenanceRecordId,
    targetDate,
    targetOdometerKm,
    completedAt,
    lastMileageNotificationPercent,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ServiceReminder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.id == this.id &&
          other.vehicleId == this.vehicleId &&
          other.maintenanceRecordId == this.maintenanceRecordId &&
          other.targetDate == this.targetDate &&
          other.targetOdometerKm == this.targetOdometerKm &&
          other.completedAt == this.completedAt &&
          other.lastMileageNotificationPercent ==
              this.lastMileageNotificationPercent);
}

class ServiceRemindersCompanion extends UpdateCompanion<ServiceReminder> {
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> id;
  final Value<int> vehicleId;
  final Value<int> maintenanceRecordId;
  final Value<DateTime?> targetDate;
  final Value<double?> targetOdometerKm;
  final Value<DateTime?> completedAt;
  final Value<int?> lastMileageNotificationPercent;
  const ServiceRemindersCompanion({
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.vehicleId = const Value.absent(),
    this.maintenanceRecordId = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.targetOdometerKm = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.lastMileageNotificationPercent = const Value.absent(),
  });
  ServiceRemindersCompanion.insert({
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.id = const Value.absent(),
    required int vehicleId,
    required int maintenanceRecordId,
    this.targetDate = const Value.absent(),
    this.targetOdometerKm = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.lastMileageNotificationPercent = const Value.absent(),
  }) : vehicleId = Value(vehicleId),
       maintenanceRecordId = Value(maintenanceRecordId);
  static Insertable<ServiceReminder> custom({
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? id,
    Expression<int>? vehicleId,
    Expression<int>? maintenanceRecordId,
    Expression<DateTime>? targetDate,
    Expression<double>? targetOdometerKm,
    Expression<DateTime>? completedAt,
    Expression<int>? lastMileageNotificationPercent,
  }) {
    return RawValuesInsertable({
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (id != null) 'id': id,
      if (vehicleId != null) 'vehicle_id': vehicleId,
      if (maintenanceRecordId != null)
        'maintenance_record_id': maintenanceRecordId,
      if (targetDate != null) 'target_date': targetDate,
      if (targetOdometerKm != null) 'target_odometer_km': targetOdometerKm,
      if (completedAt != null) 'completed_at': completedAt,
      if (lastMileageNotificationPercent != null)
        'last_mileage_notification_percent': lastMileageNotificationPercent,
    });
  }

  ServiceRemindersCompanion copyWith({
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? id,
    Value<int>? vehicleId,
    Value<int>? maintenanceRecordId,
    Value<DateTime?>? targetDate,
    Value<double?>? targetOdometerKm,
    Value<DateTime?>? completedAt,
    Value<int?>? lastMileageNotificationPercent,
  }) {
    return ServiceRemindersCompanion(
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      maintenanceRecordId: maintenanceRecordId ?? this.maintenanceRecordId,
      targetDate: targetDate ?? this.targetDate,
      targetOdometerKm: targetOdometerKm ?? this.targetOdometerKm,
      completedAt: completedAt ?? this.completedAt,
      lastMileageNotificationPercent:
          lastMileageNotificationPercent ?? this.lastMileageNotificationPercent,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (vehicleId.present) {
      map['vehicle_id'] = Variable<int>(vehicleId.value);
    }
    if (maintenanceRecordId.present) {
      map['maintenance_record_id'] = Variable<int>(maintenanceRecordId.value);
    }
    if (targetDate.present) {
      map['target_date'] = Variable<DateTime>(targetDate.value);
    }
    if (targetOdometerKm.present) {
      map['target_odometer_km'] = Variable<double>(targetOdometerKm.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (lastMileageNotificationPercent.present) {
      map['last_mileage_notification_percent'] = Variable<int>(
        lastMileageNotificationPercent.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ServiceRemindersCompanion(')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('id: $id, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('maintenanceRecordId: $maintenanceRecordId, ')
          ..write('targetDate: $targetDate, ')
          ..write('targetOdometerKm: $targetOdometerKm, ')
          ..write('completedAt: $completedAt, ')
          ..write(
            'lastMileageNotificationPercent: $lastMileageNotificationPercent',
          )
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  late final $VehiclesTable vehicles = $VehiclesTable(this);
  late final $FuelEventsTable fuelEvents = $FuelEventsTable(this);
  late final $MaintenanceRecordsTable maintenanceRecords =
      $MaintenanceRecordsTable(this);
  late final $MaintenanceItemsTable maintenanceItems = $MaintenanceItemsTable(
    this,
  );
  late final $AttachmentsTable attachments = $AttachmentsTable(this);
  late final $ServiceRemindersTable serviceReminders = $ServiceRemindersTable(
    this,
  );
  late final Index fuelEventsVehicleOccurredAt = Index(
    'fuel_events_vehicle_occurred_at',
    'CREATE INDEX fuel_events_vehicle_occurred_at ON fuel_events (vehicle_id, occurred_at)',
  );
  late final Index maintenanceRecordsVehicleOccurredAt = Index(
    'maintenance_records_vehicle_occurred_at',
    'CREATE INDEX maintenance_records_vehicle_occurred_at ON maintenance_records (vehicle_id, occurred_at)',
  );
  late final Index maintenanceItemsRecord = Index(
    'maintenance_items_record',
    'CREATE INDEX maintenance_items_record ON maintenance_items (maintenance_record_id, position)',
  );
  late final Index attachmentsRecord = Index(
    'attachments_record',
    'CREATE INDEX attachments_record ON attachments (maintenance_record_id, position)',
  );
  late final Index serviceRemindersVehicle = Index(
    'service_reminders_vehicle',
    'CREATE INDEX service_reminders_vehicle ON service_reminders (vehicle_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    vehicles,
    fuelEvents,
    maintenanceRecords,
    maintenanceItems,
    attachments,
    serviceReminders,
    fuelEventsVehicleOccurredAt,
    maintenanceRecordsVehicleOccurredAt,
    maintenanceItemsRecord,
    attachmentsRecord,
    serviceRemindersVehicle,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'vehicles',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('fuel_events', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'vehicles',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('maintenance_records', kind: UpdateKind.update)],
    ),
  ]);
}
