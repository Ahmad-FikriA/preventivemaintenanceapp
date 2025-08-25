import '../../core/utils/auth_helpers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/sources/firestore_template_repo.dart';
import '../../data/sources/firestore_instance_repo.dart';
import '../../data/models/checklist_template.dart';

class TemplatePickerPage extends StatelessWidget {
  final String equipmentId;
  const TemplatePickerPage({super.key, required this.equipmentId});

  @override
  Widget build(BuildContext context) {
    final repo = FirestoreTemplateRepo();
    final instanceRepo = FirestoreInstanceRepo();
  final uid = requireUidOrRedirect(context);
  if (uid == null) return const Scaffold(body: Center(child: Text('Please sign in')));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Template'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Ensure we return to equipment detail in the tech shell (root-level route)
            context.go('/t/equipment/$equipmentId');
          },
        ),
      ),
      body: StreamBuilder<List<ChecklistTemplate>>(
        stream: repo.watchPublished(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final templates = snap.data!;
          if (templates.isEmpty) return const Center(child: Text('No templates'));
          return ListView.separated(
            itemCount: templates.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final t = templates[i];
              return ListTile(
                title: Text(t.title),
                subtitle: t.tags.isEmpty ? null : Text(t.tags.join(' • ')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  // Immediately create an instance for this template. Show loader while creating.
                  showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                  try {
                    final inst = await instanceRepo.createFromTemplate(
                      templateId: t.id,
                      equipmentId: equipmentId,
                      createdBy: uid,
                    );
                    if (context.mounted) {
                      Navigator.of(context).pop(); // close loader
                      context.go('/t/fill/${inst.id}?transient=1');
                    }
                  } catch (e) {
                    if (context.mounted) Navigator.of(context).pop(); // close loader
                    final msg = (e is FirebaseException && e.code == 'permission-denied')
                        ? 'Tidak punya izin membuat tugas.'
                        : 'Gagal membuat tugas: $e';
                    if (context.mounted) {
                      // show an explanatory dialog so user can understand and retry by tapping again
                      showDialog<void>(context: context, builder: (errCtx) => AlertDialog(title: const Text('Gagal'), content: Text(msg), actions: [TextButton(onPressed: () => Navigator.of(errCtx).pop(), child: const Text('OK'))]));
                    }
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
