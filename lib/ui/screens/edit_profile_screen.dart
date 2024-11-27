import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logger/logger.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen(
      {super.key, User? currentUser, required String userId});

  @override
  EditProfileScreenState createState() => EditProfileScreenState();
}

class EditProfileScreenState extends State<EditProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _photoUrl;
  File? _profileImage;

  final Logger logger = Logger();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userProfile =
          await _firestore.collection('users').doc(user.uid).get();
      _nameController.text = userProfile['name'] ?? '';
      _surnameController.text = userProfile['surname'] ?? '';
      _emailController.text = user.email ?? '';
      
      final data = userProfile.data() as Map<String, dynamic>?;
      if (data != null && data.containsKey('photoUrl')) {
        _photoUrl = data['photoUrl'];
      } else {
        _photoUrl = null;
      }
      
      setState(() {});
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  void _updateProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        // Reautenticación
        if (_passwordController.text.isNotEmpty) {
          final credential = EmailAuthProvider.credential(
            email: user.email!,
            password: _passwordController.text, // Contraseña actual
          );

          await user.reauthenticateWithCredential(credential);
        }

        // Actualizar imagen de perfil
        if (_profileImage != null) {
          final ref = _storage.ref().child('profile_images/${user.uid}');
          await ref.putFile(_profileImage!);
          _photoUrl = await ref.getDownloadURL();
          
          await _firestore.collection('users').doc(user.uid).update({
            'photoUrl': _photoUrl,
          });
        }

        // Actualizar contraseña
        if (_passwordController.text.isNotEmpty) {
          await user.updatePassword(_passwordController.text);
        }

        // Actualizar correo electrónico
        if (_emailController.text.isNotEmpty && _emailController.text != user.email) {
          await user.verifyBeforeUpdateEmail(_emailController.text);
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Se ha enviado un correo de verificación. Por favor, verifique su nuevo correo electrónico.')),
          );
        }

        // Actualizar nombre y apellidos
        await _firestore.collection('users').doc(user.uid).update({
          'name': _nameController.text,
          'surname': _surnameController.text,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil actualizado con éxito')),
          );
          Navigator.of(context).pop(); // Regresa a la pantalla anterior
        }
      } catch (e) {
        logger.e('Error al actualizar el perfil: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al actualizar el perfil')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left,
            color: Color(0xFFFFEE93), // Color de la flecha FFEE93
            size: 45, // Tamaño de la flecha (puedes cambiar este valor)
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            const SizedBox(height: 10), // Espacio entre el AppBar y el texto
            const Center(
              child: Text(
                'Editar perfil', // Texto centrado
                style: TextStyle(
                  fontSize: 20.0, // Tamaño de la fuente
                  fontWeight: FontWeight.bold, // Texto en negrita
                ),
              ),
            ),
            const SizedBox(height: 25), // Espacio entre el texto y el avatar
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFFEE93), // Color del borde
                    width: 5.0, // Grosor del borde
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(1), // Sombra gris
                      spreadRadius: 6,
                      blurRadius: 10,
                      offset:
                          const Offset(0, 10), // Desplazamiento de la sombra
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 80, // Tamaño del avatar
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!)
                      : (_photoUrl != null ? NetworkImage(_photoUrl!) : null),
                  backgroundColor: _profileImage == null && _photoUrl == null
                      ? Colors.grey[300] // Color de fondo si no hay imagen
                      : null,
                  child: _profileImage == null && _photoUrl == null
                      ? const Icon(Icons.camera_alt,
                          size: 50, color: Colors.white) // Ícono de cámara
                      : null,
                ),
              ),
            ),

            const SizedBox(height: 22),
            const Text(
              'Cambiar foto', // Texto centrado
              style: TextStyle(
                fontSize: 14.0, // Tamaño de la fuente
                fontWeight: FontWeight.bold, // Texto en negrita
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(40.0), // Bordes redondeados
                  ),
                  borderSide: BorderSide(
                    color: Color(0xFFC4B8B8), // Color del borde gris
                    width: 2.0, // Grosor del borde
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(
                        40.0), // Bordes redondeados cuando está habilitado
                  ),
                  borderSide: BorderSide(
                    color: Color(
                        0xFFC4B8B8), // Color del borde gris cuando está habilitado
                    width: 2.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(
                        40.0), // Bordes redondeados cuando está enfocado
                  ),
                  borderSide: BorderSide(
                    color: Color(
                        0xFFC4B8B8), // Color del borde gris cuando está enfocado
                    width: 2.0,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            TextField(
              controller: _surnameController,
              decoration: const InputDecoration(
                labelText: 'Apellidos',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(40.0), // Bordes redondeados
                  ),
                  borderSide: BorderSide(
                    color: Color(0xFFC4B8B8), // Color del borde gris
                    width: 2.0,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(40.0),
                  ),
                  borderSide: BorderSide(
                    color: Color(0xFFC4B8B8),
                    width: 2.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(40.0),
                  ),
                  borderSide: BorderSide(
                    color: Color(0xFFC4B8B8),
                    width: 2.0,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Correo Electrónico',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(40.0), // Bordes redondeados
                  ),
                  borderSide: BorderSide(
                    color: Color(0xFFC4B8B8), // Color del borde gris
                    width: 2.0,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(40.0),
                  ),
                  borderSide: BorderSide(
                    color: Color(0xFFC4B8B8),
                    width: 2.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(40.0),
                  ),
                  borderSide: BorderSide(
                    color: Color(0xFFC4B8B8),
                    width: 2.0,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Nueva Contraseña',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(40.0), // Bordes redondeados
                  ),
                  borderSide: BorderSide(
                    color: Color(0xFFC4B8B8), // Color del borde gris
                    width: 2.0,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(40.0),
                  ),
                  borderSide: BorderSide(
                    color: Color(0xFFC4B8B8),
                    width: 2.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(40.0),
                  ),
                  borderSide: BorderSide(
                    color: Color(0xFFC4B8B8),
                    width: 2.0,
                  ),
                ),
              ),
              obscureText: true,
            ),

            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB7F6E3), // Color de fondo
                foregroundColor: const Color(0xFF0D4533), // Color del texto
                side: const BorderSide(
                  color: Color(0xFF089A6D), // Color del borde
                  width: 2.0, // Grosor del borde
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(50.0), // Bordes redondeados
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 12.0), // Tamaño del botón
              ),
              child: const Text('Actualizar'),
            ),
          ],
        ),
      ),
    );
  }
}
