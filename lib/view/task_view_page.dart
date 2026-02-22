import 'package:field_force_2/view/project_details_page.dart';
import 'package:field_force_2/view/task_details_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';
import '../provider/project_provider.dart';

import '../model/project_model.dart';
import '../model/task_model.dart';
import 'create_new_task.dart';




class ProjectsTasksPage extends StatefulWidget {
  const ProjectsTasksPage({super.key});

  @override
  State<ProjectsTasksPage> createState() => _ProjectsTasksPageState();
}

class _ProjectsTasksPageState extends State<ProjectsTasksPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 1, vsync: this); // ✅ only 1 tab now

    Future.microtask(() async {
      final auth = context.read<AuthProvider>();
      final cookie = auth.sessionCookie ?? '';
      final uid = auth.user?.uid;

      if (cookie.isNotEmpty && uid != null) {
        await context.read<TaskProvider>().fetchMyTimesheets(
          cookie: cookie,
          uid: uid,
        );
      }
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Timesheets"),
        centerTitle: true,
        // bottom: TabBar(
        //   controller: _tab,
        //   labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        //   // tabs: const [
        //   //   Tab(
        //   //     child: Text(
        //   //       "Tasks",
        //   //       style: TextStyle(color: Color(0xFF77A6FF)),
        //   //     ),
        //   //   ),
        //   // ],
        // ),
        actions: [
          InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NewTaskCreatePage()),
              );


              final auth = context.read<AuthProvider>();
              final cookie = auth.sessionCookie ?? '';
              final uid = auth.user?.uid;
              if (cookie.isNotEmpty && uid != null) {
                await context.read<TaskProvider>().fetchMyTimesheets(
                  cookie: cookie,
                  uid: uid,
                );
              }
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF77A6FF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                "New",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          )
        ],
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _TasksTab(),
        ],
      ),
    );
  }
}


class _TasksTab extends StatelessWidget {
  const _TasksTab();

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<TaskProvider>();
    final auth = context.read<AuthProvider>();

    final cookie = auth.sessionCookie ?? '';
    final uid = auth.user?.uid;


    if (prov.loadingTimesheets) {
      return const Center(child: CircularProgressIndicator());
    }


    if (prov.timesheets.isEmpty) {
      return const Center(child: Text("No Timesheets Found"));
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (cookie.isNotEmpty && uid != null) {
          await context.read<TaskProvider>().fetchMyTimesheets(
            cookie: cookie,
            uid: uid,
          );
        }
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: prov.timesheets.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _TaskTile(row: prov.timesheets[i]),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final Map<String, dynamic> row;

  const _TaskTile({super.key, required this.row});

  @override
  Widget build(BuildContext context) {
    final tp = context.read<TaskProvider>();

    final desc = tp.s(row['name'], fallback: '-');
    final date = tp.s(row['date'], fallback: '-');
    final project = tp.m2oName(row['project_id'], fallback: '-');
    final task = tp.m2oName(row['task_id'], fallback: '-');

    final hoursRaw = row['unit_amount'];
    final hours = (hoursRaw is num)
        ? hoursRaw.toDouble()
        : double.tryParse(hoursRaw?.toString() ?? "0") ?? 0.0;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),


        title: Text(
          desc,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),


        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$project • $task",
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text("Date: $date", style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),


        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer_outlined, size: 14),
              const SizedBox(width: 4),
              Text(
                "${hours.toStringAsFixed(hours % 1 == 0 ? 0 : 1)}h",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        onTap: () {

          // Navigator.push(context, MaterialPageRoute(builder: (_) => TimesheetDetailsPage(row: row)));
        },
      ),
    );
  }
}

