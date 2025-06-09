import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  bool _isLoading = false;
  final _authService = AuthService();

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.loginWithToken(
        _tokenController.text.trim(),
      );

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng nhập thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        // Chuyển đến màn hình dashboard
        Navigator.of(context).pushReplacementNamed('/dashboard');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Đăng nhập thất bại'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo
                    Image.asset(
                      'assets/images/logo.png',
                      height: 100,
                    ),
                    const SizedBox(height: 24),

                    // Tiêu đề
                    Text(
                      'MaxCloudPhone',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Đăng nhập để tiếp tục',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 32),

                    // Token input
                    ShadInput(
                      controller: _tokenController,
                      placeholder: const Text('Nhập token của bạn'),
                      leading: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(Icons.key),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _tokenController,
                      builder: (context, value, child) {
                        if (value.text.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.only(left: 12),
                            child: Text(
                              'Vui lòng nhập token',
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    const SizedBox(height: 32),

                    // Login button
                    _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : ShadButton(
                            onPressed: _login,
                            size: ShadButtonSize.lg,
                            child: const Text('Đăng nhập'),
                          ),
                    
                    const SizedBox(height: 16),
                    
                    // Link to get token
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Chưa có token? '),
                        InkWell(
                          onTap: () async {
                            // Mở trang web để lấy token bằng url_launcher
                            final Uri url = Uri.parse('https://app.maxcloudphone.com');
                            if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Không thể mở trang web'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          child: Text(
                            'Lấy token tại đây',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
