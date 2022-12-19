import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mynotes/services/cloud/cloud_storage_constants.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/services/cloud/cloud_storage_exceptions.dart';

class FirebaseCloudStorage {
  final notes = FirebaseFirestore.instance.collection('notes');

  static final FirebaseCloudStorage _instance =
      FirebaseCloudStorage._getInstance();
  FirebaseCloudStorage._getInstance();
  factory FirebaseCloudStorage() => _instance;

  Future<CloudNote> createNote(
      {required String userId, required String text}) async {
    try {
      final docRef = await notes.add({userIdField: userId, textField: text});
      final note = await docRef.get();
      return CloudNote(documentId: note.id, userId: userId, text: text);
    } catch (e) {
      throw CouldNotCreateNoteException();
    }
  }

  Stream<List<CloudNote>> allNotes({required String userId}) =>
      notes.where(userIdField, isEqualTo: userId).snapshots().map((event) =>
          event.docs.map((doc) => CloudNote.fromSnapshot(doc)).toList());

  Future<void> updateNote(
      {required String documentId, required String text}) async {
    try {
      await notes.doc(documentId).update({textField: text});
    } catch (e) {
      throw CouldNotUpdateNoteException();
    }
  }

  Future<void> deleteNote({required String documentId}) async {
    try {
      await notes.doc(documentId).delete();
    } catch (e) {
      throw CouldNotDeleteNoteException();
    }
  }
}
