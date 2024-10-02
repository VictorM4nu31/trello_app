import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_tareas/services/auth_service.dart'; // Importa AuthService
import 'package:logger/logger.dart'; // Importa Logger
import 'add_team_screen.dart'; // Importa la nueva pantalla para agregar equipo

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  TaskScreenState createState() => TaskScreenState();
}

class TaskScreenState extends State<TaskScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService(); // Instancia de AuthService
  final Logger _logger = Logger(); // Instancia de Logger

  late User? _currentUser;
  List<Map<String, dynamic>> _teams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _fetchTeams();
  }

  Future<void> _fetchTeams() async {
    try {
      if (_currentUser != null) {
        final snapshot = await _firestore
            .collection('teams')
            .where('userId', isEqualTo: _currentUser!.uid)
            .get();

        setState(() {
          _teams = snapshot.docs.map((doc) => doc.data()).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.e('Error fetching teams: $e'); // Reemplazamos 'print' con logger
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user != null) {
      // Obtener el perfil del usuario desde Firestore
      return FutureBuilder<Map<String, dynamic>?>(
        future: _authService.getUserProfile(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Error al cargar el perfil.'));
          }

          final userProfile = snapshot.data!;
          return Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: userProfile['photoUrl'] != null
                        ? NetworkImage(userProfile['photoUrl'])
                        : const AssetImage('assets/placeholder.jpg')
                            as ImageProvider, // Foto de perfil o placeholder
                  ),
                  const SizedBox(width: 10),
                  Expanded( // Usar Expanded para evitar desbordamiento
                    child: Text(
                      'Bienvenido, ${userProfile['name'] ?? 'Usuario'}',
                      overflow: TextOverflow.ellipsis, // Evitar desbordamiento
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications), // Icono de campana
                  onPressed: () {
                    // Lógica para notificaciones
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add), // Icono de agregar
                  onPressed: () {
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AddTeamScreen()), // Navegar a la nueva pantalla
                      ).then((result) {
                        if (result == true) { // Verificar si se agregó un nuevo equipo
                          _fetchTeams(); // Volver a cargar los equipos
                        }
                      });
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.logout), // Icono de cerrar sesión
                  onPressed: () async {
                    await _authService.signOut(); // Cerrar sesión
                    if (mounted) {
                      Navigator.of(context).pushReplacementNamed('/'); // Navegar a la pantalla de login
                    }
                  },
                ),
              ],
            ),
            body: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _teams.isEmpty
                    ? const Center(child: Text('No tienes equipos.'))
                    : ListView.builder(
                        itemCount: _teams.length,
                        itemBuilder: (context, index) {
                          final team = _teams[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 16.0),
                            child: Card(
                              color: Color(team['color'] ?? 0xFFFFFFFF), // Proporcionar un valor por defecto
                              child: ListTile(
                                title: Text(
                                  team['name'] ?? 'Nombre del Equipo',
                                  style: const TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                trailing: ElevatedButton(
                                  onPressed: () {
                                    // Lógica para ver el equipo
                                  },
                                  child: const Text('Ver'),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          );
        },
      );
    } else {
      return const Center(child: CircularProgressIndicator());
    }
  }
}
