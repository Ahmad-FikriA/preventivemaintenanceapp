import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TemplateBuilderPage extends StatefulWidget {
  final String? templateId; // null = new
  const TemplateBuilderPage({super.key, this.templateId});

  @override
  State<TemplateBuilderPage> createState() => _TemplateBuilderPageState();
}

class _TemplateBuilderPageState extends State<TemplateBuilderPage> {
  final _title = TextEditingController();
  // tags removed per request; no tags UI
  String _status = 'published';
  // header fields that will appear above the table
  final _eqNumber = TextEditingController();
  final _tplLocation = TextEditingController();
  final _monthYear = TextEditingController();

  final List<_Section> _sections = [
    _Section(title: 'Numbering & Date')
      ..fields.addAll([
        (_Field()
          ..key = 'no'
          ..label = 'No'
          ..type = 'number'),
        (_Field()
          ..key = 'tanggal_inspeksi'
          ..label = 'Tanggal Inspeksi'
          ..type = 'date'),
      ]),
    _Section(title: 'General'),
  ];

  bool _saving = false;

  @override
  void dispose() { _title.dispose(); _eqNumber.dispose(); _tplLocation.dispose(); _monthYear.dispose(); super.dispose(); }

  @override
  void initState() {
    super.initState();
    if (widget.templateId != null) {
      _loadTemplate();
    }
  }

  Future<void> _loadTemplate() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('checklist_templates').doc(widget.templateId).get();
      if (!doc.exists) return;
      final data = doc.data() ?? {};
      // title, tags, status
      setState(() {
        _title.text = (data['title'] as String?) ?? '';
        _status = (data['status'] as String?) ?? _status;
      });

      // schema -> sections
      final schema = data['schema'] as Map<String, dynamic>?;
      final sections = (schema?['sections'] as List?) ?? [];
      final parsed = <_Section>[];
      for (final raw in sections) {
          if (raw is Map<String, dynamic>) {
          final s = _Section(title: (raw['title'] as String?) ?? '');
          s.twoColumn = (raw['twoColumn'] == true);
          // accept both 'checklist' and legacy 'checkList'
          final checklist = (raw['checklist'] as List?) ?? (raw['checkList'] as List?);
          if (checklist != null) {
            for (final it in checklist) {
              // support: simple string items (legacy) or maps {label, description}
              if (it is String) {
                s.checklist.add(_Todo(label: it));
              } else if (it is Map<String, dynamic>) {
                s.checklist.add(_Todo(label: (it['label'] as String?) ?? it['text']?.toString() ?? '', description: it['description'] as String?));
              } else {
                s.checklist.add(_Todo(label: it?.toString() ?? ''));
              }
            }
          }
          // legacy fields
          final fields = (raw['fields'] as List?) ?? [];
          for (final f in fields) {
            if (f is Map<String, dynamic>) {
              final fld = _Field();
              fld.key = (f['key'] as String?) ?? fld.key;
              fld.label = (f['label'] as String?) ?? fld.label;
              fld.type = (f['type'] as String?) ?? fld.type;
              fld.required = (f['required'] as bool?) ?? fld.required;
              // number extras
              fld.unit = (f['unit'] as String?) ?? fld.unit;
              fld.min = f['min'] is num ? (f['min'] as num).toDouble() : fld.min;
              fld.max = f['max'] is num ? (f['max'] as num).toDouble() : fld.max;
              // choice
              final opts = (f['options'] as List?) ?? [];
              for (final o in opts) {
                fld.options.add(o.toString());
              }
              s.fields.add(fld);
            }
          }
          parsed.add(s);
        }
      }

          if (mounted) {
            setState(() => _sections
        ..clear()
        ..addAll(parsed.isNotEmpty ? parsed : [ _Section(title: 'General') ]));
          }
    } catch (e) {
      // non-fatal
    }
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }
    setState(() => _saving = true);
    try {
      final db = FirebaseFirestore.instance;
      final doc = widget.templateId == null
          ? db.collection('checklist_templates').doc()
          : db.collection('checklist_templates').doc(widget.templateId);

      // build schema map -- use checklist items per section instead of complex fields
      final schema = {
        'sections': _sections.map((s) => {
          'title': s.title,
          if (s.twoColumn) 'twoColumn': true,
          // serialize checklist: if any item has description, store as map; otherwise store as string list for compactness
          'checklist': s.checklist.map((t) {
            if (t.description == null || t.description!.isEmpty) return t.label;
            return {'label': t.label, 'description': t.description};
          }).toList(),
        }).toList(),
      };

      final data = {
        'title': _title.text.trim(),
        'titleLower': _title.text.trim().toLowerCase(),
        'status': _status, // published|archived
        // tags removed
        'schema': schema,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (widget.templateId == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }
      // Denormalized lowercase title for case-insensitive search / ordering
      final title = data['title'];
      if (title is String) {
        data['titleLower'] = title.toLowerCase();
      }

      await doc.set(data, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Template saved')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addSection() => setState(() => _sections.add(_Section(title: 'New Section')));


  void _loadCompressorExample() {
    setState(() {
      _title.text = 'Compressor';
  // tags removed
      _status = 'published';
      _eqNumber.text = '';
      _tplLocation.text = '';
      _monthYear.text = '';

      _sections
        ..clear()
        ..addAll([
          _Section(title: 'Numbering & Date')
            ..fields.addAll([
              (_Field()
                ..key = 'no'
                ..label = 'No'
                ..type = 'number'),
              (_Field()
                ..key = 'tanggal_inspeksi'
                ..label = 'Tanggal Inspeksi'
                ..type = 'date'),
            ]),

          _Section(title: 'Visual Check Head Unit')
            ..checklist.addAll([_Todo(label: 'Jam'), _Todo(label: 'Suhu'), _Todo(label: 'Running Hour'), _Todo(label: 'Remaining'), _Todo(label: 'Status')]),

          _Section(title: 'Body Compressor')
            ..checklist.addAll([_Todo(label: 'Oil'), _Todo(label: 'Air Filter'), _Todo(label: 'Oil Filter'), _Todo(label: 'Separator Oil'), _Todo(label: 'Fan'), _Todo(label: 'Motor')]),

          _Section(title: 'Voltage')
            ..checklist.addAll([_Todo(label: 'RS'), _Todo(label: 'ST'), _Todo(label: 'TR')]),

          _Section(title: 'Unload(A)')
            ..checklist.addAll([_Todo(label: 'lr'), _Todo(label: 'ls'), _Todo(label: 'lt')]),

          _Section(title: 'Load(A)')
            ..checklist.addAll([_Todo(label: 'lr'), _Todo(label: 'ls'), _Todo(label: 'lt')]),

          _Section(title: 'Drainage')..checklist.addAll([_Todo(label: 'Drainage')]),
          _Section(title: 'Pemeriksa')..checklist.addAll([_Todo(label: 'Pemeriksa')]),
          _Section(title: 'Keterangan')..checklist.addAll([_Todo(label: 'Keterangan')]),
        ]);
    });
  }

  String _layoutHelp(String layout) {
    switch (layout) {
  case 'single': return 'One item per row. Good for long labels.';
  case 'two': return 'Two items per row. Saves vertical space.';
  default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Template Builder'),
        actions: [
          TextButton(
            onPressed: _loadCompressorExample,
            child: const Text('Load Example'),
          ),
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSection, icon: const Icon(Icons.view_agenda_outlined), label: const Text('Add section')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(controller: _title, decoration: const InputDecoration(labelText: 'Template title')),
          const SizedBox(height: 8),
          // small header block (EQ Number / Compressor / Location / Month/Year)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Header', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(controller: _eqNumber, decoration: const InputDecoration(labelText: 'EQ Number :')),
                  const SizedBox(height: 8),
                  TextFormField(controller: _tplLocation, decoration: const InputDecoration(labelText: 'Location :')),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _monthYear,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Month/Year :'),
                    onTap: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: now,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        final txt = '${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                        setState(() => _monthYear.text = txt);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const SizedBox(height: 8),
          const Row(
            children: [
              Text('Status: Published', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          ..._sections.map((s) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextFormField(
                      initialValue: s.title,
                      onChanged: (v) => s.title = v,
                      decoration: const InputDecoration(labelText: 'Section title'),
                    ),
                    const SizedBox(height: 8),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Layout'),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: s.layout,
                          items: const [
                            DropdownMenuItem(value: 'single', child: Text('Single column')),
                            DropdownMenuItem(value: 'two', child: Text('Two columns')),
                          ],
                          onChanged: (v) => setState(() {
                            s.layout = v ?? 'single';
                            // keep twoColumn for backward-compatibility when saving
                            s.twoColumn = (s.layout == 'two');
                          }),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(_layoutHelp(s.layout), style: const TextStyle(color: Colors.black54))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Checklist UI: add to-do items
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() => s.checklist.add(_Todo(label: 'New to-do'))),
                        icon: const Icon(Icons.check_box_outlined),
                        label: const Text('Add to-do'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...s.checklist.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final todo = entry.value;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            children: [
                              Row(children: [
                                Expanded(child: TextFormField(
                                  initialValue: todo.label,
                                  onChanged: (v) => setState(() => s.checklist[idx] = todo.copyWith(label: v)),
                                  decoration: const InputDecoration(labelText: 'To-do item'),
                                )),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => setState(() => s.checklist.removeAt(idx)),
                                ),
                              ]),
                              const SizedBox(height: 8),
                              TextFormField(
                                initialValue: todo.description,
                                onChanged: (v) => setState(() => s.checklist[idx] = todo.copyWith(description: v)),
                                decoration: const InputDecoration(labelText: 'Description (optional)'),
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    // Backwards-compatible field editors (if any)
                    ...s.fields.map((f) => _FieldEditor(
                      field: f,
                      onDelete: () => setState(() => s.fields.remove(f)),
                    )),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _FieldEditor extends StatefulWidget {
  final _Field field;
  final VoidCallback onDelete;
  const _FieldEditor({required this.field, required this.onDelete});

  @override
  State<_FieldEditor> createState() => _FieldEditorState();
}

class _FieldEditorState extends State<_FieldEditor> {
  @override
  Widget build(BuildContext context) {
    final f = widget.field;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(children: [
              // field key is no longer editable; the system will generate it if needed
              Expanded(child: TextFormField(
                initialValue: f.label,
                onChanged: (v) => f.label = v,
                decoration: const InputDecoration(labelText: 'Label'),
              )),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              DropdownButton<String>(
                value: f.type,
                items: const [
                  DropdownMenuItem(value: 'text', child: Text('Text')),
                  DropdownMenuItem(value: 'number', child: Text('Number')),
                  DropdownMenuItem(value: 'boolean', child: Text('Yes/No')),
                  DropdownMenuItem(value: 'date', child: Text('Date')),
                  DropdownMenuItem(value: 'image', child: Text('Photo')),
                  DropdownMenuItem(value: 'choice', child: Text('Choice')),
                ],
                onChanged: (v) => setState(() => f.type = v ?? 'text'),
              ),
              const SizedBox(width: 16),
              Checkbox(
                value: f.required, onChanged: (v) => setState(() => f.required = v ?? false),
              ),
              const Text('Required'),
            ]),
            if (f.type == 'number') ...[
              const Align(alignment: Alignment.centerLeft, child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('Number', style: TextStyle(color: Colors.black54)),
              )),
            ],
            if (f.type == 'choice') ...[
              const SizedBox(height: 8),
              _ChoiceEditor(field: f),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: widget.onDelete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove field'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceEditor extends StatefulWidget {
  final _Field field;
  const _ChoiceEditor({required this.field});
  @override
  State<_ChoiceEditor> createState() => _ChoiceEditorState();
}
class _ChoiceEditorState extends State<_ChoiceEditor> {
  final _txt = TextEditingController();
  @override
  void dispose() { _txt.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final options = widget.field.options;
    return Column(
      children: [
        Row(children: [
          Expanded(child: TextField(controller: _txt, decoration: const InputDecoration(labelText: 'Add option'))),
          const SizedBox(width: 8),
          ElevatedButton(onPressed: () {
            final v = _txt.text.trim();
            if (v.isNotEmpty) { setState(() => options.add(v)); _txt.clear(); }
          }, child: const Text('Add')),
        ]),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8, runSpacing: 6,
          children: options.map((o) => Chip(
            label: Text(o),
            onDeleted: () => setState(() => options.remove(o)),
          )).toList(),
        ),
      ],
    );
  }
}

// --- lightweight in-memory structures for the builder ---
class _Section {
  _Section({required this.title});
  String title;
  final List<_Field> fields = [];
  // if true, render this section as two columns per row when building table
  bool twoColumn = false;
  // layout choices: 'auto' | 'single' | 'two'
  String layout = 'single';
  // checklist style: list of todo items (label + optional description)
  final List<_Todo> checklist = [];
}
class _Field {
  String key = '';
  String label = '';
  String type = 'text';      // text|number|boolean|date|image|choice
  bool required = false;
  // number extras
  String? unit;
  double? min;
  double? max;
  // choice extras
  final List<String> options = [];
}

class _Todo {
  _Todo({required this.label, this.description});
  final String label;
  final String? description;

  _Todo copyWith({String? label, String? description}) => _Todo(label: label ?? this.label, description: description ?? this.description);

  Map<String, dynamic> toMap() {
    if (description == null || description!.isEmpty) return {'label': label};
    return {'label': label, 'description': description};
  }

  @override
  String toString() => label;
}
