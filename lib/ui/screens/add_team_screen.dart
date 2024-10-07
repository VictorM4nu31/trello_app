// lib/screens/add_team_screen.dart

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

  Future<void> _createTeam() async {
    if (_teamName.isNotEmpty && _projectDescription.isNotEmpty) {
      await _teamService.createTeam(_teamName, _projectDescription, _selectedColor, []); // Pasamos el color seleccionado y una lista vacía de miembros
      if (mounted) { // Verificar si el widget está montado
        Navigator.pop(context); // Regresar a la pantalla anterior
      } 
    } else {
      if (mounted) { // Verificar si el widget está montado
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
                      // Agregar lógica para seleccionar el miembro
                    },
                  );
                },
              ),
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
