import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/auth_service.dart'; // Importa tu AuthService
import 'task_screen.dart'; // Importa TaskScreen
import 'package:cloud_firestore/cloud_firestore.dart'; // Importa Firestore

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  RegisterScreenState createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> {
  final _authService = AuthService(); // Instancia del servicio de autenticación
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  final _formKey = GlobalKey<FormState>();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  void _register() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Las contraseñas no coinciden')),
        );
        return;
      }

      final user = await _authService.registerWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
      );

      if (user != null) {
        // Guarda el perfil del usuario en Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'name': _nameController.text,
          'surname': _surnameController.text,
          'email': _emailController.text,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuario registrado con éxito')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const TaskScreen()),
          );
        }
      }
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese un correo electrónico';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Por favor ingrese un correo electrónico válido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese una contraseña';
    }
    if (value.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left,
            size: 45,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            constraints: BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFFFFFFF),
                            const Color(0xFF5BC0A0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFFEE93),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: _profileImage != null
                            ? Image.file(
                                _profileImage!,
                                fit: BoxFit.cover,
                                width: 160,
                                height: 160,
                              )
                            : const Icon(
                                Icons.add_circle_outline,
                                size: 70,
                                color: Color(0xFF5BC0A0),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  const Text(
                    'Agregar foto de perfil',
                    style: TextStyle(color: Color(0xFF827A7A)),
                  ),
                  const SizedBox(height: 50),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nombre',
                      labelStyle: TextStyle(color: const Color(0xFFC9C9CA)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide(color: const Color(0xFFC9C9CA)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide(color: const Color(0xFFC9C9CA)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide(color: const Color(0xFFC9C9CA)),
                      ),
                    ),
                    style: TextStyle(
                        color: const Color.fromARGB(255, 125, 125, 125)),
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _surnameController,
                    decoration: InputDecoration(
                      labelText: 'Apellidos',
                      labelStyle: TextStyle(color: const Color(0xFFC9C9CA)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide(color: const Color(0xFFC9C9CA)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide(color: const Color(0xFFC9C9CA)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide(color: const Color(0xFFC9C9CA)),
                      ),
                    ),
                    style: TextStyle(
                        color: const Color.fromARGB(255, 125, 125, 125)),
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Correo Electrónico',
                      labelStyle: TextStyle(color: const Color(0xFFC9C9CA)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide(color: const Color(0xFFC9C9CA)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide(color: const Color(0xFFC9C9CA)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide(color: const Color(0xFFC9C9CA)),
                      ),
                    ),
                    style: TextStyle(
                        color: const Color.fromARGB(255, 125, 125, 125)),
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      labelStyle: TextStyle(color: const Color(0xFFC9C9CA)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide(color: const Color(0xFFC9C9CA)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide(color: const Color(0xFFC9C9CA)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide(color: const Color(0xFFC9C9CA)),
                      ),
                    ),
                    style: TextStyle(
                        color: const Color.fromARGB(255, 125, 125, 125)),
                    obscureText: true,
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Confirmar Contraseña',
                      labelStyle: TextStyle(color: const Color(0xFFC9C9CA)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide(color: const Color(0xFFC9C9CA)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide(color: const Color(0xFFC9C9CA)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide(color: const Color(0xFFC9C9CA)),
                      ),
                    ),
                    style: TextStyle(
                        color: const Color.fromARGB(255, 125, 125, 125)),
                    obscureText: true,
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 32.0),
                  ElevatedButton(
                    onPressed: _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB7F6E3),
                      foregroundColor: Colors.black,
                      minimumSize: const Size(200, 50),
                      side:
                          BorderSide(color: const Color(0xFFFFEE93), width: 2),
                    ),
                    child: const Text(
                      'Registrar',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
<<<<<<< HEAD
}
=======
}
>>>>>>> 099dea1da43cf48bee5eebb03701eedb52af4b1c
