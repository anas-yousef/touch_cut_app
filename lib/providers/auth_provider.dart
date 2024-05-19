// Authentication Provider
import 'package:flutter/material.dart';
import 'package:touch_cut_app/providers/internet_connection_provider.dart';

import '../services/api_client.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient apiClient;

  AuthProvider(this.apiClient);

  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;

  // Function to check token validity
  Future<bool?> checkUserIsLoggedIn({
    required InternetConnectionProvider internetConnectionProvider,
  }) async {
    // Use ApiClient's method to check if user is logged in
    final userIsLoggedIn = await apiClient.userIsLoggedIn(
      internetConnectionProvider: internetConnectionProvider,
    );
    _isLoggedIn = userIsLoggedIn ?? false;
    return userIsLoggedIn;
  }

  // Function to logout user
  Future<void> logout() async {
    await apiClient.clearAccessToken();
    await apiClient.clearRefreshToken();
    // Clear tokens and navigate to login page
    _isLoggedIn = false;
    // Notify listeners to update UI
    notifyListeners();
  }
}
