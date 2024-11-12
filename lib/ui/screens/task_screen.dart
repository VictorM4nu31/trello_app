import 'package:app_tareas/ui/screens/user_task_screen.dart';
import 'package:app_tareas/ui/screens/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_tareas/services/auth_service.dart'; // Importa AuthService
import 'package:logger/logger.dart'; // Importa Logger
import 'package:app_tareas/ui/screens/add_task_screen.dart'; // Importa la nueva pantalla para agregar equipo
import 'package:app_tareas/ui/screens/add_team_screen.dart';
import 'package:firebase_storage/firebase_storage.dart';


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
  final FirebaseStorage _storage = FirebaseStorage.instance;

  late User? _currentUser;
  List<Map<String, dynamic>> _teams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _fetchTeams();
    _fetchProfileImageUrl();
  }

  Future<void> _fetchTeams() async {
    try {
      if (_currentUser != null) {
        final snapshot = await _firestore
            .collection('teams')
            .where('userId', isEqualTo: _currentUser!.uid)
            .get();

        setState(() {
          _teams = snapshot.docs.map((doc) {
            var data = doc.data();
            return {
              'id': doc.id, // Asegúrate de incluir el ID del documento
              ...data,
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.e('Error fetching teams: $e'); // Reemplazamos 'print' con logger
    }
  }

  Future<void> _deleteTeam(String? teamId) async {
    if (teamId == null) {
      _logger.e('Team ID is null, cannot delete team.');
      return; // Salir si el ID es nulo
    }

    try {
      await _firestore.collection('teams').doc(teamId).delete();
      _fetchTeams(); // Refrescar la lista de equipos después de eliminar
    } catch (e) {
      _logger.e('Error deleting team: $e');
    }
  }

  Future<String?> _getProfileImageUrl() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        final ref = _storage.ref().child('profile_images/${user.uid}');
        String downloadUrl = await ref.getDownloadURL();
        return downloadUrl;
      } catch (e) {
        _logger.e('Error al obtener la URL de la imagen de perfil: $e');
        return null;
      }
    }
    return null;
  }

  Future<void> _fetchProfileImageUrl() async {
    setState(() {}); // Actualiza el estado para que se reconstruya el widget
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot>(
          stream: _firestore.collection('users').doc(user!.uid).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Hola, Cargando...');
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Text('Hola, Usuario');
            }

            var userData = snapshot.data!.data() as Map<String, dynamic>;
            String userName = userData['name'] ?? 'Usuario';

            return Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfileScreen(
                          userId: user.uid,
                        ),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    backgroundImage: userData['photoUrl'] != null
                        ? NetworkImage(userData['photoUrl'])
                        : null,
                    child: userData['photoUrl'] == null ? const Icon(Icons.person) : null,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hola, $userName',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      '¡Bienvenido de nuevo!',
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserTasksScreen(
                    userId: _currentUser!.uid,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final navigator = Navigator.of(context);
              await _authService.signOut();
              navigator.pushReplacementNamed('/');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _teams.isEmpty
              ? const Center(child: Text('No tienes equipos.'))
              : Padding(
                  padding: const EdgeInsets.all(18.0), // Añade un padding al body
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Alinea el texto a la izquierda
                    children: [
                      const Text(
                        'Aquí puedes ver tus equipos:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), // Estilo del texto
                      ),
                      const SizedBox(height: 16), // Espacio entre el texto y la lista
                      Expanded(
                        child: ListView.builder(
                          itemCount: _teams.length,
                          itemBuilder: (context, index) {
                            final team = _teams[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                              child: Card(
                                color: Color(team['color'] ?? 0xFFFFFFFF),
                                child: ListTile(
                                  title: Text(
                                    team['name'] ?? 'Nombre del Equipo',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                                        child: const Text('Ver'),
                                      ),
                                      IconButton(
                                        icon: const CircleAvatar(
                                          radius: 24, // Ajusta el tamaño del círculo
                                          backgroundColor: Color(0xFFF28C8C), // Color rosado de fondo
                                          child: Icon(
                                            Icons.delete,
                                            color: Colors.white, // Color blanco del ícono
                                            size: 24, // Tamaño del ícono
                                          ),
                                        ),
                                        onPressed: () async {
                                          bool confirmDelete = await showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return Dialog(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20.0),
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(20.0),
                                                  child: Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: <Widget>[
                                                      // Icono de papelera grande
                                                      const CircleAvatar(
                                                        radius: 40,
                                                        backgroundColor: Color(0xFFFF9393),
                                                        child: Icon(
                                                          Icons.delete,
                                                          size: 40,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 16),

                                                      // Título de la alerta
                                                      const Text(
                                                        '¿Desea eliminar el equipo?',
                                                        style: TextStyle(
                                                          fontSize: 20,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),

                                                      // Descripción de la alerta
                                                      const Text(
                                                        'Recuerda que el equipo eliminado, no se podrá recuperar.',
                                                        textAlign: TextAlign.center,
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: Color(0xFFB4B4B4),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 24),

                                                      // Botones Aceptar y Cancelar
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Expanded(
                                                            child: TextButton(
                                                              style: TextButton.styleFrom(
                                                                backgroundColor: const Color(0xFFC8E2B3), // Color de fondo verde
                                                                shape: RoundedRectangleBorder(
                                                                  borderRadius: BorderRadius.circular(20.0),
                                                                ),
                                                              ),
                                                              child: const Text(
                                                                'Aceptar',
                                                                style: TextStyle(
                                                                  color: Colors.black,
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                              ),
                                                              onPressed: () {
                                                                Navigator.of(context).pop(true);
                                                              },
                                                            ),
                                                          ),
                                                          const SizedBox(width: 16),
                                                          Expanded(
                                                            child: TextButton(
                                                              style: TextButton.styleFrom(
                                                                backgroundColor: const Color(0xFFC6C6C6), // Color de fondo gris
                                                                shape: RoundedRectangleBorder(
                                                                  borderRadius: BorderRadius.circular(20.0),
                                                                ),
                                                              ),
                                                              child: const Text(
                                                                'Cancelar',
                                                                style: TextStyle(
                                                                  color: Colors.black,
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                              ),
                                                              onPressed: () {
                                                                Navigator.of(context).pop(false);
                                                              },
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          );

                                          if (confirmDelete) {
                                            await _deleteTeam(team['id']); // Asegúrate de que team['id'] no sea nulo
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
                      ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Esperar hasta que regrese de la pantalla para agregar equipo
          final bool? teamCreated = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTeamScreen(),
            ),
          );

          // Si se creó un nuevo equipo, actualizar la lista
          if (teamCreated == true) {
            _fetchTeams();
          }
        },
        backgroundColor: Colors.black, // Color de fondo negro
        foregroundColor: Colors.white,
        shape: const CircleBorder(), // Color del icono blanco
        child: const Icon(Icons.add), // Asegura que sea completamente redondo
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat, // Botón centrado
    );
  }
}
