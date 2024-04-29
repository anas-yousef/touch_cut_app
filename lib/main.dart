import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:touch_cut_app/screens/no_internet_screen.dart';
import 'package:touch_cut_app/services/api_client.dart';

import 'providers/auth_provider.dart';
import 'providers/internet_connection_provider.dart';

void main() {
  final apiClient = ApiClient(
    baseUrl: 'http://localhost:8080',
    secureStorage: const FlutterSecureStorage(),
    httpClient: http.Client(),
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => AuthProvider(apiClient),
        ),
        ChangeNotifierProvider(
          create: (context) => InternetConnectionProvider(),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  MyApp({
    super.key,
  });
  final _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          // Retrieve the callback from the state.extra and cast it
          return const MyHomePage(title: 'Flutter Demo Home Page');
        },
      ),
      GoRoute(
        path: '/noInternetScreen',
        builder: (BuildContext context, GoRouterState state) {
          // Retrieve the callback from the state.extra and cast it

          return const NoInternetScreen();
        },
      ),
    ],
  );
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({
    super.key,
    required this.title,
  });
  final String title;
  @override
  Widget build(BuildContext context) {
    final internetConnectionProvider =
        context.read<InternetConnectionProvider>();
    return Consumer(
      builder: (context, AuthProvider authProvider, _) {
        return FutureBuilder<bool?>(
          future: authProvider.checkUserIsLoggedIn(
            internetConnectionProvider: internetConnectionProvider,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Show loading indicator while checking token validity
              return const Center(child: CircularProgressIndicator());
            } else {
              if (snapshot.hasError) {
                // Handle error if any
                print(snapshot.error);
                return Scaffold(
                    appBar: AppBar(
                      title: Text('Home'),
                    ),
                    body: Center(
                        child: Text('Error occurred: ${snapshot.error}')));
              } else {
                final userIsLoggedIn = snapshot.data;
                if (userIsLoggedIn == null) {
                  // No internet connection
                  return const NoInternetScreen(customBackPage: '/');
                }
                // If user is not logged in, navigate to login page
                if (!snapshot.data!) {
                  // Replace the navigation logic with your own
                  // Navigator.pushReplacementNamed(context, '/login');
                  return LoginPage();
                }

                // If user is logged in, show the home page
                return Scaffold(
                  appBar: AppBar(
                    title: Text('Home'),
                  ),
                  body: Center(
                    child: Text('Welcome to the Home Page!'),
                  ),
                );
              }
            }
          },
        );
      },
    );
  }
}

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login Page'),
      ),
      body: Center(
        child: Text('Welcome to the Login Page!'),
      ),
    );
  }
}
