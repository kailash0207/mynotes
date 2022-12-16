import 'package:flutter/cupertino.dart';
import 'package:mynotes/utilities/dialogs/generic_dialog.dart';

Future<bool> showLogOutDialog(BuildContext context) {
  return showGenericDialog<bool>(
          context: context,
          title: "Log Out",
          content: "Do you want to log out?",
          optionBuilder: () => {"No": false, "Yes": true})
      .then((value) => value ?? false);
}
