import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/auth_provider.dart';
import '../../repo/odoo_json_rpc.dart';
import 'employee_details_view.dart';
import 'package:flutter/foundation.dart';


class EmployeeProviderView extends ChangeNotifier {
  bool isSaving = false;
  List<Map<String, dynamic>> employees = [];
  String locationStatus = 'Ready';


  OdooSessionRpc _rpc(String cookie) {
    return OdooSessionRpc(
      baseUrl: "http://72.61.250.60:8069",
      sessionCookie: cookie,
    );
  }


  Future<void> fetchEmployees(String cookie, {bool updateStatus = true}) async {
    isSaving = true;
    notifyListeners();

    try {
      final rows = await _rpc(cookie).fetchEmployeeData(
        domain: [],
        fields: ['id', 'name', 'work_phone', 'work_email', 'job_id', 'department_id','image_1920','avatar_128',],
      );

      employees = rows.map((row) {
        String m2oName(dynamic v, {String fallback = 'No'}) {
          if (v == null || v == false) return fallback;
          if (v is List && v.length > 1) return (v[1] ?? fallback).toString();
          return fallback;
        }

        String safe(dynamic v, {String fallback = 'No'}) {
          if (v == null || v == false) return fallback;
          final s = v.toString().trim();
          return s.isEmpty ? fallback : s;
        }

        return {
          'id': row['id'],
          'name': safe(row['name'], fallback: 'No Name'),
          'work_phone': safe(row['work_phone'], fallback: 'No Phone'),
          'work_email': safe(row['work_email'], fallback: 'No Email'),
          'department': m2oName(row['department_id'], fallback: 'No Department'),
          'job_title': m2oName(row['job_id'], fallback: 'No Job Title'),
          'image_1920' : row['image_1920']
        };
      }).toList();

      locationStatus = employees.isEmpty ? "No employees found." : "Employees loaded ✅";
    } catch (e) {
      locationStatus = "Server error: $e";
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}



class EmployeeListView extends StatefulWidget {
  const EmployeeListView({super.key});

  @override
  State<EmployeeListView> createState() => _EmployeeListViewState();
}

class _EmployeeListViewState extends State<EmployeeListView> {
  late AuthProvider auth;

  @override
  // void initState() {
  //   super.initState();
  //
  //   auth = Provider.of<AuthProvider>(context, listen: false);
  //   final employeeProvider = Provider.of<EmployeeProviderView>(context, listen: false);
  //
  //   if (auth.sessionCookie != null) {
  //     employeeProvider.fetchEmployees(auth.sessionCookie!);
  //   }
  // }


  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final employeeProvider = context.read<EmployeeProviderView>();

      if (auth.sessionCookie != null) {
        employeeProvider.fetchEmployees(auth.sessionCookie!);
      }
    });
  }
  Uint8List? base64ToImage(dynamic base64String) {
    if (base64String == null || base64String == false) return null;
    try {
      return base64Decode(base64String);
    } catch (_) {
      return null;
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

    // final prof = employeeProvider.employees[0];

    // final imageBytes = base64ToImage(prof['avatar_128'] ?? prof['image_1920']);
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 10),
      itemCount: employeeProvider.employees.length,
      separatorBuilder: (_, __) => const Divider(height: 12),
      itemBuilder: (context, index) {
        final item = employeeProvider.employees[index];

        final name = (item['name'] ?? 'Unknown').toString();
        final email = (item['work_email'] ?? 'No Email').toString();
        final imageBytes = base64ToImage(item['avatar_128'] ?? item['image_1920']);
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
                // CircleAvatar(
                //   radius: avatarRadius,
                //   backgroundColor: Colors.blue,
                //   child: Icon(Icons.person, color: Colors.white, size: isSmall ? 16 : 18),
                // ),
                CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: Colors.blue.shade100,
                  backgroundImage: imageBytes != null ? MemoryImage(imageBytes) : null,
                  child: imageBytes == null
                      ? Icon(Icons.person, size: avatarRadius + 4, color: Colors.blue)
                      : null,
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