import 'package:flutter/material.dart';
import 'package:mynotes/utilities/dialogs/generic_dialog.dart';

Future<void> showEmailVerificationSentDialog(BuildContext context) {
  return showGenericDialog(
      context: context,
      title: "Email Verification",
      content:
          "Email verification link has been sent to your email. Please click on link sent to verify your email.",
      optionBuilder: () => {"OK": null});
}
