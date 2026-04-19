# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Hive - Critical for database to work
-keep class hive.** { *; }
-keep class hive_flutter.** { *; }
-keepclassmembers class * {
    @hive.HiveField *;
}
-keepattributes *Annotation*

# Kotlin Coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembers class kotlinx.** {
    volatile <fields>;
}
-dontwarn kotlinx.coroutines.**

# Keep native methods
-keepclassmembers class * {
    native <methods>;
}

# Keep custom classes - Very important for your app
-keep class com.example.brainrot.** { *; }
-keepclassmembers class com.example.brainrot.** { *; }

# Keep attributes
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Keep Android components
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider
-keep public class * extends android.view.View
-keep public class * extends android.accessibilityservice.AccessibilityService
-keep public class * extends android.appwidget.AppWidgetProvider

# Keep MethodChannel related classes - Critical for platform channels
-keep class io.flutter.plugin.common.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep custom services
-keep class * extends android.app.Service { *; }
-keep class * extends android.content.BroadcastReceiver { *; }
-keep class * extends android.accessibilityservice.AccessibilityService { *; }

# Suppress warnings
-dontwarn java.lang.instrument.ClassFileTransformer
