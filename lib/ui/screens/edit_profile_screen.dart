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
            color: Color(0xFFFFEE93),
            size: 45,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 600), // Limita el ancho máximo
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Editar perfil',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Foto de perfil
                        Center(
                          child: Stack(
                            children: [
                              Container(
                                width: constraints.maxWidth * 0.3, // Tamaño responsivo
                                height: constraints.maxWidth * 0.3,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFFFEE93),
                                    width: 3,
                                  ),
                                ),
                                child: ClipOval(
                                  child: _buildProfileImage(),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: _buildChangePhotoButton(),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Campos de texto
                        _buildTextField(
                          controller: _nameController,
                          label: 'Nombre',
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _surnameController,
                          label: 'Apellidos',
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _emailController,
                          label: 'Correo Electrónico',
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Nueva Contraseña',
                          isPassword: true,
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Botón de actualizar
                        _buildUpdateButton(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    if (_profileImage != null) {
      return Image.file(_profileImage!, fit: BoxFit.cover);
    } else if (_photoUrl != null) {
      return Image.network(_photoUrl!, fit: BoxFit.cover);
    } else {
      return const Icon(Icons.camera_alt, size: 50, color: Colors.grey);
    }
  }

  Widget _buildChangePhotoButton() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Color(0xFFFFEE93),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.camera_alt, size: 20),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        border: _buildInputBorder(),
        enabledBorder: _buildInputBorder(),
        focusedBorder: _buildInputBorder(),
      ),
    );
  }

  OutlineInputBorder _buildInputBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(40.0),
      borderSide: const BorderSide(
        color: Color(0xFFC4B8B8),
        width: 2.0,
      ),
    );
  }

  Widget _buildUpdateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _updateProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFB7F6E3),
          foregroundColor: const Color(0xFF0D4533),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
            side: const BorderSide(
              color: Color(0xFF089A6D),
              width: 2.0,
            ),
          ),
        ),
        child: const Text('Actualizar', style: TextStyle(fontSize: 16)),
      ),
    );
  }
}
