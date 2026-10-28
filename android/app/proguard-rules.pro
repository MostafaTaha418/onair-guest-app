# Flutter plugins are registered by generated code and referenced from native entry points.
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep model metadata used by Firebase Messaging and Google Play services.
-keepattributes Signature
-keepattributes *Annotation*

# Flutter's engine exposes optional Play Feature Delivery hooks even when this
# app has no deferred components. R8 may safely discard those unreachable APIs.
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
