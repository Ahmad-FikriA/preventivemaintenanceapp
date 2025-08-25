import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/sources/firestore_equipment_repo.dart';
import '../../data/models/equipment.dart';

class EquipmentDetailPage extends StatelessWidget {
  final String equipmentId;
  const EquipmentDetailPage({super.key, required this.equipmentId});

  @override
  Widget build(BuildContext context) {
    final repo = FirestoreEquipmentRepo();
    return Scaffold(
      appBar: AppBar(title: const Text('Equipment Detail')),
      body: FutureBuilder<Equipment?>(
        future: repo.getById(equipmentId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final eq = snap.data;
          if (eq == null) return const Center(child: Text('Equipment not found'));

          String updated = eq.updatedAt != null ? eq.updatedAt!.toLocal().toString() : '-';
          String created = eq.createdAt != null ? eq.createdAt!.toLocal().toString() : '-';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(eq.name, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text('Code: ${eq.code}'),
                if (eq.location != null) ...[
                  const SizedBox(height: 4),
                  Text('Location: ${eq.location}'),
                ],
                const SizedBox(height: 12),
                Text('Specifications', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                const Text('No structured specifications available for this equipment.'),
                const SizedBox(height: 12),
                Text('Images', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (eq.images.isNotEmpty)
                  ...eq.images.map((i) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(i),
                      ))
                else
                  const Text('No images'),
                const Spacer(),
                Text('Created: $created'),
                Text('Updated: $updated'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        child: const Text('Lakukan Servis / Checklist'),
                        onPressed: () {
                          // Navigate to the template picker for this equipment (root-level)
                          context.go('/t/templates/$equipmentId');
                        },
                      ),
                    ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
