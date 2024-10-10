import 'package:flutter/material.dart';
import 'package:app_tareas/services/auth_service.dart';
import 'package:app_tareas/services/team_service.dart';
import 'package:app_tareas/models/user_profile.dart';

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
  List<UserProfile> _selectedMembers = []; // Define la lista de miembros seleccionados

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
      await _teamService.createTeam(
        _teamName,
        _projectDescription,
        _selectedColor,
        _selectedMembers.map((member) => member.uid).toList(), // Lista de IDs de miembros
      );
      if (mounted) {
        Navigator.pop(context, true); // Devuelve true para indicar que se ha creado un equipo
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
        title: const Text('Agregar Equipo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              onChanged: (value) {
                setState(() {
                  _teamName = value;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Nombre del equipo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) {
                setState(() {
                  _projectDescription = value;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Descripción del proyecto',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _searchUsers();
              },
              decoration: const InputDecoration(
                labelText: 'Buscar miembros',
                border: OutlineInputBorder(),
              ),
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
                        ? CircleAvatar(backgroundImage: NetworkImage(user.photoUrl!))
                        : null,
                    onTap: () {
                      _addMemberToTeam(user); // Llama a la función para agregar el usuario
                    },
                  );
                },
              ),
            ),
            Text('Miembros seleccionados:'),
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
            ElevatedButton(
              onPressed: _createTeam,
              child: const Text('Agregar Equipo'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (Color color in [Colors.red, Colors.green, Colors.blue, Colors.yellow])
                  GestureDetector(
                    onTap: () => _selectColor(color),
                    child: Container(
                      margin: const EdgeInsets.all(4.0),
                      width: 30,
                      height: 30,
                      color: color,
                      child: _selectedColor == color
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
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


