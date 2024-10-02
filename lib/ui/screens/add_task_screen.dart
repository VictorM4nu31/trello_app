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

  @override
  void initState() {
    super.initState();
    _fetchTasks();
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
            'name': doc['name']
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
        return AlertDialog(
          title: Text('Añadir Tarea'),
          content: TextField(
            onChanged: (value) {
              newTask = value;
            },
            decoration: InputDecoration(hintText: "Ingrese la nueva tarea"),
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
                          .add({'name': newTask, 'teamId': widget.team['id'], 'userId': user.uid});
                      setState(() {
                        tasks.add({'id': docRef.id, 'name': newTask});
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

  void _updateTask(String taskId, String currentName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String updatedTask = currentName;
        return AlertDialog(
          title: Text('Actualizar Tarea'),
          content: TextField(
            onChanged: (value) {
              updatedTask = value;
            },
            decoration: InputDecoration(hintText: "Ingrese la nueva tarea"),
            controller: TextEditingController(text: currentName),
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
                        .update({'name': updatedTask});
                    setState(() {
                      final index = tasks.indexWhere((task) => task['id'] == taskId);
                      tasks[index]['name'] = updatedTask;
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

  @override
  Widget build(BuildContext context) {
    final members = widget.team['members'] ?? [];

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
              itemCount: members.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(members[index]),
                );
              },
            ),
            SizedBox(height: 20),
            Text('Tareas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (tasks.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(tasks[index]['name']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => _updateTask(tasks[index]['id'], tasks[index]['name']),
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
            else
              ElevatedButton(
                onPressed: _addTask,
                child: Text('Añadir Tarea'),
              ),
          ],
        ),
      ),
    );
  }
}