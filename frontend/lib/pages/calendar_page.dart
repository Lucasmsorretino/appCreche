import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class CalendarioPage extends StatefulWidget {
  @override
  _CalendarioPageState createState() => _CalendarioPageState();
}

class _CalendarioPageState extends State<CalendarioPage> {
  DateTime _selectedDate = DateTime.now();
  final List<Event> _events = [
    Event(
      title: 'Reunião de Pais',
      date: DateTime(2025, 4, 20),
      description: 'Reunião semestral com os professores',
    ),
    Event(
      title: 'Festa Junina',
      date: DateTime(2025, 6, 15),
      description: 'Traje típico e comidas tradicionais',
    ),
    Event(
      title: 'Dia das Crianças',
      date: DateTime(2025, 10, 12),
      description: 'Atividades especiais e lanches',
    ),
    Event(
      title: 'Encerramento do Ano',
      date: DateTime(2025, 12, 10),
      description: 'Apresentação das crianças e entrega de relatórios',
    ),
  ];

  List<Event> _getEventsForDay(DateTime day) {
    return _events.where((event) => 
      event.date.year == day.year && 
      event.date.month == day.month && 
      event.date.day == day.day
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isFuncionario = authService.userType == 'funcionario';
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Calendário Escolar'),
      ),
      body: Column(
        children: [
          _buildCalendarHeader(),
          // Grid responsivo do calendário
          Expanded(child: _buildCalendarGrid()),
          Divider(height: 1),
          Expanded(child: _buildEventsList()),
        ],
      ),
      floatingActionButton: isFuncionario ? FloatingActionButton(
        onPressed: () => _showAddEventDialog(),
        child: Icon(Icons.add),
      ) : null,
    );
  }

  Widget _buildCalendarHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedDate = DateTime(
                  _selectedDate.year,
                  _selectedDate.month - 1,
                  _selectedDate.day,
                );
              });
            },
          ),
          Text(
            DateFormat('MMMM yyyy').format(_selectedDate),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _selectedDate = DateTime(
                  _selectedDate.year,
                  _selectedDate.month + 1,
                  _selectedDate.day,
                );
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    // Get the first day of the month
    final firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    
    // Get the day of week (0 for Monday, 6 for Sunday)
    final dayOfWeek = firstDayOfMonth.weekday;
    
    // Get the number of days in the month
    final daysInMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    
    // Create a list of dates to display
    final List<DateTime?> calendarDays = [];
    
    // Add empty slots for days before the first of the month
    for (int i = 0; i < dayOfWeek - 1; i++) {
      calendarDays.add(null);
    }
    
    // Add the days of the month
    for (int i = 1; i <= daysInMonth; i++) {
      calendarDays.add(DateTime(_selectedDate.year, _selectedDate.month, i));
    }
    
    return Container(
      padding: EdgeInsets.all(8),
      child: GridView.builder(
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1,
        ),
        itemCount: calendarDays.length + 7, // Add 7 for the weekday headers
        itemBuilder: (context, index) {
          if (index < 7) {
            // Weekday header
            final weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
            return Center(
              child: Text(
                weekdays[index],
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          }
          
          final dayIndex = index - 7;
          if (dayIndex >= calendarDays.length || calendarDays[dayIndex] == null) {
            return Container();
          }
          
          final day = calendarDays[dayIndex]!;
          final eventsForDay = _getEventsForDay(day);
          final isToday = day.year == DateTime.now().year && 
                         day.month == DateTime.now().month && 
                         day.day == DateTime.now().day;
          final isSelected = day.year == _selectedDate.year && 
                            day.month == _selectedDate.month && 
                            day.day == _selectedDate.day;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = day;
              });
            },
            child: Container(
              margin: EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Theme.of(context).primaryColor
                    : eventsForDay.isNotEmpty 
                        ? Theme.of(context).primaryColor.withOpacity(0.3)
                        : null,
                border: isToday ? Border.all(color: Colors.red, width: 2) : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  day.day.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : null,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventsList() {
    final eventsForSelectedDay = _getEventsForDay(_selectedDate);
    
    if (eventsForSelectedDay.isEmpty) {
      return Center(
        child: Text('Nenhum evento para ${DateFormat('dd/MM/yyyy').format(_selectedDate)}'),
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: eventsForSelectedDay.length,
      itemBuilder: (context, index) {
        final event = eventsForSelectedDay[index];
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          child: ListTile(
            title: Text(
              event.title,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(event.description),
            leading: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.event,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddEventDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adicionar Evento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Data: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}'),
            SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(),
              ),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                setState(() {
                  _events.add(Event(
                    title: titleController.text,
                    description: descriptionController.text,
                    date: _selectedDate,
                  ));
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

class Event {
  final String title;
  final DateTime date;
  final String description;

  Event({
    required this.title,
    required this.date,
    required this.description,
  });
}
