import 'package:flutter/cupertino.dart';
import 'package:mynotes/utilities/dialogs/generic_dialog.dart';

Future<void> showErrorDialog(BuildContext context, String text) {
  return showGenericDialog(
      context: context,
      title: "Error!",
      content: text,
      optionBuilder: () => {
            'OK': null,
          });
}
