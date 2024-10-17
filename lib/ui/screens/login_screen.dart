import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'package:app_tareas/ui/screens/register_screen.dart'; // Asegúrate de importar la pantalla de registro

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key}); // Convert 'key' to a super parameter

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _loginWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final user = await _authService.signInWithEmailAndPassword(email, password);
    if (user != null) {
      if (!mounted) return; // Check if the widget is still mounted
      Navigator.pushReplacementNamed(context, '/home');
    } else if (mounted) {
      // Verifica si el widget está montado
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Inicio de sesión fallido. Verifica tus credenciales.')),
      );
    }
  }

  void _loginWithGoogle() async {
    final user = await _authService.signInWithGoogle();
    if (user != null) {
      if (!mounted) return; // Check if the widget is still mounted
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      if (mounted) {
        // Verificar si el widget está montado
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al iniciar sesión con Google.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar sesión'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Añadir el logo aquí
            Image.asset(
              'assets/sunshine.png', // Ruta de tu logo
              height: 100, // Ajusta el tamaño según sea necesario
            ),
            const SizedBox(height: 20), // Espacio entre el logo y el formulario
            TextField(
              controller: _emailController,
              decoration:
                  const InputDecoration(labelText: 'Correo electrónico'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loginWithEmail,
              child: const Text('Iniciar sesión con correo'),
            ),
            ElevatedButton(
              onPressed: _loginWithGoogle,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // color del botón
              ),
              child: const Text('Iniciar sesión con Google'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RegisterScreen()),
                );
              },
              child: const Text('¿No tienes una cuenta? Regístrate aquí'),
            ),
          ],
        ),
      ),
    );
  }
}