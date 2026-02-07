import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../provider/auth_provider.dart';


// class EmployeeDetailPage extends StatelessWidget {
//   final Map<String, dynamic> employee;
//
//   const EmployeeDetailPage({super.key, required this.employee});
//
//   String s(dynamic v, {String fallback = '-'}) {
//     if (v == null || v == false) return fallback;
//     if (v is String && v.trim().isEmpty) return fallback;
//     return v.toString();
//   }
//
//   Future<void> _makePhoneCall(String phoneNumber) async {
//
//
//     final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
//     if (await canLaunchUrl(launchUri)) {
//       await launchUrl(launchUri);
//     } else {
//       print('Could not launch $phoneNumber');
//     }
//   }
//
//
//   Future<void> _launchEmail(String to, {String? subject, String? body}) async {
//     final email = to.trim();
//     if (email.isEmpty || email == 'No Email' || email == '-') return;
//
//     final uri = Uri(
//       scheme: 'mailto',
//       path: email,
//       queryParameters: {
//         if (subject != null && subject.isNotEmpty) 'subject': subject,
//         if (body != null && body.isNotEmpty) 'body': body,
//       },
//     );
//
//     if (await canLaunchUrl(uri)) {
//       await launchUrl(uri, mode: LaunchMode.externalApplication);
//       return;
//     }
//
//
//     final web = Uri.https('mail.google.com', '/mail/', {
//       'view': 'cm',
//       'to': email,
//       if (subject != null && subject.isNotEmpty) 'su': subject,
//       if (body != null && body.isNotEmpty) 'body': body,
//     });
//
//     if (!await launchUrl(web, mode: LaunchMode.externalApplication)) {
//       throw Exception('No email app found');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Employee Details'),
//         centerTitle: true,
//       ),
//       body: _buildDetails(context),
//     );
//   }
//
//   Widget _buildDetails(BuildContext context) {
//     final sessionCookie =
//         Provider.of<AuthProvider>(context, listen: false).sessionCookie ?? '';
//
//     final name = s(employee['name'], fallback: 'Unknown');
//     final phone = s(employee['work_phone'], fallback: 'No Phone');
//     final email = s(employee['work_email'], fallback: 'No Email');
//     final dept = s(employee['department'], fallback: 'No Department');
//     final job = s(employee['job_title'], fallback: 'No Job Title');
//
//
//     final imageUrl = s(employee['imageUrl'], fallback: '');
//
//     ImageProvider? avatarImage;
//     if (imageUrl.isNotEmpty && imageUrl != '-') {
//       avatarImage = NetworkImage(
//         "https://demo.kendroo.com$imageUrl",
//         headers: {"Cookie": sessionCookie},
//       );
//     }
//
//     return SingleChildScrollView(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.grey.shade50,
//               border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
//             ),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 CircleAvatar(
//                   radius: 36,
//                   backgroundImage: avatarImage,
//                   backgroundColor:
//                   avatarImage == null ? Colors.blue.shade100 : Colors.transparent,
//                   child: avatarImage == null
//                       ? const Icon(Icons.person, size: 40, color: Colors.blue)
//                       : null,
//                 ),
//                 const SizedBox(width: 14),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         name,
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                         style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         job,
//                         style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
//                       ),
//                       const SizedBox(height: 10),
//
//
//                       Wrap(
//                         spacing: 10,
//                         runSpacing: 10,
//                         children: [
//                           OutlinedButton.icon(
//                             onPressed: () => _makePhoneCall(phone),
//                             icon: const Icon(Icons.call, size: 18),
//                             label: const Text("Call"),
//                           ),
//                           OutlinedButton.icon(
//                             onPressed: () => _launchEmail(email, subject: "Hello $name"),
//                             icon: const Icon(Icons.email, size: 18),
//                             label: const Text("Email"),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           // Details
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const SizedBox(height: 10),
//                 const Text(
//                   "Organizational Details",
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//                 const Divider(),
//
//                 _infoRow(Icons.business_center, 'Job Title', job),
//                 _infoRow(Icons.business, 'Department', dept),
//                 _infoRow(Icons.phone, 'Phone', phone),
//                 _infoRow(Icons.email, 'Email', email),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _infoRow(IconData icon, String label, String value) {
//     final v = (value.trim().isNotEmpty && value != '-' && value != 'false') ? value : 'N/A';
//
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(icon, size: 20, color: Colors.grey.shade600),
//           const SizedBox(width: 12),
//
//           SizedBox(
//             width: 110,
//             child: Text(
//               label,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//               style: const TextStyle(color: Colors.black54, fontSize: 15),
//             ),
//           ),
//
//           const SizedBox(width: 10),
//
//           Expanded(
//             child: Text(
//               v,
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//               style: const TextStyle(
//                 color: Colors.black,
//                 fontSize: 15,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class EmployeeDetailPage extends StatelessWidget {
  final Map<String, dynamic> employee;

  const EmployeeDetailPage({super.key, required this.employee});

  String s(dynamic v, {String fallback = '-'}) {
    if (v == null || v == false) return fallback;
    if (v is String && v.trim().isEmpty) return fallback;
    return v.toString();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {


    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      print('Could not launch $phoneNumber');
    }
  }

  Future<void> _launchEmail(String to, {String? subject, String? body}) async {
    final email = to.trim();
    if (email.isEmpty || email == 'No Email' || email == '-') return;

    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        if (subject != null && subject.isNotEmpty) 'subject': subject,
        if (body != null && body.isNotEmpty) 'body': body,
      },
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    final web = Uri.https('mail.google.com', '/mail/', {
      'view': 'cm',
      'to': email,
      if (subject != null && subject.isNotEmpty) 'su': subject,
      if (body != null && body.isNotEmpty) 'body': body,
    });

    await launchUrl(web, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Details'),
        centerTitle: true,
      ),
      body: SafeArea(child: _buildDetails(context)),
    );
  }

  Widget _buildDetails(BuildContext context) {
    final sessionCookie =
        Provider.of<AuthProvider>(context, listen: false).sessionCookie ?? '';

    final size = MediaQuery.of(context).size;
    final w = size.width;
    final isSmall = w < 360;
    final isTablet = w >= 600;

    final padding = isSmall ? 12.0 : 16.0;
    final avatarRadius = isSmall ? 30.0 : (isTablet ? 44.0 : 36.0);
    final titleFont = isSmall ? 18.0 : (isTablet ? 24.0 : 20.0);
    final subFont = isSmall ? 13.0 : (isTablet ? 16.0 : 15.0);

    final name = s(employee['name'], fallback: 'Unknown');
    final phone = s(employee['work_phone'], fallback: 'No Phone');
    final email = s(employee['work_email'], fallback: 'No Email');
    final dept = s(employee['department'], fallback: 'No Department');
    final job = s(employee['job_title'], fallback: 'No Job Title');

    final imageUrl = s(employee['imageUrl'], fallback: '');

    ImageProvider? avatarImage;
    if (imageUrl.isNotEmpty && imageUrl != '-') {
      avatarImage = NetworkImage(
        "https://demo.kendroo.com$imageUrl",
        headers: {"Cookie": sessionCookie},
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: avatarRadius,
                  backgroundImage: avatarImage,
                  backgroundColor:
                  avatarImage == null ? Colors.blue.shade100 : Colors.transparent,
                  child: avatarImage == null
                      ? Icon(Icons.person, size: avatarRadius + 6, color: Colors.blue)
                      : null,
                ),
                SizedBox(width: isSmall ? 10 : 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: titleFont, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        job,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade700, fontSize: subFont),
                      ),
                      SizedBox(height: isSmall ? 10 : 12),

                      // Responsive Buttons
                      isSmall
                          ? Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _makePhoneCall(phone),
                              icon: const Icon(Icons.call, size: 18),
                              label: const Text("Call"),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _launchEmail(email, subject: "Hello $name"),
                              icon: const Icon(Icons.email, size: 18),
                              label: const Text("Email"),
                            ),
                          ),
                        ],
                      )
                          : Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _makePhoneCall(phone),
                            icon: const Icon(Icons.call, size: 18),
                            label: const Text("Call"),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _launchEmail(email, subject: "Hello $name"),
                            icon: const Icon(Icons.email, size: 18),
                            label: const Text("Email"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Details Section
          Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Organizational Details",
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),

                _infoRow(context, Icons.business_center, 'Job Title', job),
                _infoRow(context, Icons.business, 'Department', dept),
                _infoRow(context, Icons.phone, 'Phone', phone),
                _infoRow(context, Icons.email, 'Email', email),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String label, String value) {
    final w = MediaQuery.of(context).size.width;
    final isSmall = w < 360;

    // adaptive label width (prevents overflow)
    final labelWidth = isSmall ? 90.0 : (w < 420 ? 110.0 : 140.0);

    final v = (value.trim().isNotEmpty && value != '-' && value != 'false') ? value : 'N/A';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: isSmall ? 18 : 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),

          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.black54,
                fontSize: isSmall ? 13 : 15,
              ),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              v,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.black,
                fontSize: isSmall ? 13 : 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}





