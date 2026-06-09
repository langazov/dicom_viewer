// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drift_database.dart';

// ignore_for_file: type=lint
class $PatientsTable extends Patients with TableInfo<$PatientsTable, Patient> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PatientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, displayName];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'patients';
  @override
  VerificationContext validateIntegrity(
    Insertable<Patient> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Patient map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Patient(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
    );
  }

  @override
  $PatientsTable createAlias(String alias) {
    return $PatientsTable(attachedDatabase, alias);
  }
}

class Patient extends DataClass implements Insertable<Patient> {
  final String id;
  final String displayName;
  const Patient({required this.id, required this.displayName});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['display_name'] = Variable<String>(displayName);
    return map;
  }

  PatientsCompanion toCompanion(bool nullToAbsent) {
    return PatientsCompanion(id: Value(id), displayName: Value(displayName));
  }

  factory Patient.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Patient(
      id: serializer.fromJson<String>(json['id']),
      displayName: serializer.fromJson<String>(json['displayName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'displayName': serializer.toJson<String>(displayName),
    };
  }

  Patient copyWith({String? id, String? displayName}) =>
      Patient(id: id ?? this.id, displayName: displayName ?? this.displayName);
  Patient copyWithCompanion(PatientsCompanion data) {
    return Patient(
      id: data.id.present ? data.id.value : this.id,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Patient(')
          ..write('id: $id, ')
          ..write('displayName: $displayName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, displayName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Patient &&
          other.id == this.id &&
          other.displayName == this.displayName);
}

class PatientsCompanion extends UpdateCompanion<Patient> {
  final Value<String> id;
  final Value<String> displayName;
  final Value<int> rowid;
  const PatientsCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PatientsCompanion.insert({
    required String id,
    required String displayName,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       displayName = Value(displayName);
  static Insertable<Patient> custom({
    Expression<String>? id,
    Expression<String>? displayName,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PatientsCompanion copyWith({
    Value<String>? id,
    Value<String>? displayName,
    Value<int>? rowid,
  }) {
    return PatientsCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PatientsCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StudiesTable extends Studies with TableInfo<$StudiesTable, Study> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StudiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _instanceUidMeta = const VerificationMeta(
    'instanceUid',
  );
  @override
  late final GeneratedColumn<String> instanceUid = GeneratedColumn<String>(
    'instance_uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _patientIdMeta = const VerificationMeta(
    'patientId',
  );
  @override
  late final GeneratedColumn<String> patientId = GeneratedColumn<String>(
    'patient_id',
    aliasedName,
    false,
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
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _studyDateMeta = const VerificationMeta(
    'studyDate',
  );
  @override
  late final GeneratedColumn<DateTime> studyDate = GeneratedColumn<DateTime>(
    'study_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    instanceUid,
    patientId,
    description,
    studyDate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'studies';
  @override
  VerificationContext validateIntegrity(
    Insertable<Study> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('instance_uid')) {
      context.handle(
        _instanceUidMeta,
        instanceUid.isAcceptableOrUnknown(
          data['instance_uid']!,
          _instanceUidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_instanceUidMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
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
    if (data.containsKey('study_date')) {
      context.handle(
        _studyDateMeta,
        studyDate.isAcceptableOrUnknown(data['study_date']!, _studyDateMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {instanceUid};
  @override
  Study map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Study(
      instanceUid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instance_uid'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      studyDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}study_date'],
      ),
    );
  }

  @override
  $StudiesTable createAlias(String alias) {
    return $StudiesTable(attachedDatabase, alias);
  }
}

class Study extends DataClass implements Insertable<Study> {
  final String instanceUid;
  final String patientId;
  final String description;
  final DateTime? studyDate;
  const Study({
    required this.instanceUid,
    required this.patientId,
    required this.description,
    this.studyDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['instance_uid'] = Variable<String>(instanceUid);
    map['patient_id'] = Variable<String>(patientId);
    map['description'] = Variable<String>(description);
    if (!nullToAbsent || studyDate != null) {
      map['study_date'] = Variable<DateTime>(studyDate);
    }
    return map;
  }

  StudiesCompanion toCompanion(bool nullToAbsent) {
    return StudiesCompanion(
      instanceUid: Value(instanceUid),
      patientId: Value(patientId),
      description: Value(description),
      studyDate: studyDate == null && nullToAbsent
          ? const Value.absent()
          : Value(studyDate),
    );
  }

  factory Study.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Study(
      instanceUid: serializer.fromJson<String>(json['instanceUid']),
      patientId: serializer.fromJson<String>(json['patientId']),
      description: serializer.fromJson<String>(json['description']),
      studyDate: serializer.fromJson<DateTime?>(json['studyDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'instanceUid': serializer.toJson<String>(instanceUid),
      'patientId': serializer.toJson<String>(patientId),
      'description': serializer.toJson<String>(description),
      'studyDate': serializer.toJson<DateTime?>(studyDate),
    };
  }

  Study copyWith({
    String? instanceUid,
    String? patientId,
    String? description,
    Value<DateTime?> studyDate = const Value.absent(),
  }) => Study(
    instanceUid: instanceUid ?? this.instanceUid,
    patientId: patientId ?? this.patientId,
    description: description ?? this.description,
    studyDate: studyDate.present ? studyDate.value : this.studyDate,
  );
  Study copyWithCompanion(StudiesCompanion data) {
    return Study(
      instanceUid: data.instanceUid.present
          ? data.instanceUid.value
          : this.instanceUid,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      description: data.description.present
          ? data.description.value
          : this.description,
      studyDate: data.studyDate.present ? data.studyDate.value : this.studyDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Study(')
          ..write('instanceUid: $instanceUid, ')
          ..write('patientId: $patientId, ')
          ..write('description: $description, ')
          ..write('studyDate: $studyDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(instanceUid, patientId, description, studyDate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Study &&
          other.instanceUid == this.instanceUid &&
          other.patientId == this.patientId &&
          other.description == this.description &&
          other.studyDate == this.studyDate);
}

class StudiesCompanion extends UpdateCompanion<Study> {
  final Value<String> instanceUid;
  final Value<String> patientId;
  final Value<String> description;
  final Value<DateTime?> studyDate;
  final Value<int> rowid;
  const StudiesCompanion({
    this.instanceUid = const Value.absent(),
    this.patientId = const Value.absent(),
    this.description = const Value.absent(),
    this.studyDate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StudiesCompanion.insert({
    required String instanceUid,
    required String patientId,
    this.description = const Value.absent(),
    this.studyDate = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : instanceUid = Value(instanceUid),
       patientId = Value(patientId);
  static Insertable<Study> custom({
    Expression<String>? instanceUid,
    Expression<String>? patientId,
    Expression<String>? description,
    Expression<DateTime>? studyDate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (instanceUid != null) 'instance_uid': instanceUid,
      if (patientId != null) 'patient_id': patientId,
      if (description != null) 'description': description,
      if (studyDate != null) 'study_date': studyDate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StudiesCompanion copyWith({
    Value<String>? instanceUid,
    Value<String>? patientId,
    Value<String>? description,
    Value<DateTime?>? studyDate,
    Value<int>? rowid,
  }) {
    return StudiesCompanion(
      instanceUid: instanceUid ?? this.instanceUid,
      patientId: patientId ?? this.patientId,
      description: description ?? this.description,
      studyDate: studyDate ?? this.studyDate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (instanceUid.present) {
      map['instance_uid'] = Variable<String>(instanceUid.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (studyDate.present) {
      map['study_date'] = Variable<DateTime>(studyDate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StudiesCompanion(')
          ..write('instanceUid: $instanceUid, ')
          ..write('patientId: $patientId, ')
          ..write('description: $description, ')
          ..write('studyDate: $studyDate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SeriesTableTable extends SeriesTable
    with TableInfo<$SeriesTableTable, SeriesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SeriesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _instanceUidMeta = const VerificationMeta(
    'instanceUid',
  );
  @override
  late final GeneratedColumn<String> instanceUid = GeneratedColumn<String>(
    'instance_uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _studyInstanceUidMeta = const VerificationMeta(
    'studyInstanceUid',
  );
  @override
  late final GeneratedColumn<String> studyInstanceUid = GeneratedColumn<String>(
    'study_instance_uid',
    aliasedName,
    false,
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
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _modalityMeta = const VerificationMeta(
    'modality',
  );
  @override
  late final GeneratedColumn<String> modality = GeneratedColumn<String>(
    'modality',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    instanceUid,
    studyInstanceUid,
    description,
    modality,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'series_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<SeriesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('instance_uid')) {
      context.handle(
        _instanceUidMeta,
        instanceUid.isAcceptableOrUnknown(
          data['instance_uid']!,
          _instanceUidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_instanceUidMeta);
    }
    if (data.containsKey('study_instance_uid')) {
      context.handle(
        _studyInstanceUidMeta,
        studyInstanceUid.isAcceptableOrUnknown(
          data['study_instance_uid']!,
          _studyInstanceUidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_studyInstanceUidMeta);
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
    if (data.containsKey('modality')) {
      context.handle(
        _modalityMeta,
        modality.isAcceptableOrUnknown(data['modality']!, _modalityMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {instanceUid};
  @override
  SeriesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SeriesTableData(
      instanceUid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instance_uid'],
      )!,
      studyInstanceUid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}study_instance_uid'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      modality: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}modality'],
      )!,
    );
  }

  @override
  $SeriesTableTable createAlias(String alias) {
    return $SeriesTableTable(attachedDatabase, alias);
  }
}

class SeriesTableData extends DataClass implements Insertable<SeriesTableData> {
  final String instanceUid;
  final String studyInstanceUid;
  final String description;
  final String modality;
  const SeriesTableData({
    required this.instanceUid,
    required this.studyInstanceUid,
    required this.description,
    required this.modality,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['instance_uid'] = Variable<String>(instanceUid);
    map['study_instance_uid'] = Variable<String>(studyInstanceUid);
    map['description'] = Variable<String>(description);
    map['modality'] = Variable<String>(modality);
    return map;
  }

  SeriesTableCompanion toCompanion(bool nullToAbsent) {
    return SeriesTableCompanion(
      instanceUid: Value(instanceUid),
      studyInstanceUid: Value(studyInstanceUid),
      description: Value(description),
      modality: Value(modality),
    );
  }

  factory SeriesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SeriesTableData(
      instanceUid: serializer.fromJson<String>(json['instanceUid']),
      studyInstanceUid: serializer.fromJson<String>(json['studyInstanceUid']),
      description: serializer.fromJson<String>(json['description']),
      modality: serializer.fromJson<String>(json['modality']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'instanceUid': serializer.toJson<String>(instanceUid),
      'studyInstanceUid': serializer.toJson<String>(studyInstanceUid),
      'description': serializer.toJson<String>(description),
      'modality': serializer.toJson<String>(modality),
    };
  }

  SeriesTableData copyWith({
    String? instanceUid,
    String? studyInstanceUid,
    String? description,
    String? modality,
  }) => SeriesTableData(
    instanceUid: instanceUid ?? this.instanceUid,
    studyInstanceUid: studyInstanceUid ?? this.studyInstanceUid,
    description: description ?? this.description,
    modality: modality ?? this.modality,
  );
  SeriesTableData copyWithCompanion(SeriesTableCompanion data) {
    return SeriesTableData(
      instanceUid: data.instanceUid.present
          ? data.instanceUid.value
          : this.instanceUid,
      studyInstanceUid: data.studyInstanceUid.present
          ? data.studyInstanceUid.value
          : this.studyInstanceUid,
      description: data.description.present
          ? data.description.value
          : this.description,
      modality: data.modality.present ? data.modality.value : this.modality,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SeriesTableData(')
          ..write('instanceUid: $instanceUid, ')
          ..write('studyInstanceUid: $studyInstanceUid, ')
          ..write('description: $description, ')
          ..write('modality: $modality')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(instanceUid, studyInstanceUid, description, modality);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SeriesTableData &&
          other.instanceUid == this.instanceUid &&
          other.studyInstanceUid == this.studyInstanceUid &&
          other.description == this.description &&
          other.modality == this.modality);
}

class SeriesTableCompanion extends UpdateCompanion<SeriesTableData> {
  final Value<String> instanceUid;
  final Value<String> studyInstanceUid;
  final Value<String> description;
  final Value<String> modality;
  final Value<int> rowid;
  const SeriesTableCompanion({
    this.instanceUid = const Value.absent(),
    this.studyInstanceUid = const Value.absent(),
    this.description = const Value.absent(),
    this.modality = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SeriesTableCompanion.insert({
    required String instanceUid,
    required String studyInstanceUid,
    this.description = const Value.absent(),
    this.modality = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : instanceUid = Value(instanceUid),
       studyInstanceUid = Value(studyInstanceUid);
  static Insertable<SeriesTableData> custom({
    Expression<String>? instanceUid,
    Expression<String>? studyInstanceUid,
    Expression<String>? description,
    Expression<String>? modality,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (instanceUid != null) 'instance_uid': instanceUid,
      if (studyInstanceUid != null) 'study_instance_uid': studyInstanceUid,
      if (description != null) 'description': description,
      if (modality != null) 'modality': modality,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SeriesTableCompanion copyWith({
    Value<String>? instanceUid,
    Value<String>? studyInstanceUid,
    Value<String>? description,
    Value<String>? modality,
    Value<int>? rowid,
  }) {
    return SeriesTableCompanion(
      instanceUid: instanceUid ?? this.instanceUid,
      studyInstanceUid: studyInstanceUid ?? this.studyInstanceUid,
      description: description ?? this.description,
      modality: modality ?? this.modality,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (instanceUid.present) {
      map['instance_uid'] = Variable<String>(instanceUid.value);
    }
    if (studyInstanceUid.present) {
      map['study_instance_uid'] = Variable<String>(studyInstanceUid.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (modality.present) {
      map['modality'] = Variable<String>(modality.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SeriesTableCompanion(')
          ..write('instanceUid: $instanceUid, ')
          ..write('studyInstanceUid: $studyInstanceUid, ')
          ..write('description: $description, ')
          ..write('modality: $modality, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InstancesTable extends Instances
    with TableInfo<$InstancesTable, Instance> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InstancesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _studyInstanceUidMeta = const VerificationMeta(
    'studyInstanceUid',
  );
  @override
  late final GeneratedColumn<String> studyInstanceUid = GeneratedColumn<String>(
    'study_instance_uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seriesInstanceUidMeta = const VerificationMeta(
    'seriesInstanceUid',
  );
  @override
  late final GeneratedColumn<String> seriesInstanceUid =
      GeneratedColumn<String>(
        'series_instance_uid',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _sopInstanceUidMeta = const VerificationMeta(
    'sopInstanceUid',
  );
  @override
  late final GeneratedColumn<String> sopInstanceUid = GeneratedColumn<String>(
    'sop_instance_uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _instanceNumberMeta = const VerificationMeta(
    'instanceNumber',
  );
  @override
  late final GeneratedColumn<int> instanceNumber = GeneratedColumn<int>(
    'instance_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transferSyntaxUidMeta = const VerificationMeta(
    'transferSyntaxUid',
  );
  @override
  late final GeneratedColumn<String> transferSyntaxUid =
      GeneratedColumn<String>(
        'transfer_syntax_uid',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _pixelDataMeta = const VerificationMeta(
    'pixelData',
  );
  @override
  late final GeneratedColumn<Uint8List> pixelData = GeneratedColumn<Uint8List>(
    'pixel_data',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    studyInstanceUid,
    seriesInstanceUid,
    sopInstanceUid,
    instanceNumber,
    filePath,
    transferSyntaxUid,
    pixelData,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'instances';
  @override
  VerificationContext validateIntegrity(
    Insertable<Instance> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('study_instance_uid')) {
      context.handle(
        _studyInstanceUidMeta,
        studyInstanceUid.isAcceptableOrUnknown(
          data['study_instance_uid']!,
          _studyInstanceUidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_studyInstanceUidMeta);
    }
    if (data.containsKey('series_instance_uid')) {
      context.handle(
        _seriesInstanceUidMeta,
        seriesInstanceUid.isAcceptableOrUnknown(
          data['series_instance_uid']!,
          _seriesInstanceUidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_seriesInstanceUidMeta);
    }
    if (data.containsKey('sop_instance_uid')) {
      context.handle(
        _sopInstanceUidMeta,
        sopInstanceUid.isAcceptableOrUnknown(
          data['sop_instance_uid']!,
          _sopInstanceUidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sopInstanceUidMeta);
    }
    if (data.containsKey('instance_number')) {
      context.handle(
        _instanceNumberMeta,
        instanceNumber.isAcceptableOrUnknown(
          data['instance_number']!,
          _instanceNumberMeta,
        ),
      );
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('transfer_syntax_uid')) {
      context.handle(
        _transferSyntaxUidMeta,
        transferSyntaxUid.isAcceptableOrUnknown(
          data['transfer_syntax_uid']!,
          _transferSyntaxUidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transferSyntaxUidMeta);
    }
    if (data.containsKey('pixel_data')) {
      context.handle(
        _pixelDataMeta,
        pixelData.isAcceptableOrUnknown(data['pixel_data']!, _pixelDataMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Instance map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Instance(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      studyInstanceUid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}study_instance_uid'],
      )!,
      seriesInstanceUid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series_instance_uid'],
      )!,
      sopInstanceUid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sop_instance_uid'],
      )!,
      instanceNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}instance_number'],
      ),
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      transferSyntaxUid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transfer_syntax_uid'],
      )!,
      pixelData: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}pixel_data'],
      ),
    );
  }

  @override
  $InstancesTable createAlias(String alias) {
    return $InstancesTable(attachedDatabase, alias);
  }
}

class Instance extends DataClass implements Insertable<Instance> {
  final int id;
  final String studyInstanceUid;
  final String seriesInstanceUid;
  final String sopInstanceUid;
  final int? instanceNumber;
  final String filePath;
  final String transferSyntaxUid;
  final Uint8List? pixelData;
  const Instance({
    required this.id,
    required this.studyInstanceUid,
    required this.seriesInstanceUid,
    required this.sopInstanceUid,
    this.instanceNumber,
    required this.filePath,
    required this.transferSyntaxUid,
    this.pixelData,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['study_instance_uid'] = Variable<String>(studyInstanceUid);
    map['series_instance_uid'] = Variable<String>(seriesInstanceUid);
    map['sop_instance_uid'] = Variable<String>(sopInstanceUid);
    if (!nullToAbsent || instanceNumber != null) {
      map['instance_number'] = Variable<int>(instanceNumber);
    }
    map['file_path'] = Variable<String>(filePath);
    map['transfer_syntax_uid'] = Variable<String>(transferSyntaxUid);
    if (!nullToAbsent || pixelData != null) {
      map['pixel_data'] = Variable<Uint8List>(pixelData);
    }
    return map;
  }

  InstancesCompanion toCompanion(bool nullToAbsent) {
    return InstancesCompanion(
      id: Value(id),
      studyInstanceUid: Value(studyInstanceUid),
      seriesInstanceUid: Value(seriesInstanceUid),
      sopInstanceUid: Value(sopInstanceUid),
      instanceNumber: instanceNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(instanceNumber),
      filePath: Value(filePath),
      transferSyntaxUid: Value(transferSyntaxUid),
      pixelData: pixelData == null && nullToAbsent
          ? const Value.absent()
          : Value(pixelData),
    );
  }

  factory Instance.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Instance(
      id: serializer.fromJson<int>(json['id']),
      studyInstanceUid: serializer.fromJson<String>(json['studyInstanceUid']),
      seriesInstanceUid: serializer.fromJson<String>(json['seriesInstanceUid']),
      sopInstanceUid: serializer.fromJson<String>(json['sopInstanceUid']),
      instanceNumber: serializer.fromJson<int?>(json['instanceNumber']),
      filePath: serializer.fromJson<String>(json['filePath']),
      transferSyntaxUid: serializer.fromJson<String>(json['transferSyntaxUid']),
      pixelData: serializer.fromJson<Uint8List?>(json['pixelData']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'studyInstanceUid': serializer.toJson<String>(studyInstanceUid),
      'seriesInstanceUid': serializer.toJson<String>(seriesInstanceUid),
      'sopInstanceUid': serializer.toJson<String>(sopInstanceUid),
      'instanceNumber': serializer.toJson<int?>(instanceNumber),
      'filePath': serializer.toJson<String>(filePath),
      'transferSyntaxUid': serializer.toJson<String>(transferSyntaxUid),
      'pixelData': serializer.toJson<Uint8List?>(pixelData),
    };
  }

  Instance copyWith({
    int? id,
    String? studyInstanceUid,
    String? seriesInstanceUid,
    String? sopInstanceUid,
    Value<int?> instanceNumber = const Value.absent(),
    String? filePath,
    String? transferSyntaxUid,
    Value<Uint8List?> pixelData = const Value.absent(),
  }) => Instance(
    id: id ?? this.id,
    studyInstanceUid: studyInstanceUid ?? this.studyInstanceUid,
    seriesInstanceUid: seriesInstanceUid ?? this.seriesInstanceUid,
    sopInstanceUid: sopInstanceUid ?? this.sopInstanceUid,
    instanceNumber: instanceNumber.present
        ? instanceNumber.value
        : this.instanceNumber,
    filePath: filePath ?? this.filePath,
    transferSyntaxUid: transferSyntaxUid ?? this.transferSyntaxUid,
    pixelData: pixelData.present ? pixelData.value : this.pixelData,
  );
  Instance copyWithCompanion(InstancesCompanion data) {
    return Instance(
      id: data.id.present ? data.id.value : this.id,
      studyInstanceUid: data.studyInstanceUid.present
          ? data.studyInstanceUid.value
          : this.studyInstanceUid,
      seriesInstanceUid: data.seriesInstanceUid.present
          ? data.seriesInstanceUid.value
          : this.seriesInstanceUid,
      sopInstanceUid: data.sopInstanceUid.present
          ? data.sopInstanceUid.value
          : this.sopInstanceUid,
      instanceNumber: data.instanceNumber.present
          ? data.instanceNumber.value
          : this.instanceNumber,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      transferSyntaxUid: data.transferSyntaxUid.present
          ? data.transferSyntaxUid.value
          : this.transferSyntaxUid,
      pixelData: data.pixelData.present ? data.pixelData.value : this.pixelData,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Instance(')
          ..write('id: $id, ')
          ..write('studyInstanceUid: $studyInstanceUid, ')
          ..write('seriesInstanceUid: $seriesInstanceUid, ')
          ..write('sopInstanceUid: $sopInstanceUid, ')
          ..write('instanceNumber: $instanceNumber, ')
          ..write('filePath: $filePath, ')
          ..write('transferSyntaxUid: $transferSyntaxUid, ')
          ..write('pixelData: $pixelData')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    studyInstanceUid,
    seriesInstanceUid,
    sopInstanceUid,
    instanceNumber,
    filePath,
    transferSyntaxUid,
    $driftBlobEquality.hash(pixelData),
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Instance &&
          other.id == this.id &&
          other.studyInstanceUid == this.studyInstanceUid &&
          other.seriesInstanceUid == this.seriesInstanceUid &&
          other.sopInstanceUid == this.sopInstanceUid &&
          other.instanceNumber == this.instanceNumber &&
          other.filePath == this.filePath &&
          other.transferSyntaxUid == this.transferSyntaxUid &&
          $driftBlobEquality.equals(other.pixelData, this.pixelData));
}

class InstancesCompanion extends UpdateCompanion<Instance> {
  final Value<int> id;
  final Value<String> studyInstanceUid;
  final Value<String> seriesInstanceUid;
  final Value<String> sopInstanceUid;
  final Value<int?> instanceNumber;
  final Value<String> filePath;
  final Value<String> transferSyntaxUid;
  final Value<Uint8List?> pixelData;
  const InstancesCompanion({
    this.id = const Value.absent(),
    this.studyInstanceUid = const Value.absent(),
    this.seriesInstanceUid = const Value.absent(),
    this.sopInstanceUid = const Value.absent(),
    this.instanceNumber = const Value.absent(),
    this.filePath = const Value.absent(),
    this.transferSyntaxUid = const Value.absent(),
    this.pixelData = const Value.absent(),
  });
  InstancesCompanion.insert({
    this.id = const Value.absent(),
    required String studyInstanceUid,
    required String seriesInstanceUid,
    required String sopInstanceUid,
    this.instanceNumber = const Value.absent(),
    required String filePath,
    required String transferSyntaxUid,
    this.pixelData = const Value.absent(),
  }) : studyInstanceUid = Value(studyInstanceUid),
       seriesInstanceUid = Value(seriesInstanceUid),
       sopInstanceUid = Value(sopInstanceUid),
       filePath = Value(filePath),
       transferSyntaxUid = Value(transferSyntaxUid);
  static Insertable<Instance> custom({
    Expression<int>? id,
    Expression<String>? studyInstanceUid,
    Expression<String>? seriesInstanceUid,
    Expression<String>? sopInstanceUid,
    Expression<int>? instanceNumber,
    Expression<String>? filePath,
    Expression<String>? transferSyntaxUid,
    Expression<Uint8List>? pixelData,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (studyInstanceUid != null) 'study_instance_uid': studyInstanceUid,
      if (seriesInstanceUid != null) 'series_instance_uid': seriesInstanceUid,
      if (sopInstanceUid != null) 'sop_instance_uid': sopInstanceUid,
      if (instanceNumber != null) 'instance_number': instanceNumber,
      if (filePath != null) 'file_path': filePath,
      if (transferSyntaxUid != null) 'transfer_syntax_uid': transferSyntaxUid,
      if (pixelData != null) 'pixel_data': pixelData,
    });
  }

  InstancesCompanion copyWith({
    Value<int>? id,
    Value<String>? studyInstanceUid,
    Value<String>? seriesInstanceUid,
    Value<String>? sopInstanceUid,
    Value<int?>? instanceNumber,
    Value<String>? filePath,
    Value<String>? transferSyntaxUid,
    Value<Uint8List?>? pixelData,
  }) {
    return InstancesCompanion(
      id: id ?? this.id,
      studyInstanceUid: studyInstanceUid ?? this.studyInstanceUid,
      seriesInstanceUid: seriesInstanceUid ?? this.seriesInstanceUid,
      sopInstanceUid: sopInstanceUid ?? this.sopInstanceUid,
      instanceNumber: instanceNumber ?? this.instanceNumber,
      filePath: filePath ?? this.filePath,
      transferSyntaxUid: transferSyntaxUid ?? this.transferSyntaxUid,
      pixelData: pixelData ?? this.pixelData,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (studyInstanceUid.present) {
      map['study_instance_uid'] = Variable<String>(studyInstanceUid.value);
    }
    if (seriesInstanceUid.present) {
      map['series_instance_uid'] = Variable<String>(seriesInstanceUid.value);
    }
    if (sopInstanceUid.present) {
      map['sop_instance_uid'] = Variable<String>(sopInstanceUid.value);
    }
    if (instanceNumber.present) {
      map['instance_number'] = Variable<int>(instanceNumber.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (transferSyntaxUid.present) {
      map['transfer_syntax_uid'] = Variable<String>(transferSyntaxUid.value);
    }
    if (pixelData.present) {
      map['pixel_data'] = Variable<Uint8List>(pixelData.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InstancesCompanion(')
          ..write('id: $id, ')
          ..write('studyInstanceUid: $studyInstanceUid, ')
          ..write('seriesInstanceUid: $seriesInstanceUid, ')
          ..write('sopInstanceUid: $sopInstanceUid, ')
          ..write('instanceNumber: $instanceNumber, ')
          ..write('filePath: $filePath, ')
          ..write('transferSyntaxUid: $transferSyntaxUid, ')
          ..write('pixelData: $pixelData')
          ..write(')'))
        .toString();
  }
}

class $AnnotationsTable extends Annotations
    with TableInfo<$AnnotationsTable, Annotation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnnotationsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _seriesInstanceUidMeta = const VerificationMeta(
    'seriesInstanceUid',
  );
  @override
  late final GeneratedColumn<String> seriesInstanceUid =
      GeneratedColumn<String>(
        'series_instance_uid',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    seriesInstanceUid,
    kind,
    payload,
    label,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'annotations';
  @override
  VerificationContext validateIntegrity(
    Insertable<Annotation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('series_instance_uid')) {
      context.handle(
        _seriesInstanceUidMeta,
        seriesInstanceUid.isAcceptableOrUnknown(
          data['series_instance_uid']!,
          _seriesInstanceUidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_seriesInstanceUidMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Annotation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Annotation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      seriesInstanceUid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series_instance_uid'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AnnotationsTable createAlias(String alias) {
    return $AnnotationsTable(attachedDatabase, alias);
  }
}

class Annotation extends DataClass implements Insertable<Annotation> {
  final int id;
  final String seriesInstanceUid;
  final String kind;
  final String payload;
  final String label;
  final DateTime createdAt;
  const Annotation({
    required this.id,
    required this.seriesInstanceUid,
    required this.kind,
    required this.payload,
    required this.label,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['series_instance_uid'] = Variable<String>(seriesInstanceUid);
    map['kind'] = Variable<String>(kind);
    map['payload'] = Variable<String>(payload);
    map['label'] = Variable<String>(label);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AnnotationsCompanion toCompanion(bool nullToAbsent) {
    return AnnotationsCompanion(
      id: Value(id),
      seriesInstanceUid: Value(seriesInstanceUid),
      kind: Value(kind),
      payload: Value(payload),
      label: Value(label),
      createdAt: Value(createdAt),
    );
  }

  factory Annotation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Annotation(
      id: serializer.fromJson<int>(json['id']),
      seriesInstanceUid: serializer.fromJson<String>(json['seriesInstanceUid']),
      kind: serializer.fromJson<String>(json['kind']),
      payload: serializer.fromJson<String>(json['payload']),
      label: serializer.fromJson<String>(json['label']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'seriesInstanceUid': serializer.toJson<String>(seriesInstanceUid),
      'kind': serializer.toJson<String>(kind),
      'payload': serializer.toJson<String>(payload),
      'label': serializer.toJson<String>(label),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Annotation copyWith({
    int? id,
    String? seriesInstanceUid,
    String? kind,
    String? payload,
    String? label,
    DateTime? createdAt,
  }) => Annotation(
    id: id ?? this.id,
    seriesInstanceUid: seriesInstanceUid ?? this.seriesInstanceUid,
    kind: kind ?? this.kind,
    payload: payload ?? this.payload,
    label: label ?? this.label,
    createdAt: createdAt ?? this.createdAt,
  );
  Annotation copyWithCompanion(AnnotationsCompanion data) {
    return Annotation(
      id: data.id.present ? data.id.value : this.id,
      seriesInstanceUid: data.seriesInstanceUid.present
          ? data.seriesInstanceUid.value
          : this.seriesInstanceUid,
      kind: data.kind.present ? data.kind.value : this.kind,
      payload: data.payload.present ? data.payload.value : this.payload,
      label: data.label.present ? data.label.value : this.label,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Annotation(')
          ..write('id: $id, ')
          ..write('seriesInstanceUid: $seriesInstanceUid, ')
          ..write('kind: $kind, ')
          ..write('payload: $payload, ')
          ..write('label: $label, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, seriesInstanceUid, kind, payload, label, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Annotation &&
          other.id == this.id &&
          other.seriesInstanceUid == this.seriesInstanceUid &&
          other.kind == this.kind &&
          other.payload == this.payload &&
          other.label == this.label &&
          other.createdAt == this.createdAt);
}

class AnnotationsCompanion extends UpdateCompanion<Annotation> {
  final Value<int> id;
  final Value<String> seriesInstanceUid;
  final Value<String> kind;
  final Value<String> payload;
  final Value<String> label;
  final Value<DateTime> createdAt;
  const AnnotationsCompanion({
    this.id = const Value.absent(),
    this.seriesInstanceUid = const Value.absent(),
    this.kind = const Value.absent(),
    this.payload = const Value.absent(),
    this.label = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  AnnotationsCompanion.insert({
    this.id = const Value.absent(),
    required String seriesInstanceUid,
    required String kind,
    required String payload,
    this.label = const Value.absent(),
    required DateTime createdAt,
  }) : seriesInstanceUid = Value(seriesInstanceUid),
       kind = Value(kind),
       payload = Value(payload),
       createdAt = Value(createdAt);
  static Insertable<Annotation> custom({
    Expression<int>? id,
    Expression<String>? seriesInstanceUid,
    Expression<String>? kind,
    Expression<String>? payload,
    Expression<String>? label,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (seriesInstanceUid != null) 'series_instance_uid': seriesInstanceUid,
      if (kind != null) 'kind': kind,
      if (payload != null) 'payload': payload,
      if (label != null) 'label': label,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  AnnotationsCompanion copyWith({
    Value<int>? id,
    Value<String>? seriesInstanceUid,
    Value<String>? kind,
    Value<String>? payload,
    Value<String>? label,
    Value<DateTime>? createdAt,
  }) {
    return AnnotationsCompanion(
      id: id ?? this.id,
      seriesInstanceUid: seriesInstanceUid ?? this.seriesInstanceUid,
      kind: kind ?? this.kind,
      payload: payload ?? this.payload,
      label: label ?? this.label,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (seriesInstanceUid.present) {
      map['series_instance_uid'] = Variable<String>(seriesInstanceUid.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnnotationsCompanion(')
          ..write('id: $id, ')
          ..write('seriesInstanceUid: $seriesInstanceUid, ')
          ..write('kind: $kind, ')
          ..write('payload: $payload, ')
          ..write('label: $label, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$DicomDatabase extends GeneratedDatabase {
  _$DicomDatabase(QueryExecutor e) : super(e);
  $DicomDatabaseManager get managers => $DicomDatabaseManager(this);
  late final $PatientsTable patients = $PatientsTable(this);
  late final $StudiesTable studies = $StudiesTable(this);
  late final $SeriesTableTable seriesTable = $SeriesTableTable(this);
  late final $InstancesTable instances = $InstancesTable(this);
  late final $AnnotationsTable annotations = $AnnotationsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    patients,
    studies,
    seriesTable,
    instances,
    annotations,
  ];
}

typedef $$PatientsTableCreateCompanionBuilder =
    PatientsCompanion Function({
      required String id,
      required String displayName,
      Value<int> rowid,
    });
typedef $$PatientsTableUpdateCompanionBuilder =
    PatientsCompanion Function({
      Value<String> id,
      Value<String> displayName,
      Value<int> rowid,
    });

class $$PatientsTableFilterComposer
    extends Composer<_$DicomDatabase, $PatientsTable> {
  $$PatientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PatientsTableOrderingComposer
    extends Composer<_$DicomDatabase, $PatientsTable> {
  $$PatientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PatientsTableAnnotationComposer
    extends Composer<_$DicomDatabase, $PatientsTable> {
  $$PatientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );
}

class $$PatientsTableTableManager
    extends
        RootTableManager<
          _$DicomDatabase,
          $PatientsTable,
          Patient,
          $$PatientsTableFilterComposer,
          $$PatientsTableOrderingComposer,
          $$PatientsTableAnnotationComposer,
          $$PatientsTableCreateCompanionBuilder,
          $$PatientsTableUpdateCompanionBuilder,
          (Patient, BaseReferences<_$DicomDatabase, $PatientsTable, Patient>),
          Patient,
          PrefetchHooks Function()
        > {
  $$PatientsTableTableManager(_$DicomDatabase db, $PatientsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PatientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PatientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PatientsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PatientsCompanion(
                id: id,
                displayName: displayName,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String displayName,
                Value<int> rowid = const Value.absent(),
              }) => PatientsCompanion.insert(
                id: id,
                displayName: displayName,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PatientsTableProcessedTableManager =
    ProcessedTableManager<
      _$DicomDatabase,
      $PatientsTable,
      Patient,
      $$PatientsTableFilterComposer,
      $$PatientsTableOrderingComposer,
      $$PatientsTableAnnotationComposer,
      $$PatientsTableCreateCompanionBuilder,
      $$PatientsTableUpdateCompanionBuilder,
      (Patient, BaseReferences<_$DicomDatabase, $PatientsTable, Patient>),
      Patient,
      PrefetchHooks Function()
    >;
typedef $$StudiesTableCreateCompanionBuilder =
    StudiesCompanion Function({
      required String instanceUid,
      required String patientId,
      Value<String> description,
      Value<DateTime?> studyDate,
      Value<int> rowid,
    });
typedef $$StudiesTableUpdateCompanionBuilder =
    StudiesCompanion Function({
      Value<String> instanceUid,
      Value<String> patientId,
      Value<String> description,
      Value<DateTime?> studyDate,
      Value<int> rowid,
    });

class $$StudiesTableFilterComposer
    extends Composer<_$DicomDatabase, $StudiesTable> {
  $$StudiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get instanceUid => $composableBuilder(
    column: $table.instanceUid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get studyDate => $composableBuilder(
    column: $table.studyDate,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StudiesTableOrderingComposer
    extends Composer<_$DicomDatabase, $StudiesTable> {
  $$StudiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get instanceUid => $composableBuilder(
    column: $table.instanceUid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get studyDate => $composableBuilder(
    column: $table.studyDate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StudiesTableAnnotationComposer
    extends Composer<_$DicomDatabase, $StudiesTable> {
  $$StudiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get instanceUid => $composableBuilder(
    column: $table.instanceUid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get studyDate =>
      $composableBuilder(column: $table.studyDate, builder: (column) => column);
}

class $$StudiesTableTableManager
    extends
        RootTableManager<
          _$DicomDatabase,
          $StudiesTable,
          Study,
          $$StudiesTableFilterComposer,
          $$StudiesTableOrderingComposer,
          $$StudiesTableAnnotationComposer,
          $$StudiesTableCreateCompanionBuilder,
          $$StudiesTableUpdateCompanionBuilder,
          (Study, BaseReferences<_$DicomDatabase, $StudiesTable, Study>),
          Study,
          PrefetchHooks Function()
        > {
  $$StudiesTableTableManager(_$DicomDatabase db, $StudiesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StudiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StudiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StudiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> instanceUid = const Value.absent(),
                Value<String> patientId = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<DateTime?> studyDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StudiesCompanion(
                instanceUid: instanceUid,
                patientId: patientId,
                description: description,
                studyDate: studyDate,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String instanceUid,
                required String patientId,
                Value<String> description = const Value.absent(),
                Value<DateTime?> studyDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StudiesCompanion.insert(
                instanceUid: instanceUid,
                patientId: patientId,
                description: description,
                studyDate: studyDate,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StudiesTableProcessedTableManager =
    ProcessedTableManager<
      _$DicomDatabase,
      $StudiesTable,
      Study,
      $$StudiesTableFilterComposer,
      $$StudiesTableOrderingComposer,
      $$StudiesTableAnnotationComposer,
      $$StudiesTableCreateCompanionBuilder,
      $$StudiesTableUpdateCompanionBuilder,
      (Study, BaseReferences<_$DicomDatabase, $StudiesTable, Study>),
      Study,
      PrefetchHooks Function()
    >;
typedef $$SeriesTableTableCreateCompanionBuilder =
    SeriesTableCompanion Function({
      required String instanceUid,
      required String studyInstanceUid,
      Value<String> description,
      Value<String> modality,
      Value<int> rowid,
    });
typedef $$SeriesTableTableUpdateCompanionBuilder =
    SeriesTableCompanion Function({
      Value<String> instanceUid,
      Value<String> studyInstanceUid,
      Value<String> description,
      Value<String> modality,
      Value<int> rowid,
    });

class $$SeriesTableTableFilterComposer
    extends Composer<_$DicomDatabase, $SeriesTableTable> {
  $$SeriesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get instanceUid => $composableBuilder(
    column: $table.instanceUid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get studyInstanceUid => $composableBuilder(
    column: $table.studyInstanceUid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modality => $composableBuilder(
    column: $table.modality,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SeriesTableTableOrderingComposer
    extends Composer<_$DicomDatabase, $SeriesTableTable> {
  $$SeriesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get instanceUid => $composableBuilder(
    column: $table.instanceUid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get studyInstanceUid => $composableBuilder(
    column: $table.studyInstanceUid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modality => $composableBuilder(
    column: $table.modality,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SeriesTableTableAnnotationComposer
    extends Composer<_$DicomDatabase, $SeriesTableTable> {
  $$SeriesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get instanceUid => $composableBuilder(
    column: $table.instanceUid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get studyInstanceUid => $composableBuilder(
    column: $table.studyInstanceUid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modality =>
      $composableBuilder(column: $table.modality, builder: (column) => column);
}

class $$SeriesTableTableTableManager
    extends
        RootTableManager<
          _$DicomDatabase,
          $SeriesTableTable,
          SeriesTableData,
          $$SeriesTableTableFilterComposer,
          $$SeriesTableTableOrderingComposer,
          $$SeriesTableTableAnnotationComposer,
          $$SeriesTableTableCreateCompanionBuilder,
          $$SeriesTableTableUpdateCompanionBuilder,
          (
            SeriesTableData,
            BaseReferences<_$DicomDatabase, $SeriesTableTable, SeriesTableData>,
          ),
          SeriesTableData,
          PrefetchHooks Function()
        > {
  $$SeriesTableTableTableManager(_$DicomDatabase db, $SeriesTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SeriesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SeriesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SeriesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> instanceUid = const Value.absent(),
                Value<String> studyInstanceUid = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> modality = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SeriesTableCompanion(
                instanceUid: instanceUid,
                studyInstanceUid: studyInstanceUid,
                description: description,
                modality: modality,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String instanceUid,
                required String studyInstanceUid,
                Value<String> description = const Value.absent(),
                Value<String> modality = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SeriesTableCompanion.insert(
                instanceUid: instanceUid,
                studyInstanceUid: studyInstanceUid,
                description: description,
                modality: modality,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SeriesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$DicomDatabase,
      $SeriesTableTable,
      SeriesTableData,
      $$SeriesTableTableFilterComposer,
      $$SeriesTableTableOrderingComposer,
      $$SeriesTableTableAnnotationComposer,
      $$SeriesTableTableCreateCompanionBuilder,
      $$SeriesTableTableUpdateCompanionBuilder,
      (
        SeriesTableData,
        BaseReferences<_$DicomDatabase, $SeriesTableTable, SeriesTableData>,
      ),
      SeriesTableData,
      PrefetchHooks Function()
    >;
typedef $$InstancesTableCreateCompanionBuilder =
    InstancesCompanion Function({
      Value<int> id,
      required String studyInstanceUid,
      required String seriesInstanceUid,
      required String sopInstanceUid,
      Value<int?> instanceNumber,
      required String filePath,
      required String transferSyntaxUid,
      Value<Uint8List?> pixelData,
    });
typedef $$InstancesTableUpdateCompanionBuilder =
    InstancesCompanion Function({
      Value<int> id,
      Value<String> studyInstanceUid,
      Value<String> seriesInstanceUid,
      Value<String> sopInstanceUid,
      Value<int?> instanceNumber,
      Value<String> filePath,
      Value<String> transferSyntaxUid,
      Value<Uint8List?> pixelData,
    });

class $$InstancesTableFilterComposer
    extends Composer<_$DicomDatabase, $InstancesTable> {
  $$InstancesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get studyInstanceUid => $composableBuilder(
    column: $table.studyInstanceUid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seriesInstanceUid => $composableBuilder(
    column: $table.seriesInstanceUid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sopInstanceUid => $composableBuilder(
    column: $table.sopInstanceUid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get instanceNumber => $composableBuilder(
    column: $table.instanceNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transferSyntaxUid => $composableBuilder(
    column: $table.transferSyntaxUid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get pixelData => $composableBuilder(
    column: $table.pixelData,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InstancesTableOrderingComposer
    extends Composer<_$DicomDatabase, $InstancesTable> {
  $$InstancesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get studyInstanceUid => $composableBuilder(
    column: $table.studyInstanceUid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seriesInstanceUid => $composableBuilder(
    column: $table.seriesInstanceUid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sopInstanceUid => $composableBuilder(
    column: $table.sopInstanceUid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get instanceNumber => $composableBuilder(
    column: $table.instanceNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transferSyntaxUid => $composableBuilder(
    column: $table.transferSyntaxUid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get pixelData => $composableBuilder(
    column: $table.pixelData,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InstancesTableAnnotationComposer
    extends Composer<_$DicomDatabase, $InstancesTable> {
  $$InstancesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get studyInstanceUid => $composableBuilder(
    column: $table.studyInstanceUid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get seriesInstanceUid => $composableBuilder(
    column: $table.seriesInstanceUid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sopInstanceUid => $composableBuilder(
    column: $table.sopInstanceUid,
    builder: (column) => column,
  );

  GeneratedColumn<int> get instanceNumber => $composableBuilder(
    column: $table.instanceNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get transferSyntaxUid => $composableBuilder(
    column: $table.transferSyntaxUid,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get pixelData =>
      $composableBuilder(column: $table.pixelData, builder: (column) => column);
}

class $$InstancesTableTableManager
    extends
        RootTableManager<
          _$DicomDatabase,
          $InstancesTable,
          Instance,
          $$InstancesTableFilterComposer,
          $$InstancesTableOrderingComposer,
          $$InstancesTableAnnotationComposer,
          $$InstancesTableCreateCompanionBuilder,
          $$InstancesTableUpdateCompanionBuilder,
          (
            Instance,
            BaseReferences<_$DicomDatabase, $InstancesTable, Instance>,
          ),
          Instance,
          PrefetchHooks Function()
        > {
  $$InstancesTableTableManager(_$DicomDatabase db, $InstancesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InstancesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InstancesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InstancesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> studyInstanceUid = const Value.absent(),
                Value<String> seriesInstanceUid = const Value.absent(),
                Value<String> sopInstanceUid = const Value.absent(),
                Value<int?> instanceNumber = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<String> transferSyntaxUid = const Value.absent(),
                Value<Uint8List?> pixelData = const Value.absent(),
              }) => InstancesCompanion(
                id: id,
                studyInstanceUid: studyInstanceUid,
                seriesInstanceUid: seriesInstanceUid,
                sopInstanceUid: sopInstanceUid,
                instanceNumber: instanceNumber,
                filePath: filePath,
                transferSyntaxUid: transferSyntaxUid,
                pixelData: pixelData,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String studyInstanceUid,
                required String seriesInstanceUid,
                required String sopInstanceUid,
                Value<int?> instanceNumber = const Value.absent(),
                required String filePath,
                required String transferSyntaxUid,
                Value<Uint8List?> pixelData = const Value.absent(),
              }) => InstancesCompanion.insert(
                id: id,
                studyInstanceUid: studyInstanceUid,
                seriesInstanceUid: seriesInstanceUid,
                sopInstanceUid: sopInstanceUid,
                instanceNumber: instanceNumber,
                filePath: filePath,
                transferSyntaxUid: transferSyntaxUid,
                pixelData: pixelData,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InstancesTableProcessedTableManager =
    ProcessedTableManager<
      _$DicomDatabase,
      $InstancesTable,
      Instance,
      $$InstancesTableFilterComposer,
      $$InstancesTableOrderingComposer,
      $$InstancesTableAnnotationComposer,
      $$InstancesTableCreateCompanionBuilder,
      $$InstancesTableUpdateCompanionBuilder,
      (Instance, BaseReferences<_$DicomDatabase, $InstancesTable, Instance>),
      Instance,
      PrefetchHooks Function()
    >;
typedef $$AnnotationsTableCreateCompanionBuilder =
    AnnotationsCompanion Function({
      Value<int> id,
      required String seriesInstanceUid,
      required String kind,
      required String payload,
      Value<String> label,
      required DateTime createdAt,
    });
typedef $$AnnotationsTableUpdateCompanionBuilder =
    AnnotationsCompanion Function({
      Value<int> id,
      Value<String> seriesInstanceUid,
      Value<String> kind,
      Value<String> payload,
      Value<String> label,
      Value<DateTime> createdAt,
    });

class $$AnnotationsTableFilterComposer
    extends Composer<_$DicomDatabase, $AnnotationsTable> {
  $$AnnotationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seriesInstanceUid => $composableBuilder(
    column: $table.seriesInstanceUid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AnnotationsTableOrderingComposer
    extends Composer<_$DicomDatabase, $AnnotationsTable> {
  $$AnnotationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seriesInstanceUid => $composableBuilder(
    column: $table.seriesInstanceUid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AnnotationsTableAnnotationComposer
    extends Composer<_$DicomDatabase, $AnnotationsTable> {
  $$AnnotationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get seriesInstanceUid => $composableBuilder(
    column: $table.seriesInstanceUid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AnnotationsTableTableManager
    extends
        RootTableManager<
          _$DicomDatabase,
          $AnnotationsTable,
          Annotation,
          $$AnnotationsTableFilterComposer,
          $$AnnotationsTableOrderingComposer,
          $$AnnotationsTableAnnotationComposer,
          $$AnnotationsTableCreateCompanionBuilder,
          $$AnnotationsTableUpdateCompanionBuilder,
          (
            Annotation,
            BaseReferences<_$DicomDatabase, $AnnotationsTable, Annotation>,
          ),
          Annotation,
          PrefetchHooks Function()
        > {
  $$AnnotationsTableTableManager(_$DicomDatabase db, $AnnotationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnnotationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnnotationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnnotationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> seriesInstanceUid = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => AnnotationsCompanion(
                id: id,
                seriesInstanceUid: seriesInstanceUid,
                kind: kind,
                payload: payload,
                label: label,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String seriesInstanceUid,
                required String kind,
                required String payload,
                Value<String> label = const Value.absent(),
                required DateTime createdAt,
              }) => AnnotationsCompanion.insert(
                id: id,
                seriesInstanceUid: seriesInstanceUid,
                kind: kind,
                payload: payload,
                label: label,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AnnotationsTableProcessedTableManager =
    ProcessedTableManager<
      _$DicomDatabase,
      $AnnotationsTable,
      Annotation,
      $$AnnotationsTableFilterComposer,
      $$AnnotationsTableOrderingComposer,
      $$AnnotationsTableAnnotationComposer,
      $$AnnotationsTableCreateCompanionBuilder,
      $$AnnotationsTableUpdateCompanionBuilder,
      (
        Annotation,
        BaseReferences<_$DicomDatabase, $AnnotationsTable, Annotation>,
      ),
      Annotation,
      PrefetchHooks Function()
    >;

class $DicomDatabaseManager {
  final _$DicomDatabase _db;
  $DicomDatabaseManager(this._db);
  $$PatientsTableTableManager get patients =>
      $$PatientsTableTableManager(_db, _db.patients);
  $$StudiesTableTableManager get studies =>
      $$StudiesTableTableManager(_db, _db.studies);
  $$SeriesTableTableTableManager get seriesTable =>
      $$SeriesTableTableTableManager(_db, _db.seriesTable);
  $$InstancesTableTableManager get instances =>
      $$InstancesTableTableManager(_db, _db.instances);
  $$AnnotationsTableTableManager get annotations =>
      $$AnnotationsTableTableManager(_db, _db.annotations);
}
