import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';
import 'package:app_tareas/models/user_profile.dart';

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

  // Agregar método para obtener el perfil del usuario
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      _logger.e('Error al obtener el perfil del usuario: $e');
      return null;
    }
  }

  // Agregar método para obtener el nombre y la foto de perfil
  String? get displayName => _auth.currentUser?.displayName;
  String? get photoURL => _auth.currentUser?.photoURL;

  // Método para buscar usuarios por nombre
  Future<List<UserProfile>> searchUsersByName(String name) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: name)
          .where('name', isLessThanOrEqualTo: '$name\uf8ff') // {{ edit_1 }}
          .get();

      return snapshot.docs.map((doc) => UserProfile.fromFirestore(doc.data(), doc.id)).toList();
    } catch (e) {
      _logger.e('Error al buscar usuarios: $e');
      return [];
    }
  }

  // Método para buscar usuarios por nombre o correo
  Future<List<UserProfile>> searchUsersByNameOrEmail(String query) async { // {{ edit_4 }}
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      final emailSnapshot = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: query)
          .where('email', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      final users = snapshot.docs.map((doc) => UserProfile.fromFirestore(doc.data(), doc.id)).toList();
      final emailUsers = emailSnapshot.docs.map((doc) => UserProfile.fromFirestore(doc.data(), doc.id)).toList();

      return [...users, ...emailUsers]; // Combinar resultados
    } catch (e) {
      _logger.e('Error al buscar usuarios: $e');
      return [];
    }
  }
}
