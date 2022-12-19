import 'package:bloc/bloc.dart';
import 'package:mynotes/services/auth/auth_provider.dart';
import 'package:mynotes/services/auth/bloc/auth_event.dart';
import 'package:mynotes/services/auth/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(AuthProvider provider)
      : super(const AuthStateUninitialized(isLoading: true)) {
    on<AuthEventSendEmailVerification>((event, emit) async {
      emit(const AuthStateEmailNotVerified(
          isLoading: true, exception: null, hasSentEmail: false));
      try {
        await provider.sendEmailVerification();
        emit(const AuthStateEmailNotVerified(
            isLoading: false, exception: null, hasSentEmail: true));
      } on Exception catch (e) {
        emit(AuthStateEmailNotVerified(
            exception: e, isLoading: false, hasSentEmail: false));
      }
    });
    on<AuthEventRegister>((event, emit) async {
      emit(const AuthStateRegistering(
          exception: null, isLoading: true, loadingText: "Registering..."));
      final email = event.email;
      final password = event.password;
      try {
        await provider.createUser(email: email, password: password);
        try {
          await provider.sendEmailVerification();
          emit(const AuthStateEmailNotVerified(
              isLoading: false, exception: null, hasSentEmail: true));
        } on Exception catch (e) {
          emit(AuthStateEmailNotVerified(
              exception: e, isLoading: false, hasSentEmail: false));
        }
      } on Exception catch (e) {
        emit(AuthStateRegistering(exception: e, isLoading: false));
      }
    });
    on<AuthEventInitialize>((event, emit) async {
      await provider.initialize();
      final user = provider.currentUser;
      if (user == null) {
        emit(const AuthStateLoggedOut(exception: null, isLoading: false));
      } else if (!user.isEmailVerified) {
        try {
          await provider.sendEmailVerification();
          emit(const AuthStateEmailNotVerified(
              isLoading: false, exception: null, hasSentEmail: true));
        } on Exception catch (e) {
          emit(AuthStateEmailNotVerified(
              exception: e, isLoading: false, hasSentEmail: false));
        }
      } else {
        emit(AuthStateLoggedIn(user: user, isLoading: false));
      }
    });
    on<AuthEventLogIn>((event, emit) async {
      emit(const AuthStateLoggedOut(
          exception: null, isLoading: true, loadingText: "Logging in.."));
      final email = event.email;
      final password = event.password;
      try {
        final user = await provider.logIn(email: email, password: password);
        if (!user.isEmailVerified) {
          emit(const AuthStateLoggedOut(exception: null, isLoading: false));
          try {
            provider.sendEmailVerification();
            emit(const AuthStateEmailNotVerified(
                isLoading: false, exception: null, hasSentEmail: true));
          } on Exception catch (e) {
            emit(AuthStateEmailNotVerified(
                isLoading: false, exception: e, hasSentEmail: false));
          }
        } else {
          emit(const AuthStateLoggedOut(exception: null, isLoading: false));
          emit(AuthStateLoggedIn(user: user, isLoading: false));
        }
      } on Exception catch (e) {
        emit(AuthStateLoggedOut(exception: e, isLoading: false));
      }
    });
    on<AuthEventLogOut>((event, emit) async {
      try {
        await provider.logOut();
        emit(const AuthStateLoggedOut(exception: null, isLoading: false));
      } on Exception catch (e) {
        emit(AuthStateLoggedOut(exception: e, isLoading: false));
      }
    });
    on<AuthEventShouldRegister>((event, emit) async {
      emit(const AuthStateRegistering(exception: null, isLoading: false));
    });
    on<AuthEventForgotPassword>((event, emit) async {
      emit(const AuthStateForgotPassword(
          exception: null, hasSentEmail: false, isLoading: false));
      final email = event.email;
      if (email == null) {
        return;
      }
      emit(const AuthStateForgotPassword(
          exception: null, hasSentEmail: false, isLoading: true));

      bool didSendEmail;
      Exception? exception;
      try {
        await provider.sendPasswordResetEmail(email: email);
        didSendEmail = true;
        exception = null;
      } on Exception catch (e) {
        didSendEmail = false;
        exception = e;
      }

      emit(AuthStateForgotPassword(
          exception: exception, hasSentEmail: didSendEmail, isLoading: false));
    });
  }
}
