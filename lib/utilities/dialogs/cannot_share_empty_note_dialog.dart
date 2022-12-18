import 'package:flutter/cupertino.dart';
import 'package:mynotes/utilities/dialogs/generic_dialog.dart';

Future<void> showCannotShareEmptyNoteDialog(BuildContext context) {
  return showGenericDialog<void>(
      context: context,
      title: "Empty Note",
      content: "Empty note can't be shared",
      optionBuilder: () => {'OK': null});
}
