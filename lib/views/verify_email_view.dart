import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynotes/services/auth/bloc/auth_state.dart';
import 'package:mynotes/services/auth/bloc/auth_bloc.dart';
import 'package:mynotes/services/auth/bloc/auth_event.dart';
import 'package:mynotes/utilities/dialogs/email_verification_sent_dialog.dart';
import 'package:mynotes/utilities/dialogs/error_dialog.dart';

class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({super.key});

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state is AuthStateEmailNotVerified) {
          if (state.exception != null) {
            await showErrorDialog(
                context, "Request failed. Please try again later.");
          } else if (state.hasSentEmail) {
            await showEmailVerificationSentDialog(context);
          }
        }
      },
      child: Scaffold(
          appBar: AppBar(title: const Text("Verify Email")),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                      "Email verification link has been sent. Please click on that link to verify your email. Please log out after verifying email and log in again."),
                  const Text(
                      "If you haven't recieved it yet, please click below."),
                  Center(
                    child: Column(
                      children: [
                        TextButton(
                          onPressed: () {
                            context
                                .read<AuthBloc>()
                                .add(const AuthEventSendEmailVerification());
                          },
                          child: const Text("Send Email Verification Link"),
                        ),
                        TextButton(
                          onPressed: () {
                            context
                                .read<AuthBloc>()
                                .add(const AuthEventLogOut());
                          },
                          child: const Text("Log Out"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )),
    );
  }
}
