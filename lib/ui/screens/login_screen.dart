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
  bool _acceptedTerms =
      false; // Variable para controlar si se aceptan los términos

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
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
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
                        borderSide: const BorderSide(color: Color(0xFFC9C9CA)),
                      ),
                      labelStyle: const TextStyle(color: Color(0xFFC9C9CA)),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(
                        color: Color.fromARGB(255, 157, 157, 158)),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: const BorderSide(color: Color(0xFFC9C9CA)),
                      ),
                      labelStyle: const TextStyle(color: Color(0xFFC9C9CA)),
                    ),
                    obscureText: true,
                    style: const TextStyle(color: Color(0xFFC9C9CA)),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _acceptedTerms, // El valor viene de la variable
                        onChanged: (bool? value) {
                          setState(() {
                            _acceptedTerms = value ??
                                false; // Actualiza el estado del checkbox
                          });
                        },
                        activeColor: const Color.fromARGB(255, 230, 230, 230),
                        checkColor: const Color(0xFF6BCE81),
                        side: const BorderSide(color: Color(0xFFC9C9CA)),
                      ),
                      GestureDetector(
                        onTap: () {
                          _showTermsAndConditions(
                              context); // Llama al diálogo cuando se toque el texto
                        },
                        child: const Text(
                          'Acepto Términos y Condiciones',
                          style: TextStyle(
                            color: Color(0xFF6BCE81),
                          ),
                        ),
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
                      onPressed: _acceptedTerms
                          ? _loginWithEmail // Solo permite iniciar si aceptaron los términos
                          : null, // Si no, deshabilita el botón
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
                  const Text(
                    'Ingrese con su cuenta de Google',
                    style: TextStyle(color: Color(0xFFC9C9CA)),
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
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: '¿No tienes una cuenta? ',
                            style: TextStyle(color: Color(0xFFC9C9CA)),
                          ),
                          TextSpan(
                            text: 'Regístrate',
                            style: TextStyle(color: Color(0xFF0D4533)),
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
      ),
    );
  }
}

void _showTermsAndConditions(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0), // Bordes redondeados
        ),
        insetPadding: const EdgeInsets.all(20), // Espacio alrededor del diálogo
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 350, // Limitar el ancho máximo del diálogo
          ),
          child: Stack(
            clipBehavior: Clip
                .none, // Permite que el botón se muestre fuera del contenedor
            children: [
              const Padding(
                padding: EdgeInsets.all(20.0), // Padding interno del contenido
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 40), // Espacio para el botón de cerrar
                    Center(
                      child: Text(
                        'Términos y Condiciones',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Texto de la fecha de vigencia
                    Text(
                      'Fecha de entrada en vigencia:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      '02 de Octubre de 2024',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 15),

                    // Contenido de los términos y condiciones
                    Text(
                      'Bienvenido a Sunshine Note. Al acceder y utilizar la Aplicación, '
                      'aceptas cumplir con estos Términos y Condiciones de Uso. Si no '
                      'estás de acuerdo con alguno de estos Términos, por favor, no utilices la Aplicación.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 15),
                    Text(
                      '1. Aceptación de los Términos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Al registrarte en la Aplicación, confirmas que has leído, entendido y aceptas estos Términos, '
                      'así como nuestra Política de Privacidad.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),

              // Botón de cerrar circular
              Positioned(
                top: 15,
                right: 15,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop(); // Cerrar el diálogo
                  },
                  child: Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: const Color(0xFF97CE6B), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: const Offset(0, 4), // Sombra suave
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Color(0xFF97CE6B),
                      size: 25,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
