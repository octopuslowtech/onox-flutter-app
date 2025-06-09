import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../services/auth_service.dart';
import '../services/cloud_phone_service.dart';
import '../models/cloud_phone.dart';
import 'control_phone_screen.dart';
import 'package:flutter/cupertino.dart';

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
        title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
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
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShadCard(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.account_circle, color: Colors.blue),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Thông tin tài khoản',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const SizedBox(height: 12),
                              _buildInfoRow('Email', _userData?['email']?.toString() ?? 'N/A', Icons.email),
                              _buildInfoRow('Số dư', _formatCurrency(_userData?['balance']), Icons.account_balance_wallet),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ShadCard(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.smartphone, color: Colors.green),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Cloud Phone',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.refresh, color: Colors.green),
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
                                            return Container(
                                              margin: const EdgeInsets.only(bottom: 12),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: Colors.grey.withOpacity(0.2)),
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [Colors.grey.withOpacity(0.05), Colors.black.withOpacity(0.1)],
                                                ),
                                              ),
                                              child: ListTile(
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                leading: Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: phone.isOnline ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Icon(
                                                    CupertinoIcons.device_phone_portrait,
                                                    color: phone.isOnline ? Colors.green : Colors.red,
                                                  ),
                                                ),
                                                title: Text(
                                                  phone.name,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                ),
                                                subtitle: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      phone.model,
                                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        Container(
                                                          width: 8,
                                                          height: 8,
                                                          decoration: BoxDecoration(
                                                            color: phone.isOnline ? Colors.green : Colors.red,
                                                            shape: BoxShape.circle,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          phone.isOnline ? 'Online' : 'Offline',
                                                          style: TextStyle(color: phone.isOnline ? Colors.green : Colors.red),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        const Icon(Icons.timer_outlined, size: 12, color: Colors.orange),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          'Còn lại: ${_getRemainingTime(phone.expiredDate)}',
                                                          style: const TextStyle(color: Colors.orange),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                trailing: phone.isOnline ? ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.blueGrey.withOpacity(0.2),
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  ),
                                                  icon: const Icon(Icons.visibility, size: 16),
                                                  label: const Text('Xem'),
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => ControlPhoneScreen(phone: phone),
                                                      ),
                                                    );
                                                  },
                                                ) : null,
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

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.withOpacity(0.1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[400], fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ],
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
  
  String _getRemainingTime(DateTime expiredDate) {
    final now = DateTime.now();
    if (expiredDate.isBefore(now)) {
      return 'Đã hết hạn';
    }
    
    final difference = expiredDate.difference(now);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} ngày';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút';
    } else {
      return '${difference.inSeconds} giây';
    }
  }
}
