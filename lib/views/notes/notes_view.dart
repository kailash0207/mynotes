// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/services/crud/notes_service.dart';
import 'package:mynotes/views/notes/notes_list_view.dart';
import '../../enums/menu_action.dart';
import '../../utilities/dialogs/logout_dialog.dart';

class NotesView extends StatefulWidget {
  const NotesView({super.key});

  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> {
  String get userEmail => AuthService.firebase().currentUser!.email!;
  late final NotesService _notesService;

  @override
  void initState() {
    _notesService = NotesService();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Notes"),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.of(context).pushNamed(createOrUpdateNoteRoue);
              },
              icon: const Icon(Icons.add)),
          PopupMenuButton<MenuAction>(
            onSelected: (value) async {
              switch (value) {
                case MenuAction.logout:
                  final shouldLogOut = await showLogOutDialog(context);
                  if (shouldLogOut) {
                    await AuthService.firebase().logOut();
                    await _notesService.close();
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      loginRoute,
                      (route) => false,
                    );
                  }
                  break;
                default:
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<MenuAction>(
                value: MenuAction.logout,
                child: Text("Log Out"),
              )
            ],
          )
        ],
      ),
      body: FutureBuilder(
        future: _notesService.getOrCreateUser(email: userEmail),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return StreamBuilder(
              stream: _notesService.allNotes,
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.waiting:
                  case ConnectionState.active:
                    if (snapshot.hasData) {
                      final allNotes = snapshot.data as List<DatabaseNote>;
                      return NotesListView(
                        notes: allNotes,
                        onDeleteNote: (note) async {
                          await _notesService.deleteNote(id: note.id);
                        },
                        onTap: (note) {
                          Navigator.of(context).pushNamed(
                              createOrUpdateNoteRoue,
                              arguments: note);
                        },
                      );
                    } else {
                      return const CircularProgressIndicator();
                    }
                  default:
                    return const Center(child: CircularProgressIndicator());
                }
              },
            );
          } else {
            return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}
