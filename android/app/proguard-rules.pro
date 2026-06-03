# Google ML Kit Text Recognition için eksik sınıfları görmezden gel
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Genel ML Kit koruma kuralları
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**