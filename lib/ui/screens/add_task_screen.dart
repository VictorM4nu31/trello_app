import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddTaskScreen extends StatefulWidget {
  final Map<String, dynamic> team;

  const AddTaskScreen({required this.team, Key? key}) : super(key: key);

  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> tasks = [];
  List<String> teamMembers = []; // Asegúrate de inicializar la lista

  @override
  void initState() {
    super.initState();
    _fetchTasks();
    _fetchTeamMembers(); // Llamar a la función para obtener los miembros del equipo
  }

  Future<void> _fetchTasks() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final snapshot = await _firestore
            .collection('tasks')
            .where('teamId', isEqualTo: widget.team['id'])
            .where('userId', isEqualTo: user.uid)
            .get();

        setState(() {
          tasks = snapshot.docs.map((doc) => {
            'id': doc.id,
            'name': doc['name'],
            'description': doc['description'] // Agregar descripción
          }).toList();
        });
      }
    } catch (e) {
      print('Error fetching tasks: $e');
    }
  }

  void _addTask() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newTask = '';
        String newDescription = ''; // Nueva variable para la descripción
        return AlertDialog(
          title: Text('Añadir Tarea'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (value) {
                  newTask = value;
                },
                decoration: InputDecoration(hintText: "Ingrese la nueva tarea"),
              ),
              TextField(
                onChanged: (value) {
                  newDescription = value; // Captura la descripción
                },
                decoration: InputDecoration(hintText: "Ingrese la descripción"),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Añadir'),
              onPressed: () async {
                if (newTask.isNotEmpty) {
                  try {
                    final user = _auth.currentUser;
                    if (user != null) {
                      final docRef = await _firestore
                          .collection('tasks')
                          .add({
                        'name': newTask,
                        'description': newDescription, // Agregar descripción
                        'teamId': widget.team['id'],
                        'userId': user.uid
                      });
                      setState(() {
                        tasks.add({
                          'id': docRef.id,
                          'name': newTask,
                          'description': newDescription // Guardar descripción
                        });
                      });
                    }
                  } catch (e) {
                    print('Error adding task: $e');
                  }
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _updateTask(String taskId, String currentName, String currentDescription) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String updatedTask = currentName;
        String updatedDescription = currentDescription; // Nueva variable para la descripción
        return AlertDialog(
          title: Text('Actualizar Tarea'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (value) {
                  updatedTask = value;
                },
                decoration: InputDecoration(hintText: "Ingrese la nueva tarea"),
                controller: TextEditingController(text: currentName),
              ),
              TextField(
                onChanged: (value) {
                  updatedDescription = value; // Captura la nueva descripción
                },
                decoration: InputDecoration(hintText: "Ingrese la nueva descripción"),
                controller: TextEditingController(text: currentDescription),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Actualizar'),
              onPressed: () async {
                if (updatedTask.isNotEmpty) {
                  try {
                    await _firestore
                        .collection('tasks')
                        .doc(taskId)
                        .update({
                      'name': updatedTask,
                      'description': updatedDescription // Actualiza la descripción
                    });
                    setState(() {
                      final index = tasks.indexWhere((task) => task['id'] == taskId);
                      tasks[index]['name'] = updatedTask;
                      tasks[index]['description'] = updatedDescription; // Actualiza la descripción en la lista
                    });
                  } catch (e) {
                    print('Error updating task: $e');
                  }
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteTask(String taskId) async {
    try {
      await _firestore
          .collection('tasks')
          .doc(taskId)
          .delete();

      setState(() {
        tasks.removeWhere((task) => task['id'] == taskId);
      });
    } catch (e) {
      print('Error deleting task: $e');
    }
  }

  void _addMember() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String memberName = '';
        return AlertDialog(
          title: Text('Añadir Miembro'),
          content: TextField(
            onChanged: (value) {
              memberName = value;
            },
            decoration: InputDecoration(hintText: "Ingrese el nombre del miembro"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Añadir'),
              onPressed: () async {
                if (memberName.isNotEmpty) {
                  try {
                    final userSnapshot = await _firestore
                        .collection('users')
                        .where('name', isEqualTo: memberName)
                        .get();

                    if (userSnapshot.docs.isNotEmpty) {
                      final userId = userSnapshot.docs.first.id;
                      await _firestore.collection('teams').doc(widget.team['id']).update({
                        'members': FieldValue.arrayUnion([userId])
                      });
                      // Actualizar la lista de miembros inmediatamente
                      _fetchTeamMembers();  // Refrescar la lista de miembros
                    }
                  } catch (e) {
                    print('Error adding member: $e');
                  }
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchTeamMembers() async {
    try {
      final snapshot = await _firestore
          .collection('teams')
          .doc(widget.team['id'])
          .get();

      if (snapshot.exists) {
        setState(() {
          teamMembers = List<String>.from(snapshot.data()?['members'] ?? []);
        });
      }
    } catch (e) {
      print('Error fetching team members: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tareas del Equipo ${widget.team['name']}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Miembros', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ListView.builder(
              shrinkWrap: true,
              itemCount: teamMembers.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(teamMembers[index]),
                );
              },
            ),
            SizedBox(height: 20),
            Text('Tareas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: tasks.isNotEmpty
                  ? ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(tasks[index]['name']),
                          subtitle: Text(tasks[index]['description'] ?? ''), // Mostrar la descripción
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () => _updateTask(tasks[index]['id'], tasks[index]['name'], tasks[index]['description']),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () => _deleteTask(tasks[index]['id']),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  : Center(child: Text('No hay tareas')),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _addMember,
            child: Icon(Icons.person_add),
            heroTag: null,
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _addTask,
            child: Icon(Icons.add),
            heroTag: null,
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}



