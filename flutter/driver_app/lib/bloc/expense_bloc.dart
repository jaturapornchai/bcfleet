import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

const _apiBase = 'https://smlfleet.satistang.com/api/v1/fleet';

// ── Events ──────────────────────────────────────────────
abstract class ExpenseEvent {}

class LoadExpenses extends ExpenseEvent {
  final String? tripId;
  LoadExpenses({this.tripId});
}

class CreateExpense extends ExpenseEvent {
  final Map<String, dynamic> data;
  CreateExpense(this.data);
}

// ── States ──────────────────────────────────────────────
abstract class ExpenseState {}

class ExpenseLoading extends ExpenseState {}

class ExpenseLoaded extends ExpenseState {
  final List<Map<String, dynamic>> expenses;
  ExpenseLoaded(this.expenses);
}

class ExpenseError extends ExpenseState {
  final String message;
  ExpenseError(this.message);
}

class ExpenseCreated extends ExpenseState {}

// ── BLoC ────────────────────────────────────────────────
class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  ExpenseBloc() : super(ExpenseLoading()) {
    on<LoadExpenses>(_onLoad);
    on<CreateExpense>(_onCreate);
  }

  Future<void> _onLoad(LoadExpenses event, Emitter<ExpenseState> emit) async {
    emit(ExpenseLoading());
    try {
      final uri = event.tripId != null
          ? Uri.parse('$_apiBase/expenses?trip_id=${event.tripId}&limit=50')
          : Uri.parse('$_apiBase/expenses?limit=50');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final data =
            (body['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        emit(ExpenseLoaded(data));
      } else {
        emit(ExpenseError('API error: ${response.statusCode}'));
      }
    } catch (e) {
      emit(ExpenseError('โหลดข้อมูลไม่สำเร็จ: $e'));
    }
  }

  Future<void> _onCreate(
      CreateExpense event, Emitter<ExpenseState> emit) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiBase/expenses'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(event.data),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        emit(ExpenseCreated());
        add(LoadExpenses());
      } else {
        emit(ExpenseError('บันทึกไม่สำเร็จ: ${response.statusCode}'));
      }
    } catch (e) {
      emit(ExpenseError('บันทึกไม่สำเร็จ: $e'));
    }
  }
}
