import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:awesome_flutter_extensions/awesome_flutter_extensions.dart';
import 'dashboard_screen.dart';
import 'store_screen.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const DashboardScreen(showAppBar: false),
    const StoreScreen(showAppBar: false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentIndex == 0 ? 'Dashboard' : 'Cửa hàng',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Cửa hàng',
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Xác nhận đăng xuất'),
        description: const Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng không?',
        ),
        actions: [
          ShadButton.outline(
            child: const Text('Hủy'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ShadButton(
            child: const Text('Đăng xuất'),
            onPressed: () async {
              Navigator.of(context).pop();
              await _authService.logout();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
    );
  }
}
