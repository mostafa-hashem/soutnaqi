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
-keep class com.microsoft.onnxruntime.** { *; }
-dontwarn com.microsoft.onnxruntime.**
-keep class com.gtbluesky.onnxruntime.** { *; }
-dontwarn com.gtbluesky.onnxruntime.**

# FFmpeg Kit
-keep class com.arthenica.ffmpegkit.** { *; }
-dontwarn com.arthenica.ffmpegkit.**

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# SoutNaqi app classes
-keep class com.soutnaqi.app.** { *; }

# Audio & Video plugins (Media3 AARs bundle their own consumer reflection keep rules)
-keep class com.ryanheise.just_audio.** { *; }
-dontwarn com.ryanheise.just_audio.**
-dontwarn com.google.android.exoplayer2.**
-dontwarn androidx.media3.**
-keep class io.flutter.plugins.videoplayer.** { *; }
-dontwarn io.flutter.plugins.videoplayer.**

# File & Image Pickers (Lifecycle AARs bundle their own consumer rules)
-keep class com.mr.flutter.plugin.filepicker.** { *; }
-dontwarn com.mr.flutter.plugin.filepicker.**
-keep class com.miguelruivo.flutter.plugin.filepicker.** { *; }
-dontwarn com.miguelruivo.flutter.plugin.filepicker.**
-keep class io.flutter.plugins.imagepicker.** { *; }
-dontwarn io.flutter.plugins.imagepicker.**
-keep class androidx.lifecycle.DefaultLifecycleObserver
-keep class * implements androidx.lifecycle.LifecycleObserver { *; }
-keep class * implements androidx.lifecycle.DefaultLifecycleObserver { *; }
-dontwarn androidx.lifecycle.**

# Storage & Preferences plugins (keep DataStore protobuf messages & Coroutines volatile fields while allowing R8 to obfuscate internal classes)
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-dontwarn io.flutter.plugins.sharedpreferences.**
-keep class androidx.datastore.preferences.PreferencesProto** { *; }
-keepclassmembers class * extends androidx.datastore.preferences.protobuf.GeneratedMessageLite {
    <fields>;
    <methods>;
}
-dontwarn androidx.datastore.**
-dontwarn androidx.preference.**
-keepclassmembers class kotlinx.coroutines.** {
    volatile <fields>;
}
-keep class kotlinx.coroutines.android.AndroidDispatcherFactory { *; }
-keep class kotlinx.coroutines.android.AndroidExceptionPreHandler { *; }
-dontwarn kotlinx.coroutines.**
-keep class io.flutter.plugins.pathprovider.** { *; }
-dontwarn io.flutter.plugins.pathprovider.**

# Share plugin
-keep class dev.fluttercommunity.plus.share.** { *; }
-dontwarn dev.fluttercommunity.plus.share.**

# Common warnings
-dontwarn javax.annotation.**
-dontwarn org.checkerframework.**
-dontwarn com.google.errorprone.annotations.**
-dontwarn com.google.android.play.core.**

# Preserve debugging attributes for crash reports and Google Play Console deobfuscation
-keepattributes SourceFile,LineNumberTable
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses,EnclosingMethod

# Additional Flutter community plugins
-keep class dev.fluttercommunity.plus.** { *; }
-dontwarn dev.fluttercommunity.plus.**
-keep class io.flutter.plugins.urllauncher.** { *; }
-dontwarn io.flutter.plugins.urllauncher.**

