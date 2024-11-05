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
  List<Map<String, dynamic>> teamMembers = [];
  List<String> selectedMembers = [];
  Color? selectedColor;

  // Nuevas variables para la búsqueda de miembros
  List<Map<String, dynamic>> searchResults =
      []; // Lista para almacenar resultados de búsqueda
  bool isSearching = false; // Bandera para indicar si se está buscando

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
          teamMembers =
              memberData; // Asegúrate de que esto sea una lista de mapas
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
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20.0), // Bordes redondeados del cuadro
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0), // Espaciado interno
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título personalizado
                const Center(
                  child: Text(
                    'Añadir tarea',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                // Campo para título de la nota
                const Text(
                  'Título de la nota',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(
                        0xFFFFF1B0), // Color de fondo amarillo claro
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC7AE2B)
                            .withOpacity(0.5), // Sombra dorada
                        blurRadius: 6,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (value) {
                      newTask = value;
                    },
                    decoration: const InputDecoration(
                      hintText: "Título de la tarea",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ), // Padding interno
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Campo para la descripción
                const Text(
                  'Descripción',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(
                        0xFFFFF1B0), // Color de fondo amarillo claro
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC7AE2B)
                            .withOpacity(0.5), // Sombra dorada
                        blurRadius: 6,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    maxLines: 3,
                    onChanged: (value) {
                      newDescription = value;
                    },
                    decoration: const InputDecoration(
                      hintText: "Ingrese la descripción",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ), // Padding interno
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Responsable
                const Text(
                  'Seleccionar responsable:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1B0), // Color de fondo amarillo claro
                    borderRadius: BorderRadius.circular(20.0), // Bordes redondeados
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC7AE2B).withOpacity(0.5), // Sombra dorada
                        blurRadius: 6,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: DropdownButton<String>(
                    value: selectedResponsible,
                    hint: const Text('Selecciona un responsable'),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedResponsible = newValue;
                      });
                    },
                    items: teamMembers.map<DropdownMenuItem<String>>((member) {
                      return DropdownMenuItem<String>(
                        value: member['id'],
                        child: Text(
                          member['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      );
                    }).toList(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    dropdownColor: Colors.white,
                    underline: Container(
                      height: 2,
                      color: Colors.transparent, // Sin subrayado visible
                    ),
                    isExpanded: true, // Para que ocupe todo el ancho del contenedor
                  ),
                ),
                const SizedBox(height: 16),

                // Estado
                const Text(
                  'Estado',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Estado: Finalizado
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedColor = const Color(0xFFB1DAA1); // Terminado
                        });
                      },
                      child: CircleAvatar(
                        backgroundColor: const Color(0xFFB1DAA1),
                        radius: 20,
                        child: selectedColor == const Color(0xFFB1DAA1)
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    ),
                    // Estado: En desarrollo
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedColor =
                              const Color((0xFFFFEE93)); // En desarrollo
                        });
                      },
                      child: CircleAvatar(
                        backgroundColor: const Color((0xFFFFEE93)),
                        radius: 20,
                        child: selectedColor == const Color((0xFFFFEE93))
                            ? const Icon(Icons.check, color: Colors.black)
                            : null,
                      ),
                    ),
                    // Estado: Asignado
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedColor = const Color(0xFFFF9393); // Asignado
                        });
                      },
                      child: CircleAvatar(
                        backgroundColor: const Color(0xFFFF9393),
                        radius: 20,
                        child: selectedColor == const Color(0xFFFF9393)
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Fechas de inicio y final
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fecha de inicio',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fecha final',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Botón Guardar
                Center(
                  child: SizedBox(
                    width: 150, // Ancho específico para el botón Guardar
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(
                            0xFFC8E2B3), // Color de fondo verde claro
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                      ),
                      child: const Text(
                        'Guardar',
                        style: TextStyle(
                          color: Colors.black, // Color del texto
                          fontWeight: FontWeight.bold,
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
                                'description': newDescription,
                                'teamId': widget.team['id'],
                                'userId': user.uid,
                                'statusColor': selectedColor?.value ??
                                    Colors.transparent.value,
                                'responsibleId': selectedResponsible,
                              });
                              setState(() {
                                tasks.add({
                                  'id': docRef.id,
                                  'name': newTask,
                                  'description': newDescription,
                                });
                              });
                            }
                          } catch (e) {
                            logger.e('Error adding task: $e');
                          }
                        }
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
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
        String updatedDescription = currentDescription;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20.0), // Bordes redondeados del cuadro
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0), // Espaciado interno
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono en la parte superior
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Color(0xFFE5F4DD), // Color verde claro
                  child: Icon(
                    Icons.edit,
                    size: 40,
                    color: Color(0xFF7FC47F), // Color verde
                  ),
                ),
                const SizedBox(height: 16),

                // Título centrado
                const Text(
                  'Actualizar Tarea',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),

                // Campo para el nombre de la tarea
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0EEEE), // Color de fondo gris claro
                    borderRadius:
                        BorderRadius.circular(20.0), // Bordes redondeados
                  ),
                  child: TextField(
                    onChanged: (value) {
                      updatedTask = value;
                    },
                    controller: TextEditingController(text: currentName),
                    decoration: const InputDecoration(
                      hintText: "Ingrese la nueva tarea",
                      hintStyle: TextStyle(
                        color: Color(0xFFB4B4B4), // Color del hint (gris claro)
                      ),
                      border: InputBorder.none, // Sin borde visible
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ), // Relleno interno
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Campo para la descripción de la tarea
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0EEEE), // Color de fondo gris claro
                    borderRadius:
                        BorderRadius.circular(20.0), // Bordes redondeados
                  ),
                  child: TextField(
                    onChanged: (value) {
                      updatedDescription = value;
                    },
                    controller: TextEditingController(text: currentDescription),
                    decoration: const InputDecoration(
                      hintText: "Ingrese la nueva descripción",
                      hintStyle: TextStyle(
                        color: Color(0xFFB4B4B4), // Color del hint (gris claro)
                      ),
                      border: InputBorder.none, // Sin borde visible
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ), // Relleno interno
                    ),
                  ),
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
                          backgroundColor: const Color(
                              0xFFC8E2B3), // Color de fondo verde claro
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                        ),
                        child: const Text(
                          'Actualizar',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () async {
                          if (updatedTask.isNotEmpty) {
                            try {
                              await _firestore
                                  .collection('tasks')
                                  .doc(taskId)
                                  .update({
                                'name': updatedTask,
                                'description': updatedDescription,
                              });
                              setState(() {
                                final index = tasks
                                    .indexWhere((task) => task['id'] == taskId);
                                tasks[index]['name'] = updatedTask;
                                tasks[index]['description'] =
                                    updatedDescription;
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
                          backgroundColor: const Color(
                              0xFFC6C6C6), // Color de fondo gris claro
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
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

  const AddMemberDialog({super.key, required this.onMemberAdded, required this.auth, required this.firestore});

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
                      searchResults = []; // Restablecer resultados si la consulta está vacía
                      isSearching = false; // Indica que no se está buscando
                    });
                  }
                },
                decoration: const InputDecoration(
                  hintText: "Ingresar correo",
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
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
    print('Buscando usuarios con el nombre: $query'); // Mensaje de depuración
    if (query.isNotEmpty) {
      final user = widget.auth.currentUser; // Obtén el usuario autenticado
      if (user != null) {
        try {
          final results = await widget.firestore
              .collection('users')
              .where('name', isGreaterThanOrEqualTo: query) // Cambiar a 'name'
              .where('name', isLessThanOrEqualTo: query + '\uf8ff') // Para buscar coincidencias
              .get();

          print('Resultados encontrados: ${results.docs.length}'); // Mensaje de depuración

          setState(() {
            searchResults = results.docs
                .map((doc) => {
                      'id': doc.id,
                      'name': doc['name'],
                      'email': doc['email'], // Asegúrate de incluir el email si lo necesitas
                    })
                .toList();
            isSearching = true; // Indica que se está buscando
          });
        } catch (e) {
          logger.e('Error fetching users: $e'); // Imprime el error en la consola
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
