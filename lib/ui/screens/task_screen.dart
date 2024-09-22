import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class TaskScreen extends StatelessWidget {
  final AuthService _authService = AuthService();

  TaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Tareas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (context.mounted) { // Cambiado 'mounted' a 'context.mounted'
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Bienvenido a tu aplicación de tareas'),
      ),
    );
  }
}
