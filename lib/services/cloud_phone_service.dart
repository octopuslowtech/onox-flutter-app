import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import '../models/cloud_phone.dart';
import 'auth_service.dart';

class CloudPhoneService {
  final String baseUrl = 'https://api.maxcloudphone.com/public/v1';
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> getMyCloudPhones() async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Không có token xác thực',
        };
      }


      final response = await http.get(
        Uri.parse('$baseUrl/CloudPhone/get-my-cloud-phone'),
        headers: {
          'Content-Type': 'application/json',
          'api_key': token,
        },
      );

      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200) {
        final List<CloudPhone> phones = (responseData['data'] as List)
            .map((item) => CloudPhone.fromJson(item))
            .toList();
            
        return {
          'success': true,
          'data': phones,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Lỗi khi lấy danh sách cloud phone',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi: ${e.toString()}',
      };
    }
  }
}
