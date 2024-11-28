import 'package:flutter/material.dart';
import 'package:app_tareas/services/auth_service.dart';
import 'package:app_tareas/services/team_service.dart';
import 'package:app_tareas/models/user_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

class AddTeamScreen extends StatefulWidget {
  const AddTeamScreen({super.key});

  @override
  AddTeamScreenState createState() => AddTeamScreenState();
}

class AddTeamScreenState extends State<AddTeamScreen> {
  final AuthService _authService = AuthService();
  final TeamService _teamService = TeamService();
  final Logger _logger = Logger();
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
      try {
        User? currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          List<String> allMembers = _selectedMembers
              .map((member) => member.uid)
              .toList();
          
          if (!allMembers.contains(currentUser.uid)) {
            allMembers.add(currentUser.uid);
          }
_logger.i('Miembros seleccionados antes de crear el equipo: $allMembers');

          final teamId = await _teamService.createTeam(
            _teamName,
            _projectDescription,
            _selectedColor,
            allMembers,
          );

          if (teamId != null) {
            if (mounted) {
              Navigator.pop(context, true);
            }
          } else {
            throw Exception('Error al crear el equipo: ID no generado');
          }
        }
      } catch (e) {
        _logger.e('Error creating team: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al crear el equipo')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, completa todos los campos.')),
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
            color: Color(0xFFFFEE93),
            size: 45,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Agregar equipo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),

                // Campos de texto
                _buildTextField('Nombre del equipo', (value) {
                  setState(() => _teamName = value);
                }),
                const SizedBox(height: 16),
                _buildTextField('Descripción del proyecto', (value) {
                  setState(() => _projectDescription = value);
                }),
                const SizedBox(height: 16),

                // Búsqueda de miembros
                _buildTextField('Agregar miembros', (value) {
                  setState(() => _searchQuery = value);
                  _searchUsers();
                }),

                // Lista de resultados de búsqueda
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) =>
                        _buildSearchResultItem(_searchResults[index]),
                  ),
                ),

                // Miembros seleccionados
                const SizedBox(height: 16),
                const Text(
                  'Miembros seleccionados:',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _selectedMembers.length,
                    itemBuilder: (context, index) =>
                        _buildSelectedMemberItem(_selectedMembers[index]),
                  ),
                ),

                // Selector de colores
                const SizedBox(height: 16),
                _buildColorSelector(),

                // Botón de agregar
                const SizedBox(height: 16),
                _buildAddButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(
                color: Color(0xFFC4B8B8),
                width: 2.0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultItem(UserProfile user) {
    return ListTile(
      title: Text(user.name),
      subtitle: Text(user.surname),
      leading: user.photoUrl != null
          ? CircleAvatar(backgroundImage: NetworkImage(user.photoUrl!))
          : null,
      onTap: () {
        _addMemberToTeam(user); // Llama a la función para agregar el usuario
      },
    );
  }

  Widget _buildSelectedMemberItem(UserProfile member) {
    return ListTile(
      title: Text(member.name),
      subtitle: Text(member.surname),
    );
  }

  Widget _buildColorSelector() {
    return Wrap(
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
                shape: BoxShape.circle, // Hace que el contenedor sea circular
              ),
              child: _selectedColor == color
                  ? const Icon(Icons.check, color: Colors.white)
                  : null,
            ),
          ),
      ],
    );
  }

  Widget _buildAddButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _createTeam,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFB7F6E3), // Color de fondo
          foregroundColor: const Color(0xFF0D4533), // Color del texto
          side: const BorderSide(
            color: Color(0xFF089A6D), // Color del borde
            width: 2.0, // Grosor del borde
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50), // Bordes redondeados
          ),
        ),
        child: const Text('Agregar'),
      ),
    );
  }
}
