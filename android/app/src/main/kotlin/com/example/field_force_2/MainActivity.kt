//package com.example.field_force_2
//
//import io.flutter.embedding.android.FlutterActivity
//
//class MainActivity : FlutterActivity()
//
package com.example.field_force_2

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // This ensures all plugins (including background_location_tracker)
        // are registered correctly with the engine
        GeneratedPluginRegistrant.registerWith(flutterEngine)
    }
}