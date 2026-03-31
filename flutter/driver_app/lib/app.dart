import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/trip_bloc.dart';
import 'bloc/gps_bloc.dart';
import 'bloc/expense_bloc.dart';
import 'bloc/checklist_bloc.dart';
import 'screens/home_screen.dart';

class DriverApp extends StatelessWidget {
  const DriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => TripBloc()),
        BlocProvider(create: (_) => GpsBloc()),
        BlocProvider(create: (_) => ExpenseBloc()),
        BlocProvider(create: (_) => ChecklistBloc()),
      ],
      child: MaterialApp(
        title: 'SML Fleet Driver',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: const ColorScheme(
            brightness: Brightness.light,
            primary: Color(0xFF1565C0),
            onPrimary: Colors.white,
            primaryContainer: Color(0xFFD1E4FF),
            onPrimaryContainer: Color(0xFF0D47A1),
            secondary: Color(0xFFFF8F00),
            onSecondary: Colors.white,
            secondaryContainer: Color(0xFFFFE0B2),
            onSecondaryContainer: Color(0xFFE65100),
            tertiary: Color(0xFF00897B),
            onTertiary: Colors.white,
            error: Color(0xFFD32F2F),
            onError: Colors.white,
            surface: Colors.white,
            onSurface: Color(0xFF212121),
            onSurfaceVariant: Color(0xFF616161),
            outline: Color(0xFFBDBDBD),
            outlineVariant: Color(0xFFE0E0E0),
            shadow: Color(0x33000000),
            inverseSurface: Color(0xFF303030),
            onInverseSurface: Colors.white,
            surfaceContainerHighest: Color(0xFFF5F5F5),
          ),
          useMaterial3: true,
          fontFamily: 'Sarabun',
          scaffoldBackgroundColor: const Color(0xFFF5F5F5),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 2,
            shadowColor: Color(0x40000000),
            backgroundColor: Color(0xFF1565C0),
            foregroundColor: Colors.white,
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: Colors.white,
            indicatorColor: const Color(0xFF1565C0).withValues(alpha: 0.15),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1565C0),
                );
              }
              return const TextStyle(
                fontSize: 12,
                color: Color(0xFF757575),
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(color: Color(0xFF1565C0));
              }
              return const IconThemeData(color: Color(0xFF757575));
            }),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shadowColor: const Color(0x30000000),
            surfaceTintColor: Colors.transparent,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
            ),
          ),
          dividerTheme: const DividerThemeData(
            color: Color(0xFFE0E0E0),
            thickness: 1,
          ),
        ),
        locale: const Locale('th', 'TH'),
        supportedLocales: const [
          Locale('th', 'TH'),
          Locale('en', 'US'),
        ],
        initialRoute: '/home',
        routes: {
          '/login': (_) => const HomeScreen(), // demo: skip login
          '/home': (_) => const HomeScreen(),
        },
      ),
    );
  }
}
