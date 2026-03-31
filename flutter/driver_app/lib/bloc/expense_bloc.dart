import 'package:flutter_bloc/flutter_bloc.dart';

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
      await Future.delayed(const Duration(milliseconds: 500));
      // TODO: เรียก GET /fleet/expenses
      emit(ExpenseLoaded([]));
    } catch (e) {
      emit(ExpenseError('โหลดข้อมูลไม่สำเร็จ'));
    }
  }

  Future<void> _onCreate(CreateExpense event, Emitter<ExpenseState> emit) async {
    try {
      // TODO: เรียก POST /fleet/expenses
      await Future.delayed(const Duration(milliseconds: 500));
      emit(ExpenseCreated());
      add(LoadExpenses());
    } catch (e) {
      emit(ExpenseError('บันทึกไม่สำเร็จ: ${e.toString()}'));
    }
  }
}
