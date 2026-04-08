import 'dart:async';
import 'package:background_location_tracker/background_location_tracker.dart';
import 'package:field_force_2/provider/chat_provider.dart';
import 'package:field_force_2/provider/employee_provider.dart';
import 'package:field_force_2/provider/journey_provider.dart';
import 'package:field_force_2/provider/leave_provider.dart';
import 'package:field_force_2/provider/project_provider.dart';
import 'package:field_force_2/repo/journey_repository.dart';
import 'package:field_force_2/repo/leave_repository.dart';
import 'package:field_force_2/repo/memory_chat_repository.dart';
import 'package:field_force_2/repo/odoo_json_rpc.dart';
import 'package:field_force_2/repo/project_repository.dart';
import 'package:field_force_2/services/background_journey_service.dart';
import 'package:field_force_2/view/create_new_task.dart';
import 'package:field_force_2/view/employee/all_employee_page.dart';
import 'package:field_force_2/view/employee_profile_page.dart';
import 'package:field_force_2/view/journey_screen.dart';
import 'package:field_force_2/view/login.dart';
import 'package:flutter/material.dart';
import 'package:field_force_2/provider/all_employee_provider.dart';
import 'package:field_force_2/provider/attendance_provider.dart';
import 'package:field_force_2/provider/auth_provider.dart';
import 'package:field_force_2/provider/customer_provider.dart';
import 'package:field_force_2/provider/product_provider.dart';
import 'package:field_force_2/repo/all_employee_repository.dart';
import 'package:field_force_2/repo/attendance_repository.dart';
import 'package:field_force_2/repo/customer_repository.dart';
import 'package:field_force_2/repo/product_repository.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:flutter/widgets.dart';
import 'dart:ui';
import 'package:latlong2/latlong.dart' as ll;
import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart';
import 'globals.dart';


OdooSessionRpc _bgRpc(String cookie, String baseUrl) {
  return OdooSessionRpc(
    baseUrl: baseUrl,
    sessionCookie: cookie,
  );
}

@pragma('vm:entry-point')
void backgroundCallback() {
  BackgroundLocationTrackerManager.handleBackgroundUpdated(
        (data) async => BackgroundJourneyService.handleBackgroundUpdate(data),
  );
}

Future<void> main() async {
  String url = "http://72.61.250.60:8069";
 // String url = "http://192.168.50.92:8017";
  WidgetsFlutterBinding.ensureInitialized();
  await BackgroundLocationTrackerManager.initialize(
    backgroundCallback,
    config: const BackgroundLocationTrackerConfig(
      loggingEnabled: true,
      androidConfig: AndroidConfig(
        notificationIcon: 'ic_launcher',
        trackingInterval: Duration(seconds: 30),
        distanceFilterMeters: null,


      ),
      iOSConfig: IOSConfig(
        distanceFilterMeters: null,
        restartAfterKill: true,
      ),
    ),
  );


  final journey = JourneyProviderView();
  await journey.restoreFromCache();

  runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AuthProvider(),

          ),

          ChangeNotifierProxyProvider<AuthProvider, EmployeeProvider>(
            create: (_) => EmployeeProvider(null),
            update: (_, auth, __) => EmployeeProvider(auth),
          ),
          ChangeNotifierProxyProvider<AuthProvider, JourneyProvider>(
            create: (context) => JourneyProvider(
              repository: FieldForceRepository(baseUrl:url, sessionCookie: ''),
              authToken: "", // Initial empty token
            ),
            update: (context, auth, previous) => JourneyProvider(
              repository: FieldForceRepository(
                baseUrl: url,
                sessionCookie: auth.sessionCookie ?? '',
              ),
              authToken: auth.sessionCookie ?? "",
            ),
          ),
          ChangeNotifierProxyProvider<AuthProvider, AllEmployeeProvider>(
            create: (_) => AllEmployeeProvider(
              AllEmployeeRepository(baseUrl: url, sessionCookie: ''),
            ),
            update: (_, auth, provider) =>
                AllEmployeeProvider(AllEmployeeRepository(
                  baseUrl: url,
                  sessionCookie: auth.sessionCookie ?? '',
                )),
          ),
          ChangeNotifierProxyProvider<AuthProvider, AttendanceProvider>(
            create: (_) => AttendanceProvider(
              AttendanceRepository(baseUrl: url, sessionCookie: ''),
            ),
            update: (_, auth, provider) =>
                AttendanceProvider(AttendanceRepository(
                  baseUrl:url,
                  sessionCookie: auth.sessionCookie ?? '',
                )),
          ),
          ChangeNotifierProxyProvider<AuthProvider, ChatProvider>(
            create: (_) => ChatProvider(
              MemoryChatRepository(baseUrl:url, sessionCookie: ''),
            ),
            update: (_, auth, provider) =>
                ChatProvider(MemoryChatRepository(
                  baseUrl:url,
                  sessionCookie: auth.sessionCookie ?? '',
                )),
          ),
          ChangeNotifierProxyProvider<AuthProvider, ProductProvider>(
            create: (_) => ProductProvider(
              ProductRepository(baseUrl:url, sessionCookie: ''),
            ),
            update: (_, auth, provider) =>
                ProductProvider(ProductRepository(
                  baseUrl:url,
                  sessionCookie: auth.sessionCookie ?? '',
                )),
          ),
          ChangeNotifierProxyProvider<AuthProvider, CustomerProvider>(
            create: (_) => CustomerProvider(
              CustomerRepository(baseUrl:url, sessionCookie: ''),
            ),
            update: (_, auth, provider) =>
                CustomerProvider(CustomerRepository(
                  baseUrl:url,
                  sessionCookie: auth.sessionCookie ?? '',
                )),
          ),
          ChangeNotifierProxyProvider<AuthProvider, LeaveProvider>(
            create: (_) => LeaveProvider(
              LeaveRepository(baseUrl:url, sessionCookie: ''),
            ),
            update: (_, auth, provider) =>
                LeaveProvider(LeaveRepository(
                  baseUrl:url,
                  sessionCookie: auth.sessionCookie ?? '',
                )),
          ),

          // ChangeNotifierProxyProvider<AuthProvider, TaskProvider>(
          //   create: (_) => TaskProvider(
          //     repository: TaskRepository(baseUrl: "", sessionCookie: ""),
          //   ),
          //   update: (_, auth, previous) => TaskProvider(
          //     repository: TaskRepository(
          //       baseUrl:url,
          //       sessionCookie: auth.sessionCookie ?? "",
          //     ),
          //   ),
          // ),

          ChangeNotifierProxyProvider<AuthProvider, ProjectProvider>(
            create: (_) => ProjectProvider(
              repository: ProjectRepository(baseUrl: "", sessionCookie: ""),
            ),
            update: (_, auth, previous) => ProjectProvider(
              repository: ProjectRepository(
                baseUrl:url,
                sessionCookie: auth.sessionCookie ?? "",
              ),
            ),
          ),
  ChangeNotifierProvider(create: (_) => JourneyProviderView()),
          ChangeNotifierProvider(create: (_) => EmployeeProviderView()),
          ChangeNotifierProvider(create: (_) => EmployeeProfileProvider()),
          ChangeNotifierProvider(create: (_) => journey),

          ChangeNotifierProvider(create: (_) => TaskProvider()),
        ],
        child: const MyApp(), )
     );

}

@pragma('vm:entry-point')

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      navigatorKey: navigatorKey,

      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const OdooLoginPage(),
    );
  }
}


