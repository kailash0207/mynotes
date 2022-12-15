// ignore_for_file: unrelated_type_equality_checks

import 'package:flutter/cupertino.dart';
import "package:sqflite/sqflite.dart";
import "package:path_provider/path_provider.dart";
import "package:path/path.dart" show join;
import 'crud_exceptions.dart';

class NotesService {
  Database? _db;

  Future<void> deleteUser({required String email}) async {
    final db = _getDatabaseOrThrow();
    final deletedCount = db.delete(userTable,
        where: '$emailColumn = ?', whereArgs: [email.toLowerCase()]);

    if (deletedCount != 1) {
      throw CouldNotDeleteUserException();
    }
  }

  Future<DatabaseUser> createUser({required String email}) async {
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
    final db = _getDatabaseOrThrow();
    final results = await db.query(userTable,
        limit: 1, where: "$emailColumn = ?", whereArgs: [email.toLowerCase()]);
    if (results.isEmpty) {
      throw UserDoesNotExistException();
    }

    return DatabaseUser.fromRow(results.first);
  }

  Future<DatabaseNote> createNote({required DatabaseUser user}) async {
    final db = _getDatabaseOrThrow();
    final dbUser = getUser(email: user.email);
    if (dbUser != user) {
      throw UserDoesNotExistException();
    }
    const note = '';
    final noteId =
        await db.insert(noteTable, {userIdColumn: user.id, note: note});
    final databaseNote = DatabaseNote(id: noteId, userId: user.id, note: note);
    return databaseNote;
  }

  Future<void> deleteNote({required int id}) async {
    final db = _getDatabaseOrThrow();
    final deletedCount =
        await db.delete(noteTable, where: 'id = ?', whereArgs: [id]);
    if (deletedCount == 0) {
      throw CouldNotDeleteNoteException();
    }
  }

  Future<DatabaseNote> getNote({required int id}) async {
    final db = _getDatabaseOrThrow();
    final result =
        await db.query(noteTable, limit: 1, where: "id = ?", whereArgs: [id]);
    if (result.isEmpty) {
      throw CouldNotGetNoteException;
    }
    return DatabaseNote.fromRow(result.first);
  }

  Future<List<DatabaseNote>> getAllNotes() async {
    final db = _getDatabaseOrThrow();
    final result = await db.query(noteTable);
    return result.map((e) => DatabaseNote.fromRow(e)).toList();
  }

  Future<DatabaseNote> updateNote(
      {required DatabaseNote note, required String text}) async {
    final db = _getDatabaseOrThrow();
    await getNote(id: note.id);
    final count = db.update(noteTable, {noteColumn: text},
        where: "id = ?", whereArgs: [note.id]);
    if (count != 1) {
      throw CouldNotUpdateNoteException();
    }
    return await getNote(id: note.id);
  }

  Future<int> deleteAllNotes() async {
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(noteTable);
    return deletedCount;
  }

  Database _getDatabaseOrThrow() {
    final db = _db;
    if (db == null) {
      throw DatabaseNotOpenException();
    } else {
      return db;
    }
  }

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

@immutable
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
            PIMARY KEY("$idColumn" AUTOINCREMENT)
          );
        ''';
const createNoteTableQuery = '''
          CREATE TABLE IF NOT EXISTS "$noteTable"(
            "$idColumn" INTEGER NOT NULL,
            "$userIdColumn" INTEGER NOT NULL,
            "$noteColumn" TEXT,
            FOREIGN KEY("$userIdColumn) REFERENCES "$userTable"("$idColumn"),
            PIMARY KEY("$idColumn" AUTOINCREMENT)
          );
        ''';
