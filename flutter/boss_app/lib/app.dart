import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/dashboard_bloc.dart';
import 'bloc/vehicle_bloc.dart';
import 'bloc/trip_bloc.dart';
import 'bloc/maintenance_bloc.dart';
import 'bloc/partner_bloc.dart';
import 'bloc/alert_bloc.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

// ─── Responsive Breakpoints ───────────────────────────────────────────────────
class Responsive {
  static const double mobileMax = 600;
  static const double tabletMax = 1024;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileMax;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= mobileMax && w < tabletMax;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletMax;

  static bool isTabletOrDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileMax;

  /// padding: 8 mobile, 16 tablet, 24 desktop
  static double padding(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= tabletMax) return 24;
    if (w >= mobileMax) return 16;
    return 8;
  }

  /// crossAxisCount for grid layouts
  static int gridColumns(BuildContext context, {int mobile = 1, int tablet = 2, int desktop = 3}) {
    final w = MediaQuery.of(context).size.width;
    if (w >= tabletMax) return desktop;
    if (w >= mobileMax) return tablet;
    return mobile;
  }
}

class BossApp extends StatelessWidget {
  const BossApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => DashboardBloc()),
        BlocProvider(create: (_) => VehicleBloc()),
        BlocProvider(create: (_) => TripBloc()),
        BlocProvider(create: (_) => MaintenanceBloc()),
        BlocProvider(create: (_) => PartnerBloc()),
        BlocProvider(create: (_) => AlertBloc()),
      ],
      child: MaterialApp(
        title: 'SML Fleet Boss',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(Brightness.light),
        darkTheme: _buildTheme(Brightness.dark),
        themeMode: ThemeMode.system,
        locale: const Locale('th', 'TH'),
        home: const DashboardScreen(),
        routes: {
          '/login': (_) => const LoginScreen(),
          '/dashboard': (_) => const DashboardScreen(),
        },
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1565C0), // เพิ่มความน่าเชื่อถือ
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Sarabun',
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
