# Crashlytics: readable stack traces with R8 on
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# ML Kit text recognition: the plugin references every script's recogniser, but
# only the Latin model is bundled (Bangla goes through Tesseract).
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
