import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:webview_flutter/webview_flutter.dart';
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
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36')
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {},
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
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      ) 
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
        title: Text(widget.phone.name),
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
