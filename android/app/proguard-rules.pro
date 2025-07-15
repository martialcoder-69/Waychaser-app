######################################
# BACKGROUND LOCATOR (your fork)
######################################
-keep class yukams.app.background_locator_2.** { *; }

######################################
# FLUTTER BACKGROUND SERVICE
######################################
-keep class id.flutter.flutter_background_service.** { *; }

######################################
# DEVICE INFO PLUS, NETWORK INFO PLUS, BATTERY PLUS, etc.
######################################
-keep class io.flutter.plugins.** { *; }
-keep class dev.flutter.plugins.** { *; }
-keep class com.baseflow.** { *; }  # for geolocator, battery_plus, etc.
-keep class com.lyokone.** { *; }   # if using flutter location plugins
-keep class com.example.** { *; }   # your own app package

######################################
# PLATFORM CHANNELS & METHOD CALLS
######################################
-keep class io.flutter.plugin.common.MethodChannel { *; }
-keep class io.flutter.plugin.common.EventChannel { *; }

######################################
# ANNOTATED ENTRY POINTS FROM DART
######################################
-keepclassmembers class * {
    @dart.vm.entry-point <methods>;
}

######################################
# GENERAL KEEP RULES TO AVOID STRIPPING
######################################
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**
-keep class io.flutter.embedding.** { *; }

# Prevent R8 from removing your entry points accidentally
-keep class *.MainActivity { *; }

######################################
# OPTIONAL: Prevent issues with gson/json decoding
######################################
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

######################################
# OPTIONAL: If using WorkManager or Firebase
######################################
# Uncomment if needed:
# -keep class androidx.work.** { *; }
# -keep class com.google.firebase.** { *; }
