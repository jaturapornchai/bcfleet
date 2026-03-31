import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/trip_bloc.dart';
import '../widgets/trip_card.dart';
import 'expense_screen.dart';
import 'repair_report_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _bottomNavIndex = 0;

  final List<Widget> _pages = const [
    _TripListPage(),
    ExpenseScreen(),
    RepairReportScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<TripBloc>().add(LoadTrips());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _bottomNavIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _bottomNavIndex,
        onDestinationSelected: (i) => setState(() => _bottomNavIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'หน้าหลัก',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'บันทึก',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_outlined),
            selectedIcon: Icon(Icons.build),
            label: 'แจ้งซ่อม',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'โปรไฟล์',
          ),
        ],
      ),
    );
  }
}

class _TripListPage extends StatelessWidget {
  const _TripListPage();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('BC Fleet Driver'),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {},
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'รอรับงาน'),
              Tab(text: 'กำลังวิ่ง'),
              Tab(text: 'เสร็จแล้ว'),
            ],
          ),
        ),
        body: BlocBuilder<TripBloc, TripState>(
          builder: (context, state) {
            if (state is TripLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is TripError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 8),
                    Text(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<TripBloc>().add(LoadTrips()),
                      child: const Text('ลองใหม่'),
                    ),
                  ],
                ),
              );
            }
            if (state is TripLoaded) {
              final pending = state.trips
                  .where((t) => ['pending', 'accepted'].contains(t['status']))
                  .toList();
              final inProgress = state.trips
                  .where((t) =>
                      ['started', 'arrived', 'delivering'].contains(t['status']))
                  .toList();
              final completed = state.trips
                  .where((t) => ['completed', 'cancelled'].contains(t['status']))
                  .toList();

              return TabBarView(
                children: [
                  _TripTab(trips: pending, emptyText: 'ไม่มีงานรอรับ'),
                  _TripTab(trips: inProgress, emptyText: 'ไม่มีงานที่กำลังวิ่ง'),
                  _TripTab(trips: completed, emptyText: 'ยังไม่มีงานที่เสร็จวันนี้'),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _TripTab extends StatelessWidget {
  final List<Map<String, dynamic>> trips;
  final String emptyText;

  const _TripTab({required this.trips, required this.emptyText});

  @override
  Widget build(BuildContext context) {
    if (trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_shipping_outlined,
                size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(emptyText,
                style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        context.read<TripBloc>().add(LoadTrips());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: trips.length,
        itemBuilder: (context, index) => TripCard(trip: trips[index]),
      ),
    );
  }
}
