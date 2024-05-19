// Authentication Provider
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class InternetConnectionProvider extends ChangeNotifier {
  final Connectivity connectivity;

  InternetConnectionProvider() : connectivity = Connectivity();

  Future<bool> checkInternetConnectivity() async {
    final connectivityResult = await connectivity.checkConnectivity();
    return !connectivityResult.contains(ConnectivityResult.none);
  }
}
