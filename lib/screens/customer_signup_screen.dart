import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomerSignUpScreen extends StatelessWidget {
  const CustomerSignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Customer Sign Up Screen',
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {},
              child: const Text(
                'Sign up',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                context.push('/customerSignInScreen');
              },
              child: const Text(
                'Sign in',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
