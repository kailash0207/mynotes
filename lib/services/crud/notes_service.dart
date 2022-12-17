// ignore_for_file: unrelated_type_equality_checks

import 'dart:async';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:mynotes/extensions/list/filter.dart';
import 'package:mynotes/services/auth/auth_exceptions.dart';
import "package:sqflite/sqflite.dart";
import "package:path_provider/path_provider.dart";
import "package:path/path.dart" show join;
import 'crud_exceptions.dart';

class NotesService {
  Database? _db;
  List<DatabaseNote> _notes = [];
  DatabaseUser? _currentUser;

  static final NotesService _instance = NotesService._getInstance();
  NotesService._getInstance() {
    _notesStreamController =
        StreamController<List<DatabaseNote>>.broadcast(onListen: () {
      _notesStreamController.sink.add(_notes);
    });
  }
  factory NotesService() => _instance;

  late final StreamController<List<DatabaseNote>> _notesStreamController;

  Future<void> _cacheNotes() async {
    final allNotes = await getAllNotes();
    _notes = allNotes;
    _notesStreamController.add(_notes);
  }

  Future<void> _ensureDbIsOpen() async {
    try {
      await open();
    } on DatabaseAlreadyOpenException {
      //empty
    }
  }

  Database _getDatabaseOrThrow() {
    final db = _db;
    if (db == null) {
      throw DatabaseNotOpenException();
    } else {
      return db;
    }
  }

  Future<DatabaseUser> getOrCreateUser(
      {required String email, bool setAsCurrentUser = true}) async {
    try {
      final user = await getUser(email: email);
      if (setAsCurrentUser) {
        _currentUser = user;
      }
      return user;
    } on UserDoesNotExistException {
      final user = await createUser(email: email);
      if (setAsCurrentUser) {
        _currentUser = user;
      }
      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<DatabaseUser> createUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final results = await db.query(userTable,
        limit: 1, where: "$emailColumn = ?", whereArgs: [email.toLowerCase()]);
    if (results.isNotEmpty) {
      throw UserAlreadyExistsException();
    } else {
      final userId =
          await db.insert(userTable, {emailColumn: email.toLowerCase()});

      return DatabaseUser(id: userId, email: email);
    }
  }

  Future<DatabaseUser> getUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final results = await db.query(userTable,
        limit: 1, where: "$emailColumn = ?", whereArgs: [email.toLowerCase()]);
    if (results.isEmpty) {
      throw UserDoesNotExistException();
    }

    return DatabaseUser.fromRow(results.first);
  }

  Future<void> deleteUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = db.delete(userTable,
        where: '$emailColumn = ?', whereArgs: [email.toLowerCase()]);

    if (deletedCount != 1) {
      throw CouldNotDeleteUserException();
    }
  }

  Future<DatabaseNote> createNote({required DatabaseUser user}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final dbUser = await getUser(email: user.email);
    if (dbUser != user) {
      throw UserDoesNotExistException();
    }

    const note = '';
    final noteId =
        await db.insert(noteTable, {userIdColumn: user.id, noteColumn: note});
    final databaseNote = DatabaseNote(id: noteId, userId: user.id, note: note);
    _notes.add(databaseNote);
    _notesStreamController.add(_notes);
    return databaseNote;
  }

  Future<void> deleteNote({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount =
        await db.delete(noteTable, where: 'id = ?', whereArgs: [id]);
    if (deletedCount == 0) {
      throw CouldNotDeleteNoteException();
    } else {
      _notes.removeWhere((element) => element.id == id);
      _notesStreamController.add(_notes);
    }
  }

  Future<DatabaseNote> getNote({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final result =
        await db.query(noteTable, limit: 1, where: "id = ?", whereArgs: [id]);
    if (result.isEmpty) {
      throw CouldNotGetNoteException;
    }
    final note = DatabaseNote.fromRow(result.first);
    _notes.removeWhere((element) => element.id == note.id);
    _notes.add(note);
    _notesStreamController.add(_notes);
    return note;
  }

  Future<List<DatabaseNote>> getAllNotes() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final result = await db.query(noteTable);
    return result.map((e) => DatabaseNote.fromRow(e)).toList();
  }

  Future<DatabaseNote> updateNote(
      {required DatabaseNote note, required String text}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    await getNote(id: note.id);
    final count = db.update(noteTable, {noteColumn: text},
        where: "$idColumn = ?", whereArgs: [note.id]);
    if (count == 0) {
      throw CouldNotUpdateNoteException();
    } else {
      final dbNote = await getNote(id: note.id);
      _notes.removeWhere((element) => element.id == dbNote.id);
      _notes.add(dbNote);
      _notesStreamController.add(_notes);
      return dbNote;
    }
  }

  Future<int> deleteAllNotes() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(noteTable);
    _notes = [];
    _notesStreamController.add(_notes);
    return deletedCount;
  }

  Stream<List<DatabaseNote>> get allNotes =>
      _notesStreamController.stream.filter((note) {
        final currentUser = _currentUser;
        if (currentUser != null) {
          return note.userId == currentUser.id;
        } else {
          throw CurrentUserNotSetException();
        }
      });

  Future<void> open() async {
    if (_db != null) {
      throw DatabaseAlreadyOpenException();
    }
    try {
      final docsPath = await getApplicationDocumentsDirectory();
      final dbPath = join(docsPath.path, dbName);
      final db = await openDatabase(dbPath);
      _db = db;
      await db.execute(createUserTableQuery);
      await db.execute(createNoteTableQuery);
      await _cacheNotes();
    } on MissingPlatformDirectoryException {
      throw UnableToGetDocumentsException();
    }
  }

  Future<void> close() async {
    final db = _getDatabaseOrThrow();
    await db.close();
    _db = null;
  }
}

@immutable
class DatabaseUser {
  final int id;
  final String email;

  const DatabaseUser({required this.id, required this.email});

  DatabaseUser.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        email = map[emailColumn] as String;

  @override
  String toString() => 'Person, ID = $id, email = $email';

  @override
  bool operator ==(covariant DatabaseUser other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class DatabaseNote {
  final int id;
  final int userId;
  final String note;

  const DatabaseNote(
      {required this.id, required this.userId, required this.note});

  DatabaseNote.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        userId = map[userIdColumn] as int,
        note = map[noteColumn] as String;

  @override
  String toString() => "Note, ID = $id, userId = $userId, note = $note";
  @override
  bool operator ==(covariant DatabaseUser other) => id == other.id;
  @override
  int get hashCode => id.hashCode;
}

const dbName = 'notes.db';
const noteTable = 'note';
const userTable = 'user';
const idColumn = 'id';
const emailColumn = 'email';
const userIdColumn = 'user_id';
const noteColumn = 'note';
const createUserTableQuery = '''
          CREATE TABLE IF NOT EXISTS "$userTable"(
            "$idColumn" INTEGER NOT NULL,
            "$emailColumn" TEXT NOT NULL UNIQUE,
            PRIMARY KEY("$idColumn" AUTOINCREMENT)
            
          );
        ''';
const createNoteTableQuery = '''
          CREATE TABLE IF NOT EXISTS "$noteTable"(
            "$idColumn" INTEGER NOT NULL,
            "$userIdColumn" INTEGER NOT NULL,
            "$noteColumn" TEXT,
            FOREIGN KEY("$userIdColumn") REFERENCES "$userTable"("$idColumn"),
            PRIMARY KEY("$idColumn" AUTOINCREMENT)
          );
        ''';
