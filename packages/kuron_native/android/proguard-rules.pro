-keep class com.antonkarpenko.ffmpegkit.** { *; }
-keep class com.arthenica.ffmpegkit.** { *; }
-keepclasseswithmembernames class * {
    native <methods>;
}
-keepclassmembers class * {
    native <methods>;
}
-dontwarn com.antonkarpenko.ffmpegkit.**
-dontwarn com.arthenica.ffmpegkit.**

# ONNX Runtime — native lib resolves ai.onnxruntime.* classes via JNI at runtime.
# R8 strip/obfuscation → "java_class == null in GetMethodID" crash (release-only).
# consumerProguardFiles merge these into the app release build automatically.
-keep class ai.onnxruntime.** { *; }
-dontwarn ai.onnxruntime.**
