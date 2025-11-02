# ProGuard rules for audio_service
# Prevent R8 from removing notification-related classes and resources

# Keep all notification-related classes
-keep class * extends androidx.core.app.NotificationCompat { *; }
-keep class androidx.core.app.NotificationCompat** { *; }
-keep class androidx.media.app.NotificationCompat** { *; }

# Keep media session classes
-keep class * extends android.media.session.MediaSession { *; }
-keep class android.support.v4.media.** { *; }
-keep class androidx.media.** { *; }

# Keep audio_service classes
-keep class com.ryanheise.audioservice.** { *; }

# Keep notification icon resources
-keepclassmembers class **.R$drawable {
    public static <fields>;
}

# Keep MediaBrowserService
-keep class * extends android.service.media.MediaBrowserService { *; }

# Keep all drawables
-keep class **.R
-keep class **.R$* {
    <fields>;
}
