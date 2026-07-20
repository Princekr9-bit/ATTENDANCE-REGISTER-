import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme.dart';
import '../attendance/attendance_screen.dart';
import '../payments/payments_screen.dart';
import '../workers/workers_screen.dart';
import 'dashboard_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  static const _titles = ['Dashboard', 'Attendance', 'Workers', 'Payments'];

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final tabs = [
      const DashboardTab(),
      const AttendanceScreen(),
      const WorkersScreen(),
      const PaymentsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nirman Manager',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            Text(
              _titles[_tab],
              style: const TextStyle(fontSize: 12, color: Color(0xFFAEB9CE)),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.orange,
              backgroundImage: user?.photoURL != null
                  ? NetworkImage(user!.photoURL!)
                  : null,
              child: user?.photoURL == null
                  ? Text(
                      _initial(user?.displayName ?? user?.phoneNumber ?? 'U'),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700),
                    )
                  : null,
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Text(
                  user?.displayName ?? user?.email ?? user?.phoneNumber ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'logout') AuthService.instance.signOut();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(index: _tab, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.fact_check_outlined), label: 'Hazri'),
          NavigationDestination(
              icon: Icon(Icons.groups_outlined), label: 'Workers'),
          NavigationDestination(
              icon: Icon(Icons.currency_rupee), label: 'Payments'),
        ],
      ),
    );
  }

  String _initial(String s) => s.isEmpty ? 'U' : s.characters.first.toUpperCase();
}
