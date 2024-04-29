import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:touch_cut_app/providers/internet_connection_provider.dart';

typedef TokenProvider = Future<String?> Function();

class AccessTokenNotFoundException implements Exception {
  const AccessTokenNotFoundException({
    this.errorMessage,
  });
  final String? errorMessage;
  @override
  String toString() {
    return errorMessage ?? 'Access token was not found in local storage';
  }
}

class AccessTokenCantRefresh implements Exception {
  const AccessTokenCantRefresh({
    this.errorMessage,
  });
  final String? errorMessage;
  @override
  String toString() {
    return errorMessage ?? 'Access token was not refreshed';
  }
}

class RefreshTokenNotFoundException implements Exception {
  const RefreshTokenNotFoundException({
    this.errorMessage,
  });
  final String? errorMessage;
  @override
  String toString() {
    return errorMessage ?? 'Refresh token was not found in local storage';
  }
}

class ApiClient {
  final String baseUrl;
  final FlutterSecureStorage secureStorage;
  final http.Client httpClient;
  final Connectivity connectivity;
  ApiClient({
    required this.baseUrl,
    required this.secureStorage,
    required this.httpClient,
  }) : connectivity = Connectivity();

  Future<String?> _getAccessToken() async {
    return await secureStorage.read(key: 'access_token');
  }

  Future<void> _saveAccessToken(String accessToken) async {
    await secureStorage.write(key: 'access_token', value: accessToken);
  }

  Future<void> clearAccessToken() async {
    await secureStorage.delete(key: 'access_token');
  }

  Future<String?> _getRefreshToken() async {
    return await secureStorage.read(key: 'refresh_token');
  }

  Future<void> _saveRefreshToken(String refreshToken) async {
    await secureStorage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<void> clearRefreshToken() async {
    await secureStorage.delete(key: 'refresh_token');
  }

  Future<void> _refreshAccessToken() async {
    print('Refershing access token');
    final refreshToken = await _getRefreshToken();
    if (refreshToken != null) {
      try {
        final response = await httpClient.post(
          Uri.parse('$baseUrl/api/auth/refresh'),
          body: jsonEncode({'refresh_token': refreshToken}),
          headers: {
            HttpHeaders.contentTypeHeader: ContentType.json.value,
          },
        );
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (response.statusCode == HttpStatus.ok) {
          // TODO Unite futures
          final newAccessToken = responseData['access_token'] as String;
          final refreshToken = responseData['refresh_token'] as String;
          await _saveAccessToken(newAccessToken);
          await _saveRefreshToken(refreshToken);
        } else {
          // Handle error response
          throw AccessTokenCantRefresh(
              errorMessage:
                  'Failed to refresh access token. ${response.statusCode}, error: ${responseData['error_message']}');
        }
      } catch (e) {
        print('Failed to refresh access token: $e');
        // Handle network or server errors
        rethrow;
      }
    } else {
      // Handle case where refresh token is not available
      throw const RefreshTokenNotFoundException();
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
      throw TimeoutException('Request timeout. Please try again');
    } catch (e) {
      // Handle network or server errors
      rethrow;
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
      throw const AccessTokenNotFoundException();
    }

    print('Doing request to $baseUrl$path');
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

  Future<bool?> userIsLoggedIn({
    required InternetConnectionProvider internetConnectionProvider,
  }) async {
    try {
      final response = await makeRequest(
        method: 'GET',
        path: '/api/v1/validateToken',
        internetConnectionProvider: internetConnectionProvider,
      );
      if (response == null) {
        return null;
      }
      if (response.statusCode == HttpStatus.ok) {
        return true;
      }
    } on TimeoutException {
      throw TimeoutException('Request timeout. Please try again');
    } catch (e) {
      print('Got exception when validating user session, $e');
      if (e is AccessTokenCantRefresh ||
          e is AccessTokenNotFoundException ||
          e is RefreshTokenNotFoundException) {
        return false;
      }
      rethrow;
    }
    return false;
  }

  Future<http.Response?> makeRequest({
    required InternetConnectionProvider internetConnectionProvider,
    required String method, // HTTP method type: GET, DELETE, PATCH, PUT, POST
    required String path,
    Map<String, dynamic>? body,
  }) async {
    bool isConnected =
        await internetConnectionProvider.checkInternetConnectivity();
    if (!isConnected) {
      // Return null as the response since there's no internet connection
      return null;
    }

    try {
      final http.Response response;
      switch (method) {
        case 'GET':
          response = await get(path);
          break;
        case 'DELETE':
          response = await delete(path);
          break;
        case 'PATCH':
          response = await patch(path, body: body!);
          break;
        case 'PUT':
          response = await put(path, body: body!);
          break;
        case 'POST':
          response = await post(path, body: body!);
          break;
        default:
          throw ArgumentError('Invalid HTTP method: $method');
      }

      // Handle response here
      return response;
    } catch (e) {
      // Handle other exceptions
      print('Error when making request: $e');
      rethrow;
    }
  }

// Future<Map<String, dynamic>> get(String chatRoomId) async {
//     final uri = Uri.parse('$_baseUrl/chat-rooms/id/$chatRoomId/messages');
//     final response = await _handleRequest(
//         (headers) => _httpClient.get(uri, headers: headers));
//     return response;
//   }
}
