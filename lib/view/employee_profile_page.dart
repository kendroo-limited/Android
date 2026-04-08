import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../model/employee_model.dart';
import '../provider/auth_provider.dart';
import '../provider/employee_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
// class EmployeeProfilePage extends StatefulWidget {
//   const EmployeeProfilePage({super.key});
//
//   @override
//   State<EmployeeProfilePage> createState() => _EmployeeProfilePageState();
// }
//
// class _EmployeeProfilePageState extends State<EmployeeProfilePage> {
//
//   @override
//   void initState() {
//     super.initState();
//     Future.microtask(() =>
//         Provider.of<EmployeeProvider>(context, listen: false).loadProfile());
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final provider = context.watch<EmployeeProvider>();
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('My profile'),
//         centerTitle: true,
//       ),
//       body: provider.isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : provider.error != null
//           ? Center(
//           child: Text(provider.error!,
//               style: const TextStyle(color: Colors.redAccent)))
//           : provider.profile == null
//           ? const Center(child: Text('No data'))
//           : _buildProfile(context, provider),
//     );
//   }
//
//   // Widget _buildProfile(BuildContext context, EmployeeProvider provider) {
//   //   // We can safely access provider.profile! here because of the checks in build()
//   //   final emp = provider.profile!.employee;
//   //   // Assuming AuthProvider is available
//   //   final sessionCookie = Provider.of<AuthProvider>(context, listen: false).sessionCookie ?? '';
//   //   final w = MediaQuery.of(context).size.width;
//   //
//   //
//   //   return SingleChildScrollView(
//   //     child: Column(
//   //       children: [
//   //         // --- Profile Header Section ---
//   //         Stack(
//   //           alignment: Alignment.topCenter,
//   //           children: [
//   //             // 2. Profile Content (Name, Title, Location, Profile Pic, Contact Info)
//   //             Padding(
//   //               padding: const EdgeInsets.only(top: 20), // Adjust to overlap with the header
//   //               child: Column(
//   //                 children: [
//   //                   // Profile Picture
//   //                   Stack(
//   //                     alignment: Alignment.center,
//   //                     children: [
//   //                       Container(
//   //                         width: 110,
//   //                         height: 110,
//   //                         decoration: BoxDecoration(
//   //                           shape: BoxShape.circle,
//   //                           border: Border.all(color: Colors.white, width: 3),
//   //                           boxShadow: [
//   //                             BoxShadow(
//   //                               color: Colors.black.withOpacity(0.1),
//   //                               blurRadius: 10,
//   //                             ),
//   //                           ],
//   //                         ),
//   //                         child: ClipOval(
//   //                           child: Image.network(
//   //                             'https://demo.kendroo.com${emp.imageUrl}',
//   //                             headers: {'Cookie': sessionCookie},
//   //                             fit: BoxFit.cover,
//   //                             width: 110,
//   //                             height: 110,
//   //                             errorBuilder: (context, error, stackTrace) =>
//   //                             const Icon(Icons.person, size: 60, color: Colors.grey),
//   //                           ),
//   //                         ),
//   //                       ),
//   //                       // Edit Icon on the profile picture
//   //                       Positioned(
//   //                         right: 0,
//   //                         bottom: 0,
//   //                         child: Container(
//   //                           padding: const EdgeInsets.all(4),
//   //                           decoration: const BoxDecoration(
//   //                             color: Colors.white,
//   //                             shape: BoxShape.circle,
//   //                           ),
//   //                           child: const Icon(Icons.camera_alt_outlined, size: 18, color: Colors.grey),
//   //                         ),
//   //                       ),
//   //                     ],
//   //                   ),
//   //                   const SizedBox(height: 16),
//   //                   // Row(
//   //                   //   mainAxisAlignment: MainAxisAlignment.center,
//   //                   //   children: [
//   //                   //     Text(emp.name,
//   //                   //         style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
//   //                   //     const SizedBox(width: 8),
//   //                   //     // Edit icon next to the name
//   //                   //     const Icon(Icons.edit, size: 18, color: Colors.grey),
//   //                   //   ],
//   //                   // ),
//   //
//   //                   Row(
//   //                     mainAxisAlignment: MainAxisAlignment.center,
//   //                     children: [
//   //                       Flexible(
//   //                         child: Text(
//   //                           emp.name,
//   //                           maxLines: 1,
//   //                           overflow: TextOverflow.ellipsis,
//   //                           style: TextStyle(
//   //                             fontSize: (MediaQuery.of(context).size.width * 0.055)
//   //                                 .clamp(16.0, 24.0),
//   //                             fontWeight: FontWeight.bold,
//   //                           ),
//   //                         ),
//   //                       ),
//   //
//   //                       SizedBox(
//   //                         width: (MediaQuery.of(context).size.width * 0.02)
//   //                             .clamp(4.0, 10.0),
//   //                       ),
//   //
//   //                       Icon(
//   //                         Icons.edit,
//   //                         size: (MediaQuery.of(context).size.width * 0.045)
//   //                             .clamp(14.0, 20.0),
//   //                         color: Colors.grey,
//   //                       ),
//   //                     ],
//   //                   ),
//   //
//   //                   // Text(emp.jobTitle,
//   //                   //     style: const TextStyle(color: Colors.black54, fontSize: 16)),
//   //
//   //                   Text(
//   //                     emp.jobTitle,
//   //                     maxLines: 1,
//   //                     overflow: TextOverflow.ellipsis,
//   //                     style: TextStyle(
//   //                       color: Colors.black54,
//   //                       fontSize: (MediaQuery.of(context).size.width * 0.04)
//   //                           .clamp(13.0, 18.0), // responsive font size
//   //                     ),
//   //                   ),
//   //
//   //
//   //                   const SizedBox(height: 16),
//   //                   // Contact Info Section with Profile Completion
//   //                   Padding(
//   //                     padding: const EdgeInsets.symmetric(horizontal: 20.0),
//   //                     child: Row(
//   //                       mainAxisAlignment: MainAxisAlignment.spaceAround,
//   //                       children: [
//   //                         _contactInfoTile(Icons.phone, emp.workPhone.replaceAll(' ', ''),),
//   //                         _contactInfoTile(Icons.email, emp.workEmail, ),
//   //
//   //                       ],
//   //                     ),
//   //                   ),
//   //                   const SizedBox(height: 16),
//   //                 ],
//   //               ),
//   //             ),
//   //           ],
//   //         ),
//   //
//   //         // --- Personal Information Section (Main Content) ---
//   //         const Divider(height: 1, thickness: 1),
//   //         _buildPersonalTab(emp,),
//   //       ],
//   //     ),
//   //   );
//   // }
//
//   // inside your profile screen widget
//
//   Widget _buildProfile(BuildContext context, EmployeeProvider provider) {
//     final emp = provider.profile!.employee;
//     final auth = Provider.of<AuthProvider>(context, listen: false);
//     final sessionCookie = auth.sessionCookie ?? '';
//
//     final width = MediaQuery.of(context).size.width;
//
//     return SingleChildScrollView(
//       child: Column(
//         children: [
//           Stack(
//             alignment: Alignment.topCenter,
//             children: [
//               Padding(
//                 padding: const EdgeInsets.only(top: 20),
//                 child: Column(
//                   children: [
//                     Stack(
//                       alignment: Alignment.center,
//                       children: [
//                         Container(
//                           width: 110,
//                           height: 110,
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             border: Border.all(color: Colors.white, width: 3),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.1),
//                                 blurRadius: 10,
//                               ),
//                             ],
//                           ),
//                           child: ClipOval(
//                             child: emp.imageUrl.isNotEmpty
//                                 ? Image.network(
//                               'https://demo.kendroo.com${emp.imageUrl}',
//                               headers: sessionCookie.isNotEmpty
//                                   ? {'Cookie': sessionCookie}
//                                   : null,
//                               fit: BoxFit.cover,
//                               width: 110,
//                               height: 110,
//                               errorBuilder:
//                                   (context, error, stackTrace) {
//                                 debugPrint(
//                                     '🟥 Profile image error: $error');
//                                 return const Icon(
//                                   Icons.person,
//                                   size: 60,
//                                   color: Colors.grey,
//                                 );
//                               },
//                             )
//                                 : const Icon(
//                               Icons.person,
//                               size: 60,
//                               color: Colors.grey,
//                             ),
//                           ),
//                         ),
//                         Positioned(
//                           right: 0,
//                           bottom: 0,
//                           child: Container(
//                             padding: const EdgeInsets.all(4),
//                             decoration: const BoxDecoration(
//                               color: Colors.white,
//                               shape: BoxShape.circle,
//                             ),
//                             child: const Icon(
//                               Icons.camera_alt_outlined,
//                               size: 18,
//                               color: Colors.grey,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 16),
//
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Flexible(
//                           child: Text(
//                             emp.name,
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                             style: TextStyle(
//                               fontSize:
//                               (width * 0.055).clamp(16.0, 24.0),
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                         SizedBox(
//                           width: (width * 0.02).clamp(4.0, 10.0),
//                         ),
//                         Icon(
//                           Icons.edit,
//                           size: (width * 0.045).clamp(14.0, 20.0),
//                           color: Colors.grey,
//                         ),
//                       ],
//                     ),
//
//                     Text(
//                       emp.jobTitle,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: TextStyle(
//                         color: Colors.black54,
//                         fontSize:
//                         (width * 0.04).clamp(13.0, 18.0),
//                       ),
//                     ),
//
//                     const SizedBox(height: 16),
//
//                     Padding(
//                       padding:
//                       const EdgeInsets.symmetric(horizontal: 20.0),
//                       child: Row(
//                         mainAxisAlignment:
//                         MainAxisAlignment.spaceAround,
//                         children: [
//                           _contactInfoTile(
//                             Icons.phone,
//                             emp.workPhone.replaceAll(' ', ''),
//                           ),
//                           _contactInfoTile(
//                             Icons.email,
//                             emp.workEmail,
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//
//           const Divider(height: 1, thickness: 1),
//
//           _buildPersonalTab(emp),
//         ],
//       ),
//     );
//   }
//
//
//
//
//
//
//   Widget _contactInfoTile(IconData icon, String text) {
//
//     String displayString = text.contains('@')
//         ? text.substring(0, text.indexOf('@'))
//         : text;
//
//     if (displayString.length > 15) {
//       displayString = '${displayString.substring(0, 12)}...';
//     }
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, color: Colors.grey.shade600, size: 14),
//             const SizedBox(width: 2),
//             Text(displayString, style: const TextStyle(fontSize: 12, color: Colors.black87)),
//           ],
//         ),
//         Text(
//           text.contains('@') ? text.substring(text.indexOf('@')) : '',
//           style: const TextStyle(fontSize: 10, color: Colors.grey),
//         ),
//       ],
//     );
//   }
//
//
//
//
//
//   // Widget _buildPersonalTab(Employee emp,) {
//   //
//   //   return Padding(
//   //     padding: const EdgeInsets.all(16),
//   //     child: Column(
//   //       crossAxisAlignment: CrossAxisAlignment.start,
//   //       children: [
//   //         Row(
//   //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//   //           children: [
//   //             const Text('Personal Information',
//   //                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//   //
//   //           ],
//   //         ),
//   //         const Divider(),
//   //         _personalInfoRow('Name', emp.name),
//   //
//   //         _personalInfoRow('Manager', emp.manager),
//   //         _personalInfoRow('Department', emp.department),
//   //         _personalInfoRow('Company', emp.company),
//   //
//   //       ],
//   //     ),
//   //   );
//   // }
//
//   Widget _buildPersonalTab(Employee emp) {
//     final w = MediaQuery.of(context).size.width;
//
//
//     final titleSize = (w * 0.048).clamp(16.0, 20.0);
//
//
//     final horizontalPad = (w * 0.04).clamp(12.0, 22.0);
//
//     return Padding(
//       padding: EdgeInsets.all(horizontalPad),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Personal Information',
//             style: TextStyle(
//               fontSize: titleSize,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const Divider(),
//
//           _personalInfoRow('Name', emp.name),
//           _personalInfoRow('Manager', emp.manager),
//           _personalInfoRow('Department', emp.department),
//           _personalInfoRow('Company', emp.company),
//         ],
//       ),
//     );
//   }
//
//
//   // Helper widget for Personal Information rows
//   // Widget _personalInfoRow(String label, String value) {
//   //   return Padding(
//   //     padding: const EdgeInsets.symmetric(vertical: 6.0),
//   //     child: Row(
//   //       crossAxisAlignment: CrossAxisAlignment.start,
//   //       children: [
//   //         SizedBox(
//   //           width: 130, // Aligning the labels, increased width for safety
//   //           child: Text(
//   //             label,
//   //             style: const TextStyle(color: Colors.black54, fontSize: 15),
//   //           ),
//   //         ),
//   //         const Text('', style: TextStyle(color: Colors.grey, fontSize: 15)), // Removed colon for cleaner alignment
//   //         Expanded(
//   //           child: Text(
//   //             value,
//   //             style: const TextStyle(
//   //                 color: Colors.black, fontSize: 15, fontWeight: FontWeight.w600),
//   //           ),
//   //         ),
//   //       ],
//   //     ),
//   //   );
//   // }
//
//   Widget _personalInfoRow(String label, String value) {
//     final w = MediaQuery.of(context).size.width;
//
//     final labelWidth = (w * 0.32).clamp(90.0, 150.0);
//
//     final labelFont = (w * 0.036).clamp(12.0, 15.0);
//     final valueFont = (w * 0.038).clamp(13.0, 16.0);
//
//     final rowSpacing = (w * 0.018).clamp(4.0, 10.0);
//
//     return Padding(
//       padding: EdgeInsets.symmetric(vertical: rowSpacing),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//
//           SizedBox(
//             width: labelWidth,
//             child: Text(
//               label,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//               style: TextStyle(
//                 color: Colors.black54,
//                 fontSize: labelFont,
//               ),
//             ),
//           ),
//
//
//           Expanded(
//             child: Text(
//               value,
//               style: TextStyle(
//                 color: Colors.black,
//                 fontSize: valueFont,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//
// }

import 'package:flutter/foundation.dart';
import '../repo/odoo_json_rpc.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ImageHandler {
  static Widget buildAvatar(dynamic data, double radius) {
    if (data == null || data == false || data.toString().trim().isEmpty) {
      return _placeholder(radius);
    }

    final String raw = data.toString().trim();

    // Network image
    if (raw.startsWith('http')) {
      return Image.network(
        raw,
        fit: BoxFit.cover,
        width: radius * 2,
        height: radius * 2,
        errorBuilder: (_, __, ___) => _placeholder(radius),
      );
    }

    try {
      final String clean = _cleanBase64(raw);
      final Uint8List bytes = base64Decode(clean);

      // Check SVG
      final String text = utf8.decode(bytes, allowMalformed: true);
      if (text.contains('<svg')) {
        return SvgPicture.string(
          text,
          fit: BoxFit.cover,
          width: radius * 2,
          height: radius * 2,
        );
      }

      // PNG/JPG/WEBP/other bitmap
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: radius * 2,
        height: radius * 2,
        errorBuilder: (_, __, ___) => _placeholder(radius),
      );
    } catch (e) {
      debugPrint('ImageHandler error: $e');
      return _placeholder(radius);
    }
  }

  static String _cleanBase64(String value) {
    String s = value.trim();

    // remove prefix like rawImageData,xxxxx or data:image/png;base64,xxxxx
    if (s.contains(',')) {
      s = s.split(',').last;
    }

    // remove spaces/new lines
    s = s.replaceAll(RegExp(r'\s+'), '');
    return s;
  }

  static Widget _placeholder(double radius) {
    return Center(
      child: Icon(
        Icons.person,
        size: radius,
        color: Colors.blue.shade300,
      ),
    );
  }
}
class EmployeeProfileProvider extends ChangeNotifier {
  bool loading = false;
  String status = 'Ready';
  Map<String, dynamic> profile = {};

  OdooSessionRpc _rpc(String cookie) {
    return OdooSessionRpc(
      baseUrl: "http://72.61.250.60:8069",
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

  Future<void> fetchMyProfile({
    required String cookie,
    required int uid,
  }) async {
    loading = true;
    status = "Loading...";
 //   notifyListeners();

    try {
      final fields = <String>[
        'id', 'name', 'image_1920',

        // Work info (res.users)
        'mobile_phone', 'work_phone', 'work_email',
        'work_location_id', 'employee_parent_id',
        'department_id', 'address_id', 'company_id', 'job_title','user_id',

        // Private
        'private_street','private_street2','private_city','private_state_id',
        'private_zip','private_country_id','private_email','private_phone','lang',

        // Citizenship
        'country_id','identification_id','ssnid','passport_id','gender',
        'birthday','place_of_birth','country_of_birth',
      ];

      final rows = await _rpc(cookie).searchRead(
        model: 'res.users',
        domain: [['id', '=', uid]],
        fields: fields,
        limit: 1,
      );

      if (rows.isEmpty) {
        profile = {};
        status = "No profile found";
      } else {
        profile = Map<String, dynamic>.from(rows.first);
        status = "Loaded ✅";
      }
    } catch (e) {
      status = "Server error: $e";
    } finally {
      loading = false;
      notifyListeners();

    }
  }


}

class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {

  // @override
  // void initState() {
  //   super.initState();
  //
  //   final auth = Provider.of<AuthProvider>(context, listen: false);
  //   final cookie = auth.sessionCookie ?? '';
  //   final uid = auth.user?.uid;
  //
  //   if (cookie.isNotEmpty && uid != null) {
  //     Provider.of<EmployeeProfileProvider>(context, listen: false)
  //         .fetchMyProfile(cookie: cookie, uid: uid);
  //   }
  // }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final cookie = auth.sessionCookie ?? '';
      final uid = auth.user?.uid;

      if (cookie.isNotEmpty && uid != null) {
        context.read<EmployeeProfileProvider>()
            .fetchMyProfile(cookie: cookie, uid: uid);
      }
    });
  }

  // Uint8List? base64ToImage(dynamic base64String) {
  //   if (base64String == null || base64String == false) return null;
  //   try {
  //     return base64Decode(base64String);
  //   } catch (_) {
  //     return null;
  //   }
  // }

// Change the return type to dynamic so we can return the String for SVGs
// or Uint8List for PNG/JPG
  dynamic base64ToImage(dynamic base64String) {
    if (base64String == null || base64String is! String || base64String.isEmpty) {
      return null;
    }

    try {
      String cleanString = base64String.contains(',')
          ? base64String.split(',').last
          : base64String;
      cleanString = cleanString.replaceAll(RegExp(r'\s+'), '');

      // Decode the bytes
      Uint8List bytes = base64Decode(cleanString);
      String decodedString = utf8.decode(bytes, allowMalformed: true);

      // Check if it's an SVG
      if (decodedString.contains('<svg')) {
        return decodedString; // Return the SVG XML string
      }

      return bytes; // Return raw bytes for PNG/JPG
    } catch (e) {
      return null;
    }
  }

  // Uint8List? base64ToImage(dynamic base64String) {
  //   // 1. Check if the value is actually a string (Odoo often returns 'false' as a bool)
  //   if (base64String == null || base64String is! String || base64String.isEmpty) {
  //     return null;
  //   }
  //
  //   try {
  //     // 2. Remove the "data:image/png;base64," prefix if it exists
  //     String cleanString = base64String.contains(',')
  //         ? base64String.split(',').last
  //         : base64String;
  //
  //     // 3. Remove any whitespace or newlines that might be in the string
  //     cleanString = cleanString.replaceAll(RegExp(r'\s+'), '');
  //
  //     return base64Decode(cleanString);
  //   } catch (e) {
  //     print("Base64 Decoding Error: $e");
  //     return null;
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final w = MediaQuery.of(context).size.width;

    final isSmall = w < 360;
    final isTablet = w >= 600;

    final padding = isSmall ? 12.0 : 16.0;
    final avatarRadius = isSmall ? 28.0 : (isTablet ? 44.0 : 34.0);
    final nameFont = isSmall ? 16.5 : (isTablet ? 22.0 : 18.0);
    final jobFont = isSmall ? 12.5 : (isTablet ? 16.0 : 14.0);
    final sectionFont = isTablet ? 20.0 : 18.0;

    return Scaffold(
      appBar: AppBar(title: const Text("My Profile"), centerTitle: true,
    //   actions: [
    //       ElevatedButton(
    //       onPressed: () async {
    // await Provider.of<AuthProvider>(context, listen: false)
    //     .logout(context);
    // },
    //   child: const Image(
    //     image: AssetImage('assets/icon/logout.png'),
    //   ),
    // ),
    //     ],
      ),
      body: SafeArea(
        child: Consumer<EmployeeProfileProvider>(
          builder: (context, p, _) {
            if (p.loading) return const Center(child: CircularProgressIndicator());
            if (p.profile.isEmpty) return Center(child: Text(p.status));

            final prof = p.profile;
            final name = p.s(prof['name'], fallback: 'Unknown');
            final job = p.s(prof['job_title'], fallback: 'Job Position');

            final rawImageData = prof['avatar_128'] ?? prof['image_1920'];
print("rawImageData,$rawImageData");
            return ListView(
              padding: EdgeInsets.all(padding),
              children: [
                Container(
                  padding: EdgeInsets.all(padding),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                    CircleAvatar(
                    radius: avatarRadius,
                    backgroundColor: Colors.blue.shade50,
                    child: ClipOval(
                      child: SizedBox(
                        width: avatarRadius * 2,
                        height: avatarRadius * 2,
                        child: ImageHandler.buildAvatar(
                          prof['image_1920'] ?? prof['avatar_128'],
                          avatarRadius,
                        ),
                      ),
                    ),
                  ),
                      SizedBox(width: isSmall ? 10 : 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: nameFont,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              job,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: jobFont,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: isSmall ? 16 : 20),

                // Work Info
                Text("Work Info",
                    style: TextStyle(fontSize: sectionFont, fontWeight: FontWeight.bold)),
                const Divider(),

                _row(context, "Work Mobile", p.s(prof['mobile_phone'])),
                _row(context, "Work Phone", p.s(prof['work_phone'])),
                _row(context, "Work Email", p.s(prof['work_email'])),
                _row(context, "Work Location", p.m2oName(prof['work_location_id'])),
                _row(context, "Manager", p.m2oName(prof['employee_parent_id'])),
                _row(context, "Department", p.m2oName(prof['department_id'])),
                _row(context, "Work Address", p.m2oName(prof['address_id'])),

                SizedBox(height: isSmall ? 14 : 18),

                // Private Info
                Text("Private Info",
                    style: TextStyle(fontSize: sectionFont, fontWeight: FontWeight.bold)),
                const Divider(),

                _row(context, "Private Street", p.s(prof['private_street'])),
                _row(context, "Private City", p.s(prof['private_city'])),
                _row(context, "Country", p.m2oName(prof['private_country_id'])),
                _row(context, "Private Email", p.s(prof['private_email'])),
                _row(context, "Private Phone", p.s(prof['private_phone'])),

                SizedBox(height: isSmall ? 14 : 18),

                // Citizenship
                Text("Citizenship",
                    style: TextStyle(fontSize: sectionFont, fontWeight: FontWeight.bold)),
                const Divider(),

                _row(context, "Identification", p.s(prof['identification_id'])),
                _row(context, "Passport", p.s(prof['passport_id'])),
                _row(context, "Gender", p.s(prof['gender'])),
                _row(context, "Date of Birth", p.s(prof['birthday'])),

                const SizedBox(height: 10),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final w = MediaQuery.of(context).size.width;
    final isSmall = w < 360;


    final labelWidth = isSmall ? 115.0 : (w < 420 ? 140.0 : 170.0);

    final v = (value.trim().isNotEmpty && value != '-' && value != 'false') ? value : 'N/A';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.black54,
                fontSize: isSmall ? 13 : 14.5,
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
                fontWeight: FontWeight.w600,
                fontSize: isSmall ? 13 : 14.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}