import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../services/auth_service.dart';
import '../services/cloud_phone_service.dart';
import '../models/cloud_phone.dart';
import 'control_phone_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _authService = AuthService();
  final _cloudPhoneService = CloudPhoneService();
  Map<String, dynamic>? _userData;
  List<CloudPhone> _cloudPhones = [];
  bool _isLoading = true;
  bool _isLoadingPhones = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCloudPhones();
  }

  Future<void> _loadUserData({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
    });

    final result = await _authService.getUserInfo(null, forceRefresh);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success']) {
          _userData = result['data'];
        }
      });
    }
  }
  
  Future<void> _loadCloudPhones() async {
    setState(() {
      _isLoadingPhones = true;
    });
    
    final result = await _cloudPhoneService.getMyCloudPhones();
    
    if (mounted) {
      setState(() {
        _isLoadingPhones = false;
        if (result['success']) {
          _cloudPhones = result['data'];
        }
      });
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MaxCloudPhone Dashboard'),
        actions: [
          ShadIconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userData == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Không thể tải thông tin người dùng'),
                      const SizedBox(height: 16),
                      ShadButton(
                        child: const Text('Thử lại'),
                        onPressed: _loadUserData,
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShadCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Thông tin tài khoản',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildInfoRow('Email', _userData?['email']?.toString() ?? 'N/A'),
                              _buildInfoRow('Số dư', _formatCurrency(_userData?['balance'])),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ShadCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Danh sách Cloud Phone',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  ShadIconButton(
                                    icon: const Icon(Icons.refresh),
                                    onPressed: _loadCloudPhones,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _isLoadingPhones
                                  ? const Center(child: CircularProgressIndicator())
                                  : _cloudPhones.isEmpty
                                      ? const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(16.0),
                                            child: Text('Không có Cloud Phone nào'),
                                          ),
                                        )
                                      : ListView.builder(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          itemCount: _cloudPhones.length,
                                          itemBuilder: (context, index) {
                                            final phone = _cloudPhones[index];
                                            return Card(
                                              margin: const EdgeInsets.only(bottom: 8),
                                              child: ListTile(
                                                title: Text(phone.name),
                                                subtitle: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text('Model: ${phone.model}'),
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          phone.isOnline ? Icons.check_circle : Icons.cancel,
                                                          color: phone.isOnline ? Colors.green : Colors.red,
                                                          size: 16,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(phone.isOnline ? 'Online' : 'Offline'),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                trailing: ShadButton(
                                                  child: const Text('View'),
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => ControlPhoneScreen(phone: phone),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
  
  String _formatCurrency(dynamic value) {
    if (value == null) return 'N/A';
    
    final amount = value is int ? value : int.tryParse(value.toString()) ?? 0;
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    
    return '$formatted VNĐ';
  }
  
  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return 'N/A';
    
    try {
      final date = DateTime.parse(dateStr.toString());
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
    } catch (e) {
      return dateStr.toString();
    }
  }
}
