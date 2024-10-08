import 'package:app_tareas/ui/screens/edit_profile_screen.dart';
import 'package:app_tareas/ui/screens/user_task_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_tareas/services/auth_service.dart'; // Importa AuthService
import 'package:logger/logger.dart'; // Importa Logger
import 'package:app_tareas/ui/screens/add_task_screen.dart';// Importa la nueva pantalla para agregar equipo
import 'package:app_tareas/ui/screens/add_team_screen.dart';

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

  Future<void> _deleteTeam(String teamId) async {
    try {
      await _firestore.collection('teams').doc(teamId).delete();
      _fetchTeams(); // Refrescar la lista de equipos después de eliminar
    } catch (e) {
      _logger.e('Error deleting team: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user != null) {
      return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Text('Bienvenido, '),
              Text(
                user.displayName?.isNotEmpty == true ? user.displayName! : 'Usuario',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserTasksScreen(userId: _currentUser!.uid),
                  ),
                );
              },
              child: CircleAvatar(
                backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                child: user.photoURL == null ? const Icon(Icons.person) : null,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await _authService.signOut();
                Navigator.of(context).pushReplacementNamed('/');
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
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AddTaskScreen(
                                          team: {
                                            'id': team['id'], // Asegúrate de pasar el ID del equipo
                                            'name': team['name'],
                                            'members': team['members'] ?? [],
                                            'color': team['color'],
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text('Ver'), // Añadir el texto "ver" aquí
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () async {
                                    bool confirmDelete = await showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text('Eliminar Equipo'),
                                          content: const Text('¿Estás seguro de que deseas eliminar este equipo?'),
                                          actions: <Widget>[
                                            TextButton(
                                              child: const Text('Cancelar'),
                                              onPressed: () {
                                                Navigator.of(context).pop(false);
                                              },
                                            ),
                                            TextButton(
                                              child: const Text('Eliminar'),
                                              onPressed: () {
                                                Navigator.of(context).pop(true);
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );

                                    if (confirmDelete) {
                                      await _deleteTeam(team['id']); //corregir está parte, para el botón de eliminar equipo  
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddTeamScreen()),
            );
          },
          child: const Icon(Icons.add),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      );
    } else {
      return const Center(child: CircularProgressIndicator());
    }
  }
}
