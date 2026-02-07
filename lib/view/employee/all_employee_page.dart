import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/auth_provider.dart';
import '../../repo/odoo_json_rpc.dart';
import 'employee_details_view.dart';

class EmployeeProviderView extends ChangeNotifier {
  bool isSaving = false;
  List<Map<String, dynamic>> employees = [];
  String locationStatus = 'Ready';


  OdooSessionRpc _rpc(String cookie) {
    return OdooSessionRpc(
      baseUrl: "https://demo.kendroo.com",
      sessionCookie: cookie,
    );
  }


  Future<void> fetchEmployees(String cookie, {bool updateStatus = true}) async {
    isSaving = true;
    notifyListeners();
    try {
      final rows = await _rpc(cookie).fetchEmployeeData(
        domain: [],
        fields: ['name', 'work_phone', 'work_email', 'job_id', 'department_id'],
      );
      print("Rows fetched:");
      print("Rows fetched: $rows");

      employees = rows.map((row) {

        return {
          'name': row['name'] ?? 'No Name',
          'work_phone': row['work_phone'] ?? 'No Phone',
          'work_email': row['work_email'] ?? 'No Email',
          'department': row['department_id'] != null && row['department_id'].isNotEmpty
              ? row['department_id'][1] ?? 'No Department'
              : 'No Department',
          'job_title': row['job_id'] != null ? row['job_id'] ?? 'No Job Title' : 'No Job Title',
        };
      }).toList();

      print("employees: $employees");

      if (rows.isEmpty) {
        locationStatus = "No employees found.";
      } else {
        locationStatus = "Employees loaded ✅";
      }
    } catch (e) {
      locationStatus = "Server error: $e";
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}

// class EmployeeListView extends StatefulWidget {
//   const EmployeeListView({super.key});
//
//   @override
//   State<EmployeeListView> createState() => _EmployeeListViewState();
// }
//
// class _EmployeeListViewState extends State<EmployeeListView> {
//  // late EmployeeProviderView _employeeProviderView;
//   late AuthProvider auth;
//
//   @override
//   void initState() {
//     super.initState();
//
//     auth = Provider.of<AuthProvider>(context, listen: false);
//     final employeeProvider = Provider.of<EmployeeProviderView>(context, listen: false);
//
//
//     if (auth.sessionCookie != null) {
//       employeeProvider.fetchEmployees(auth.sessionCookie!);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Employee List'),
//         centerTitle: true,
//       ),
//       body: Consumer<EmployeeProviderView>(
//         builder: (context, employeeProvider, child) {
//           return employeeProvider.isSaving
//               ? const Center(child: CircularProgressIndicator())
//               : _buildEmployeeList(employeeProvider);
//         },
//       ),
//     );
//   }
//
//   Widget _buildEmployeeList(EmployeeProviderView employeeProvider) {
//     print("Employee List: ${employeeProvider.employees.toString()}");
//
//     if (employeeProvider.employees.isEmpty && !employeeProvider.isSaving) {
//       return const Padding(
//         padding: EdgeInsets.all(20.0),
//         child: Text("No employees available"),
//       );
//     }
//
//     return ListView.separated(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: employeeProvider.employees.length,
//       separatorBuilder: (_, __) => const Divider(height: 1),
//       itemBuilder: (context, index) {
//         final item = employeeProvider.employees[index];
//         final name = item['name'] ?? 'Unknown';
//         final phone = item['work_phone'] ?? 'No Phone';
//         final email = item['work_email'] ?? 'No Email';
//    //     final department = item['department'] ?? 'No Department'; // Use correct key
//      //  final jobTitle = item['job_title'] ?? 'No Job Title'; // Use correct key
//
//         return ListTile(
//           contentPadding: EdgeInsets.zero,
//           leading: const CircleAvatar(
//             backgroundColor: Colors.blue,
//             child: Icon(Icons.person, color: Colors.white, size: 18),
//           ),
//           title: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
//         //  subtitle: Text('$jobTitle\n$department', style: const TextStyle(fontSize: 11)),
//           trailing: Container(
//             padding: const EdgeInsets.all(4),
//             decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
//             child: Text(
//               email,
//               style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
//             ),
//           ),
//           onTap: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (_) => EmployeeDetailPage(employee: item),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
// }

class EmployeeListView extends StatefulWidget {
  const EmployeeListView({super.key});

  @override
  State<EmployeeListView> createState() => _EmployeeListViewState();
}

class _EmployeeListViewState extends State<EmployeeListView> {
  late AuthProvider auth;

  @override
  void initState() {
    super.initState();

    auth = Provider.of<AuthProvider>(context, listen: false);
    final employeeProvider = Provider.of<EmployeeProviderView>(context, listen: false);

    if (auth.sessionCookie != null) {
      employeeProvider.fetchEmployees(auth.sessionCookie!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee List'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Consumer<EmployeeProviderView>(
          builder: (context, employeeProvider, child) {
            if (employeeProvider.isSaving) {
              return const Center(child: CircularProgressIndicator());
            }
            return _buildEmployeeList(context, employeeProvider);
          },
        ),
      ),
    );
  }

  Widget _buildEmployeeList(BuildContext context, EmployeeProviderView employeeProvider) {
    if (employeeProvider.employees.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Text("No employees available"),
      );
    }

    final w = MediaQuery.of(context).size.width;
    final isSmall = w < 360;

    final horizontalPadding = isSmall ? 10.0 : 14.0;
    final titleFont = isSmall ? 12.5 : 13.5;
    final emailFont = isSmall ? 9.0 : 10.0;
    final avatarRadius = isSmall ? 16.0 : 18.0;

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 10),
      itemCount: employeeProvider.employees.length,
      separatorBuilder: (_, __) => const Divider(height: 12),
      itemBuilder: (context, index) {
        final item = employeeProvider.employees[index];

        final name = (item['name'] ?? 'Unknown').toString();
        final email = (item['work_email'] ?? 'No Email').toString();

        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EmployeeDetailPage(employee: item),
              ),
            );
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? 10 : 12,
              vertical: isSmall ? 10 : 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.person, color: Colors.white, size: isSmall ? 16 : 18),
                ),
                const SizedBox(width: 10),


                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: titleFont, fontWeight: FontWeight.w600),
                  ),
                ),

                const SizedBox(width: 8),


                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isSmall ? w * 0.40 : w * 0.45,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: emailFont, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}