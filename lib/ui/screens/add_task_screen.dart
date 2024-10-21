import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class AddTaskScreen extends StatefulWidget {
  final Map<String, dynamic> team;

  const AddTaskScreen({required this.team, super.key});

  @override
  AddTaskScreenState createState() => AddTaskScreenState();
}

class AddTaskScreenState extends State<AddTaskScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> tasks = [];
<<<<<<< HEAD
  List<Map<String, dynamic>> teamMembers = []; // Cambiar a una lista de mapas para incluir nombre y foto
  List<String> selectedMembers = []; // Lista para almacenar los IDs de los miembros seleccionados
=======
  List<Map<String, dynamic>> teamMembers =
      []; // Cambiar a una lista de mapas para incluir nombre y foto
>>>>>>> 099dea1da43cf48bee5eebb03701eedb52af4b1c

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
          tasks = snapshot.docs
              .map((doc) => {
                    'id': doc.id,
                    'name': doc['name'],
                    'description': doc['description'] // Agregar descripción
                  })
              .toList();
        });
      }
    } catch (e) {
      logger.e('Error fetching tasks: $e');
    }
  }

  Future<void> _fetchTeamMembers() async {
    try {
      final snapshot = await _firestore
          .collection('teams')
          .doc(widget.team['id'])
          .get();

      if (snapshot.exists) {
        final memberIds = List<String>.from(snapshot.data()?['members'] ?? []);
        final memberData = await Future.wait(memberIds.map((id) async {
          final userDoc = await _firestore.collection('users').doc(id).get();
          return {
            'id': id,
            'name': userDoc['name'],
            'photoUrl': userDoc['photoUrl'],
          };
        }));

        setState(() {
          teamMembers = memberData; // Asegúrate de que esto sea una lista de mapas
        });
      }
    } catch (e) {
      logger.e('Error fetching team members: $e');
    }
  }

  Future<void> _addTask() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newTask = '';
        String newDescription = '';
        return AlertDialog(
          title: const Text('Añadir Tarea'),
<<<<<<< HEAD
          content: SingleChildScrollView( // Permite el desplazamiento si hay muchos miembros
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  onChanged: (value) {
                    newTask = value;
                  },
                  decoration: const InputDecoration(hintText: "Ingrese la nueva tarea"),
                ),
                TextField(
                  onChanged: (value) {
                    newDescription = value;
                  },
                  decoration: const InputDecoration(hintText: "Ingrese la descripción"),
                ),
                const SizedBox(height: 16),
                const Text('Asignar a miembros:'),
                Column(
                  children: teamMembers.map((member) {
                    return CheckboxListTile(
                      title: Text(member['name']),
                      value: selectedMembers.contains(member['id']),
                      onChanged: (bool? selected) {
                        setState(() {
                          if (selected == true) {
                            selectedMembers.add(member['id']);
                          } else {
                            selectedMembers.remove(member['id']);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
=======
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EEEE), // Color de relleno gris
                  borderRadius:
                      BorderRadius.circular(20.0), // Bordes redondeados
                ),
                child: TextField(
                  onChanged: (value) {
                    newTask = value;
                  },
                  decoration: InputDecoration(
                    hintText: "Ingrese la nueva tarea",
                    hintStyle: TextStyle(
                        color: const Color(
                            0xFFB4B4B4)), // Color del texto del hint
                    border: InputBorder.none, // Sin borde por defecto
                    contentPadding:
                        const EdgeInsets.all(16.0), // Relleno interno
                  ),
                ),
              ),
              const SizedBox(height: 10), // Espaciado entre los TextFields
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EEEE), // Color de relleno gris
                  borderRadius:
                      BorderRadius.circular(20.0), // Bordes redondeados
                ),
                child: TextField(
                  onChanged: (value) {
                    newDescription = value; // Captura la descripción
                  },
                  decoration: InputDecoration(
                    hintText: "Ingrese la descripción",
                    hintStyle: TextStyle(
                        color: const Color(
                            0xFFB4B4B4)), // Color del texto del hint
                    border: InputBorder.none, // Sin borde por defecto
                    contentPadding:
                        const EdgeInsets.all(16.0), // Relleno interno
                  ),
                ),
              ),
            ],
>>>>>>> 099dea1da43cf48bee5eebb03701eedb52af4b1c
          ),
          actions: <Widget>[
            Container(
              width: 150, // Ancho específico para el botón Cancelar
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor:
                      const Color(0xFFC6C6C6), // Color de fondo gris
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(20.0), // Bordes redondeados
                  ),
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(
                    color: Colors.black, // Color del texto
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
<<<<<<< HEAD
            TextButton(
              child: const Text('Añadir'),
              onPressed: () async {
                if (newTask.isNotEmpty) {
                  try {
                    final user = _auth.currentUser;
                    if (user != null) {
                      final docRef = await _firestore.collection('tasks').add({
                        'name': newTask,
                        'description': newDescription,
                        'teamId': widget.team['id'],
                        'userId': user.uid,
                        'assignedMembers': selectedMembers.isNotEmpty ? selectedMembers : [],
                      });
                      setState(() {
                        tasks.add({
                          'id': docRef.id,
                          'name': newTask,
                          'description': newDescription,
                          'assignedMembers': selectedMembers,
                        });
                      });
                    } else {
                      logger.e('No hay usuario autenticado.');
=======
            Container(
              width: 150, // Ancho específico para el botón Añadir
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor:
                      const Color(0xFFC8E2B3), // Color de fondo verde
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(20.0), // Bordes redondeados
                  ),
                ),
                child: const Text(
                  'Añadir',
                  style: TextStyle(
                    color: Colors.black, // Color del texto
                  ),
                ),
                onPressed: () async {
                  if (newTask.isNotEmpty) {
                    try {
                      final user = _auth.currentUser;
                      if (user != null) {
                        final docRef =
                            await _firestore.collection('tasks').add({
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
                      logger.e('Error adding task: $e');
>>>>>>> 099dea1da43cf48bee5eebb03701eedb52af4b1c
                    }
                  }
<<<<<<< HEAD
                }
                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
=======
                  if (!context.mounted) return; // Cambiar a context.mounted
                  Navigator.of(context).pop();
                },
              ),
>>>>>>> 099dea1da43cf48bee5eebb03701eedb52af4b1c
            ),
          ],
        );
      },
    );
  }

  void _updateTask(
      String taskId, String currentName, String currentDescription) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String updatedTask = currentName;
        String updatedDescription =
            currentDescription; // Nueva variable para la descripción
        return AlertDialog(
          title: const Text('Actualizar Tarea'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EEEE), // Color de relleno gris
                  borderRadius:
                      BorderRadius.circular(20.0), // Bordes redondeados
                ),
                child: TextField(
                  onChanged: (value) {
                    updatedTask = value;
                  },
                  decoration: InputDecoration(
                    hintText: "Ingrese la nueva tarea",
                    hintStyle: TextStyle(
                        color: const Color(
                            0xFFB4B4B4)), // Color del texto del hint
                    border: InputBorder.none, // Sin borde por defecto
                    contentPadding:
                        const EdgeInsets.all(16.0), // Relleno interno
                  ),
                  controller: TextEditingController(text: currentName),
                ),
              ),
              const SizedBox(height: 10), // Espaciado entre los TextFields
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EEEE), // Color de relleno gris
                  borderRadius:
                      BorderRadius.circular(20.0), // Bordes redondeados
                ),
                child: TextField(
                  onChanged: (value) {
                    updatedDescription = value; // Captura la nueva descripción
                  },
                  decoration: InputDecoration(
                    hintText: "Ingrese la nueva descripción",
                    hintStyle: TextStyle(
                        color: const Color(
                            0xFFB4B4B4)), // Color del texto del hint
                    border: InputBorder.none, // Sin borde por defecto
                    contentPadding:
                        const EdgeInsets.all(16.0), // Relleno interno
                  ),
                  controller: TextEditingController(text: currentDescription),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            Container(
              width: 150, // Ancho específico para el botón Cancelar
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor:
                      const Color(0xFFC6C6C6), // Color de fondo gris
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(20.0), // Bordes redondeados
                  ),
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(
                    color: Colors.black, // Color del texto
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
            Container(
              width: 150, // Ancho específico para el botón Actualizar
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor:
                      const Color(0xFFC8E2B3), // Color de fondo verde
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(20.0), // Bordes redondeados
                  ),
                ),
                child: const Text(
                  'Actualizar',
                  style: TextStyle(
                    color: Colors.black, // Color del texto
                  ),
                ),
                onPressed: () async {
                  if (updatedTask.isNotEmpty) {
                    try {
                      await _firestore.collection('tasks').doc(taskId).update({
                        'name': updatedTask,
                        'description':
                            updatedDescription // Actualiza la descripción
                      });
                      setState(() {
                        final index =
                            tasks.indexWhere((task) => task['id'] == taskId);
                        tasks[index]['name'] = updatedTask;
                        tasks[index]['description'] =
                            updatedDescription; // Actualiza la descripción en la lista
                      });
                    } catch (e) {
                      logger.e('Error updating task: $e');
                    }
                  }
                  if (!context.mounted) return; // Cambiar a context.mounted
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteTask(String taskId) async {
    try {
      await _firestore.collection('tasks').doc(taskId).delete();

      setState(() {
        tasks.removeWhere((task) => task['id'] == taskId);
      });
    } catch (e) {
      logger.e('Error deleting task: $e');
    }
  }

  void _addMember() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String memberName = '';
        return AlertDialog(
          title: const Text('Añadir Miembro'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EEEE), // Color de relleno gris
                  borderRadius:
                      BorderRadius.circular(20.0), // Bordes redondeados
                ),
                child: TextField(
                  onChanged: (value) {
                    memberName = value;
                  },
                  decoration: InputDecoration(
                    hintText: "Ingrese el nombre del miembro",
                    hintStyle: TextStyle(
                        color: const Color(
                            0xFFB4B4B4)), // Color del texto del hint
                    border: InputBorder.none, // Sin borde por defecto
                    contentPadding:
                        const EdgeInsets.all(16.0), // Relleno interno
                  ),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            Container(
              width: 150, // Ancho específico para el botón Cancelar
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor:
                      const Color(0xFFC6C6C6), // Color de fondo gris
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(20.0), // Bordes redondeados
                  ),
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(
                    color: Colors.black, // Color del texto
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
            Container(
              width: 150, // Ancho específico para el botón Añadir
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor:
                      const Color(0xFFC8E2B3), // Color de fondo verde
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(20.0), // Bordes redondeados
                  ),
                ),
                child: const Text(
                  'Añadir',
                  style: TextStyle(
                    color: Colors.black, // Color del texto
                  ),
                ),
                onPressed: () async {
                  if (memberName.isNotEmpty) {
                    try {
                      final userSnapshot = await _firestore
                          .collection('users')
                          .where('name', isEqualTo: memberName)
                          .get();

                      if (userSnapshot.docs.isNotEmpty) {
                        final userId = userSnapshot.docs.first.id;
                        await _firestore
                            .collection('teams')
                            .doc(widget.team['id'])
                            .update({
                          'members': FieldValue.arrayUnion([userId])
                        });
                        // Actualizar la lista de miembros inmediatamente
                        _fetchTeamMembers(); // Refrescar la lista de miembros
                      }
                    } catch (e) {
                      logger.e('Error adding member: $e');
                    }
                  }
                  if (!context.mounted) return; // Cambiar a context.mounted
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        );
      },
    );
  }

<<<<<<< HEAD
  void _showAssignedMembers(List<String>? assignedMembers) async {
    // Asegúrate de que assignedMembers no sea null
    if (assignedMembers == null || assignedMembers.isEmpty) {
      // Manejo de caso donde no hay miembros asignados
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Miembros Asignados'),
            content: const Text('No hay miembros asignados a esta tarea.'),
            actions: <Widget>[
              TextButton(
                child: const Text('Cerrar'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      return;
    }

    // Obtener los datos de los miembros asignados
    List<Map<String, dynamic>> memberData = [];
    for (String memberId in assignedMembers) {
      final userDoc = await _firestore.collection('users').doc(memberId).get();
      if (userDoc.exists) {
        memberData.add({
          'id': memberId,
          'name': userDoc['name'],
=======
  Future<void> _fetchTeamMembers() async {
    try {
      final snapshot =
          await _firestore.collection('teams').doc(widget.team['id']).get();

      if (snapshot.exists) {
        final memberIds = List<String>.from(snapshot.data()?['members'] ?? []);
        final memberData = await Future.wait(memberIds.map((id) async {
          final userDoc = await _firestore.collection('users').doc(id).get();
          return {
            'id': id,
            'name': userDoc['name'],
            'photoUrl': userDoc['photoUrl'],
          };
        }));

        setState(() {
          teamMembers =
              memberData; // Asegúrate de que esto sea una lista de mapas
>>>>>>> 099dea1da43cf48bee5eebb03701eedb52af4b1c
        });
      }
    }

    // Mostrar un diálogo con los miembros asignados
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Miembros Asignados'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: memberData.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(memberData[index]['name']),
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Texto que aparece debajo del AppBar
            Center(
              // Agrega este widget para centrar el texto
              child: Text(
                '${widget.team['name']}',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Center(
              // Agrega este widget para centrar el texto
              child: Text(
                'Tareas del equipo',
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(
              height:
                  10, // Espaciado entre el texto del equipo y la lista de miembros
            ),
            const Text(
              'Miembros',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ListView.builder(
              shrinkWrap:
                  true, // Esto permite que la lista ocupe solo el espacio necesario
              physics:
                  const NeverScrollableScrollPhysics(), // Desactiva el desplazamiento si no es necesario
              itemCount: teamMembers.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: teamMembers[index]['photoUrl'] != null
                      ? CircleAvatar(
                          backgroundImage:
                              NetworkImage(teamMembers[index]['photoUrl']),
                        )
                      : null,
                  title: Text(teamMembers[index]['name']),
                );
              },
            ),

            const SizedBox(height: 10), // Espaciado antes de la línea divisoria
            const Divider(
              color: Colors.grey, // Color de la línea
              thickness: 1, // Grosor de la línea
            ),
            const SizedBox(
                height: 10), // Espaciado después de la línea divisoria

            const Text(
              'Tareas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            Expanded(
              child: tasks.isNotEmpty
                  ? ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
<<<<<<< HEAD
                        return ListTile(
                          title: Text(tasks[index]['name']),
                          subtitle: Text(tasks[index]['description'] ?? ''), // Mostrar la descripción
                          onTap: () {
                            // Llamar a la función para mostrar los miembros asignados
                            _showAssignedMembers(tasks[index]['assignedMembers']);
                          },
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _updateTask(tasks[index]['id'], tasks[index]['name'], tasks[index]['description']),
=======
                        return Column(
                          children: [
                            ListTile(
                              title: Text(tasks[index]['name']),
                              subtitle: Text(tasks[index]['description'] ?? ''),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _updateTask(
                                      tasks[index]['id'],
                                      tasks[index]['name'],
                                      tasks[index]['description'],
                                    ),
                                  ),
                                  Container(
                                    decoration: const BoxDecoration(
                                      color: Color(
                                          0xFFFF9393), // Color de fondo rosa
                                      shape: BoxShape.circle, // Forma circular
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.white),
                                      onPressed: () =>
                                          _deleteTask(tasks[index]['id']),
                                    ),
                                  ),
                                ],
>>>>>>> 099dea1da43cf48bee5eebb03701eedb52af4b1c
                              ),
                            ),
                            const Divider(
                              color: Colors.grey, // Color de la línea
                              thickness: 1, // Grosor de la línea
                            ), // Línea divisoria después de cada tarea
                          ],
                        );
                      },
                    )
                  : const Center(child: Text('No hay tareas')),
            ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment:
            MainAxisAlignment.center, // Centra los botones en el eje horizontal
        children: [
          FloatingActionButton(
            onPressed: _addMember,
            heroTag: null,
            backgroundColor: Colors.black, // Cambia el color de fondo
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(100), // Hace que sea totalmente redondo
            ),
            child: const Icon(Icons.person_add,
                color: Colors.white), // Cambia el color del ícono
          ),
          const SizedBox(width: 20), // Espaciado horizontal entre los botones
          FloatingActionButton(
            onPressed: _addTask,
            heroTag: null,
            backgroundColor: Colors.black, // Otro color para el botón
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(100), // Hace que sea totalmente redondo
            ),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation
          .centerFloat, // Ubica los botones centrados horizontalmente
    );
  }
}
