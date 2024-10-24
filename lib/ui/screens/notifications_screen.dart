import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  NotificationsScreenState createState() => NotificationsScreenState();
}

class NotificationsScreenState extends State<NotificationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _tasks = [];

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    try {
      final snapshot = await _firestore.collection('tasks').get();
      setState(() {
        _tasks = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'name': doc['name'],
            'description': doc['description'],
            'isCompleted': doc['isCompleted'] ?? false, // Manejar la ausencia del campo
          };
        }).toList();
      });
    } catch (e) {
      // Manejo de errores
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
      ),
      body: ListView.builder(
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          return ListTile(
            title: Text(task['name']),
            subtitle: Text(task['description']),
            trailing: Icon(
              task['isCompleted'] ? Icons.check : Icons.pending,
              color: task['isCompleted'] ? Colors.green : Colors.red,
            ),
          );
        },
      ),
    );
  }
}
