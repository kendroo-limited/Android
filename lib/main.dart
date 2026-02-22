import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:field_force_2/provider/chat_provider.dart';
import 'package:field_force_2/provider/journey_provider.dart';
import 'package:field_force_2/provider/leave_provider.dart';
import 'package:field_force_2/provider/project_provider.dart';

import 'package:field_force_2/repo/chat_repository.dart';
import 'package:field_force_2/repo/journey_repository.dart';
import 'package:field_force_2/repo/leave_repository.dart';
import 'package:field_force_2/repo/memory_chat_repository.dart';
import 'package:field_force_2/repo/project_repository.dart';
import 'package:field_force_2/repo/task_repository.dart';
import 'package:field_force_2/view/create_new_task.dart';
import 'package:field_force_2/view/dashboard.dart';
import 'package:field_force_2/view/employee/all_employee_page.dart';
import 'package:field_force_2/view/employee_profile_page.dart';
import 'package:field_force_2/view/journey_screen.dart';
import 'package:field_force_2/view/login.dart';
import 'package:flutter/material.dart';
import 'package:field_force_2/provider/all_employee_provider.dart';
import 'package:field_force_2/provider/attendance_provider.dart';
import 'package:field_force_2/provider/auth_provider.dart';
import 'package:field_force_2/provider/customer_provider.dart';
import 'package:field_force_2/provider/employee_provider.dart';
import 'package:field_force_2/provider/product_provider.dart';
import 'package:field_force_2/repo/all_employee_repository.dart';
import 'package:field_force_2/repo/attendance_repository.dart';
import 'package:field_force_2/repo/customer_repository.dart';
import 'package:field_force_2/repo/product_repository.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:location/location.dart' as loc;
import 'package:provider/provider.dart';


Future<void> main() async {
  String url = "https://demo.kendroo.com";
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'location_channel',
      channelName: 'Location Tracking',
      channelDescription: 'Tracking location in background',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
      iconData: const NotificationIconData(
        resType: ResourceType.mipmap,
        resPrefix: ResourcePrefix.ic,
        name: 'launcher',
      ),
    ),

    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: true,
      playSound: false,
    ),

    foregroundTaskOptions: const ForegroundTaskOptions(
      interval: 900000, // 15 minutes
      autoRunOnBoot: false,
      allowWakeLock: true,
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


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const OdooLoginPage(),
    );
  }
}


