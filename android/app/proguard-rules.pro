# Flutter & Android R8 Security Hardening Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep MainActivity & MethodChannel bridge
-keep class com.orthodox.app.orthodox_app.MainActivity { *; }

# Keep Firebase, Firestore, Google Sign-In & Play Services
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keepattributes Signature,InnerClasses,EnclosingMethod,*Annotation*

# Keep Flutter Local Notifications (Gson/scheduled alarms)
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }

# Keep Biometrics & Secure Storage (Tink / Keystore)
-keep class androidx.biometric.** { *; }
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class com.google.crypto.tink.** { *; }

# Keep WebView / YouTube player JS bridges
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Optional Flutter Play Store deferred components (not used)
-dontwarn com.google.android.play.core.**

# Strip verbose debug logs in Release builds
-assumenosideeffects class android.util.Log {
    public static int d(...);
    public static int v(...);
    public static int i(...);
}
