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
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            constraints: BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/sunshine.png',
                  height: 280,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Ingrese correo electrónico',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide(color: const Color(0xFFC9C9CA)),
                    ),
                    labelStyle: TextStyle(color: const Color(0xFFC9C9CA)),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(
                      color: const Color.fromARGB(255, 157, 157, 158)),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide(color: const Color(0xFFC9C9CA)),
                    ),
                    labelStyle: TextStyle(color: const Color(0xFFC9C9CA)),
                  ),
                  obscureText: true,
                  style: TextStyle(color: const Color(0xFFC9C9CA)),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: false,
                      onChanged: (bool? value) {
                        // Manejar el cambio de estado del checkbox
                      },
                      activeColor: const Color(0xFFC9C9CA),
                      checkColor: Colors.black,
                      side: BorderSide(color: const Color(0xFFC9C9CA)),
                    ),
                    Text(
                      'Acepto Términos y Condiciones',
                      style: TextStyle(color: const Color(0xFF6BCE81)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: const Color(0xFFFFEE93), width: 2),
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  child: ElevatedButton(
                    onPressed: _loginWithEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB7F6E3),
                      foregroundColor: Colors.black,
                      minimumSize: const Size(200, 50),
                      shadowColor: Colors.transparent,
                    ),
                    child: const Text('Iniciar'),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Ingrese con su cuenta de Google',
                  style: TextStyle(color: const Color(0xFFC9C9CA)),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loginWithGoogle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 8, 155, 131),
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
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '¿No tienes una cuenta? ',
                          style: TextStyle(color: const Color(0xFFC9C9CA)),
                        ),
                        TextSpan(
                          text: 'Regístrate',
                          style: TextStyle(color: const Color(0xFF0D4533)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
