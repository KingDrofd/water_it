# flutter_local_notifications stores scheduled notifications as Gson JSON.
# R8 full mode (default since AGP 8) strips the generic signatures Gson's
# TypeToken needs, causing "Missing type parameter" at runtime in release
# builds and breaking all scheduling. Keep the involved types intact.
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep public class * implements java.lang.reflect.Type
-keep class com.dexterous.flutterlocalnotifications.** { *; }
