# Keep Mobile Scanner and ML Kit classes
-keep class dev.steenbakker.mobile_scanner.** { *; }
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class androidx.camera.** { *; }
-dontwarn dev.steenbakker.mobile_scanner.**
-dontwarn com.google.mlkit.**
-dontwarn androidx.camera.**
