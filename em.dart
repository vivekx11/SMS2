// em.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart'; // Import for AppState, RepairJob

class DashboardPage extends StatelessWidget {
  const DashboardPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final st = Provider.of<AppState>(context);
    final pendingRepairs = st.repairs
        .where((r) => r.status != 'Completed')
        .length;
    final completed = st.repairs.where((r) => r.status == 'Completed').length;
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: ListView(
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.build_circle),
              title: const Text("Repairs Pending"),
              subtitle: Text("$pendingRepairs pending"),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.check_circle),
              title: const Text("Repairs Completed"),
              subtitle: Text("$completed completed"),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
