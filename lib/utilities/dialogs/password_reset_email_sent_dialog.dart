import 'package:flutter/material.dart';
import 'package:mynotes/utilities/dialogs/generic_dialog.dart';

Future<void> showPasswordResentEmailSentDialog(BuildContext context) {
  return showGenericDialog(
      context: context,
      title: "Password Reset",
      content:
          "Password reset link has been sent to your email. Please click on link sent to reset your password.",
      optionBuilder: () => {"OK": null});
}
