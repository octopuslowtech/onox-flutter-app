import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/cloud_phone.dart';
import '../services/auth_service.dart';
import '../services/cloud_phone_service.dart';

class ControlPhoneScreen extends StatefulWidget {
  final CloudPhone phone;

  const ControlPhoneScreen({
    super.key,
    required this.phone,
  });

  @override
  State<ControlPhoneScreen> createState() => _ControlPhoneScreenState();
}

class _ControlPhoneScreenState extends State<ControlPhoneScreen> {
  final AuthService _authService = AuthService();
  final storage = const FlutterSecureStorage();
  late WebViewController _controller;
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic>? _phoneDetails;

  @override
  void initState() {
    super.initState();
    _loadPhoneDetails();
    _initWebView();
  }
  
  Future<void> _loadPhoneDetails() async {
    try {
      final cloudPhoneService = CloudPhoneService();
      final result = await cloudPhoneService.getCloudPhoneDetails(widget.phone.id);
      
      if (mounted) {
        setState(() {
          if (result['success']) {
            _phoneDetails = result['data'];
          }
        });
      }
    } catch (e) {
      // Xử lý lỗi nếu cần
    }
  }

  Future<void> _initWebView() async {
    final token = await _authService.getToken();
    if (token == null) {
      setState(() {
        _errorMessage = 'Không có token xác thực';
        _isLoading = false;
      });
      return;
    }

    // Lưu token vào cookie để WebView có thể sử dụng
    await storage.write(key: 'access_token', value: token);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Cập nhật tiến trình tải trang
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _errorMessage = 'Lỗi tải trang: ${error.description}';
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(
        Uri.parse('https://app.maxcloudphone.com/control-device?deviceId=${widget.phone.id}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Điều khiển ${widget.phone.name}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = '';
              });
              _initWebView();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          ShadCard(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tên: ${widget.phone.name}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ID: ${widget.phone.id}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (_phoneDetails != null) ...[  
                    const SizedBox(height: 8),
                    Text(
                      'Trạng thái: ${_phoneDetails!['status'] ?? 'Không có thông tin'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Phiên bản Android: ${_phoneDetails!['androidVersion'] ?? 'Không có thông tin'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
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
                              onPressed: () {
                                setState(() {
                                  _isLoading = true;
                                  _errorMessage = '';
                                });
                                _initWebView();
                              },
                            ),
                          ],
                        ),
                      )
                    : WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }
}
