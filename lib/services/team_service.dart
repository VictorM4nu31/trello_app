import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:flutter/material.dart'; // {{ edit_1 }}

class TeamService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  // Crear un nuevo equipo
  Future<void> createTeam(String teamName, String projectDescription, Color color) async { // {{ edit_5 }}
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _firestore.collection('teams').add({
          'name': teamName,
          'description': projectDescription,
          'userId': currentUser.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'color': color.value, // Guardar el color como valor hexadecimal
        });
      }
    } catch (e) {
      _logger.e('Error al crear el equipo: $e');
    }
  }
}
