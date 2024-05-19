import 'package:flutter/material.dart';

class CustomerSignInScreen extends StatelessWidget {
  const CustomerSignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Customer Sign In Screen',
        ),
      ),
      body: Center(
        child: TextField(
          keyboardType: TextInputType.phone,
        ),
      ),
    );
  }
}

class CustomerSignInWidget extends StatefulWidget {
  const CustomerSignInWidget({super.key});

  @override
  State<CustomerSignInWidget> createState() => _CustomerSignInWidgetState();
}

class _CustomerSignInWidgetState extends State<CustomerSignInWidget> {
  late TextEditingController textEditingController;
  @override
  void initState() {
    super.initState();
    textEditingController = TextEditingController();
  }

  @override
  void dispose() {
    super.dispose();
    textEditingController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
