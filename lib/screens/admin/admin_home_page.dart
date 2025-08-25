import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    final eq = db.collection('equipment').snapshots();
    final tpl = db.collection('checklist_templates').snapshots();
    final issuesOpen = db.collection('issues').where('status', isEqualTo: 'open').snapshots();

    Widget count(Stream<QuerySnapshot> s, String label) => Card(
      child: StreamBuilder<QuerySnapshot>(
        stream: s,
        builder: (_, snap) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text('${snap.data?.size ?? 0}', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: Color(0xFF6B7280))),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Admin'),
      actions:[
        IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push('/profile'),
            tooltip: 'Profile',
          ),
      ]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            Expanded(child: count(eq, 'Equipment')),
            const SizedBox(width: 8),
            Expanded(child: count(tpl, 'Templates')),
            const SizedBox(width: 8),
            Expanded(child: count(issuesOpen, 'Open Issues')),
          ]),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Create Template'),
            subtitle: const Text('Open the template builder'),
            onTap: () => context.push('/admin/templates/new'),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => context.push('/admin/work/new'),
              icon: const Icon(Icons.assignment_turned_in_outlined),
              label: const Text('Assign Work Now'),
            ),
          ),
        ],
      ),
    );
  }
}
