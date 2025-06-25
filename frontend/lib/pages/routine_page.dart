import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';

class RoutinePage extends StatefulWidget {
  @override
  _RoutinePageState createState() => _RoutinePageState();
}

class _RoutinePageState extends State<RoutinePage> {
  final List<Child> _children = [
    Child(id: 1, name: 'Ana Silva', age: '3 anos', classroom: 'Turma A'),
    Child(id: 2, name: 'Pedro Oliveira', age: '2 anos', classroom: 'Turma B'),
    Child(id: 3, name: 'Lucas Mendes', age: '4 anos', classroom: 'Turma A'),
    Child(id: 4, name: 'Julia Costa', age: '3 anos', classroom: 'Turma A'),
    Child(id: 5, name: 'Mateus Santos', age: '4 anos', classroom: 'Turma C'),
  ];

  final Map<int, List<RoutineActivity>> _childActivities = {
    1: [
      RoutineActivity(
        id: 1,
        type: ActivityType.meal,
        time: TimeOfDay(hour: 9, minute: 30),
        description: 'Tomou café da manhã completo',
        date: DateTime.now(),
      ),
      RoutineActivity(
        id: 2,
        type: ActivityType.nap,
        time: TimeOfDay(hour: 13, minute: 0),
        description: 'Dormiu por 2 horas',
        date: DateTime.now(),
      ),
      RoutineActivity(
        id: 3,
        type: ActivityType.educational,
        time: TimeOfDay(hour: 10, minute: 0),
        description: 'Participou da roda de leitura',
        date: DateTime.now(),
      ),
    ],
    2: [
      RoutineActivity(
        id: 4,
        type: ActivityType.meal,
        time: TimeOfDay(hour: 11, minute: 30),
        description: 'Almoçou bem, comeu todos os legumes',
        date: DateTime.now(),
      ),
      RoutineActivity(
        id: 5,
        type: ActivityType.hygiene,
        time: TimeOfDay(hour: 14, minute: 15),
        description: 'Trocado após o sono',
        date: DateTime.now(),
      ),
    ],
  };

  Child? _selectedChild;

  @override
  void initState() {
    super.initState();
    if (_children.isNotEmpty) {
      _selectedChild = _children.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isFuncionario = authService.userType == 'funcionario';
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Rotina Diária'),
      ),
      body: Column(
        children: [
          _buildChildSelector(),
          Expanded(
            child: _selectedChild != null 
                ? _buildActivityTimeline(_selectedChild!.id) 
                : Center(child: Text('Selecione uma criança')),
          ),
        ],
      ),
      floatingActionButton: isFuncionario && _selectedChild != null 
          ? FloatingActionButton(
              onPressed: () => _showAddActivityDialog(context),
              child: Icon(Icons.add),
            ) 
          : null,
    );
  }

  Widget _buildChildSelector() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selecione uma criança:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<Child>(
              isExpanded: true,
              value: _selectedChild,
              underline: Container(),
              items: _children.map((Child child) {
                return DropdownMenuItem<Child>(
                  value: child,
                  child: Text('${child.name} - ${child.classroom}'),
                );
              }).toList(),
              onChanged: (Child? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedChild = newValue;
                  });
                }
              },
            ),
          ),
          SizedBox(height: 8),
          if (_selectedChild != null)
            Text(
              'Idade: ${_selectedChild!.age}',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityTimeline(int childId) {
    final activities = _childActivities[childId] ?? [];
    
    if (activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhuma atividade registrada para hoje',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    // Sort activities by time
    activities.sort((a, b) {
      final aMinutes = a.time.hour * 60 + a.time.minute;
      final bMinutes = b.time.hour * 60 + b.time.minute;
      return aMinutes.compareTo(bMinutes);
    });
    
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        final isLast = index == activities.length - 1;
        
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                _buildActivityIcon(activity.type),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 70,
                    color: Colors.grey[300],
                  ),
              ],
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatTime(activity.time),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 4),
                  Card(
                    margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getActivityTitle(activity.type),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(activity.description),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => _showEditActivityDialog(context, activity, childId),
                                child: Text('Editar'),
                              ),
                              SizedBox(width: 8),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _childActivities[childId]!.removeWhere((a) => a.id == activity.id);
                                  });
                                },
                                child: Text('Remover', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildActivityIcon(ActivityType type) {
    IconData iconData;
    Color iconColor;
    
    switch (type) {
      case ActivityType.meal:
        iconData = Icons.restaurant;
        iconColor = Colors.orange;
        break;
      case ActivityType.nap:
        iconData = Icons.bedtime;
        iconColor = Colors.indigo;
        break;
      case ActivityType.hygiene:
        iconData = Icons.cleaning_services;
        iconColor = Colors.blue;
        break;
      case ActivityType.educational:
        iconData = Icons.school;
        iconColor = Colors.green;
        break;
      case ActivityType.other:
        iconData = Icons.category;
        iconColor = Colors.purple;
        break;
    }
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }
  
  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  
  String _getActivityTitle(ActivityType type) {
    switch (type) {
      case ActivityType.meal:
        return 'Alimentação';
      case ActivityType.nap:
        return 'Sono/Descanso';
      case ActivityType.hygiene:
        return 'Higiene';
      case ActivityType.educational:
        return 'Atividade Pedagógica';
      case ActivityType.other:
        return 'Outra Atividade';
    }
  }

  void _showAddActivityDialog(BuildContext context) {
    final descriptionController = TextEditingController();
    ActivityType selectedType = ActivityType.meal;
    TimeOfDay selectedTime = TimeOfDay.now();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adicionar Atividade'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Criança: ${_selectedChild!.name}'),
              SizedBox(height: 16),
              Text('Tipo de Atividade:'),
              SizedBox(height: 8),
              DropdownButtonFormField<ActivityType>(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                ),
                value: selectedType,
                items: ActivityType.values.map((ActivityType type) {
                  return DropdownMenuItem<ActivityType>(
                    value: type,
                    child: Text(_getActivityTitle(type)),
                  );
                }).toList(),
                onChanged: (ActivityType? value) {
                  if (value != null) {
                    selectedType = value;
                  }
                },
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Text('Horário: '),
                  TextButton(
                    onPressed: () async {
                      final TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (pickedTime != null) {
                        selectedTime = pickedTime;
                      }
                    },
                    child: Text(_formatTime(selectedTime)),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (descriptionController.text.isNotEmpty) {
                setState(() {
                  if (_childActivities[_selectedChild!.id] == null) {
                    _childActivities[_selectedChild!.id] = [];
                  }
                  
                  // Find the highest ID to increment
                  int maxId = 0;
                  _childActivities.forEach((_, activities) {
                    for (var activity in activities) {
                      if (activity.id > maxId) {
                        maxId = activity.id;
                      }
                    }
                  });
                  
                  _childActivities[_selectedChild!.id]!.add(
                    RoutineActivity(
                      id: maxId + 1,
                      type: selectedType,
                      time: selectedTime,
                      description: descriptionController.text,
                      date: DateTime.now(),
                    ),
                  );
                });
                Navigator.pop(context);
              }
            },
            child: Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _showEditActivityDialog(BuildContext context, RoutineActivity activity, int childId) {
    final descriptionController = TextEditingController(text: activity.description);
    ActivityType selectedType = activity.type;
    TimeOfDay selectedTime = activity.time;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Atividade'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Criança: ${_selectedChild!.name}'),
              SizedBox(height: 16),
              Text('Tipo de Atividade:'),
              SizedBox(height: 8),
              DropdownButtonFormField<ActivityType>(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                ),
                value: selectedType,
                items: ActivityType.values.map((ActivityType type) {
                  return DropdownMenuItem<ActivityType>(
                    value: type,
                    child: Text(_getActivityTitle(type)),
                  );
                }).toList(),
                onChanged: (ActivityType? value) {
                  if (value != null) {
                    selectedType = value;
                  }
                },
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Text('Horário: '),
                  TextButton(
                    onPressed: () async {
                      final TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (pickedTime != null) {
                        selectedTime = pickedTime;
                      }
                    },
                    child: Text(_formatTime(selectedTime)),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (descriptionController.text.isNotEmpty) {
                setState(() {
                  final index = _childActivities[childId]!.indexWhere((a) => a.id == activity.id);
                  if (index != -1) {
                    _childActivities[childId]![index] = RoutineActivity(
                      id: activity.id,
                      type: selectedType,
                      time: selectedTime,
                      description: descriptionController.text,
                      date: activity.date,
                    );
                  }
                });
                Navigator.pop(context);
              }
            },
            child: Text('Salvar'),
          ),
        ],
      ),
    );
  }
}

class Child {
  final int id;
  final String name;
  final String age;
  final String classroom;

  Child({
    required this.id,
    required this.name,
    required this.age,
    required this.classroom,
  });
}

class RoutineActivity {
  final int id;
  final ActivityType type;
  final TimeOfDay time;
  final String description;
  final DateTime date;

  RoutineActivity({
    required this.id,
    required this.type,
    required this.time,
    required this.description,
    required this.date,
  });
}

enum ActivityType {
  meal,
  nap,
  hygiene,
  educational,
  other,
}
