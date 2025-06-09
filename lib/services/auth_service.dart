import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const String baseUrl = 'https://api.maxcloudphone.com';
  final storage = const FlutterSecureStorage();
  
  // Lưu thông tin người dùng vào secure storage
  Future<void> saveUserInfo(Map<String, dynamic> userData) async {
    await storage.write(key: 'user_email', value: userData['email']?.toString());
    await storage.write(key: 'user_balance', value: userData['balance']?.toString());
    await storage.write(key: 'user_createAt', value: userData['createAt']?.toString());
    await storage.write(key: 'last_updated', value: DateTime.now().toIso8601String());
  }
  
  // Lấy thông tin người dùng từ secure storage
  Future<Map<String, dynamic>?> getCachedUserInfo() async {
    final email = await storage.read(key: 'user_email');
    final balance = await storage.read(key: 'user_balance');
    final createAt = await storage.read(key: 'user_createAt');
    final lastUpdated = await storage.read(key: 'last_updated');
    
    if (email != null && balance != null) {
      return {
        'email': email,
        'balance': int.tryParse(balance) ?? 0,
        'createAt': createAt,
        'lastUpdated': lastUpdated,
      };
    }
    
    return null;
  }
  
  Future<Map<String, dynamic>> loginWithToken(String token) async {
    try {
      // Lưu token vào secure storage
      await storage.write(key: 'api_token', value: token);
      
      // Kiểm tra token bằng cách gọi API get-info
      final result = await getUserInfo(token);
      
      if (result['success']) {
        return {
          'success': true,
          'data': result['data'],
        };
      } else {
        // Xóa token nếu không hợp lệ
        await storage.delete(key: 'api_token');
        return {
          'success': false,
          'message': result['message'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> getUserInfo([String? token]) async {
    final storedToken = token ?? await storage.read(key: 'api_token');
    
    if (storedToken == null) {
      return {
        'success': false,
        'message': 'Không tìm thấy token',
      };
    }
    
    // Luôn lấy dữ liệu mới của user
    
    final url = Uri.parse('$baseUrl/public/v1/CloudPhone/get-info');
    
    try {
      final response = await http.get(
        url,
        headers: {
          'api_key': storedToken,
        },
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200 && responseData['succeeded'] == true) {
        
        // Lưu thông tin người dùng vào secure storage
        if (responseData['data'] != null) {
          await saveUserInfo(responseData['data']);
        }
        
        return {
          'success': true,
          'data': responseData['data'],
        };
      } else {
        String errorMessage = 'Không thể lấy thông tin người dùng';
        if (responseData['message'] != null) {
          errorMessage = responseData['message'];
        }
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }
  
  Future<bool> isLoggedIn() async {
    final token = await storage.read(key: 'api_token');
    return token != null;
  }
  
  Future<String?> getToken() async {
    return await storage.read(key: 'api_token');
  }
  
  Future<void> logout() async {
    await storage.delete(key: 'api_token');
  }
}
