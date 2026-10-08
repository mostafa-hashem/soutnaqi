# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ONNX Runtime
-keep class ai.onnxruntime.** { *; }
-dontwarn ai.onnxruntime.**

# FFmpeg Kit
-keep class com.arthenica.ffmpegkit.** { *; }
-dontwarn com.arthenica.ffmpegkit.**

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# SoutNaqi app classes
-keep class com.soutnaqi.app.** { *; }

# Audio & Video plugins
-keep class com.ryanheise.just_audio.** { *; }
-dontwarn com.ryanheise.just_audio.**
-keep class io.flutter.plugins.videoplayer.** { *; }
-dontwarn io.flutter.plugins.videoplayer.**

# File & Image Pickers
-dontwarn com.mr.flutter.plugin.filepicker.**
-dontwarn io.flutter.plugins.imagepicker.**

# Common warnings
-dontwarn javax.annotation.**
-dontwarn org.checkerframework.**
-dontwarn com.google.errorprone.annotations.**
-dontwarn com.google.android.play.core.**
