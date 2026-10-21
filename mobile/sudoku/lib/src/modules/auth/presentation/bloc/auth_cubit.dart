import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sudoku/src/core/util/logger_service.dart';
import 'package:sudoku/src/modules/auth/data/auth_service.dart';
import 'package:sudoku/src/modules/auth/domain/model/auth_user.dart';

class AuthState extends Equatable {
  final AuthUser? user;

  /// A sign-in or sign-out is in progress.
  final bool busy;

  const AuthState({this.user, this.busy = false});

  bool get signedIn => user != null;

  @override
  List<Object?> get props => [user, busy];
}

class AuthCubit extends Cubit<AuthState> {
  static const signInFailedMessage =
      'Could not sign in. Check your connection and try again.';

  final AuthService service;
  late final StreamSubscription<AuthUser?> _userSubscription;

  AuthCubit(this.service) : super(AuthState(user: service.currentUser)) {
    // Also catches sessions dropped when a refresh is refused.
    _userSubscription = service.userChanges.listen((user) {
      if (!isClosed) emit(AuthState(user: user, busy: state.busy));
    });
  }

  Future<void> restore() async {
    try {
      await service.restore();
    } catch (e, stackTrace) {
      // e.g. an unreadable keystore after a device restore: start signed out
      LoggerService.logError(e, stackTrace: stackTrace);
    }
  }

  /// Returns an error message, or null when signed in or cancelled.
  Future<String?> signIn() async {
    emit(AuthState(user: state.user, busy: true));
    try {
      await service.signIn();
      return null;
    } catch (e, stackTrace) {
      LoggerService.logError(e, stackTrace: stackTrace);
      return signInFailedMessage;
    } finally {
      if (!isClosed) emit(AuthState(user: service.currentUser));
    }
  }

  Future<void> signOut() async {
    emit(AuthState(user: state.user, busy: true));
    try {
      await service.signOut();
    } catch (e, stackTrace) {
      LoggerService.logError(e, stackTrace: stackTrace);
    } finally {
      if (!isClosed) emit(AuthState(user: service.currentUser));
    }
  }

  @override
  Future<void> close() async {
    await _userSubscription.cancel();
    return super.close();
  }
}
