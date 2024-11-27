import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class AddTaskWidget extends StatefulWidget {
  final Map<String, dynamic> team;
  final List<Map<String, dynamic>> teamMembers;
  final VoidCallback onTaskAdded;

  const AddTaskWidget({
    super.key,
    required this.team,
    required this.teamMembers,
    required this.onTaskAdded,
  });

  @override
  AddTaskWidgetState createState() => AddTaskWidgetState();
}

class AddTaskWidgetState extends State<AddTaskWidget> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String newTask = '';
  String newDescription = '';
  String? selectedResponsible;
  DateTime? startDate;
  DateTime? endDate;
  String taskStatus = 'Pendiente';

  void _saveTask() async {
    if (newTask.isNotEmpty) {
      try {
        final user = _auth.currentUser;
        if (user != null) {
          await _firestore.collection('tasks').add({
            'name': newTask,
            'description': newDescription,
            'teamId': widget.team['id'],
            'userId': user.uid,
            'responsibleId': selectedResponsible,
            'status': taskStatus,
            'startDate': startDate,
            'endDate': endDate,
          });

          widget.onTaskAdded();
          // ignore: use_build_context_synchronously
          Navigator.of(context).pop();
        }
      } catch (e) {
        logger.e('Error adding task: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Añadir tarea',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 25),

              // Task title field
              const Text('Título de la nota',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                onChanged: (value) {
                  newTask = value;
                },
                decoration: const InputDecoration(
                  hintText: "Título de la tarea",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Color(0xFFFFF59D),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                ),
              ),
              const SizedBox(height: 16),

              // Description field
              const Text('Descripción',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                maxLines: 3,
                onChanged: (value) {
                  newDescription = value;
                },
                decoration: const InputDecoration(
                  hintText: "Ingrese la descripción",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Color(0xFFFFF59D),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                ),
              ),
              const SizedBox(height: 16),

              // Responsible dropdown
              const Text('Responsable:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF59D),
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButton<String>(
                  value: selectedResponsible,
                  hint: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('Selecciona un responsable',
                        style: TextStyle(color: Colors.black54)),
                  ),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedResponsible = newValue;
                    });
                  },
                  items: widget.teamMembers
                      .map<DropdownMenuItem<String>>((member) {
                    return DropdownMenuItem<String>(
                      value: member['id'],
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(member['name']),
                      ),
                    );
                  }).toList(),
                  isExpanded: true,
                  underline: const SizedBox(),
                ),
              ),
              const SizedBox(height: 16),

              // Status indicators
              const Text('Estado',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      StatusIndicator(
                        status: 'Finalizado',
                        color: Colors.green,
                        isSelected: taskStatus == 'Finalizado',
                        onTap: () => setState(() => taskStatus = 'Finalizado'),
                      ),
                      const SizedBox(height: 8),
                      StatusIndicator(
                        status: 'En desarrollo',
                        color: Colors.orange,
                        isSelected: taskStatus == 'En desarrollo',
                        onTap: () =>
                            setState(() => taskStatus = 'En desarrollo'),
                      ),
                      const SizedBox(height: 8),
                      StatusIndicator(
                        status: 'No Iniciado',
                        color: Colors.red,
                        isSelected: taskStatus == 'No Iniciado',
                        onTap: () => setState(() => taskStatus = 'No Iniciado'),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      DateField(
                        label: 'Fecha de inicio',
                        selectedDate: startDate,
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2022),
                            lastDate: DateTime(2101),
                          );
                          if (picked != null && picked != startDate) {
                            setState(() {
                              startDate = picked;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      DateField(
                        label: 'Fecha final',
                        selectedDate: endDate,
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2022),
                            lastDate: DateTime(2101),
                          );
                          if (picked != null && picked != endDate) {
                            setState(() {
                              endDate = picked;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Save button
              Center(
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFC8E2B3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  onPressed: _saveTask,
                  child: const Text(
                    'Guardar',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatusIndicator extends StatelessWidget {
  final String status;
  final Color color;
  final bool isSelected;
  final VoidCallback? onTap;

  const StatusIndicator({
    super.key,
    required this.status,
    required this.color,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, color: color, size: 12),
            const SizedBox(width: 8),
            Text(status, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class DateField extends StatelessWidget {
  final String label;
  final DateTime? selectedDate;
  final VoidCallback onTap;

  const DateField({
    super.key,
    required this.label,
    required this.selectedDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF59D),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    selectedDate != null
                        ? "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"
                        : 'Seleccionar',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.access_time, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
