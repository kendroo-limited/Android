import 'package:flutter/material.dart';

/// This key allows us to access the Navigator and show dialogs
/// from inside Providers or Services without needing 'context'.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();