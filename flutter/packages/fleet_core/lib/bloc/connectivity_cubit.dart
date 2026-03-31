import 'package:flutter_bloc/flutter_bloc.dart';

/// ConnectivityCubit — ตรวจสอบสถานะ internet
/// ใช้สำหรับ offline support ใน driver app
class ConnectivityCubit extends Cubit<ConnectivityState> {
  ConnectivityCubit() : super(ConnectivityState.online);

  void setOnline() => emit(ConnectivityState.online);
  void setOffline() => emit(ConnectivityState.offline);

  bool get isOnline => state == ConnectivityState.online;
}

enum ConnectivityState { online, offline }
