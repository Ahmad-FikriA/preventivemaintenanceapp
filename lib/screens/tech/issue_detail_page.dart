import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/auth_helpers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

class IssueDetailPage extends StatefulWidget {
  final String issueId;
  const IssueDetailPage({super.key, required this.issueId});

  @override
  State<IssueDetailPage> createState() => _IssueDetailPageState();
}

class _IssueDetailPageState extends State<IssueDetailPage> {
  final _db = FirebaseFirestore.instance;
  final _picker = ImagePicker();
  bool _busy = false;

  Stream<DocumentSnapshot<Map<String, dynamic>>> _issueStream() =>
      _db.collection('issues').doc(widget.issueId).snapshots();

  Future<void> _addPhoto(String createdBy) async {
    final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (x == null) return;
    setState(() => _busy = true);
    try {
      final ext = p.extension(x.path);
      final name = '${DateTime.now().millisecondsSinceEpoch}$ext';
      final dir = await getApplicationDocumentsDirectory();
      final base = Directory(p.join(dir.path, 'issues', widget.issueId));
      if (!await base.exists()) await base.create(recursive: true);
      final dest = File(p.join(base.path, name));
      await dest.writeAsBytes(await File(x.path).readAsBytes());
      await _db.collection('issues').doc(widget.issueId).update({
        'images': FieldValue.arrayUnion([dest.path]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo added')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _closeIssue() async {
    setState(() => _busy = true);
    try {
      await _db.collection('issues').doc(widget.issueId).update({
        'status': 'closed',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Issue closed')));
      Navigator.pop(context);
    } on FirebaseException catch (e) {
      final msg = e.code == 'permission-denied'
          ? 'You’re not allowed to update this issue.'
          : 'Failed: ${e.message ?? e.code}';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
  final me = requireUidOrRedirect(context);
  if (me == null) return const Scaffold(body: Center(child: Text('Please sign in')));

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _issueStream(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snap.data!.exists) {
          return const Scaffold(body: Center(child: Text('Issue not found')));
        }

        final data = snap.data!.data()!;
        final desc = (data['description'] as String?) ?? '';
        final sev  = (data['severity'] as String?) ?? 'medium';
        final status = (data['status'] as String?) ?? 'open';
        final createdBy = (data['createdBy'] as String?) ?? '';
        final equipmentId = (data['equipmentId'] as String?) ?? '';
        final instanceId = (data['instanceId'] as String?);
    final images = (data['images'] as List?)?.cast<String>() ?? const <String>[];
        DateTime? createdAt;
        final ts = data['createdAt'];
        if (ts is Timestamp) createdAt = ts.toDate();

        final canClose = status == 'open' && me == createdBy;
        final canAddPhoto = me == createdBy; // tighten/loosen as you want

        return Scaffold(
          appBar: AppBar(
            title: const Text('Issue Detail'),
            actions: [
              if (canClose)
                TextButton(
                  onPressed: _busy ? null : _closeIssue,
                  child: _busy
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Close'),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  _sevChip(sev),
                  const SizedBox(width: 8),
                  _statusChip(status),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                desc,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _kv('Equipment', equipmentId),
                  if (instanceId != null) _kv('Checklist', instanceId),
                  if (createdAt != null) _kv('Created', _fmt(createdAt)),
                ],
              ),
              const SizedBox(height: 16),

              Text('Photos', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (images.isEmpty)
                Container(
                  height: 120,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: const Text('No photos'),
                )
              else
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                        final img = images[i];
                        if (img.startsWith('http')) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(img, width: 160, height: 120, fit: BoxFit.cover),
                          );
                        }
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(File(img), width: 160, height: 120, fit: BoxFit.cover),
                        );
                      },
                  ),
                ),
              const SizedBox(height: 12),
              if (canAddPhoto)
                ElevatedButton.icon(
                  onPressed: _busy ? null : () => _addPhoto(createdBy),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Add Photo'),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _kv(String k, String v) => Chip(
        label: Text('$k: $v'),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      );

  Widget _sevChip(String sev) {
    Color c;
    switch (sev) {
      case 'critical': c = const Color(0xFFDC2626); break;
      case 'high':     c = const Color(0xFFF97316); break;
      case 'medium':   c = const Color(0xFFF59E0B); break;
      default:         c = const Color(0xFF10B981);
    }
    return Chip(
      avatar: CircleAvatar(backgroundColor: c, radius: 6),
      label: Text('Severity: $sev'),
      side: const BorderSide(color: Color(0xFFE5E7EB)),
    );
  }

  Widget _statusChip(String status) {
    final isOpen = status == 'open';
    return Chip(
      label: Text('Status: $status'),
      side: BorderSide(color: isOpen ? const Color(0xFF10B981) : const Color(0xFF6B7280)),
    );
  }

  String _fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
