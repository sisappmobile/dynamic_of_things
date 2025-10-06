// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schemas.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
class Version extends _Version with RealmEntity, RealmObjectBase, RealmObject {
  Version(
    String key,
    int value,
  ) {
    RealmObjectBase.set(this, 'key', key);
    RealmObjectBase.set(this, 'value', value);
  }

  Version._();

  @override
  String get key => RealmObjectBase.get<String>(this, 'key') as String;
  @override
  set key(String value) => RealmObjectBase.set(this, 'key', value);

  @override
  int get value => RealmObjectBase.get<int>(this, 'value') as int;
  @override
  set value(int value) => RealmObjectBase.set(this, 'value', value);

  @override
  Stream<RealmObjectChanges<Version>> get changes =>
      RealmObjectBase.getChanges<Version>(this);

  @override
  Stream<RealmObjectChanges<Version>> changesFor([List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<Version>(this, keyPaths);

  @override
  Version freeze() => RealmObjectBase.freezeObject<Version>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'key': key.toEJson(),
      'value': value.toEJson(),
    };
  }

  static EJsonValue _toEJson(Version value) => value.toEJson();
  static Version _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'key': EJsonValue key,
        'value': EJsonValue value,
      } =>
        Version(
          fromEJson(key),
          fromEJson(value),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(Version._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(ObjectType.realmObject, Version, 'Version', [
      SchemaProperty('key', RealmPropertyType.string, primaryKey: true),
      SchemaProperty('value', RealmPropertyType.int),
    ]);
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}

class DynamicForm extends _DynamicForm
    with RealmEntity, RealmObjectBase, RealmObject {
  DynamicForm(
    String id,
    String json,
  ) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'json', json);
  }

  DynamicForm._();

  @override
  String get id => RealmObjectBase.get<String>(this, 'id') as String;
  @override
  set id(String value) => RealmObjectBase.set(this, 'id', value);

  @override
  String get json => RealmObjectBase.get<String>(this, 'json') as String;
  @override
  set json(String value) => RealmObjectBase.set(this, 'json', value);

  @override
  Stream<RealmObjectChanges<DynamicForm>> get changes =>
      RealmObjectBase.getChanges<DynamicForm>(this);

  @override
  Stream<RealmObjectChanges<DynamicForm>> changesFor(
          [List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<DynamicForm>(this, keyPaths);

  @override
  DynamicForm freeze() => RealmObjectBase.freezeObject<DynamicForm>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'json': json.toEJson(),
    };
  }

  static EJsonValue _toEJson(DynamicForm value) => value.toEJson();
  static DynamicForm _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
        'json': EJsonValue json,
      } =>
        DynamicForm(
          fromEJson(id),
          fromEJson(json),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(DynamicForm._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
        ObjectType.realmObject, DynamicForm, 'DynamicForm', [
      SchemaProperty('id', RealmPropertyType.string, primaryKey: true),
      SchemaProperty('json', RealmPropertyType.string),
    ]);
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}

class Schema extends _Schema with RealmEntity, RealmObjectBase, RealmObject {
  Schema(
    String name,
    String json,
  ) {
    RealmObjectBase.set(this, 'name', name);
    RealmObjectBase.set(this, 'json', json);
  }

  Schema._();

  @override
  String get name => RealmObjectBase.get<String>(this, 'name') as String;
  @override
  set name(String value) => RealmObjectBase.set(this, 'name', value);

  @override
  String get json => RealmObjectBase.get<String>(this, 'json') as String;
  @override
  set json(String value) => RealmObjectBase.set(this, 'json', value);

  @override
  Stream<RealmObjectChanges<Schema>> get changes =>
      RealmObjectBase.getChanges<Schema>(this);

  @override
  Stream<RealmObjectChanges<Schema>> changesFor([List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<Schema>(this, keyPaths);

  @override
  Schema freeze() => RealmObjectBase.freezeObject<Schema>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'name': name.toEJson(),
      'json': json.toEJson(),
    };
  }

  static EJsonValue _toEJson(Schema value) => value.toEJson();
  static Schema _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'name': EJsonValue name,
        'json': EJsonValue json,
      } =>
        Schema(
          fromEJson(name),
          fromEJson(json),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(Schema._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(ObjectType.realmObject, Schema, 'Schema', [
      SchemaProperty('name', RealmPropertyType.string, primaryKey: true),
      SchemaProperty('json', RealmPropertyType.string),
    ]);
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
