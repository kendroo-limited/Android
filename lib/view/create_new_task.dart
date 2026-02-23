import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';
import '../repo/odoo_json_rpc.dart';
import 'package:flutter/foundation.dart';

class TaskProvider extends ChangeNotifier {
  String status = 'Ready';

  OdooSessionRpc _rpc(String cookie) => OdooSessionRpc(
    baseUrl: "https://demo.kendroo.com",
    sessionCookie: cookie,
  );


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


  bool loadingProjects = false;
  bool loadingTasks = false;
  List<Map<String, dynamic>> projects = [];
  List<Map<String, dynamic>> tasks = [];
  int? selectedProjectId;
  String? selectedProjectName;
  int? selectedTaskId;
  String? selectedTaskName;
  bool loadingTimesheets = false;
  bool savingTimesheet = false;
  List<Map<String, dynamic>> timesheets = [];

  Future<void> fetchProjects({
    required String cookie,
    String query = "",
    int limit = 20,
    int offset = 0,
    bool onlyMyProjects = true,
  }) async {
    loadingProjects = true;
    notifyListeners();

    try {
      final domain = <dynamic>[
        ['allow_timesheets', '=', true],
      ];

      if (query.trim().isNotEmpty) {
        domain.add(['name', 'ilike', query.trim()]);
      }

      final ctx = <String, dynamic>{
        if (onlyMyProjects) 'search_default_my_projects': true,
      };

      final rows = await _rpc(cookie).searchRead(
        model: 'project.project',
        domain: domain,
        fields: ['id', 'display_name', 'partner_id', 'user_id'],
        limit: limit,
        offset: offset,
        context: ctx,
      );

      projects = (rows as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      status = "Projects loaded ✅";
    } catch (e) {
      status = "Project load error: $e";
    } finally {
      loadingProjects = false;
      notifyListeners();
    }
  }

  Future<void> fetchTasks({
    required String cookie,
    int? projectId,
    String query = "",
    int limit = 20,
    int offset = 0,
    bool onlyMyTasks = true,
    bool onlyOpenTasks = true,
  }) async {
    loadingTasks = true;
    notifyListeners();

    try {
      final domain = <dynamic>[
        ['allow_timesheets', '=', true],
      ];

      if (projectId != null) {
        domain.add(['project_id', '=', projectId]);
      }

      if (query.trim().isNotEmpty) {
        domain.add(['name', 'ilike', query.trim()]);
      }

      final ctx = <String, dynamic>{
        if (projectId != null) 'default_project_id': projectId,
        if (onlyMyTasks) 'search_default_my_tasks': true,
        if (onlyOpenTasks) 'search_default_open_tasks': true,
      };

      final rows = await _rpc(cookie).searchRead(
        model: 'project.task',
        domain: domain,
        fields: [
          'id',
          'name',
          'user_ids',
          'effective_hours',
          'progress',
          'stage_id',
        ],
        limit: limit,
        offset: offset,
        context: ctx,
      );

      tasks = (rows as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      status = "Tasks loaded ✅";
    } catch (e) {
      status = "Task load error: $e";
    } finally {
      loadingTasks = false;
      notifyListeners();
    }
  }


  void setSelectedProject(Map<String, dynamic> row) {
    selectedProjectId = row['id'] as int?;
    selectedProjectName = s(row['display_name'] ?? row['name']);


    selectedTaskId = null;
    selectedTaskName = null;
    tasks = [];
    notifyListeners();
  }

  void setSelectedTask(Map<String, dynamic> row) {
    selectedTaskId = row['id'] as int?;
    selectedTaskName = s(row['name']);
    notifyListeners();
  }


  Future<int?> createTimesheet({
    required String cookie,
    required int uid,
    required DateTime date,
    required int projectId,
    required int taskId,
    required String description,
    required double hours,
  }) async {
    savingTimesheet = true;
    notifyListeners();

    try {
      final dateStr =
          "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";


      final newId = await _rpc(cookie).create(
        model: 'account.analytic.line',
        values: {
          'date': dateStr,
          'project_id': projectId,
          'task_id': taskId,
          'name': description,
          'unit_amount': hours,
          'user_id': uid,
        },
      );

      status = "Timesheet created ✅";
      return newId is int ? newId : null;
    } catch (e) {
      status = "Timesheet create error: $e";
      return null;
    } finally {
      savingTimesheet = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyTimesheets({
    required String cookie,
    required int uid,
    int limit = 30,
    int offset = 0,
    DateTime? from,
    DateTime? to,
  }) async {
    loadingTimesheets = true;
    notifyListeners();

    try {
      final domain = <dynamic>[
        ['user_id', '=', uid],
      ];

      if (from != null) {
        final f =
            "${from.year.toString().padLeft(4, '0')}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}";
        domain.add(['date', '>=', f]);
      }
      if (to != null) {
        final t =
            "${to.year.toString().padLeft(4, '0')}-${to.month.toString().padLeft(2, '0')}-${to.day.toString().padLeft(2, '0')}";
        domain.add(['date', '<=', t]);
      }

      final rows = await _rpc(cookie).searchRead(
        model: 'account.analytic.line',
        domain: domain,
        fields: [
          'id',
          'date',
          'project_id',
          'task_id',
          'name',
          'unit_amount',
          'user_id',
        ],
        limit: limit,
        offset: offset,

      );

      timesheets = (rows as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      status = "Timesheets loaded ✅";
    } catch (e) {
      status = "Timesheet load error: $e";
    } finally {
      loadingTimesheets = false;
      notifyListeners();
    }
  }


  void clearSelection() {
    selectedProjectId = null;
    selectedProjectName = null;
    selectedTaskId = null;
    selectedTaskName = null;
    tasks = [];
    notifyListeners();
  }
}
class NewTaskCreatePage extends StatefulWidget {
  const NewTaskCreatePage({super.key});

  @override
  State<NewTaskCreatePage> createState() => _NewTaskCreatePageState();
}

class _NewTaskCreatePageState extends State<NewTaskCreatePage> {
  final _descCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();

  DateTime? _selectedDateTime;
  bool _saving = false;

  late final TaskProvider tp;

  @override
  void initState() {
    super.initState();


    tp = context.read<TaskProvider>();

    final auth = context.read<AuthProvider>();
    final cookie = auth.sessionCookie ?? '';

    if (cookie.isNotEmpty) {
      tp.fetchProjects(cookie: cookie);
      // optional: preload timesheets list
      // final uid = auth.user?.uid;
      // if (uid != null) tp.fetchMyTimesheets(cookie: cookie, uid: uid);
    }
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

    setState(() {
      _selectedDateTime = date; // only date, no time
    });
  }

  // String _formatDT(DateTime dt) {
  //   final hh = dt.hour.toString().padLeft(2, '0');
  //   final mm = dt.minute.toString().padLeft(2, '0');
  //   return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}  $hh:$mm";
  //
  // }
  String _formatDT(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }

  Future<void> _pickProject() async {
    final auth = context.read<AuthProvider>();
    final cookie = auth.sessionCookie ?? '';
    if (cookie.isEmpty) return;

    await tp.fetchProjects(cookie: cookie, query: "");

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => _SearchSelectDialog(
        title: "Search: Project",
        loading: tp.loadingProjects,
        items: tp.projects,
        displayText: (row) => (row["display_name"] ?? row["name"] ?? "-").toString(),
        onSearch: (q) => tp.fetchProjects(cookie: cookie, query: q),
        onSelect: (row) {
          tp.setSelectedProject(row);
          Navigator.pop(context);
        },
      ),
    );


    if (tp.selectedProjectId != null) {
      await tp.fetchTasks(cookie: cookie, projectId: tp.selectedProjectId!, query: "");
    }
  }


  Future<void> _pickTask() async {
    final auth = context.read<AuthProvider>();
    final cookie = auth.sessionCookie ?? '';
    if (cookie.isEmpty) return;

    if (tp.selectedProjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select a project first")),
      );
      return;
    }

    await tp.fetchTasks(cookie: cookie, projectId: tp.selectedProjectId!, query: "");

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => _SearchSelectDialog(
        title: "Search: Task",
        loading: tp.loadingTasks,
        items: tp.tasks,
        displayText: (row) => (row["name"] ?? "-").toString(),
        onSearch: (q) => tp.fetchTasks(
          cookie: cookie,
          projectId: tp.selectedProjectId!,
          query: q,
        ),
        onSelect: (row) {
          tp.setSelectedTask(row);
          Navigator.pop(context);
        },
      ),
    );
  }


  bool get _canSubmit {
    final hours = double.tryParse(_hoursCtrl.text.trim());
    return _selectedDateTime != null &&
        tp.selectedProjectId != null &&
        tp.selectedTaskId != null &&
        _descCtrl.text.trim().isNotEmpty &&
        hours != null &&
        hours > 0;
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;

    setState(() => _saving = true);

    try {
      final auth = context.read<AuthProvider>();
      final cookie = auth.sessionCookie ?? '';
      final uid = auth.user?.uid;

      if (cookie.isEmpty || uid == null) {
        throw Exception("Auth missing (cookie/uid)");
      }

      final hours = double.parse(_hoursCtrl.text.trim());
      final desc = _descCtrl.text.trim();

      final newId = await tp.createTimesheet(
        cookie: cookie,
        uid: uid,
        date: _selectedDateTime!,
        projectId: tp.selectedProjectId!,
        taskId: tp.selectedTaskId!,
        description: desc,
        hours: hours,
      );

      if (newId == null) {
        throw Exception("Timesheet create failed");
      }


      // await tp.fetchMyTimesheets(cookie: cookie, uid: uid);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Timesheet created ✅  (${hours.toString()} hours)")),
      );

      Navigator.pop(context, {
        "id": newId,
        "date": _selectedDateTime!.toIso8601String(),
        "project_id": tp.selectedProjectId,
        "task_id": tp.selectedTaskId,
        "description": desc,
        "hours": hours,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tpWatch = context.watch<TaskProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Timesheet"),
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
                              ? "Select date"
                              : _formatDT(_selectedDateTime!),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _selectedDateTime == null ? Colors.black54 : Colors.black87,
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
              child: InkWell(
                onTap: _saving ? null : _pickProject,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.folder_open),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          tpWatch.selectedProjectName ?? "Select a project",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: tpWatch.selectedProjectName == null ? Colors.black54 : Colors.black87,
                          ),
                        ),
                      ),
                      if (tpWatch.loadingProjects) ...[
                        const SizedBox(width: 10),
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ] else
                        const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            _SectionCard(
              title: "Task",
              child: InkWell(
                onTap: (_saving || tpWatch.selectedProjectId == null) ? null : _pickTask,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.task_alt),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          tpWatch.selectedTaskName ??
                              (tpWatch.selectedProjectId == null
                                  ? "Select project first"
                                  : "Select a task"),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: tpWatch.selectedTaskName == null ? Colors.black54 : Colors.black87,
                          ),
                        ),
                      ),
                      if (tpWatch.loadingTasks) ...[
                        const SizedBox(width: 10),
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ] else
                        const Icon(Icons.chevron_right),
                    ],
                  ),
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
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(
                  hintText: "e.g. 9:15",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timer_outlined),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d{0,2}:?\d{0,2}$')),
                ],
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
                    : const Text("Create Timesheet"),
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

class _SearchSelectDialog extends StatefulWidget {
  final String title;
  final bool loading;
  final List<Map<String, dynamic>> items;
  final String Function(Map<String, dynamic>) displayText;
  final Future<void> Function(String q) onSearch;
  final void Function(Map<String, dynamic> row) onSelect;

  const _SearchSelectDialog({
    required this.title,
    required this.loading,
    required this.items,
    required this.displayText,
    required this.onSearch,
    required this.onSelect,
  });

  @override
  State<_SearchSelectDialog> createState() => _SearchSelectDialogState();
}

class _SearchSelectDialogState extends State<_SearchSelectDialog> {
  final _qCtrl = TextEditingController();

  @override
  void dispose() {
    _qCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.all(12),
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        height: 420,
        child: Column(
          children: [
            TextField(
              controller: _qCtrl,
              decoration: InputDecoration(
                hintText: "Search...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => widget.onSearch(_qCtrl.text),
                ),
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) {
                // small debounce feel (optional)
              },
              onSubmitted: (v) => widget.onSearch(v),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: widget.loading
                  ? const Center(child: CircularProgressIndicator())
                  : widget.items.isEmpty
                  ? const Center(child: Text("No items found"))
                  : ListView.separated(
                itemCount: widget.items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final row = widget.items[i];
                  return ListTile(
                    title: Text(widget.displayText(row)),
                    onTap: () => widget.onSelect(row),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        ),
      ],
    );
  }
}