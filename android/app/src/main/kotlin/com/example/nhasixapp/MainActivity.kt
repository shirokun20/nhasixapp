package com.example.nhasixapp

import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "app_disguise"

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d("AppDisguise", "MainActivity onCreate called")
        Log.d("AppDisguise", "Intent action: ${intent?.action}")
        Log.d("AppDisguise", "Component: ${intent?.component}")
    }
    
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.d("AppDisguise", "configureFlutterEngine called")

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

                                // Simple response without restart for now
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
            Log.e("AppDisguise", "Error setting up MethodChannel", e)
        }
    }
    
    private fun setAppDisguise(mode: String) {
        try {
            val packageManager = packageManager
            val packageName = packageName
            Log.d("AppDisguise", "setAppDisguise called with mode: $mode")

            // Disable all aliases first
            val aliases = listOf("CalculatorActivity", "NotesActivity", "WeatherActivity")
            aliases.forEach { alias ->
                try {
                    val componentName = ComponentName(packageName, "com.example.nhasixapp.$alias")
                    val result = packageManager.setComponentEnabledSetting(
                        componentName,
                        PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                        PackageManager.DONT_KILL_APP
                    )
                    Log.d("AppDisguise", "Disabled alias: $alias, result: $result")
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
                    // Default mode - enable main activity, disable all aliases
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
            val mainComponent = ComponentName(packageName, "com.example.nhasixapp.MainActivity")
            val result = packageManager.setComponentEnabledSetting(
                mainComponent,
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                PackageManager.DONT_KILL_APP
            )
            Log.d("AppDisguise", "Disabled main activity, result: $result")
        } catch (e: Exception) {
            Log.e("AppDisguise", "Error disabling main activity", e)
        }
    }

    private fun enableMainActivity() {
        try {
            val mainComponent = ComponentName(packageName, "com.example.nhasixapp.MainActivity")
            val result = packageManager.setComponentEnabledSetting(
                mainComponent,
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                PackageManager.DONT_KILL_APP
            )
            Log.d("AppDisguise", "Enabled main activity, result: $result")
        } catch (e: Exception) {
            Log.e("AppDisguise", "Error enabling main activity", e)
        }
    }

    private fun refreshLauncher() {
        try {
            Log.d("AppDisguise", "Refreshing launcher")
            val intent = Intent(Intent.ACTION_MAIN)
            intent.addCategory(Intent.CATEGORY_HOME)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(intent)
        } catch (e: Exception) {
            Log.e("AppDisguise", "Error refreshing launcher", e)
        }
    }
    
    private fun enableAlias(aliasName: String) {
        try {
            val componentName = ComponentName(packageName, "com.example.nhasixapp.$aliasName")
            val result = packageManager.setComponentEnabledSetting(
                componentName,
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                PackageManager.DONT_KILL_APP
            )
            Log.d("AppDisguise", "Enabled alias: $aliasName, result: $result")
        } catch (e: Exception) {
            Log.e("AppDisguise", "Error enabling alias $aliasName", e)
        }
    }
    
    private fun getCurrentDisguise(): String {
        val packageManager = packageManager
        val packageName = packageName
        Log.d("AppDisguise", "getCurrentDisguise called")

        // Check aliases first
        val aliases = listOf("CalculatorActivity", "NotesActivity", "WeatherActivity")
        for (alias in aliases) {
            try {
                val componentName = ComponentName(packageName, "com.example.nhasixapp.$alias")
                val state = packageManager.getComponentEnabledSetting(componentName)
                Log.d("AppDisguise", "Alias $alias state: $state")
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

        // Check main activity
        try {
            val mainComponent = ComponentName(packageName, "com.example.nhasixapp.MainActivity")
            val mainState = packageManager.getComponentEnabledSetting(mainComponent)
            Log.d("AppDisguise", "Main activity state: $mainState")
            if (mainState == PackageManager.COMPONENT_ENABLED_STATE_ENABLED) {
                Log.d("AppDisguise", "Current disguise mode: default")
                return "default"
            }
        } catch (e: Exception) {
            Log.e("AppDisguise", "Error checking main activity", e)
        }

        // If nothing is enabled, default to default
        Log.d("AppDisguise", "No activity enabled, defaulting to default")
        return "default"
    }
}
