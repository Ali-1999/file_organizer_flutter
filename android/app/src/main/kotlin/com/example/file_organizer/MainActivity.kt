package com.example.file_organizer

import android.os.Environment
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "file_organizer/storage"
        ).setMethodCallHandler { call, result ->
            if (call.method == "root") {
                @Suppress("DEPRECATION")
                result.success(Environment.getExternalStorageDirectory().canonicalPath)
            } else {
                result.notImplemented()
            }
        }
    }
}
