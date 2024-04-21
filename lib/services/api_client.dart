import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

typedef TokenProvider = Future<String?> Function();

class ApiClient {
  final String baseUrl;
  final FlutterSecureStorage secureStorage;

  ApiClient({required this.baseUrl, required this.secureStorage});

  Future<String?> _getAccessToken() async {
    return await secureStorage.read(key: 'access_token');
  }

  Future<void> _saveAccessToken(String accessToken) async {
    await secureStorage.write(key: 'access_token', value: accessToken);
  }

  Future<void> _clearAccessToken() async {
    await secureStorage.delete(key: 'access_token');
  }

  Future<String?> _getRefreshToken() async {
    return await secureStorage.read(key: 'refresh_token');
  }

  Future<void> _saveRefreshToken(String refreshToken) async {
    await secureStorage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<void> _clearRefreshToken() async {
    await secureStorage.delete(key: 'refresh_token');
  }

  Future<void> _refreshAccessToken() async {
    final refreshToken = await _getRefreshToken();
    if (refreshToken != null) {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/auth/refresh'),
          body: {'refresh_token': refreshToken},
        );
        final responseData = jsonDecode(response.body) as Map<String, String>;
        if (response.statusCode == HttpStatus.ok) {
          // TODO Unite futures
          final newAccessToken = responseData['access_token'] as String;
          final refreshToken = responseData['refresh_token'] as String;
          await _saveAccessToken(newAccessToken);
          await _saveRefreshToken(refreshToken);
        } else {
          // Handle error response
          throw Exception(
              'Failed to refresh access token. ${response.statusCode}, error: ${responseData['error_message']}');
        }
      } catch (e) {
        // Handle network or server errors
        throw Exception('Failed to refresh access token: $e');
      }
    } else {
      // Handle case where refresh token is not available
      throw Exception('No refresh token available');
    }
  }

  Future<http.Response> _handleRequest(
    Future<http.Response> Function() requestFunction,
  ) async {
    try {
      final response = await requestFunction();
      if (response.statusCode == HttpStatus.unauthorized) {
        // Unauthorized, attempt to refresh token
        await _refreshAccessToken();
        // Retry request with new token
        return await requestFunction();
      }
      // else if (response.statusCode != HttpStatus.ok) {
      //   final responseData = jsonDecode(response.body) as Map<String, String>;
      //   throw Exception(
      //       'Error in request. ${response.statusCode}, error: ${responseData['error_message']}');
      // }
      return response;
    } on TimeoutException {
      throw Exception('Request timeout. Please try again');
    } catch (e) {
      // Handle network or server errors
      throw Exception('Failed to make request: $e');
    }
  }

  Future<http.Response> get(String path) async {
    return _handleRequest(() async {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        throw Exception('No access token available');
      }

      return await http.get(
        Uri.parse('$baseUrl$path'),
        headers: {
          // HttpHeaders.contentTypeHeader: ContentType.json.value,
          // HttpHeaders.acceptHeader: ContentType.json.value,
          'Authorization': 'Bearer $accessToken'
        },
      );
    });
  }

  Future<http.Response> post(String path,
      {required Map<String, dynamic> body}) async {
    return _handleRequest(() async {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        throw Exception('No access token available');
      }

      return await http.post(
        Uri.parse('$baseUrl$path'),
        headers: {
          HttpHeaders.contentTypeHeader: ContentType.json.value,
          // HttpHeaders.acceptHeader: ContentType.json.value,
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      );
    });
  }
}
