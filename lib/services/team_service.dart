import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:flutter/material.dart'; // {{ edit_1 }}

class TeamService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  // Crear un nuevo equipo
  Future<String?> createTeam(String teamName, String projectDescription, Color color, List<String> selectedMembers) async { // {{ edit_5 }}
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        DocumentReference docRef = await _firestore.collection('teams').add({
          'name': teamName,
          'description': projectDescription,
          'userId': currentUser.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'color': color.value, // Guardar el color como valor hexadecimal
        });
        return docRef.id; // Devuelve el ID del documento creado
      }
    } catch (e) {
      _logger.e('Error al crear el equipo: $e');
    }
    return null; // Devuelve null si hay un error
  }
}
