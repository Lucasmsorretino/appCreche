import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';

class SaudePage extends StatefulWidget {
  @override
  _SaudePageState createState() => _SaudePageState();
}

class _SaudePageState extends State<SaudePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<HealthRecord> _healthRecords = [
    HealthRecord(
      id: 1,
      title: 'Medicação - Paracetamol',
      date: DateTime.now().subtract(Duration(days: 2)),
      description: 'Administrar 5ml às 14:00 em caso de febre acima de 38°C',
      status: 'Pendente',
      childName: 'Ana Silva',
    ),
    HealthRecord(
      id: 2,
      title: 'Alergia Alimentar',
      date: DateTime.now().subtract(Duration(days: 5)),
      description: 'Ana apresenta reação a morango, favor não oferecer',
      status: 'Informativo',
      childName: 'Ana Silva',
    ),
    HealthRecord(
      id: 3,
      title: 'Febre - 38.5°C',
      date: DateTime.now().subtract(Duration(days: 1)),
      description: 'Criança apresentou febre às 10:30, responsável foi informado por telefone',
      status: 'Concluído',
      childName: 'Pedro Oliveira',
    ),
  ];
  
  final List<HealthRecord> _dietRecords = [
    HealthRecord(
      id: 4,
      title: 'Intolerância à Lactose',
      date: DateTime.now().subtract(Duration(days: 30)),
      description: 'Não oferecer leite e derivados',
      status: 'Permanente',
      childName: 'Lucas Mendes',
    ),
    HealthRecord(
      id: 5,
      title: 'Dieta Especial',
      date: DateTime.now().subtract(Duration(days: 10)),
      description: 'Substituir carboidratos refinados por integrais conforme orientação nutricional',
      status: 'Ativo',
      childName: 'Julia Costa',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isFuncionario = authService.userType == 'funcionario';
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Saúde'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Medicação', icon: Icon(Icons.medical_services)),
            Tab(text: 'Alimentação', icon: Icon(Icons.restaurant)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Medicação Tab
          _buildHealthRecordsList(_healthRecords),
          
          // Alimentação Tab
          _buildHealthRecordsList(_dietRecords),
        ],
      ),
      floatingActionButton: isFuncionario ? FloatingActionButton(
        onPressed: () => _showAddHealthRecordDialog(context),
        child: Icon(Icons.add),
      ) : null,
    );
  }
  
  Widget _buildHealthRecordsList(List<HealthRecord> records) {
    if (records.isEmpty) {
      return Center(
        child: Text('Nenhum registro encontrado'),
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text(
                  record.title,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Criança: ${record.childName}'),
                trailing: _buildStatusChip(record.status),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.description,
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Data: ${DateFormat('dd/MM/yyyy').format(record.date)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => _showEditHealthRecordDialog(context, record),
                          child: Text('Editar'),
                        ),
                        SizedBox(width: 8),
                        record.status != 'Concluído'
                            ? ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    record.status = 'Concluído';
                                  });
                                },
                                child: Text('Marcar como concluído'),
                              )
                            : Container(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildStatusChip(String status) {
    Color chipColor;
    
    switch (status) {
      case 'Pendente':
        chipColor = Colors.orange;
        break;
      case 'Concluído':
        chipColor = Colors.green;
        break;
      case 'Informativo':
        chipColor = Colors.blue;
        break;
      case 'Permanente':
        chipColor = Colors.purple;
        break;
      case 'Ativo':
        chipColor = Colors.teal;
        break;
      default:
        chipColor = Colors.grey;
    }
    
    return Chip(
      backgroundColor: chipColor.withOpacity(0.2),
      label: Text(
        status,
        style: TextStyle(
          color: chipColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showAddHealthRecordDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final childNameController = TextEditingController();
    String status = 'Pendente';
    int tabIndex = _tabController.index;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adicionar Registro de ${tabIndex == 0 ? 'Medicação' : 'Alimentação'}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: childNameController,
                decoration: InputDecoration(
                  labelText: 'Nome da Criança',
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
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                value: status,
                items: tabIndex == 0
                    ? ['Pendente', 'Concluído', 'Informativo'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList()
                    : ['Ativo', 'Pendente', 'Permanente', 'Informativo'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                onChanged: (value) {
                  status = value!;
                },
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
              if (titleController.text.isNotEmpty && childNameController.text.isNotEmpty) {
                setState(() {
                  final newRecord = HealthRecord(
                    id: _healthRecords.length + _dietRecords.length + 1,
                    title: titleController.text,
                    description: descriptionController.text,
                    date: DateTime.now(),
                    status: status,
                    childName: childNameController.text,
                  );
                  
                  if (tabIndex == 0) {
                    _healthRecords.add(newRecord);
                  } else {
                    _dietRecords.add(newRecord);
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

  void _showEditHealthRecordDialog(BuildContext context, HealthRecord record) {
    final titleController = TextEditingController(text: record.title);
    final descriptionController = TextEditingController(text: record.description);
    final childNameController = TextEditingController(text: record.childName);
    String status = record.status;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Registro'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: childNameController,
                decoration: InputDecoration(
                  labelText: 'Nome da Criança',
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
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                value: status,
                items: ['Pendente', 'Concluído', 'Informativo', 'Permanente', 'Ativo'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) {
                  status = value!;
                },
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
              if (titleController.text.isNotEmpty && childNameController.text.isNotEmpty) {
                setState(() {
                  record.title = titleController.text;
                  record.description = descriptionController.text;
                  record.childName = childNameController.text;
                  record.status = status;
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

class HealthRecord {
  final int id;
  String title;
  final DateTime date;
  String description;
  String status;
  String childName;

  HealthRecord({
    required this.id,
    required this.title,
    required this.date,
    required this.description,
    required this.status,
    required this.childName,
  });
}