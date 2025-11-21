# Keep app update manager classes
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.install.** { *; }
-keep interface com.google.android.play.core.** { *; }

# WorkManager
-keep class * extends androidx.work.Worker
-keep class * extends androidx.work.InputMerger
-keep class androidx.work.impl.WorkManagerImpl
