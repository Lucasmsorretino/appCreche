import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userType = authService.userType;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('CMEI App'),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () async {
              await authService.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bem-vindo ${userType == 'responsavel' ? 'Responsável' : 'Funcionário'}!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            
            // Main menu grid
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildMenuCard(
                  context, 
                  'Avisos', 
                  Icons.announcement, 
                  Colors.orange, 
                  () => Navigator.pushNamed(context, '/notices')
                ),
                _buildMenuCard(
                  context, 
                  'Rotina', 
                  Icons.schedule, 
                  Colors.blue, 
                  () => Navigator.pushNamed(context, '/routine')
                ),
                _buildMenuCard(
                  context, 
                  'Saúde', 
                  Icons.local_hospital, 
                  Colors.red, 
                  () => Navigator.pushNamed(context, '/health')
                ),
                _buildMenuCard(
                  context, 
                  'Calendário', 
                  Icons.calendar_today, 
                  Colors.green, 
                  () => Navigator.pushNamed(context, '/calendar')
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMenuCard(BuildContext context, String title, IconData icon, 
      Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              SizedBox(height: 12),
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}