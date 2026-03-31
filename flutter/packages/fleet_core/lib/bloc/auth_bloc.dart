import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../services/auth_service.dart';

// === Events ===
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthOTPRequested extends AuthEvent {
  final String phone;
  AuthOTPRequested(this.phone);
  @override
  List<Object?> get props => [phone];
}

class AuthLoginRequested extends AuthEvent {
  final String phone;
  final String otp;
  AuthLoginRequested(this.phone, this.otp);
  @override
  List<Object?> get props => [phone, otp];
}

class AuthLogoutRequested extends AuthEvent {}

// === States ===
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthOTPSent extends AuthState {}
class AuthAuthenticated extends AuthState {
  final AuthResult user;
  AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}
class AuthUnauthenticated extends AuthState {}
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

// === BLoC ===
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc(this._authService) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthOTPRequested>(_onOTPRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onCheckRequested(AuthCheckRequested event, Emitter<AuthState> emit) async {
    final token = await _authService.getSavedToken();
    if (token != null) {
      // TODO: verify token validity
      emit(AuthUnauthenticated()); // ยังไม่ได้ implement token verify
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onOTPRequested(AuthOTPRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authService.requestOTP(event.phone);
      emit(AuthOTPSent());
    } catch (e) {
      emit(AuthError('ส่ง OTP ไม่สำเร็จ: $e'));
    }
  }

  Future<void> _onLoginRequested(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final result = await _authService.loginWithOTP(event.phone, event.otp);
      emit(AuthAuthenticated(result));
    } catch (e) {
      emit(AuthError('เข้าสู่ระบบไม่สำเร็จ: $e'));
    }
  }

  Future<void> _onLogoutRequested(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    await _authService.logout();
    emit(AuthUnauthenticated());
  }
}
