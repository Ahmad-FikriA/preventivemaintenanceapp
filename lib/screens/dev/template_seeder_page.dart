import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TemplateSeederPage extends StatelessWidget {
  const TemplateSeederPage({super.key});

  Future<void> _createSample(BuildContext context) async {
    final db = FirebaseFirestore.instance;
    final doc = db.collection('checklist_templates').doc();
    final now = FieldValue.serverTimestamp();

    final schema = {
      "sections": [
        {
          "title": "General",
          "fields": [
            {"key":"serialNo","label":"Serial No","type":"text","required":true},
            {"key":"operational","label":"Operational?","type":"boolean"}
          ]
        },
        {
          "title": "Measurements",
          "fields": [
            {"key":"voltage","label":"Voltage (V)","type":"number"},
            {"key":"lastService","label":"Last Service","type":"date"}
          ]
        },
        {
          "title": "Photos",
          "fields": [
            {"key":"panelPhoto","label":"Panel Photo","type":"image"}
          ]
        }
      ]
    };

    await doc.set({
      "title": "Routine Check",
      "version": 1,
      "tags": ["weekly"],
      "schema": schema,
      "createdAt": now,
      "updatedAt": now,
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template created')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Template Seeder')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: db.collection('checklist_templates').orderBy('updatedAt', descending: true).snapshots(),
        builder: (context, snap) {
          final items = snap.data?.docs ?? const [];
          return ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Create “Routine Check” template'),
                subtitle: const Text('Text, number, date, boolean, image'),
                onTap: () => _createSample(context),
              ),
              const Divider(),
              ...items.map((d) => ListTile(
                    title: Text(d.data()['title'] ?? d.id),
                    subtitle: Text('version ${d.data()['version'] ?? 1}'),
                  )),
            ],
          );
        },
      ),
    );
  }
}
