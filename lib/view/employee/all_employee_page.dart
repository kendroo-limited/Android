import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/auth_provider.dart';
import '../../repo/odoo_json_rpc.dart';

class EmployeeProviderView extends ChangeNotifier {
  bool isSaving = false;
  List<Map<String, dynamic>> employees = [];
  String locationStatus = 'Ready';

  // Initialize OdooSessionRpc with the cookie
  OdooSessionRpc _rpc(String cookie) {
    return OdooSessionRpc(
      baseUrl: "https://demo.kendroo.com",
      sessionCookie: cookie,
    );
  }

  // Fetch employee data from Odoo
  Future<void> fetchEmployees(String cookie, {bool updateStatus = true}) async {
    isSaving = true;
    notifyListeners();  // Notify listeners to show loading

    try {
      final rows = await _rpc(cookie).fetchEmployeeData(
        domain: [], // You can filter employees as needed
        fields: ['name', 'work_phone', 'work_email', 'job_id', 'department_id'], // Fields to retrieve
      );
      print("Rows fetched:");
      print("Rows fetched: $rows");  // Print the fetched rows

      employees = rows.map((row) {
        // Extract relevant fields from each row and handle nested fields
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
      notifyListeners();  // Notify listeners to refresh the UI after data has been fetched
    }
  }
}

class EmployeeListView extends StatefulWidget {
  const EmployeeListView({super.key});

  @override
  State<EmployeeListView> createState() => _EmployeeListViewState();
}

class _EmployeeListViewState extends State<EmployeeListView> {
 // late EmployeeProviderView _employeeProviderView;
  late AuthProvider auth;

  @override
  void initState() {
    super.initState();
    // Initialize EmployeeProviderView and AuthProvider
    auth = Provider.of<AuthProvider>(context, listen: false);
    final employeeProvider = Provider.of<EmployeeProviderView>(context, listen: false);

    // Fetch employees as soon as the page is loaded
    if (auth.sessionCookie != null) {
      employeeProvider.fetchEmployees(auth.sessionCookie!); // Pass the session cookie
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee List'),
        centerTitle: true,
      ),
      body: Consumer<EmployeeProviderView>(
        builder: (context, employeeProvider, child) {
          return employeeProvider.isSaving
              ? const Center(child: CircularProgressIndicator())
              : _buildEmployeeList(employeeProvider);
        },
      ),
    );
  }

  Widget _buildEmployeeList(EmployeeProviderView employeeProvider) {
    print("Employee List: ${employeeProvider.employees.toString()}");

    if (employeeProvider.employees.isEmpty && !employeeProvider.isSaving) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Text("No employees available"),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: employeeProvider.employees.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = employeeProvider.employees[index];
        final name = item['name'] ?? 'Unknown';
        final phone = item['work_phone'] ?? 'No Phone';
        final email = item['work_email'] ?? 'No Email';
   //     final department = item['department'] ?? 'No Department'; // Use correct key
     //  final jobTitle = item['job_title'] ?? 'No Job Title'; // Use correct key

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(
            backgroundColor: Colors.blue,
            child: Icon(Icons.person, color: Colors.white, size: 18),
          ),
          title: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        //  subtitle: Text('$jobTitle\n$department', style: const TextStyle(fontSize: 11)),
          trailing: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
            child: Text(
              email,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
          onTap: () {
            // Handle tap to show employee details if needed
          },
        );
      },
    );
  }
}