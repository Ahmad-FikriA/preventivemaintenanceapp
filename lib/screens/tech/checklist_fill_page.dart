import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

import '../../data/sources/firestore_instance_repo.dart';
import '../../data/sources/firestore_template_repo.dart';
import '../../data/models/checklist_instance.dart';
import '../../data/models/checklist_template.dart';
import '../../services/storage_service.dart';

class ChecklistFillPage extends StatefulWidget {
  final String instanceId;
  final bool transient;
  const ChecklistFillPage({super.key, required this.instanceId, this.transient = false});

  @override
  State<ChecklistFillPage> createState() => _ChecklistFillPageState();
}

class _ChecklistFillPageState extends State<ChecklistFillPage> {
  final _instanceRepo = FirestoreInstanceRepo();
  final _templateRepo = FirestoreTemplateRepo();
  final _storage = StorageService();
  final _picker = ImagePicker();

  ChecklistInstance? _instance;
  ChecklistTemplate? _template;
  String? _equipmentName;
  List<String> _assigneeNames = [];
  final Map<String, dynamic> _answers = {};
  final Map<String, TextEditingController> _noteCtrls = {};
  bool _loading = true;
  bool _submitting = false;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _instSub;
  bool _submittedBannerShown = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _instSub = FirebaseFirestore.instance
        .collection('checklist_instances')
        .doc(widget.instanceId)
        .snapshots()
        .listen((doc) async {
      if (!doc.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checklist not found')));
        context.go('/t/home');
        return;
      }
      final inst = ChecklistInstance.fromDoc(doc);
      ChecklistTemplate? tpl = _template;
      if (tpl == null || tpl.id != inst.templateId) {
        tpl = await _templateRepo.getById(inst.templateId);
      }
      if (!mounted) return;

      final wasSubmitted = _instance?.status == ChecklistStatus.submitted;
      final nowSubmitted = inst.status == ChecklistStatus.submitted;
      if (!wasSubmitted && nowSubmitted && !_submittedBannerShown) {
        _showSubmittedBanner();
        _submittedBannerShown = true;
      }

      // flatten nested answer maps into dotted keys
      Map<String, dynamic> flattenAnswers(Map<String, dynamic>? src) {
        final out = <String, dynamic>{};
        if (src == null) return out;
        void walk(String prefix, dynamic node) {
          if (node is Map<String, dynamic>) {
            node.forEach((k, v) => walk(prefix.isEmpty ? k : '$prefix.$k', v));
          } else {
            out[prefix] = node;
          }
        }
        walk('', src);
        return out;
      }

      final flat = flattenAnswers(inst.answers);

  // resolve equipment and assignee names (best-effort)
      String? eqName;
      final assignees = <String>[];
      try {
        final edoc = await FirebaseFirestore.instance.collection('equipment').doc(inst.equipmentId).get();
        eqName = (edoc.data()?['name'] as String?) ?? (edoc.data()?['title'] as String?);
        if (inst.assignees.isNotEmpty) {
          for (final uid in inst.assignees) {
            try {
              final udoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
              assignees.add((udoc.data()?['name'] as String?) ?? (udoc.data()?['email'] as String?) ?? uid);
            } catch (_) {
              assignees.add(uid);
            }
          }
        }
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _instance = inst;
        _template = tpl;
        _answers
          ..clear()
          ..addAll(flat);
        _equipmentName = eqName;
        _assigneeNames = assignees;
        _loading = false;
      });
      // initialize/update note controllers from template defaults and saved answers
      try {
        final sections = (_template!.schema['sections'] as List?) ?? const [];
        final keep = <String>{};
        for (var sIndex = 0; sIndex < sections.length; sIndex++) {
          final sec = sections[sIndex] as Map<String, dynamic>;
          final checklist = (sec['checklist'] as List?) ?? (sec['checkList'] as List?) ?? const [];
          for (var i = 0; i < checklist.length; i++) {
            String? defaultDesc;
            final item = checklist[i];
            if (item is Map<String, dynamic>) defaultDesc = item['description'] as String?;
            final noteKey = 'checklistNote.$sIndex.$i';
            keep.add(noteKey);
            final existing = _answers.containsKey(noteKey) ? _answers[noteKey]?.toString() : null;
            final desired = existing ?? defaultDesc ?? '';

            if (_noteCtrls.containsKey(noteKey)) {
              final ctrl = _noteCtrls[noteKey]!;
              if (ctrl.text != desired) {
                // update text but keep caret at end
                ctrl.value = ctrl.value.copyWith(text: desired, selection: TextSelection.collapsed(offset: desired.length));
              }
            } else {
              final ctrl = TextEditingController(text: desired);
              ctrl.addListener(() {
                if (!mounted) return;
                final text = ctrl.text;
                _savePatch(noteKey, text).catchError((_) {});
              });
              _noteCtrls[noteKey] = ctrl;
            }
          }
        }
        // dispose controllers for items that no longer exist
        final toRemove = _noteCtrls.keys.where((k) => !keep.contains(k)).toList();
        for (final k in toRemove) {
          try { _noteCtrls[k]?.dispose(); } catch (_) {}
          _noteCtrls.remove(k);
        }
      } catch (_) {}
    }, onError: (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Load error: $e')));
      setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _instSub?.cancel();
    for (final c in _noteCtrls.values) {
      try { c.dispose(); } catch (_) {}
    }
    try {
      ScaffoldMessenger.of(context).clearMaterialBanners();
    } catch (_) {}
    super.dispose();
  }

  void _showSubmittedBanner() {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showMaterialBanner(MaterialBanner(
      content: const Text('This checklist was submitted elsewhere — read-only now.'),
      actions: [
        TextButton(
          onPressed: () => messenger.clearMaterialBanners(),
          child: const Text('Dismiss'),
        ),
      ],
    ));
  }

  Future<void> _savePatch(String key, dynamic value) async {
    if (!mounted) return;
    setState(() => _answers[key] = value);
    try {
      await _instanceRepo.saveAnswers(widget.instanceId, {key: value});
    } catch (e) {
      // revert optimistic update if still mounted
      if (mounted) {
        setState(() => _answers[key] = _answers.containsKey(key) ? _answers[key] : null);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
      rethrow;
    }
  }

  Future<void> _pickAndUpload(String fieldKey) async {
    final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (x == null) return;
    try {
      final url = await _storage.uploadInstanceImage(instanceId: widget.instanceId, fieldKey: fieldKey, file: File(x.path));
      await _instanceRepo.attachImage(widget.instanceId, fieldKey, url);
      if (!mounted) return;
      setState(() => _answers[fieldKey] = url);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      String? tplTitle;
      String? eqName;
      try {
        final instDoc = await FirebaseFirestore.instance.collection('checklist_instances').doc(widget.instanceId).get();
        final instData = instDoc.data();
        final tplId = instData?['templateId'] as String? ?? _instance?.templateId;
        final eqId = instData?['equipmentId'] as String? ?? _instance?.equipmentId;
        if (tplId != null) {
          final tdoc = await FirebaseFirestore.instance.collection('checklist_templates').doc(tplId).get();
          tplTitle = (tdoc.data()?['title'] as String?);
        }
        if (eqId != null) {
          final edoc = await FirebaseFirestore.instance.collection('equipment').doc(eqId).get();
          eqName = (edoc.data()?['name'] as String?);
        }
      } catch (_) {}

      await _instanceRepo.submit(widget.instanceId, templateTitle: tplTitle, equipmentName: eqName);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submitted')));
      context.go('/t/equipment');
    } catch (e) {
      final msg = (e is FirebaseException && e.code == 'permission-denied')
          ? 'Tidak bisa mengubah checklist yang sudah “submitted”.'
          : 'Submit failed: $e';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final tpl = _template!;
    final inst = _instance!;
    final isLocked = inst.status == ChecklistStatus.submitted;

    return WillPopScope(
      onWillPop: () async {
        // if this instance was created transiently (from template picker) and not submitted,
        // ask the user before deleting the draft to avoid accidental loss.
        if (widget.transient && _instance != null && _instance!.status != ChecklistStatus.submitted) {
          final should = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
            title: const Text('Batalkan tugas?'),
            content: const Text('Tugas ini belum disubmit. Jika Anda kembali, tugas akan dihapus. Lanjutkan?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
              TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Hapus')),
            ],
          ));
          if (should == true) {
            final deleted = await _attemptDeleteTransient();
            return deleted;
          }
          return false;
        }
        return true;
      },
      child: Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () async {
          if (widget.transient && _instance != null && _instance!.status != ChecklistStatus.submitted) {
            final should = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
              title: const Text('Batalkan tugas?'),
              content: const Text('Tugas ini belum disubmit. Jika Anda kembali, tugas akan dihapus. Lanjutkan?'),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
                TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Hapus')),
              ],
            ));
            if (should == true) {
              final deleted = await _attemptDeleteTransient();
              if (!deleted) return; // user can retry or cancel; stay on page if deletion failed
            } else {
              return;
            }
          }
          context.go('/t/home');
        }),
        title: Text(tpl.title),
        actions: [
          if (!isLocked)
            IconButton(
              onPressed: _submitting ? null : _submit,
              icon: _submitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check),
              tooltip: 'Submit',
            ),
          IconButton(
            tooltip: 'Report issue',
            onPressed: () {
              final inst = _instance!;
              context.go('/t/issues/new?equipmentId=${inst.equipmentId}&instanceId=${inst.id}');
            },
            icon: const Icon(Icons.report_problem_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_equipmentName ?? inst.equipmentId, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (inst.dueDate != null) Text('Due: ${_fmt(inst.dueDate!)}'),
                Text(_assigneeNames.isNotEmpty ? 'Assigned: ${_assigneeNames.join(', ')}' : 'Assigned: Unassigned'),
                const SizedBox(height: 6),
                Text('Status: ${inst.status.name}'),
              ]),
            ),
          ),
          ..._buildFields(context, tpl, isLocked),
        ],
      ),
    ));
  }

  List<Widget> _buildFields(BuildContext context, ChecklistTemplate tpl, bool isLocked) {
    final List<Widget> widgets = [];
    final sections = (tpl.schema['sections'] as List?) ?? const [];
    final screenW = MediaQuery.of(context).size.width;

    for (var sIndex = 0; sIndex < sections.length; sIndex++) {
      final sec = sections[sIndex] as Map<String, dynamic>;
      final title = (sec['title'] ?? '') as String;
      widgets.add(Padding(padding: const EdgeInsets.only(top: 8, bottom: 4), child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))));

      final checklist = (sec['checklist'] as List?) ?? (sec['checkList'] as List?) ?? const [];
      final layout = (sec['layout'] as String?) ?? (sec['twoColumn'] == true ? 'two' : 'auto');

      if (checklist.isNotEmpty) {
        final useTwo = layout == 'two' || (layout == 'auto' && screenW > 600);
        if (!useTwo) {
          for (var i = 0; i < checklist.length; i++) {
            final item = checklist[i]?.toString() ?? '';
            final key = 'checklist.$sIndex.$i';
            final noteKey = 'checklistNote.$sIndex.$i';
            final val = _answers[key] is bool ? _answers[key] as bool : false;
            final ctrl = _noteCtrls[noteKey];
            widgets.add(Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    CheckboxListTile(
                      value: val,
                      onChanged: (!isLocked && !_submitting && !_loading)
                          ? (v) {
                              setState(() => _answers[key] = v == true);
                              _instanceRepo.saveAnswers(widget.instanceId, {key: v == true}).catchError((e) {
                                if (mounted) {
                                  setState(() => _answers[key] = val);
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
                                }
                              });
                            }
                          : null,
                      title: Text(item),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    if (ctrl != null) ...[
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: ctrl,
                        decoration: const InputDecoration(labelText: 'Notes'),
                        enabled: !isLocked && !_submitting && !_loading,
                        maxLines: 2,
                      ),
                    ],
                  ],
                ),
              ),
            ));
          }
        } else {
          final double cardW = (screenW - 48) / 2;
          widgets.add(Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(checklist.length, (i) {
              final item = checklist[i]?.toString() ?? '';
              final key = 'checklist.$sIndex.$i';
              final val = _answers[key] is bool ? _answers[key] as bool : false;
              final noteKey = 'checklistNote.$sIndex.$i';
              final ctrl = _noteCtrls[noteKey];
              return SizedBox(
                width: cardW,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        CheckboxListTile(
                          value: val,
                          onChanged: (!isLocked && !_submitting && !_loading)
                              ? (v) {
                                  setState(() => _answers[key] = v == true);
                                  _instanceRepo.saveAnswers(widget.instanceId, {key: v == true}).catchError((e) {
                                    if (mounted) {
                                      setState(() => _answers[key] = val);
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
                                    }
                                  });
                                }
                              : null,
                          title: Text(item),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        if (ctrl != null) ...[
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: ctrl,
                            decoration: const InputDecoration(labelText: 'Notes (optional)'),
                            enabled: !isLocked && !_submitting && !_loading,
                            maxLines: 2,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ));
        }
        continue;
      }

      final fields = (sec['fields'] as List?) ?? const [];
      for (final f in fields) {
        final key = f['key'] as String;
        final label = f['label'] as String? ?? key;
        final type = (f['type'] as String? ?? 'text').toLowerCase();
        final required = (f['required'] as bool?) ?? false;
        widgets.add(Card(margin: const EdgeInsets.symmetric(vertical: 6), child: Padding(padding: const EdgeInsets.all(12), child: _buildField(type: type, key: key, label: label, required: required, locked: isLocked))));
      }
    }

    return widgets;
  }

  Widget _buildField({required String type, required String key, required String label, required bool required, required bool locked}) {
    final value = _answers[key];
    switch (type) {
      case 'text':
        return TextFormField(initialValue: value?.toString(), decoration: InputDecoration(labelText: label), enabled: !locked, onChanged: (v) => _savePatch(key, v));
      case 'number':
        return TextFormField(initialValue: value?.toString(), keyboardType: TextInputType.number, decoration: InputDecoration(labelText: label), enabled: !locked, onChanged: (v) => _savePatch(key, num.tryParse(v)));
      case 'boolean':
        return SwitchListTile(value: (value is bool) ? value : false, onChanged: locked ? null : (v) => _savePatch(key, v), title: Text(label));
      case 'date':
        final dt = _dateFrom(value);
        return ListTile(title: Text(label), subtitle: Text(dt == null ? '—' : _fmt(dt)), trailing: locked ? null : const Icon(Icons.calendar_today), onTap: locked ? null : () async {
          final picked = await showDatePicker(context: context, firstDate: DateTime(2000), lastDate: DateTime(2100), initialDate: dt ?? DateTime.now());
          if (picked != null) await _savePatch(key, picked);
        });
      case 'image':
        final url = value as String?;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (url != null)
            ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(url, height: 160, width: double.infinity, fit: BoxFit.cover))
          else
            Container(height: 160, width: double.infinity, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE5E7EB))), child: const Text('No photo')),
          const SizedBox(height: 8),
          if (!locked) ElevatedButton.icon(onPressed: () => _pickAndUpload(key), icon: const Icon(Icons.camera_alt_outlined), label: const Text('Add Photo'))
        ]);
      default:
        return Text('$label  (unsupported type: $type)');
    }
  }

  DateTime? _dateFrom(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  String _fmt(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<bool> _attemptDeleteTransient() async {
    try {
      await _instanceRepo.delete(widget.instanceId);
      return true;
    } catch (e) {
      // Show retry dialog explaining the failure
      if (!mounted) return false;
      final shouldRetry = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
        title: const Text('Gagal menghapus'),
        content: Text('Menghapus tugas gagal: $e'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Coba lagi')),
        ],
      ));
      if (shouldRetry == true) {
        return await _attemptDeleteTransient();
      }
      return false;
    }
  }
}
