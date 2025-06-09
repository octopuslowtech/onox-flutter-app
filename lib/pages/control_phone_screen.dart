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
    String? token = await _authService.getToken();
    if (token == null) {
      setState(() {
        _errorMessage = 'Không có token xác thực';
        _isLoading = false;
      });
      return;
    }
     token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJodHRwOi8vc2NoZW1hcy54bWxzb2FwLm9yZy93cy8yMDA1LzA1L2lkZW50aXR5L2NsYWltcy9uYW1laWRlbnRpZmllciI6ImQ0YzA4MmMxLTY4MDYtNDM1MS02NDc4LTA4ZGFmNjllOTIyOSIsImh0dHA6Ly9zY2hlbWFzLnhtbHNvYXAub3JnL3dzLzIwMDUvMDUvaWRlbnRpdHkvY2xhaW1zL2VtYWlsYWRkcmVzcyI6Im9jdG9wdXNsb3d0ZWNoQGdtYWlsLmNvbSIsIlBlcm1pc3Npb24iOlsiUGVybWlzc2lvbnMuQWRtaW4iLCJQZXJtaXNzaW9ucy5NYW5hZ2VyIiwiUGVybWlzc2lvbnMuRGV2ZWxvcGVyIiwiUGVybWlzc2lvbnMuQW5kcm9pZCIsIlBlcm1pc3Npb25zLk1lbWJlci5DaGFuZ2VCYWNrZ3JvdW5kIiwiUGVybWlzc2lvbnMuTWVtYmVyLkRlYnVnIiwiUGVybWlzc2lvbnMuRmFjZWJvb2suVmlldyIsIlBlcm1pc3Npb25zLkZhY2Vib29rLkVkaXQiLCJQZXJtaXNzaW9ucy5GYWNlYm9vay5TY3JpcHQiLCJQZXJtaXNzaW9ucy5UaWt0b2suVmlldyIsIlBlcm1pc3Npb25zLlRpa3Rvay5FZGl0IiwiUGVybWlzc2lvbnMuVGlrdG9rLlNjcmlwdCIsIlBlcm1pc3Npb25zLlR3aXR0ZXIuVmlldyIsIlBlcm1pc3Npb25zLlR3aXR0ZXIuRWRpdCIsIlBlcm1pc3Npb25zLlR3aXR0ZXIuU2NyaXB0IiwiUGVybWlzc2lvbnMuSW5zdGFncmFtLlZpZXciLCJQZXJtaXNzaW9ucy5JbnN0YWdyYW0uRWRpdCIsIlBlcm1pc3Npb25zLkluc3RhZ3JhbS5TY3JpcHQiLCJQZXJtaXNzaW9ucy5UaHJlYWRzLlZpZXciLCJQZXJtaXNzaW9ucy5UaHJlYWRzLkVkaXQiLCJQZXJtaXNzaW9ucy5UaHJlYWRzLlNjcmlwdCIsIlBlcm1pc3Npb25zLk1lbWJlci5HYWxsZXJ5Il0sImV4cCI6MTc0OTQ1NzE4NX0.8QyL0nvW-x19iKMIk3tTd0IiXZw4up8ApQaLeuW_GSg';
    // Lưu token vào cookie để WebView có thể sử dụng
    await storage.write(key: 'access_token', value: token);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      // Thêm cấu hình User-Agent để tránh bị chặn
      ..setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36')
      // Cho phép truy cập nội dung không an toàn
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
          // Thêm xử lý cho các yêu cầu không an toàn
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      // Thêm cấu hình cho WebView
      ..enableZoom(true)
      ..loadRequest(
        Uri.parse('https://app.maxcloudphone.com/shared-view?deviceId=${widget.phone.id}&apiToken=${token}'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.9',
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
