import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/store_cloud_phone.dart';
import '../services/cloud_phone_service.dart';

class StoreScreen extends StatefulWidget {
  final bool showAppBar;
  
  const StoreScreen({super.key, this.showAppBar = true});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final _cloudPhoneService = CloudPhoneService();
  List<StoreCloudPhone> _storePhones = [];
  bool _isLoading = true;
  String _errorMessage = '';
  
  // Biến để lưu trữ thông tin mua hàng
  int _selectedAmount = 1;
  int _selectedHours = 24;
  StoreCloudPhone? _selectedPhone;
  bool _isBuying = false;

  @override
  void initState() {
    super.initState();
    _loadStorePhones();
  }

  Future<void> _loadStorePhones() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    final result = await _cloudPhoneService.getStoreCloudPhones();
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success']) {
          _storePhones = result['data'];
        } else {
          _errorMessage = result['message'] ?? 'Không thể tải danh sách thiết bị';
        }
      });
    }
  }
  
  Future<void> _buyPhone(StoreCloudPhone phone) async {
    setState(() {
      _selectedPhone = phone;
      _isBuying = true;
    });
    
    // Hiển thị dialog để chọn số lượng và thời gian
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thuê ${phone.model}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Số lượng:'),
              trailing: DropdownButton<int>(
                value: _selectedAmount,
                items: List.generate(
                  phone.countDevice > 5 ? 5 : phone.countDevice,
                  (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text('${index + 1}'),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _selectedAmount = value!;
                  });
                },
              ),
            ),
            ListTile(
              title: const Text('Thời gian (giờ):'),
              trailing: DropdownButton<int>(
                value: _selectedHours,
                items: [
                  for (var hours in [24, 48, 72, 168, 720])
                    DropdownMenuItem(
                      value: hours,
                      child: Text('$hours'),
                    ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedHours = value!;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tổng tiền: ${_formatCurrency(phone.price * _selectedAmount * (_selectedHours / 24))}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _isBuying = false;
              });
            },
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _confirmPurchase();
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _confirmPurchase() async {
    if (_selectedPhone == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    final result = await _cloudPhoneService.buyCloudPhone(
      _selectedPhone!.id,
      _selectedAmount,
      _selectedHours,
    );
    
    setState(() {
      _isLoading = false;
      _isBuying = false;
    });
    
    if (result['success']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Thuê thiết bị thành công'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Làm mới danh sách sau khi mua
        _loadStorePhones();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Không thể thuê thiết bị'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return 'N/A';
    
    final amount = value is int ? value : (value is double ? value.toInt() : int.tryParse(value.toString()) ?? 0);
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    
    return '$formatted VNĐ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar ? AppBar(
        title: const Text('Cửa hàng', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStorePhones,
          ),
        ],
      ) : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage),
                      const SizedBox(height: 16),
                      ShadButton(
                        child: const Text('Thử lại'),
                        onPressed: _loadStorePhones,
                      ),
                    ],
                  ),
                )
              : _storePhones.isEmpty
                  ? const Center(child: Text('Không có thiết bị nào'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _storePhones.length,
                      itemBuilder: (context, index) {
                        final phone = _storePhones[index];
                        return ShadCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AspectRatio(
                                aspectRatio: 16 / 9,
                                child: phone.imagePreview.isNotEmpty
                                    ? Image.network(
                                        phone.imagePreview,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey[800],
                                            child: const Center(
                                              child: Icon(Icons.phone_android, size: 50),
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        color: Colors.grey[800],
                                        child: const Center(
                                          child: Icon(Icons.phone_android, size: 50),
                                        ),
                                      ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      phone.model,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Android ${phone.osVersion}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.memory, size: 14, color: Colors.grey[400]),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            phone.memoryInfo,
                                            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.storage, size: 14, color: Colors.grey[400]),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            phone.storageInfo,
                                            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _formatCurrency(phone.price),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Còn lại: ${phone.countDevice}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: phone.countDevice > 0 ? Colors.green : Colors.red,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ShadButton(
                                        onPressed: (phone.countDevice <= 0 || _isBuying) ? null : () => _buyPhone(phone),
                                        child: const Text('Thuê ngay'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
