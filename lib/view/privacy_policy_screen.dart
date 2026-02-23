import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Privacy Policy"),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Text(
          '''
Kendroo ERP – Field Force Mobile Application

Effective Date: 12/02/26
Company: Kendroo Ltd.

1. Introduction

Kendroo ERP Field Force App is developed for employee attendance, journey tracking, task monitoring, and organizational communication. This Privacy Policy explains how user data is collected, used, stored, and protected when using the application.

By using this App, you agree to the collection and use of information in accordance with this policy.

2. Information We Collect
2.1 Login & Authentication Data

To access the app, users must provide:

Database name

Email / Username

Password

These credentials are used only for authentication with the company ERP system and are not shared with unauthorized parties.

2.2 Employee Information

The app may collect and display:

Name

Email address

Phone number

Job title

Department

Company information

This data is used for organizational communication and employee management.

2.3 Attendance & Work Activity Data

The app records:

Check-in / Check-out time

Working hours

Activity logs

Task-related updates

This information is used for operational and performance tracking.

2.4 Location Data (GPS)

The app collects real-time location to:

Track field movement

Monitor journey routes

Verify attendance

Calculate distance travelled

Location data is collected only for official work purposes while using the app.

2.5 Journey & Map Data

The app may store:

Travel routes

Visit locations

Map-based activity logs

This helps improve monitoring and reporting of field operations.

2.6 Device & Technical Information

We may collect:

Device type

OS version

App version

IP address

Network information

This ensures app performance, debugging, and security.

3. How We Use Your Information

We use collected data to:

Authenticate users securely

Track attendance and field activity

Monitor employee performance

Manage organizational operations

Improve application performance

Prevent fraud or unauthorized access

Generate operational reports

4. Data Security

We implement strong security measures:

Secure ERP database integration

Role-based access control

Password protection

Server-level security

User passwords are not visible to other users or unauthorized personnel.

5. Data Sharing

We do NOT sell, trade, or rent personal information.

Data may only be shared:

With authorized company administrators

Within internal ERP systems

When required by law or regulatory authorities

6. Data Retention

User data is stored:

During employment period

As required for operational reporting

As per company data retention policy

Data may be removed after employee termination or inactivity.

7. User Responsibilities

Users must:

Keep login credentials confidential

Not share database access

Log out after use

Report suspicious activity immediately

8. Location & Tracking Consent

By using this app, users agree that:

GPS location may be collected during work hours

Journey tracking may be enabled for field monitoring

Attendance verification may use location data

9. Third-Party Services

The app may use:

Map services (Google Maps / OpenStreetMap)

ERP backend systems

These services follow their own privacy and security standards.

10. Policy Updates

This Privacy Policy may be updated periodically. Users will be notified via:

App updates

Internal company communication

Email notification

11. Contact Information

For questions regarding privacy:

Company: Kendroo Ltd.
Email: info@kendroo.io

Phone: [Insert Office Contact]

12. Consent

By logging into Kendroo ERP Field Force App, you consent to:

Data collection

Attendance tracking

Location monitoring

ERP integration
          ''',
          style: TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}