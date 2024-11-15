import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:app_tareas/ui/screens/widgets/add_task_widget.dart';

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
  List<Map<String, dynamic>> teamMembers = [];
  List<String> selectedMembers = [];
  Color? selectedColor;

  // Nuevas variables para la búsqueda de miembros
  List<Map<String, dynamic>> searchResults = [];
  bool isSearching = false;

  String? selectedResponsible;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
    _fetchTeamMembers();
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
                    'description': doc['description']
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
      final snapshot =
          await _firestore.collection('teams').doc(widget.team['id']).get();

      if (snapshot.exists) {
        final memberIds = List<String>.from(snapshot.data()?['members'] ?? []);
        final memberData = await Future.wait(memberIds.map((id) async {
          final userDoc = await _firestore.collection('users').doc(id).get();
          return {
            'id': id,
            'name': userDoc['name'],
            'photoUrl': userDoc.data()?['photoUrl'] ?? '',
          };
        }));

        setState(() {
          teamMembers = memberData;
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
        return AddTaskWidget(
          team: widget.team,
          teamMembers: teamMembers,
        );
      },
    );
  }

  void _updateTask(
      String taskId, String currentName, String currentDescription, DateTime? startDate, DateTime? endDate, String? currentStatus) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String updatedTask = currentName;
        String updatedDescription = currentDescription;
        DateTime updatedStartDate = startDate ?? DateTime.now();
        DateTime updatedEndDate = endDate ?? DateTime.now();
        String updatedStatus = currentStatus ?? 'No Iniciado';

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título
                const Text(
                  'Actualizar Tarea',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Campo para el título
                const Text('Título', style: TextStyle(fontSize: 16)),
                TextField(
                  onChanged: (value) {
                    updatedTask = value;
                  },
                  controller: TextEditingController(text: updatedTask),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF0EEEE), // Color de fondo
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      borderSide: BorderSide.none, // Sin borde visible
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Campo para la descripción
                const Text('Descripción', style: TextStyle(fontSize: 16)),
                TextField(
                  onChanged: (value) {
                    updatedDescription = value;
                  },
                  controller: TextEditingController(text: updatedDescription),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF0EEEE), // Color de fondo
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      borderSide: BorderSide.none, // Sin borde visible
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Campo para la fecha de inicio
                const Text('Fecha de inicio', style: TextStyle(fontSize: 16)),
                TextField(
                  readOnly: true, // Hace que el campo sea solo lectura
                  controller: TextEditingController(text: updatedStartDate.toLocal().toString().split(' ')[0]), // Muestra la fecha
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.calendar_today), // Ícono del calendario
                    filled: true,
                    fillColor: const Color(0xFFF0EEEE), // Color de fondo
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      borderSide: BorderSide.none, // Sin borde visible
                    ),
                  ),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: updatedStartDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        updatedStartDate = pickedDate; // Actualiza la fecha seleccionada
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Campo para la fecha de fin
                const Text('Fecha de fin', style: TextStyle(fontSize: 16)),
                TextField(
                  readOnly: true, // Hace que el campo sea solo lectura
                  controller: TextEditingController(text: updatedEndDate.toLocal().toString().split(' ')[0]), // Muestra la fecha
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.calendar_today), // Ícono del calendario
                    filled: true,
                    fillColor: const Color(0xFFF0EEEE), // Color de fondo
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      borderSide: BorderSide.none, // Sin borde visible
                    ),
                  ),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: updatedEndDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        updatedEndDate = pickedDate; // Actualiza la fecha seleccionada
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Campo para el estado
                const Text('Estado', style: TextStyle(fontSize: 16)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Estado: Finalizado
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: updatedStatus == 'Finalizado' ? Colors.green : Colors.transparent,
                        side: BorderSide(color: Colors.green),
                      ),
                      onPressed: () {
                        setState(() {
                          updatedStatus = 'Finalizado';
                        });
                      },
                      child: const Text('Finalizado', style: TextStyle(color: Colors.black)),
                    ),
                    
                    // Estado: En desarrollo
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: updatedStatus == 'En desarrollo' ? Colors.orange : Colors.transparent,
                        side: BorderSide(color: Colors.orange),
                      ),
                      onPressed: () {
                        setState(() {
                          updatedStatus = 'En desarrollo';
                        });
                      },
                      child: const Text('En desarrollo', style: TextStyle(color: Colors.black)),
                    ),
                    
                    // Estado: No Iniciado
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: updatedStatus == 'No Iniciado' ? Colors.red : Colors.transparent,
                        side: BorderSide(color: Colors.red),
                      ),
                      onPressed: () {
                        setState(() {
                          updatedStatus = 'No Iniciado';
                        });
                      },
                      child: const Text('No Iniciado', style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Botones Aceptar y Cancelar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Botón Actualizar
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFC8E2B3),
                        ),
                        child: const Text(
                          'Actualizar',
                          style: TextStyle(color: Colors.black),
                        ),
                        onPressed: () async {
                          if (updatedTask.isNotEmpty) {
                            try {
                              await _firestore.collection('tasks').doc(taskId).update({
                                'name': updatedTask,
                                'description': updatedDescription,
                                'startDate': updatedStartDate,
                                'endDate': updatedEndDate,
                                'status': updatedStatus,
                              });
                              setState(() {
                                final index = tasks.indexWhere((task) => task['id'] == taskId);
                                tasks[index]['name'] = updatedTask;
                                tasks[index]['description'] = updatedDescription;
                                tasks[index]['startDate'] = updatedStartDate;
                                tasks[index]['endDate'] = updatedEndDate;
                                tasks[index]['status'] = updatedStatus;
                              });
                            } catch (e) {
                              logger.e('Error updating task: $e');
                            }
                          }
                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Botón Cancelar
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFC6C6C6),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(color: Colors.black),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
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

  Future<void> _showDeleteTaskWarning(String taskId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Column(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Color(0xFFFF9393), // Color de fondo
                child: Icon(Icons.delete, color: Colors.white), // Ícono de papelera
              ),
              const SizedBox(height: 10),
              const Text(
                '¿Desea eliminar la tarea?',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: const Text(
            'Recuerda que la tarea eliminada no se podrá recuperar.',
            textAlign: TextAlign.center,
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFC8E2B3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  child: const Text('Aceptar', style: TextStyle(color: Colors.black)),
                  onPressed: () async {
                    await _deleteTask(taskId); // Llama al método de eliminación
                    Navigator.of(context).pop(); // Cierra el diálogo
                  },
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFC6C6C6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.black)),
                  onPressed: () {
                    Navigator.of(context).pop(); // Cierra el diálogo
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _addMember() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddMemberDialog(
          onMemberAdded: (userId) {
            _addMemberToTeam(userId);
            Navigator.of(context).pop();
          },
          auth: _auth,
          firestore: _firestore,
        );
      },
    );
  }

  void _addMemberToTeam(String userId) async {
    try {
      if (!selectedMembers.contains(userId)) {
        await _firestore.collection('teams').doc(widget.team['id']).update({
          'members': FieldValue.arrayUnion([userId])
        });
        _fetchTeamMembers(); // Actualizar lista de miembros
      }
    } catch (e) {
      logger.e('Error adding member to team: $e');
    }
  }

  void showAssignedMembers(List<String>? assignedMembers) async {
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
          'photoUrl': userDoc['photoUrl'],
        });
      }
    }

    // Mostrar un diálogo con los miembros asignados
    showDialog(
      // ignore: use_build_context_synchronously
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
            const Center(
              // Agrega este widget para centrar el texto
              child: Text(
                'Tareas del equipo',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
                                      tasks[index]['startDate'],
                                      tasks[index]['endDate'],
                                      tasks[index]['status'],
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
                                          _showDeleteTaskWarning(tasks[index]['id']),
                                    ),
                                  ),
                                ],
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

// Nuevo widget para el diálogo de agregar miembro
class AddMemberDialog extends StatefulWidget {
  final Function(String) onMemberAdded;
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  const AddMemberDialog(
      {super.key,
      required this.onMemberAdded,
      required this.auth,
      required this.firestore});

  @override
  AddMemberDialogState createState() => AddMemberDialogState();
}

class AddMemberDialogState extends State<AddMemberDialog> {
  String memberEmail = '';
  List<Map<String, dynamic>> searchResults = [];
  bool isSearching = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: Color(0xFFE5F4DD),
              child: Icon(Icons.person_add, size: 30, color: Color(0xFF7FC47F)),
            ),
            const SizedBox(height: 16),
            const Text('Agregar Miembro',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                  color: const Color(0xFFF0EEEE),
                  borderRadius: BorderRadius.circular(20.0)),
              child: TextField(
                onChanged: (value) {
                  memberEmail = value;
                  if (memberEmail.isNotEmpty) {
                    _searchUsers(memberEmail); // Llama a la función de búsqueda
                  } else {
                    setState(() {
                      searchResults =
                          []; // Restablecer resultados si la consulta está vacía
                      isSearching = false; // Indica que no se está buscando
                    });
                  }
                },
                decoration: const InputDecoration(
                  hintText: "Ingresar correo",
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                ),
              ),
            ),
            const SizedBox(height: 16),
            isSearching
                ? Expanded(
                    child: ListView.builder(
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final user = searchResults[index];
                        return ListTile(
                          title: Text(user['name']),
                          subtitle: Text(user['email']),
                          onTap: () {
                            widget.onMemberAdded(user['id']);
                          },
                        );
                      },
                    ),
                  )
                : const SizedBox.shrink(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFC8E2B3)),
                    child: const Text('Aceptar',
                        style: TextStyle(color: Colors.black)),
                    onPressed: () {
                      // Aquí puedes manejar la lógica de aceptación si es necesario
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFC6C6C6)),
                    child: const Text('Cancelar',
                        style: TextStyle(color: Colors.black)),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _searchUsers(String query) async {
    logger
        .d('Buscando usuarios con el nombre: $query'); // Mensaje de depuración
    if (query.isNotEmpty) {
      final user = widget.auth.currentUser; // Obtén el usuario autenticado
      if (user != null) {
        try {
          final results = await widget.firestore
              .collection('users')
              .where('name', isGreaterThanOrEqualTo: query) // Cambiar a 'name'
              .where('name',
                  isLessThanOrEqualTo:
                      '$query\uf8ff') // Para buscar coincidencias
              .get();

          logger.d(
              'Resultados encontrados: ${results.docs.length}'); // Mensaje de depuración

          setState(() {
            searchResults = results.docs
                .map((doc) => {
                      'id': doc.id,
                      'name': doc['name'],
                      'email': doc[
                          'email'], // Asegúrate de incluir el email si lo necesitas
                    })
                .toList();
            isSearching = true; // Indica que se está buscando
          });
        } catch (e) {
          logger
              .e('Error fetching users: $e'); // Imprime el error en la consola
        }
      }
    } else {
      setState(() {
        searchResults = []; // Restablecer resultados si la consulta está vacía
        isSearching = false; // Indica que no se está buscando
      });
    }
  }
}
