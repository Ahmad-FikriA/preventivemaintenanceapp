import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

import '../../data/sources/firestore_instance_repo.dart';
import '../../data/sources/firestore_template_repo.dart';
import '../../data/models/checklist_template.dart';
import '../../services/storage_service.dart';
import '../../core/utils/auth_helpers.dart';

// This page is a local-only draft editor. It does NOT create a Firestore document until the user taps Submit.
class ChecklistDraftPage extends StatefulWidget {
  final String templateId;
  final String equipmentId;
  const ChecklistDraftPage({super.key, required this.templateId, required this.equipmentId});

  @override
  State<ChecklistDraftPage> createState() => _ChecklistDraftPageState();
}

class _ChecklistDraftPageState extends State<ChecklistDraftPage> {
  final _templateRepo = FirestoreTemplateRepo();
  final _storage = StorageService();
  final _picker = ImagePicker();

  ChecklistTemplate? _template;
  final Map<String, dynamic> _answers = {};
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tpl = await _templateRepo.getById(widget.templateId);
    if (!mounted) return;
    setState(() {
      _template = tpl;
      _loading = false;
    });
  }

  Future<void> _submit() async {
    if (_template == null) return;
    final uid = requireUidOrRedirect(context);
    if (uid == null) return;
    setState(() => _submitting = true);
    try {
      final instRepo = FirestoreInstanceRepo();
      final inst = await instRepo.createFromTemplateAssigned(
        templateId: _template!.id,
        equipmentId: widget.equipmentId,
        createdBy: uid,
        assignees: [uid],
      );
      // attach answers as patch
      if (_answers.isNotEmpty) await instRepo.saveAnswers(inst.id, _answers);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submitted')));
      context.go('/t/home');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submit failed: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final tpl = _template!;
    return Scaffold(
      appBar: AppBar(title: Text(tpl.title)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        ..._buildFields(tpl),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _submitting ? null : _submit, child: _submitting ? const CircularProgressIndicator() : const Text('Submit'))
      ]),
    );
  }

  List<Widget> _buildFields(ChecklistTemplate tpl) {
    final widgets = <Widget>[];
    final sections = (tpl.schema['sections'] as List?) ?? const [];
    for (var sIndex = 0; sIndex < sections.length; sIndex++) {
      final sec = sections[sIndex] as Map<String, dynamic>;
      widgets.add(Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(sec['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700))));
      final checklist = (sec['checklist'] as List?) ?? (sec['checkList'] as List?) ?? const [];
      if (checklist.isNotEmpty) {
        for (var i = 0; i < checklist.length; i++) {
          final key = 'checklist.$sIndex.$i';
          final val = _answers[key] is bool ? _answers[key] as bool : false;
          widgets.add(CheckboxListTile(value: val, onChanged: (v) => setState(() => _answers[key] = v == true), title: Text(checklist[i]?.toString() ?? '')));
        }
        continue;
      }
      final fields = (sec['fields'] as List?) ?? const [];
      for (final f in fields) {
        final key = f['key'] as String;
        final label = f['label'] as String? ?? key;
        final type = (f['type'] as String? ?? 'text').toLowerCase();
        widgets.add(Padding(padding: const EdgeInsets.only(bottom: 12), child: _buildField(type: type, key: key, label: label)));
      }
    }
    return widgets;
  }

  Widget _buildField({required String type, required String key, required String label}) {
    final val = _answers[key];
    switch (type) {
      case 'text':
        return TextFormField(initialValue: val?.toString(), decoration: InputDecoration(labelText: label), onChanged: (v) => _answers[key] = v);
      case 'number':
        return TextFormField(initialValue: val?.toString(), keyboardType: TextInputType.number, decoration: InputDecoration(labelText: label), onChanged: (v) => _answers[key] = num.tryParse(v));
      case 'boolean':
        return SwitchListTile(value: (val is bool) ? val : false, onChanged: (v) => setState(() => _answers[key] = v), title: Text(label));
      case 'date':
        return ListTile(
          title: Text(label),
          subtitle: Text(_dateString(_answers[key])),
          onTap: () async {
            final picked = await showDatePicker(context: context, firstDate: DateTime(2000), lastDate: DateTime(2100), initialDate: DateTime.now());
            if (picked != null) setState(() => _answers[key] = picked);
          },
        );
      case 'image':
        final url = val as String?;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (url != null)
              Image.network(url, height: 160, width: double.infinity, fit: BoxFit.cover)
            else
              Container(height: 160, width: double.infinity, color: const Color(0xFFF3F4F6), alignment: Alignment.center, child: const Text('No photo')),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                if (x == null) return;
                final uploaded = await _storage.uploadInstanceImage(instanceId: DateTime.now().millisecondsSinceEpoch.toString(), fieldKey: key, file: File(x.path));
                setState(() => _answers[key] = uploaded);
              },
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Add Photo'),
            )
          ],
        );
      default:
        return Text('$label (unsupported)');
    }
   }

   String _dateString(dynamic v) {
     if (v == null) return '—';
     if (v is DateTime) return '${v.year}-${v.month.toString().padLeft(2, '0')}-${v.day.toString().padLeft(2, '0')}';
     return v.toString();
   }

}


