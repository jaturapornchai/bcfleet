// Placeholder BLoC file — will be replaced with actual BLoC/Cubit implementations
// when connecting to the Go backend API.
//
// Each feature will have its own BLoC in this directory:
//   - dashboard_bloc.dart
//   - vehicle_bloc.dart
//   - driver_bloc.dart
//   - trip_bloc.dart
//   - maintenance_bloc.dart
//   - partner_bloc.dart
//   - expense_bloc.dart
//   - alert_bloc.dart
//
// Pattern to use (flutter_bloc package):
//
// class VehicleBloc extends Bloc<VehicleEvent, VehicleState> {
//   final VehicleRepository _repo;
//
//   VehicleBloc(this._repo) : super(VehicleInitial()) {
//     on<LoadVehicles>(_onLoadVehicles);
//     on<CreateVehicle>(_onCreateVehicle);
//     on<UpdateVehicle>(_onUpdateVehicle);
//     on<DeleteVehicle>(_onDeleteVehicle);
//   }
//
//   Future<void> _onLoadVehicles(LoadVehicles event, Emitter<VehicleState> emit) async {
//     emit(VehicleLoading());
//     try {
//       final vehicles = await _repo.getVehicles(shopId: event.shopId);
//       emit(VehicleLoaded(vehicles));
//     } catch (e) {
//       emit(VehicleError(e.toString()));
//     }
//   }
// }

// Dependencies to add to pubspec.yaml when implementing:
//   flutter_bloc: ^8.1.3
//   equatable: ^2.0.5
//   dio: ^5.3.2
//   get_it: ^7.6.0  (service locator)
