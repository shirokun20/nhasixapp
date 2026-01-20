package id.nhasix.app

import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import id.nhasix.app.download.DownloadMethodChannel
import id.nhasix.app.pdf.PdfMethodChannel
import id.nhasix.app.backup.BackupMethodChannel
import id.nhasix.app.pdf.PdfReaderMethodChannel
import id.nhasix.app.network.DnsMethodChannel  // NEW

class MainActivity: FlutterActivity() {
    private val CHANNEL = "app_disguise"
    private lateinit var downloadChannel: DownloadMethodChannel
    private lateinit var pdfChannel: PdfMethodChannel
    private lateinit var backupChannel: BackupMethodChannel
    private lateinit var pdfReaderChannel: PdfReaderMethodChannel

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // FIX: Plant Timber for logging
        Log.d("AppDisguise", "MainActivity onCreate called")
        Log.d("AppDisguise", "Intent action: ${intent?.action}")
        Log.d("AppDisguise", "Component: ${intent?.component}")
    }
    
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.d("AppDisguise", "configureFlutterEngine called")

        // 1. Setup Download Channel
        try {
            downloadChannel = DownloadMethodChannel(
                context = applicationContext,
                messenger = flutterEngine.dartExecutor.binaryMessenger
            )
            Log.d("DownloadService", "DownloadMethodChannel setup completed")
        } catch (e: Exception) {
            Log.e("DownloadService", "Error setting up DownloadMethodChannel", e)
        }

        // 2. Setup PDF Channel
        try {
            pdfChannel = PdfMethodChannel(
                context = applicationContext,
                messenger = flutterEngine.dartExecutor.binaryMessenger
            )
            Log.d("PdfService", "PdfMethodChannel setup completed")
        } catch (e: Exception) {
            Log.e("PdfService", "Error setting up PdfMethodChannel", e)
        }

        // 3. Setup Backup Channel
        try {
            backupChannel = BackupMethodChannel(
                activity = this,
                messenger = flutterEngine.dartExecutor.binaryMessenger
            )
            Log.d("BackupService", "BackupMethodChannel setup completed")
        } catch (e: Exception) {
            Log.e("BackupService", "Error setting up BackupMethodChannel", e)
        }

        // 4. Setup PDF Reader Channel
        try {
            pdfReaderChannel = PdfReaderMethodChannel(
                activity = this,
                messenger = flutterEngine.dartExecutor.binaryMessenger
            )
            Log.d("PdfReaderService", "PdfReaderMethodChannel setup completed")
        } catch (e: Exception) {
            Log.e("PdfReaderService", "Error setting up PdfReaderMethodChannel", e)
        }

        // 5. Setup DNS Channel (NEW)
        try {
            DnsMethodChannel(flutterEngine.dartExecutor.binaryMessenger)
            Log.d("DnsService", "DnsMethodChannel setup completed")
        } catch (e: Exception) {
            Log.e("DnsService", "Error setting up DnsMethodChannel", e)
        }

        // 6. Setup App Disguise Channel
        try {
            val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            Log.d("AppDisguise", "MethodChannel created successfully")

            methodChannel.setMethodCallHandler { call, result ->
                Log.d("AppDisguise", "Received method call: ${call.method}")
                try {
                    when (call.method) {
                        "setDisguiseMode" -> {
                            val mode = call.argument<String>("mode")
                            Log.d("AppDisguise", "Setting disguise mode to: $mode")

                            if (mode != null) {
                                setAppDisguise(mode)
                                result.success("Mode set to: $mode")
                                Log.d("AppDisguise", "setDisguiseMode completed for mode: $mode")
                            } else {
                                result.error("INVALID_MODE", "Mode cannot be null", null)
                            }
                        }
                        "getCurrentDisguiseMode" -> {
                            Log.d("AppDisguise", "getCurrentDisguiseMode called")
                            val currentMode = getCurrentDisguise()
                            Log.d("AppDisguise", "Returning current disguise mode: $currentMode")
                            result.success(currentMode)
                        }
                        else -> {
                            Log.w("AppDisguise", "Unknown method: ${call.method}")
                            result.notImplemented()
                        }
                    }
                } catch (e: Exception) {
                    Log.e("AppDisguise", "Error processing method call", e)
                    result.error("METHOD_ERROR", e.message, null)
                }
            }
            Log.d("AppDisguise", "MethodChannel handler setup completed successfully")
        } catch (e: Exception) {
            Log.e("AppDisguise", "Error setting up MethodChannel (AppDisguise)", e)
        }
    }
    
    override fun onDestroy() {
        if (::downloadChannel.isInitialized) {
            downloadChannel.dispose()
        }
        if (::pdfChannel.isInitialized) {
            pdfChannel.dispose()
        }
        if (::backupChannel.isInitialized) {
            backupChannel.dispose()
        }
        super.onDestroy()
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (::backupChannel.isInitialized) {
            backupChannel.onActivityResult(requestCode, resultCode, data)
        }
    }

    private fun setAppDisguise(mode: String) {
        try {
            Log.d("AppDisguise", "setAppDisguise called with mode: $mode")

            // Disable all aliases first
            val aliases = listOf("CalculatorActivity", "NotesActivity", "WeatherActivity")
            aliases.forEach { alias ->
                try {
                    val componentName = ComponentName(packageName, "id.nhasix.app.$alias")
                    packageManager.setComponentEnabledSetting(
                        componentName,
                        PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                        PackageManager.DONT_KILL_APP
                    )
                    Log.d("AppDisguise", "Disabled alias: $alias")
                } catch (e: Exception) {
                    Log.e("AppDisguise", "Error disabling alias $alias", e)
                }
            }

            // Handle main activity and selected alias
            when (mode) {
                "calculator" -> {
                    disableMainActivity()
                    enableAlias("CalculatorActivity")
                }
                "notes" -> {
                    disableMainActivity()
                    enableAlias("NotesActivity")
                }
                "weather" -> {
                    disableMainActivity()
                    enableAlias("WeatherActivity")
                }
                else -> {
                    // Default mode - enable main activity
                    enableMainActivity()
                    Log.d("AppDisguise", "Default mode - main activity enabled")
                }
            }
        } catch (e: Exception) {
            Log.e("AppDisguise", "Error in setAppDisguise", e)
        }
    }

    private fun disableMainActivity() {
        try {
            val mainComponent = ComponentName(packageName, "id.nhasix.app.MainActivity")
            packageManager.setComponentEnabledSetting(
                mainComponent,
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                PackageManager.DONT_KILL_APP
            )
            Log.d("AppDisguise", "Disabled main activity")
        } catch (e: Exception) {
            Log.e("AppDisguise", "Error disabling main activity", e)
        }
    }

    private fun enableMainActivity() {
        try {
            val mainComponent = ComponentName(packageName, "id.nhasix.app.MainActivity")
            packageManager.setComponentEnabledSetting(
                mainComponent,
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                PackageManager.DONT_KILL_APP
            )
            Log.d("AppDisguise", "Enabled main activity")
        } catch (e: Exception) {
            Log.e("AppDisguise", "Error enabling main activity", e)
        }
    }
    
    private fun enableAlias(aliasName: String) {
        try {
            val componentName = ComponentName(packageName, "id.nhasix.app.$aliasName")
            packageManager.setComponentEnabledSetting(
                componentName,
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                PackageManager.DONT_KILL_APP
            )
            Log.d("AppDisguise", "Enabled alias: $aliasName")
        } catch (e: Exception) {
            Log.e("AppDisguise", "Error enabling alias $aliasName", e)
        }
    }
    
    private fun getCurrentDisguise(): String {
        Log.d("AppDisguise", "getCurrentDisguise called")

        // Check aliases first
        val aliases = listOf("CalculatorActivity", "NotesActivity", "WeatherActivity")
        for (alias in aliases) {
            try {
                val componentName = ComponentName(packageName, "id.nhasix.app.$alias")
                val state = packageManager.getComponentEnabledSetting(componentName)
                if (state == PackageManager.COMPONENT_ENABLED_STATE_ENABLED) {
                    val mode = when (alias) {
                        "CalculatorActivity" -> "calculator"
                        "NotesActivity" -> "notes"
                        "WeatherActivity" -> "weather"
                        else -> "default"
                    }
                    Log.d("AppDisguise", "Current disguise mode: $mode")
                    return mode
                }
            } catch (e: Exception) {
                Log.e("AppDisguise", "Error checking alias $alias", e)
            }
        }

        // Default
        return "default"
    }
}
