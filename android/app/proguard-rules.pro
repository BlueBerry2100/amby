# R8 (AGP 9) turns some Kotlin suspend methods of shared_preferences_android
# into static ones while Pigeon callers still invoke them virtually, which
# crashes at startup with NoSuchMethodError on SharedPreferencesAsyncApiRegistrar.
-keep class io.flutter.plugins.sharedpreferences.** { *; }
