import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final Logger _logger = Logger();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Registrar usuario con correo y contraseña
  Future<User?> registerWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      _logger.e('Error al registrar usuario: $e');
      return null;
    }
  }

  // Guardar perfil del usuario en Firestore
  Future<void> saveUserProfile(String uid, String name, String surname, File? profileImage) async {
    try {
      String? photoUrl;
      if (profileImage != null) {
        final storageRef = _storage.ref().child('profileImages/$uid.jpg');
        await storageRef.putFile(profileImage);
        photoUrl = await storageRef.getDownloadURL();
      }

      await _firestore.collection('users').doc(uid).set({
        'name': name,
        'surname': surname,
        'photoUrl': photoUrl,
      });
      _logger.i('Perfil guardado con éxito');
    } catch (e) {
      _logger.e('Error al guardar el perfil del usuario: $e');
    }
  }

  // Iniciar sesión con correo y contraseña
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      _logger.e('Error al iniciar sesión: $e');
      return null;
    }
  }

  // Iniciar sesión con Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      _logger.e('Error al iniciar sesión con Google: $e');
      return null;
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  // Obtener el usuario actual
  User? get currentUser => _auth.currentUser;
}
