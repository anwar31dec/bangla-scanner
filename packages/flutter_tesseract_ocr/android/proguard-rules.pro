# Bangla Scanner patch: the native Tesseract/Leptonica code looks up these
# Java classes and fields by name over JNI, so R8 must not rename or remove
# them in release builds.
-keep class com.googlecode.tesseract.android.** { *; }
-keep class com.googlecode.leptonica.android.** { *; }
