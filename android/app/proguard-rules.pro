# === Chef Planet ProGuard Rules ===

# Flutter defaults
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Razorpay SDK — must not be obfuscated
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keepattributes JavascriptInterface
-keepattributes *Annotation*
-dontwarn com.razorpay.**
-keep class com.razorpay.** { *; }
-optimizations !method/inlining/*

# Google Fonts — network font fetching
-dontwarn com.google.android.gms.**

# Flutter embedding sometimes references Play Core classes when
# deferred components or splitcompat are enabled. The library is now
# added as a dependency, but keep rules ensure R8 doesn't complain if
# any symbols are ever missing.
-dontwarn com.google.android.play.core.**
