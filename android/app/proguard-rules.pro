# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Bluetooth HID
-keep class android.bluetooth.** { *; }

# Keep R8 from stripping Kotlin metadata
-keepattributes *Annotation*
-dontwarn kotlin.**
-dontwarn kotlinx.**

# Play Core (deferred components) — not used but referenced by Flutter engine
-dontwarn com.google.android.play.core.**

# SharedPreferences
-keepclassmembers class * implements android.content.SharedPreferences$Editor {
    public ** apply();
    public ** commit();
}
