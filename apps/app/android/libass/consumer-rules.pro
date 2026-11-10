# JNI exports bind by name (Java_app_heisuca_libass_*); keep the names stable.
-keepclasseswithmembernames class app.heisuca.libass.* {
    native <methods>;
}
