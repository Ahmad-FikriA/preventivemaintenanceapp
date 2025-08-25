import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/auth_helpers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../data/sources/firestore_issue_repo.dart';
import '../../data/models/issue.dart';

class IssueCreatePage extends StatefulWidget {
  final String equipmentId;
  final String? instanceId; // optional link to current checklist
  const IssueCreatePage({super.key, required this.equipmentId, this.instanceId});

  @override
  State<IssueCreatePage> createState() => _IssueCreatePageState();
}

class _IssueCreatePageState extends State<IssueCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _desc = TextEditingController();
  IssueSeverity _severity = IssueSeverity.medium;
  final _picker = ImagePicker();
  final _images = <XFile>[];
  bool _saving = false;

  @override
  void dispose() {
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (x != null) setState(() => _images.add(x));
  }

  Future<List<String>> _uploadImages(String issueId) async {
    if (_images.isEmpty) return const [];
    final dir = await getApplicationDocumentsDirectory();
    final base = Directory(p.join(dir.path, 'issues', issueId));
    if (!await base.exists()) await base.create(recursive: true);
    final urls = <String>[];
    for (final x in _images) {
      final ext = p.extension(x.path);
      final name = '${DateTime.now().millisecondsSinceEpoch}$ext';
      final dest = File(p.join(base.path, name));
      await dest.writeAsBytes(await File(x.path).readAsBytes());
      urls.add(dest.path);
    }
    return urls;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final uid = requireUidOrRedirect(context);
      if (uid == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in')));
        return;
      }
      final repo = FirestoreIssueRepo();

      // Create a placeholder issue to get its ID for image path
      // (We’ll do 2-step: create without images, then upload + update)
      final tmp = await repo.create(
        equipmentId: widget.equipmentId,
        instanceId: widget.instanceId,
        description: _desc.text.trim(),
        severity: _severity,
        createdBy: uid,
      );
      final urls = await _uploadImages(tmp.id);

      if (urls.isNotEmpty) {
        await FirebaseFirestore.instance.collection('issues').doc(tmp.id).update({
          'images': urls,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Issue reported')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Issue'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _severityPicker(),
              const SizedBox(height: 12),
              TextFormField(
                controller: _desc,
                maxLines: 5,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Describe the issue' : null,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              _thumbs(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _pick,
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Add Photo'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _severityPicker() {
    return DropdownButtonFormField<IssueSeverity>(
      value: _severity,
      decoration: const InputDecoration(
        labelText: 'Severity',
        border: OutlineInputBorder(),
      ),
      items: IssueSeverity.values.map((s) {
        return DropdownMenuItem(value: s, child: Text(s.name));
      }).toList(),
      onChanged: (v) => setState(() => _severity = v ?? IssueSeverity.medium),
    );
  }

  Widget _thumbs() {
    if (_images.isEmpty) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Text('No photos'),
      );
    }
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(File(_images[i].path), width: 140, height: 100, fit: BoxFit.cover),
        ),
      ),
    );
  }
}
