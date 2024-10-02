import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

class TeamService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  // Crear un nuevo equipo
  Future<void> createTeam(String teamName) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _firestore.collection('teams').add({
          'name': teamName,
          'userId': currentUser.uid, // Se guarda el ID del usuario que creó el equipo
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      _logger.e('Error al crear el equipo: $e');
    }
  }

  // Obtener equipos del usuario actual
  Stream<List<Map<String, dynamic>>> getUserTeams() {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        return _firestore
            .collection('teams')
            .where('userId', isEqualTo: currentUser.uid)
            .orderBy('createdAt', descending: true)
            .snapshots()
            .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
      }
    } catch (e) {
      _logger.e('Error al obtener los equipos del usuario: $e');
    }
    return const Stream.empty();
  }

  // Actualizar el nombre de un equipo
  Future<void> updateTeam(String teamId, String newTeamName) async {
    try {
      await _firestore.collection('teams').doc(teamId).update({
        'name': newTeamName,
      });
    } catch (e) {
      _logger.e('Error al actualizar el equipo: $e');
    }
  }

  // Eliminar un equipo
  Future<void> deleteTeam(String teamId) async {
    try {
      await _firestore.collection('teams').doc(teamId).delete();
    } catch (e) {
      _logger.e('Error al eliminar el equipo: $e');
    }
  }
}
