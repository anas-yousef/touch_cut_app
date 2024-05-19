import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/internet_connection_provider.dart';

class NoInternetScreen extends StatefulWidget {
  final String? customBackPage;
  const NoInternetScreen({
    super.key,
    this.customBackPage,
  });

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen> {
  late bool _isConnected;
  late bool _checkingConnection;

  @override
  void initState() {
    super.initState();
    // Initially set connection status to false
    _isConnected = false;
    // Initially set checking connection to true
    _checkingConnection = true;
    // Check for internet connection when the screen is loaded
    _checkInternetConnection();
  }

  // Method to check internet connection
  Future<void> _checkInternetConnection() async {
    print('Checking internet connection');
    var connectivityResult = await Future<bool>.delayed(
        const Duration(milliseconds: 1000), () async {
      return await context
          .read<InternetConnectionProvider>()
          .checkInternetConnectivity();
    });
    // var connectivityResult = await widget.checkInternetConnectivity();
    setState(
      () {
        _isConnected = connectivityResult;
        _checkingConnection =
            false; // Set checking connection to false after checking
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _checkingConnection
                ? const CircularProgressIndicator() // Show circular progress indicator while checking connection
                : Text(
                    _isConnected ? 'Connected' : 'No internet connection',
                  ),
            ElevatedButton(
              onPressed: _checkingConnection
                  ? null
                  : () {
                      if (!_checkingConnection) {
                        setState(
                          () {
                            // Set checking connection to true when retry is pressed
                            _checkingConnection = true;
                          },
                        );
                        // Check internet connection again
                        _checkInternetConnection().then((_) {
                          if (_isConnected) {
                            // If internet connection is restored, pop the screen
                            widget.customBackPage == null
                                ? context.pop()
                                : context
                                    .pushReplacement(widget.customBackPage!);
                          } else {
                            // If no internet connection, do nothing
                          }
                        });
                      }
                    },
              child: _checkingConnection
                  ? Text('Checking...')
                  : _isConnected
                      ? Text('Connected, Retry')
                      : Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
