import 'package:flutter/material.dart';
import 'package:app_tareas/services/auth_service.dart';
import 'package:app_tareas/services/team_service.dart';
import 'package:app_tareas/models/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // {{ edit_1 }}

class AddTeamScreen extends StatefulWidget {
  const AddTeamScreen({super.key});

  @override
  AddTeamScreenState createState() => AddTeamScreenState();
}

class AddTeamScreenState extends State<AddTeamScreen> {
  final AuthService _authService = AuthService();
  final TeamService _teamService = TeamService();
  List<UserProfile> _searchResults = [];
  String _searchQuery = '';
  String _teamName = '';
  String _projectDescription = '';
  Color _selectedColor = Colors.blue; // Color por defecto
  final List<UserProfile> _selectedMembers =
      []; // Define la lista de miembros seleccionados

  // Función para buscar usuarios por nombre o correo electrónico
  void _searchUsers() async {
    if (_searchQuery.isNotEmpty) {
      final results = await _authService.searchUsersByNameOrEmail(_searchQuery);
      setState(() {
        _searchResults = results;
      });
    } else {
      setState(() {
        _searchResults = [];
      });
    }
  }

  // Función para crear el equipo con miembros seleccionados
  Future<void> _createTeam() async {
    if (_teamName.isNotEmpty && _projectDescription.isNotEmpty) {
      final teamId = await _teamService.createTeam(
        _teamName,
        _projectDescription,
        _selectedColor,
        _selectedMembers
            .map((member) => member.uid)
            .toList(), // Lista de IDs de miembros
      );

      // Guardar los miembros en el equipo
      if (teamId != null) {
        await _firestore.collection('teams').doc(teamId).update({
          'members': FieldValue.arrayUnion(
              _selectedMembers.map((member) => member.uid).toList()),
        });
      }

      if (mounted) {
        Navigator.pop(context,
            true); // Devuelve true para indicar que se ha creado un equipo
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Por favor, completa todos los campos.')),
        );
      }
    }
  }

  void _selectColor(Color color) {
    setState(() {
      _selectedColor = color;
    });
  }

  // Función para agregar un miembro al equipo
  void _addMemberToTeam(UserProfile user) {
    setState(() {
      if (!_selectedMembers.contains(user)) {
        _selectedMembers.add(user); // Agregar solo si no está ya en la lista
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left,
            color: Color(0xFFFFEE93), // Color de la flecha FFEE93
            size: 45, // Tamaño de la flecha (puedes cambiar este valor)
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.center, // Alinea el texto al centro
          children: [
            const Text(
              'Agregar equipo', // Texto agregado
              style: TextStyle(
                fontSize: 20, // Tamaño de fuente del texto
                fontWeight: FontWeight.bold, // Negrita
              ),
            ),
            const SizedBox(height: 30), // Espaciado entre el texto y el campo
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nombre del equipo', // Texto que estará encima del TextField
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                    height: 8), // Espaciado entre el texto y el TextField
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _teamName = value;
                    });
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(12.0), // Bordes redondeados
                      ),
                      borderSide: BorderSide(
                        color: Color(0xFFC4B8B8), // Color del borde
                        width: 2.0, // Grosor del borde
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(
                            40.0), // Bordes redondeados cuando está habilitado
                      ),
                      borderSide: BorderSide(
                        color: Color(0xFFC4B8B8), // Color del borde
                        width: 2.0, // Grosor del borde
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(
                            40.0), // Bordes redondeados cuando está enfocado
                      ),
                      borderSide: BorderSide(
                        color: Color(
                            0xFFC4B8B8), // Color del borde cuando está enfocado
                        width: 2.0, // Grosor del borde
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Descripción del proyecto', // Texto que estará encima del TextField
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                    height: 8), // Espaciado entre el texto y el TextField
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _projectDescription = value;
                    });
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(12.0), // Bordes redondeados
                      ),
                      borderSide: BorderSide(
                        color: Color(0xFFC4B8B8), // Color del borde
                        width: 2.0, // Grosor del borde
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(
                            40.0), // Bordes redondeados cuando está habilitado
                      ),
                      borderSide: BorderSide(
                        color: Color(0xFFC4B8B8), // Color del borde
                        width: 2.0, // Grosor del borde
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(
                            40.0), // Bordes redondeados cuando está enfocado
                      ),
                      borderSide: BorderSide(
                        color: Color(
                            0xFFC4B8B8), // Color del borde cuando está enfocado
                        width: 2.0, // Grosor del borde
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Agregar miembros', // Texto que estará encima del TextField
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                    height: 8), // Espaciado entre el texto y el TextField
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _searchUsers();
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(12.0), // Bordes redondeados
                      ),
                      borderSide: BorderSide(
                        color: Color(0xFFC4B8B8), // Color del borde
                        width: 2.0, // Grosor del borde
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(
                            40.0), // Bordes redondeados cuando está habilitado
                      ),
                      borderSide: BorderSide(
                        color: Color(0xFFC4B8B8), // Color del borde
                        width: 2.0, // Grosor del borde
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(
                            40.0), // Bordes redondeados cuando está enfocado
                      ),
                      borderSide: BorderSide(
                        color: Color(
                            0xFFC4B8B8), // Color del borde cuando está enfocado
                        width: 2.0, // Grosor del borde
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final user = _searchResults[index];
                  return ListTile(
                    title: Text(user.name),
                    subtitle: Text(user.surname),
                    leading: user.photoUrl != null
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(user.photoUrl!))
                        : null,
                    onTap: () {
                      _addMemberToTeam(
                          user); // Llama a la función para agregar el usuario
                    },
                  );
                },
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Contenedor para centrar el texto
                Center(
                  child: const Text(
                    'Miembros seleccionados:',
                    style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight
                            .bold), // Opcional: personalización del estilo
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: _selectedMembers.length,
                  itemBuilder: (context, index) {
                    final member = _selectedMembers[index];
                    return ListTile(
                      title: Text(member.name),
                      subtitle: Text(member.surname),
                    );
                  },
                ),

                const SizedBox(height: 50),
                // Sección de colores
                Wrap(
                  spacing: 8.0, // Espacio horizontal entre los círculos
                  runSpacing: 8.0, // Espacio vertical entre las filas
                  alignment: WrapAlignment.center, // Centra el contenido
                  children: [
                    for (Color color in [
                      const Color(0xFF79ADDC), // Color adicional 1
                      const Color(0xFFFFC09F), // Color adicional 2
                      const Color(0xFFFFEE93), // Color adicional 3
                      const Color(0xFFFCF5C7), // Color adicional 4
                      const Color(0xFFADF7B6), // Color adicional 5
                      const Color(0xFFD4AFB9), // Color adicional 6
                      const Color(0xFFD1CFE2), // Color adicional 7
                      const Color(0xFF9CADCE), // Color adicional 8
                      const Color(0xFF7EC4CF), // Color adicional 9
                      const Color(0xFFDAEAF6), // Color adicional 10
                      const Color(0xFFCDB4DB), // Color adicional 11
                      const Color(0xFFFFC8DD), // Color adicional 12
                      const Color(0xFFFFAFCC), // Color adicional 13
                      const Color(0xFFBDE0FE), // Color adicional 14
                      const Color(0xFFA2D2FF), // Color adicional 15
                      const Color(0xFFE27396), // Color adicional 16
                      const Color(0xFFEA9AB2), // Color adicional 16
                      const Color(0xFFEFCFE3), // Color adicional 16
                      const Color(0xFFEAF2D7), // Color adicional 16
                      const Color(0xFFB3DEE2), // Color adicional 6
                    ])
                      GestureDetector(
                        onTap: () => _selectColor(color),
                        child: Container(
                          margin: const EdgeInsets.all(4.0),
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape
                                .circle, // Hace que el contenedor sea circular
                          ),
                          child: _selectedColor == color
                              ? const Icon(Icons.check, color: Colors.white)
                              : null,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),
                // Botón "Agregar Equipo"
                Center(
                  child: ElevatedButton(
                    onPressed: _createTeam,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFFB7F6E3), // Color de fondo
                      foregroundColor:
                          const Color(0xFF0D4533), // Color del texto
                      side: BorderSide(
                        color: const Color(0xFF089A6D), // Color del borde
                        width: 2.0, // Grosor del borde
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(50), // Bordes redondeados
                      ),
                    ),
                    child: const Text('Agregar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final FirebaseFirestore _firestore = FirebaseFirestore.instance; // {{ edit_1 }}
