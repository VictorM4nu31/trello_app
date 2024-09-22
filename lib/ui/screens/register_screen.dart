import 'package:flutter/material.dart';

class RegisterScreen extends StatelessWidget {
  // Añadir el constructor con el parámetro 'key'
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: const Center(
        child: Text('Register Screen'),
      ),
    );
  }
}
