import 'package:flutter/material.dart';

import '../repo/odoo_json_rpc.dart';


class TaskProvider extends ChangeNotifier {
  bool loading = false;
  String status = 'Ready';
  Map<String, dynamic> profile = {};

  OdooSessionRpc _rpc(String cookie) {
    return OdooSessionRpc(
      baseUrl: "https://demo.kendroo.com",
      sessionCookie: cookie,
    );
  }

  String s(dynamic v, {String fallback = '-'}) {
    if (v == null || v == false) return fallback;
    if (v is String && v.trim().isEmpty) return fallback;
    return v.toString();
  }

  String m2oName(dynamic v, {String fallback = '-'}) {
    if (v == null || v == false) return fallback;
    if (v is List && v.length > 1) return s(v[1], fallback: fallback);
    return fallback;
  }

  Future<void> writeTask({
    required String cookie,
    required int uid,
  }) async {
    loading = true;
    status = "Loading...";
    notifyListeners();

    try {
      final now = DateTime.now();
      final dateStr =
          "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final ok = await _rpc(cookie).write(
        model: 'res.users',
        ids: [uid],
        values: {
          "date": dateStr,
        },
      );

      status = ok == true ? "Success" : "Failed";
    } catch (e) {
      status = "Server error: $e";
    } finally {
      loading = false;
      notifyListeners();
    }
  }


}
class NewTaskCreatePage extends StatefulWidget {
  const NewTaskCreatePage({super.key});

  @override
  State<NewTaskCreatePage> createState() => _NewTaskCreatePageState();
}

class _NewTaskCreatePageState extends State<NewTaskCreatePage> {
  // Controllers
  final _descCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();

  // Form state
  DateTime? _selectedDateTime;
  String? _selectedProject;
  String? _selectedTask;

  bool _saving = false;


  final List<String> _projects = const ["Kendroo ERP", "ISP Suite", "Hospital App"];
  final Map<String, List<String>> _tasksByProject = const {
    "Kendroo ERP": ["Bug Fix", "New Feature", "Testing"],
    "ISP Suite": ["Client Module", "Work Order", "Billing"],
    "Hospital App": ["UI Design", "API Integration", "Release"],
  };

  List<String> get _tasks {
    if (_selectedProject == null) return const [];
    return _tasksByProject[_selectedProject] ?? const [];
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _hoursCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime ?? now),
    );
    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  String _formatDT(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}  $hh:$mm";
  }

  void _onProjectChanged(String? v) {
    setState(() {
      _selectedProject = v;
      _selectedTask = null;
    });
  }

  bool get _canSubmit {
    final hours = double.tryParse(_hoursCtrl.text.trim());
    return _selectedDateTime != null &&
        _selectedProject != null &&
        _selectedTask != null &&
        _descCtrl.text.trim().isNotEmpty &&
        hours != null &&
        hours > 0;
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;

    setState(() => _saving = true);


    final payload = {
      "datetime": _selectedDateTime!.toIso8601String(),
      "project": _selectedProject,
      "task": _selectedTask,
      "description": _descCtrl.text.trim(),
      "hours": double.parse(_hoursCtrl.text.trim()),
    };


    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Task created ✅  (${payload["hours"]} hours)")),
    );

    Navigator.pop(context, payload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create New Task"),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionCard(
              title: "Time",
              child: InkWell(
                onTap: _saving ? null : _pickDateTime,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedDateTime == null
                              ? "Select date & time"
                              : _formatDT(_selectedDateTime!),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _selectedDateTime == null
                                ? Colors.black54
                                : Colors.black87,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            _SectionCard(
              title: "Project",
              child: DropdownButtonFormField<String>(
                value: _selectedProject,
                items: _projects
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: _saving ? null : _onProjectChanged,
                decoration: const InputDecoration(
                  hintText: "Select a project",
                  border: OutlineInputBorder(),
                ),
              ),
            ),

            const SizedBox(height: 12),

            _SectionCard(
              title: "Task",
              child: DropdownButtonFormField<String>(
                value: _selectedTask,
                items: _tasks
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (_saving || _selectedProject == null) ? null : (v) => setState(() => _selectedTask = v),
                decoration: const InputDecoration(
                  hintText: "Select a task",
                  border: OutlineInputBorder(),
                ),
              ),
            ),

            const SizedBox(height: 12),

            _SectionCard(
              title: "Description",
              child: TextFormField(
                controller: _descCtrl,
                enabled: !_saving,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: "Write what you worked on...",
                  border: OutlineInputBorder(),
                ),
              ),
            ),

            const SizedBox(height: 12),

            _SectionCard(
              title: "Hours",
              child: TextFormField(
                controller: _hoursCtrl,
                enabled: !_saving,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  hintText: "e.g. 1.5",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timer_outlined),
                ),
              ),
            ),

            const SizedBox(height: 18),

            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: (_saving || !_canSubmit) ? null : _submit,
                child: _saving
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text("Create Task",
                  style: TextStyle(
                    color: Color(0xFF77A6FF)
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}