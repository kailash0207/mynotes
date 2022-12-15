import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum MenuAction { logout }

class NotesView extends StatefulWidget {
  const NotesView({super.key});

  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Notes"),
        actions: [
          PopupMenuButton<MenuAction>(
            onSelected: (value) async {
              switch (value) {
                case MenuAction.logout:
                  final shouldLogOut = await showLogOutDialog(context);
                  if (shouldLogOut) {
                    await FirebaseAuth.instance.signOut();
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      "/login/",
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
    );
  }
}

Future<bool> showLogOutDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Log Out"),
      content: const Text("Do you really want to log out?"),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          child: const Text("Yes"),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: const Text("No"),
        )
      ],
    ),
  ).then((value) => value ?? false);
}
