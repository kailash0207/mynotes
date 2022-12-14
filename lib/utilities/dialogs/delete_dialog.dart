import 'package:flutter/material.dart';
import 'package:mynotes/utilities/dialogs/generic_dialog.dart';

Future<bool> showDeleteDialog(BuildContext context) {
  return showGenericDialog<bool>(
          context: context,
          title: "Delete Note",
          content: "Do you want to delete this note?",
          optionBuilder: () => {"No": false, "Yes": true})
      .then((value) => value ?? false);
}
