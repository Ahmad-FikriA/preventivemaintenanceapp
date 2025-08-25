// Moved from tech/equipment_edit_page.dart: admin-only equipment create/edit screen.
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/models/equipment.dart';
import '../../data/sources/firestore_equipment_repo.dart';

class AdminEquipmentEditPage extends StatefulWidget {
  final String? equipmentId; // null => create, non-null => edit
  const AdminEquipmentEditPage({super.key, this.equipmentId});

  @override
  State<AdminEquipmentEditPage> createState() => _AdminEquipmentEditPageState();
}

class _AdminEquipmentEditPageState extends State<AdminEquipmentEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _code = TextEditingController();
  final _location = TextEditingController();
  final _typeOther = TextEditingController();

  String? _type; // equipment type
  DateTime? _installedDate;

  final _picker = ImagePicker();
  final _repo = FirestoreEquipmentRepo();

  bool _loading = false;
  Equipment? _existing;
  final List<String> _existingUrls = [];
  final List<XFile> _newImages = [];

  @override
  void initState() {
    super.initState();
    if (widget.equipmentId != null) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final e = await _repo.getById(widget.equipmentId!);
    if (mounted) {
      if (e == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Equipment not found')));
        context.pop();
        return;
      }
      _existing = e;
      _name.text = e.name;
      _code.text = e.code;
      _location.text = e.location ?? '';
      _existingUrls.addAll(e.images);
      // normalize any gs:// or storage references into downloadable https URLs
      await _normalizeExistingUrls();
      // load extra metadata (type, installed date) from the raw document
      try {
        final doc = await FirebaseFirestore.instance.collection('equipment').doc(widget.equipmentId!).get();
        final data = doc.data();
        if (data != null) {
          final t = data['type'] as String?;
          if (t != null) {
            // if t matches our known set, use it; otherwise treat it as Other with custom text
            const known = ['AC', 'Generator', 'Pump', 'Valve', 'Other'];
            if (known.contains(t)) {
              _type = t;
            } else {
              _type = 'Other';
              _typeOther.text = t;
            }
          }
          final inst = data['installedAt'];
          if (inst is Timestamp) _installedDate = inst.toDate();
        }
      } catch (_) {}
      setState(() => _loading = false);
    }
  }

  Future<void> _normalizeExistingUrls() async {
    if (_existingUrls.isEmpty) return;
    final normalized = <String>[];
    final removed = <String>[];
    for (final u in List<String>.from(_existingUrls)) {
      if (u.trim().isEmpty) continue;
      // If it's an http(s) URL, keep it. Otherwise treat as local file path and check existence.
      if (u.startsWith('http')) {
        normalized.add(u);
      } else {
        final f = File(u);
        if (await f.exists()) {
          normalized.add(f.path);
        } else {
          // missing local file or unknown storage ref -> drop it
          removed.add(u);
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _existingUrls
        ..clear()
        ..addAll(normalized);
    });
    if (removed.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Removed ${removed.length} missing images')));
    }
  }

  Future<void> _pickFromCamera() async {
    final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (x != null) setState(() => _newImages.add(x));
  }

  Future<void> _pickFromGallery() async {
    final xs = await _picker.pickMultiImage(imageQuality: 80);
    if (xs.isNotEmpty) setState(() => _newImages.addAll(xs));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
      Equipment eq;
      if (_existing == null) {
        final created = await _repo.create(Equipment(
          id: '',
          name: _name.text.trim(),
          code: _code.text.trim(),
          location: _location.text.trim().isEmpty ? null : _location.text.trim(),
          images: const [],
          createdBy: uid,
        ));
        eq = created;
        // persist extra metadata
        try {
          await FirebaseFirestore.instance.collection('equipment').doc(eq.id).update({
            if (_type != null) 'type': (_type == 'Other' ? _typeOther.text.trim() : _type),
            if (_installedDate != null) 'installedAt': Timestamp.fromDate(_installedDate!),
            if (_code.text.trim().isNotEmpty) 'serialNumber': _code.text.trim(),
          });
        } catch (_) {}
      } else {
        eq = _existing!.copyWith(
          name: _name.text.trim(),
          code: _code.text.trim(),
          location: _location.text.trim().isEmpty ? null : _location.text.trim(),
          images: _existingUrls,
        );
        await _repo.update(eq);
        try {
          await FirebaseFirestore.instance.collection('equipment').doc(eq.id).update({
            if (_type != null) 'type': (_type == 'Other' ? _typeOther.text.trim() : _type),
            if (_installedDate != null) 'installedAt': Timestamp.fromDate(_installedDate!),
            if (_code.text.trim().isNotEmpty) 'serialNumber': _code.text.trim(),
          });
        } catch (_) {}
      }

      if (_newImages.isNotEmpty) {
        final urls = <String>[];
        for (final x in _newImages) {
          final url = await _repo.uploadImage(equipmentId: eq.id, file: File(x.path));
          urls.add(url);
        }
        final updated = eq.copyWith(images: [..._existingUrls, ...urls]);
        await _repo.update(updated);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.equipmentId != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Equipment' : 'Add Equipment'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            _tf(_name, 'Nama Equipment', Icons.precision_manufacturing_outlined, validator: _req),
                            const SizedBox(height: 12),
                            _tf(_code, 'Nomor Seri', Icons.confirmation_number_outlined, validator: _req),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: _type,
                              decoration: const InputDecoration(labelText: 'Jenis Equipment', border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem(value: 'AC', child: Text('AC')),
                                DropdownMenuItem(value: 'Generator', child: Text('Generator')),
                                DropdownMenuItem(value: 'Pump', child: Text('Pump')),
                                DropdownMenuItem(value: 'Valve', child: Text('Valve')),
                                DropdownMenuItem(value: 'Other', child: Text('Other')),
                              ],
                              onChanged: (v) => setState(() => _type = v),
                              validator: (v) => (v == null || v.isEmpty) ? 'Pilih jenis equipment' : null,
                            ),
                            if (_type == 'Other') ...[
                              const SizedBox(height: 12),
                              _tf(_typeOther, 'Jenis (lainnya)', Icons.category_outlined, validator: _req),
                            ],
                            const SizedBox(height: 12),
                            _tf(_location, 'Letak Tempat Alat (optional)', Icons.place_outlined),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _installedDate ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                                );
                                if (picked != null) setState(() => _installedDate = picked);
                              },
                              child: AbsorbPointer(
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Dipasang pada tanggal',
                                    prefixIcon: Icon(Icons.event_outlined),
                                    border: OutlineInputBorder(),
                                  ),
                                  controller: TextEditingController(text: _installedDate == null ? '' : '${_installedDate!.year}-${_installedDate!.month.toString().padLeft(2,'0')}-${_installedDate!.day.toString().padLeft(2,'0')}'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const SizedBox(height: 16),
                    if (_existingUrls.isNotEmpty) ...[
                      Align(alignment: Alignment.centerLeft, child: Text('Existing photos', style: theme(context).textTheme.titleSmall)),
                      const SizedBox(height: 8),
                      _thumbRow(_existingUrls.map((u) {
                        if (u.startsWith('http')) {
                          return Image.network(u, fit: BoxFit.cover);
                        }
                        return Image.file(File(u), fit: BoxFit.cover);
                      }).toList()),
                      const SizedBox(height: 16),
                    ],
                    if (_newImages.isNotEmpty) ...[
                      Align(alignment: Alignment.centerLeft, child: Text('To upload', style: theme(context).textTheme.titleSmall)),
                      const SizedBox(height: 8),
                      _thumbRow(_newImages.map((x) => Image.file(File(x.path), fit: BoxFit.cover)).toList()),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _loading ? null : _pickFromGallery,
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Gallery'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _loading ? null : _pickFromCamera,
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: const Text('Camera'),
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

  ThemeData theme(BuildContext c) => Theme.of(c);
  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;
  Widget _tf(TextEditingController c, String label, IconData icon, {String? Function(String?)? validator}) => TextFormField(
        controller: c,
        validator: validator,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: const OutlineInputBorder()),
      );
  Widget _thumbRow(List<Widget> images) => SizedBox(
        height: 90,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: images.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) => ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(width: 120, height: 90, child: images[i]),
          ),
        ),
      );
}
