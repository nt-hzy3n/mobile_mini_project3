# Google ML Kit Text Recognition ProGuard Rules
-dontwarn com.google.mlkit.vision.text.**
-dontwarn com.google.mlkit.vision.barcode.**
-dontwarn com.google.mlkit.common.**

-keep class com.google.mlkit.** { *; }
-keep class com.google_mlkit_text_recognition.** { *; }
-keep class com.google_mlkit_barcode_scanning.** { *; }
-keep class dev.steenbakker.mobile_scanner.** { *; }
