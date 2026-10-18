# R8/ProGuard keeps for Pigeon suspend APIs (Kotlin coroutines).
# shared_preferences_android 2.5.x exposes suspend funs through
# SharedPreferencesApiRegistrar; without explicit keeps, R8 full-mode renames
# kotlin.coroutines.Continuation (e.g. to i7.c), breaking linkage at runtime.
-keep class kotlin.** { *; }
-keep class kotlinx.coroutines.** { *; }
-keep class io.flutter.plugins.sharedpreferences.** { *; }
