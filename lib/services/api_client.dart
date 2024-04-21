import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

typedef TokenProvider = Future<String?> Function();

class ApiClient {
  final String baseUrl;
  final FlutterSecureStorage secureStorage;
  final http.Client httpClient;

  const ApiClient(
      {required this.baseUrl,
      required this.secureStorage,
      required this.httpClient});

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
        final response = await httpClient.post(
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

  Future<http.Response> _authenticatedRequest(
    String method,
    String path, {
    int timeoutSeconds = 10, // Default timeout
    Map<String, dynamic>? body,
  }) async {
    final accessToken = await _getAccessToken();
    if (accessToken == null) {
      throw Exception('No access token available');
    }

    final request = http.Request(method, Uri.parse('$baseUrl$path'))
      ..headers['Authorization'] = 'Bearer $accessToken'
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode(body);

    // httpClient.send can be used to set a custom timeout
    final streamedResponse = await httpClient
        .send(request)
        .timeout(Duration(seconds: timeoutSeconds)); // Set timeout

    // Below method closes the connection after it has been used to create an http.Response object.
    // This method creates an http.Response object from a stream of bytes,
    // which allows us to read the response body asynchronously when needed.
    return http.Response.fromStream(streamedResponse);
  }

  Future<http.Response> get(String path) async {
    return _handleRequest(() async {
      return await _authenticatedRequest('GET', path);
    });
  }

  Future<http.Response> post(String path,
      {required Map<String, dynamic> body}) async {
    return _handleRequest(() async {
      return await _authenticatedRequest('POST', path, body: body);
    });
  }

  Future<http.Response> delete(String path) async {
    return _handleRequest(() async {
      return await _authenticatedRequest('DELETE', path);
    });
  }

  Future<http.Response> patch(String path,
      {required Map<String, dynamic> body}) async {
    return _handleRequest(() async {
      return await _authenticatedRequest('PATCH', path, body: body);
    });
  }

  Future<http.Response> put(String path,
      {required Map<String, dynamic> body}) async {
    return _handleRequest(() async {
      return await _authenticatedRequest('PUT', path, body: body);
    });
  }
}
