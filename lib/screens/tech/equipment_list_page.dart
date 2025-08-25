import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/sources/firestore_equipment_repo.dart';
import '../../data/models/equipment.dart';

class EquipmentListPage extends StatelessWidget {
  const EquipmentListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = FirestoreEquipmentRepo();
    return Scaffold(
      appBar: AppBar(title: const Text('Equipment')),
              
      body: StreamBuilder<List<Equipment>>(
        stream: repo.watchAll(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? const <Equipment>[];
          if (items.isEmpty) {
            return const Center(child: Text('No equipment yet'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final e = items[i];
              return ListTile(
                title: Text(e.name),
                subtitle: Text('${e.code}${e.location == null ? '' : ' • ${e.location}'}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/t/equipment/${e.id}'),
              );
            },
          );
        },
      ),
  // Editing/adding equipment is now admin-only; FAB removed for technicians.
      
    );
  }
}
