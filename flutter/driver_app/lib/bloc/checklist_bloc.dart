import 'package:flutter_bloc/flutter_bloc.dart';

// ── Events ──────────────────────────────────────────────
abstract class ChecklistEvent {}

class LoadChecklist extends ChecklistEvent {}

class UpdateChecklistItem extends ChecklistEvent {
  final String itemName;
  final String status; // 'ok', 'warning', 'fail'
  final String? photoPath;
  UpdateChecklistItem({required this.itemName, required this.status, this.photoPath});
}

class SubmitChecklist extends ChecklistEvent {
  final String tripId;
  SubmitChecklist({required this.tripId});
}

// ── States ──────────────────────────────────────────────
abstract class ChecklistState {}

class ChecklistLoading extends ChecklistState {}

class ChecklistLoaded extends ChecklistState {
  final List<Map<String, dynamic>> items;
  final bool isSubmitted;
  ChecklistLoaded({required this.items, this.isSubmitted = false});
}

class ChecklistError extends ChecklistState {
  final String message;
  ChecklistError(this.message);
}

class ChecklistSubmitted extends ChecklistState {}

// ── BLoC ────────────────────────────────────────────────
class ChecklistBloc extends Bloc<ChecklistEvent, ChecklistState> {
  static const _defaultItems = [
    'เบรค',
    'ยาง',
    'ไฟส่องสว่าง',
    'น้ำมันเครื่อง',
    'น้ำ radiator',
    'กระจก',
    'ไฟเบรค',
    'แตร',
  ];

  ChecklistBloc() : super(ChecklistLoading()) {
    on<LoadChecklist>(_onLoad);
    on<UpdateChecklistItem>(_onUpdate);
    on<SubmitChecklist>(_onSubmit);
  }

  Future<void> _onLoad(LoadChecklist event, Emitter<ChecklistState> emit) async {
    emit(ChecklistLoading());
    final items = _defaultItems
        .map((name) => {'name': name, 'status': 'ok', 'photo': null})
        .toList();
    emit(ChecklistLoaded(items: items));
  }

  Future<void> _onUpdate(
      UpdateChecklistItem event, Emitter<ChecklistState> emit) async {
    final current = state;
    if (current is! ChecklistLoaded) return;
    final updated = current.items.map((item) {
      if (item['name'] == event.itemName) {
        return {
          ...item,
          'status': event.status,
          'photo': event.photoPath ?? item['photo'],
        };
      }
      return item;
    }).toList();
    emit(ChecklistLoaded(items: updated));
  }

  Future<void> _onSubmit(
      SubmitChecklist event, Emitter<ChecklistState> emit) async {
    final current = state;
    if (current is! ChecklistLoaded) return;
    try {
      // TODO: POST /fleet/trips/:id checklist
      await Future.delayed(const Duration(milliseconds: 500));
      emit(ChecklistSubmitted());
    } catch (e) {
      emit(ChecklistError('บันทึก checklist ไม่สำเร็จ'));
    }
  }
}
