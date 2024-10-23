import 'package:app_tareas/ui/screens/user_task_screen.dart';
import 'package:app_tareas/ui/screens/edit_profile_screen.dart'; // Asegúrate de tener esta pantalla implementada
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_tareas/services/auth_service.dart'; // Importa AuthService
import 'package:logger/logger.dart'; // Importa Logger
import 'package:app_tareas/ui/screens/add_task_screen.dart'; // Importa la nueva pantalla para agregar equipo
import 'package:app_tareas/ui/screens/add_team_screen.dart';

class PuzzlePieceClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();

    // Dibujar rectángulo básico
    path.moveTo(0, 0);
    path.lineTo(
        0,
        size.height *
            0.8); // Se dibuja el lado izquierdo hasta el 80% de la altura

    // Parte inferior con curva para simular una pieza de rompecabezas
    path.quadraticBezierTo(
        size.width * 0.25, size.height, size.width * 0.5, size.height * 0.8);
    path.quadraticBezierTo(
        size.width * 0.75, size.height, size.width, size.height * 0.8);

    path.lineTo(size.width, 0); // Lado derecho de la tarjeta
    path.lineTo(0, 0); // Lado superior de la tarjeta
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}

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

  @override
  Widget build(BuildContext context) {
    if (_currentUser != null) {
      return FutureBuilder<DocumentSnapshot>(
        future: _firestore.collection('users').doc(_currentUser!.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar el usuario'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No se encontró el usuario'));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String userName =
              userData['name'] ?? ''; // Recuperar el nombre del usuario

          return Scaffold(
            appBar: AppBar(
              title: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Alinea el texto a la izquierda
                children: [
                  Row(
                    children: [
                      const Text('Hola, '),
                      Text(
                        userName.isNotEmpty ? userName : 'Cargando...',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(
                      height: 4), // Espacio entre el saludo y el subtítulo
                  const Text(
                    '¡Bienvenido de nuevo!', // Texto adicional
                    style:
                        TextStyle(fontSize: 12), // Tamaño de fuente más pequeño
                  ),
                ],
              ),
              actions: [
                GestureDetector(
                  onTap: () {
                    // Navegar a la pantalla de edición de perfil
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfileScreen(
                          userId: _currentUser!
                              .uid, // Pasa el userId a la pantalla de edición
                        ),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    backgroundImage: _currentUser?.photoURL != null
                        ? NetworkImage(_currentUser!.photoURL!)
                        : null,
                    child: _currentUser?.photoURL == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.assignment), // Botón para tareas
                  onPressed: () {
                    // Navegar a la pantalla de tareas del usuario
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserTasksScreen(
                          userId: _currentUser!
                              .uid, // Pasa el userId a la pantalla de tareas
                        ),
                      ),
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
                    : Padding(
                        padding: const EdgeInsets.all(
                            16.0), // Añade un padding al body
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment
                              .start, // Alinea el texto a la izquierda
                          children: [
                            const Text(
                              'Aquí puedes ver tus equipos:',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.bold), // Estilo del texto
                            ),
                            const SizedBox(
                                height:
                                    16), // Espacio entre el texto y la lista
                            Expanded(
                              child: ListView.builder(
                                itemCount: _teams.length,
                                itemBuilder: (context, index) {
                                  final team = _teams[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0, horizontal: 16.0),
                                    child: Card(
                                      color: Color(team['color'] ?? 0xFFFFFFFF),
                                      child: ListTile(
                                        title: Text(
                                          team['name'] ?? 'Nombre del Equipo',
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        AddTaskScreen(
                                                      team: {
                                                        'id': team[
                                                            'id'], // Asegúrate de pasar el ID del equipo
                                                        'name': team['name'],
                                                        'members':
                                                            team['members'] ??
                                                                [],
                                                        'color': team['color'],
                                                      },
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: const Text('Ver'),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete),
                                              onPressed: () async {
                                                bool confirmDelete =
                                                    await showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return AlertDialog(
                                                      title: const Text(
                                                          'Eliminar Equipo'),
                                                      content: const Text(
                                                        '¿Estás seguro de que deseas eliminar este equipo?',
                                                        style: TextStyle(
                                                            color: Color(
                                                                0xFFB4B4B4)), // Color del texto gris
                                                      ),
                                                      actions: <Widget>[
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween, // Espacio entre botones
                                                          children: [
                                                            Expanded(
                                                              child: TextButton(
                                                                style: TextButton
                                                                    .styleFrom(
                                                                  backgroundColor:
                                                                      const Color(
                                                                          0xFFC6C6C6), // Color de fondo gris
                                                                  shape:
                                                                      RoundedRectangleBorder(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            20.0), // Bordes redondeados
                                                                  ),
                                                                ),
                                                                child:
                                                                    const Text(
                                                                  'Cancelar',
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .black), // Color del texto
                                                                ),
                                                                onPressed: () {
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop(
                                                                          false);
                                                                },
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width:
                                                                    16), // Espacio entre botones
                                                            Expanded(
                                                              child: TextButton(
                                                                style: TextButton
                                                                    .styleFrom(
                                                                  backgroundColor:
                                                                      const Color(
                                                                          0xFFC8E2B3), // Color de fondo verde
                                                                  shape:
                                                                      RoundedRectangleBorder(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            20.0), // Bordes redondeados
                                                                  ),
                                                                ),
                                                                child:
                                                                    const Text(
                                                                  'Eliminar',
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .black), // Color del texto
                                                                ),
                                                                onPressed: () {
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop(
                                                                          true);
                                                                },
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );

                                                if (confirmDelete) {
                                                  await _deleteTeam(team[
                                                      'id']); // Asegúrate de que team['id'] no sea nulo
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
              child: const Icon(Icons.add),
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          );
        },
      );
    } else {
      return const Center(child: CircularProgressIndicator());
    }
  }
}
