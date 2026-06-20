# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Hive
-keep class com.fasn.app.** { *; }
-keepattributes *Annotation*

# Just Audio
-keep class com.ryanheise.** { *; }
-keep class androidx.media.** { *; }

# On Audio Query
-keep class com.lucasjosino.on_audio_query.** { *; }

# Notifications
-keep class com.dexterous.** { *; }

# TTS
-keep class com.tundralabs.** { *; }

# General
-dontwarn okhttp3.**
-dontwarn okio.**
-keepattributes Signature
-keepattributes InnerClasses
