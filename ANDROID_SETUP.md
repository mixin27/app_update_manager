# Android Setup Guide

This guide walks you through setting up app_update_manager for Android.

## Prerequisites

- Android SDK 21 or higher (minSdkVersion 21)
- Kotlin 1.7.0 or higher
- Your app must be published on Google Play Store (can be internal testing track)

## Step 1: Update build.gradle

### app/build.gradle

```gradle
android {
    compileSdkVersion 34

    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

## Step 2: AndroidManifest.xml

Add required permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Internet permission for API calls -->
    <uses-permission android:name="android.permission.INTERNET" />

    <!-- Network state for connectivity checks -->
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <!-- For background work manager (optional) -->
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>

    <application>
        <!-- Your app configuration -->
    </application>
</manifest>
```

## Step 3: ProGuard Rules (if using)

Add to `android/app/proguard-rules.pro`:

```proguard
# Keep app update manager classes
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.install.** { *; }
-keep interface com.google.android.play.core.** { *; }

# WorkManager
-keep class * extends androidx.work.Worker
-keep class * extends androidx.work.InputMerger
-keep class androidx.work.impl.WorkManagerImpl
```

## Step 4: Testing In-App Updates

### Internal Testing Track

1. Upload your app to Play Console
2. Create an internal testing track
3. Upload a new version with higher version code
4. Add test users
5. Install the lower version on test device
6. Test in-app updates

### Important Notes

- In-app updates only work on devices with Play Store
- The app must be installed from Play Store (not sideloaded)
- For flexible updates, app must be in foreground
- For immediate updates, app will restart after update

## Step 5: Handling Update Types

### Flexible Update

```dart
await AppUpdateManager.initialize(
  config: UpdateConfig(
    playStoreId: 'com.yourapp.package',
    strategy: UpdateStrategy.flexible,
  ),
);
```

User can dismiss and continue using app. Update installs in background.

### Immediate Update

```dart
await AppUpdateManager.initialize(
  config: UpdateConfig(
    playStoreId: 'com.yourapp.package',
    strategy: UpdateStrategy.immediate,
  ),
);
```

User must update before continuing. Blocks app usage.

## Troubleshooting

### In-app update not showing

**Problem:** Update check returns no update available

**Solutions:**
1. Ensure higher version is on Play Store
2. Wait 24 hours after uploading to Play Console
3. Clear Play Store cache
4. Check if device has Play Store installed
5. Verify package name matches Play Console

### Update download fails

**Problem:** Update starts but fails to download

**Solutions:**
1. Check internet connectivity
2. Ensure sufficient storage space
3. Check Play Store settings
4. Try on different network

### App crashes during update

**Problem:** App crashes when checking or installing update

**Solutions:**
1. Check ProGuard rules are applied
2. Verify dependencies are up to date
3. Check logcat for specific errors
4. Test on different Android versions

### Background checks not working

**Problem:** Background update checks don't run

**Solutions:**
1. Check battery optimization settings
2. Verify WorkManager is initialized
3. Check app is not in restricted background mode
4. Test on different device manufacturers

## Testing Checklist

- [ ] In-app update shows for flexible strategy
- [ ] In-app update blocks for immediate strategy
- [ ] Fallback to Play Store works when in-app fails
- [ ] Background checks run on schedule
- [ ] Updates work on WiFi and mobile data
- [ ] Updates work with battery saver on
- [ ] Force updates block app usage
- [ ] Release notes display correctly
- [ ] Analytics events fire properly
- [ ] App doesn't crash on update failure

## Best Practices

1. **Test on multiple devices** - Different manufacturers handle updates differently
2. **Use internal testing track** - Test before releasing to production
3. **Handle failures gracefully** - Always provide fallback to Play Store
4. **Respect user choice** - Don't force updates too aggressively
5. **Monitor analytics** - Track update success rates
6. **Inform users** - Show clear update messages
7. **Test offline** - Handle no network scenarios

## Example Configuration

```dart
await AppUpdateManager.initialize(
  config: UpdateConfig(
    playStoreId: 'com.yourapp.package',
    strategy: UpdateStrategy.flexible,
    enableBackgroundCheck: true,
    backgroundCheckInterval: 24,
    wifiOnly: false,
    enableAnalytics: true,
    onAnalyticsEvent: (event, data) {
      // Track update events
      print('Update event: ${event.name}');
    },
  ),
);
```

## Support

For Android-specific issues:
- Check Play Console dashboard
- Review Play Store policies
- Test on different Android versions
- Check device manufacturer forums
