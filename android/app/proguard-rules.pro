# shared_preferences_android: R8 renames Kotlin stdlib/coroutines classes while
# the plugin's suspend-method callers still reference them by their original
# names, crashing at startup with NoSuchMethodError on
# SharedPreferencesAsyncApiRegistrar.getString and ClassNotFoundException on
# kotlin.coroutines.intrinsics.CoroutineSingletons.
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class kotlin.** { *; }
-keep class kotlinx.coroutines.** { *; }
