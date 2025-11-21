# iOS Setup Guide

This guide walks you through setting up app_update_manager for iOS.

## Prerequisites

- iOS 12.0 or higher
- Xcode 14.0 or higher
- Your app must be published on App Store (can be TestFlight)
- Valid App Store ID

## Step 1: Update Info.plist

Add to `ios/Runner/Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>itunes.apple.com</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
            <key>NSIncludesSubdomains</key>
            <true/>
        </dict>
        <key>apps.apple.com</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
            <key>NSIncludesSubdomains</key>
            <true/>
        </dict>
    </dict>
</dict>

<!-- For opening App Store -->
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>itms-apps</string>
    <string>https</string>
</array>
```

## Step 2: Find Your App Store ID

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Select your app
3. Go to App Information
4. Find the Apple ID (numeric ID)

Or from App Store URL:
```
https://apps.apple.com/app/idXXXXXXXXX
                             ^^^^^^^^^^
                             This is your App Store ID
```

## Step 3: Configuration

```dart
await AppUpdateManager.initialize(
  config: UpdateConfig(
    appStoreId: '123456789', // Your App Store ID
    regionCode: 'us', // Optional: defaults to 'us'
  ),
);
```

## How It Works on iOS

### Version Checking

The package uses iTunes Search API to check for updates:
```
https://itunes.apple.com/lookup?id=YOUR_APP_STORE_ID
```

### Update Process

1. Package checks iTunes API for latest version
2. Compares with current app version
3. If update available, shows dialog
4. Opens App Store when user accepts
5. User manually updates in App Store

### Important Notes

- **No in-app updates**: iOS doesn't support in-app updates like Android
- **Manual process**: Users must go to App Store to update
- **App Store approval**: All updates go through App Store review
- **TestFlight**: Works with TestFlight builds for testing

## Step 4: Testing

### Using TestFlight

1. Upload build to TestFlight
2. Increment version number
3. Add testers
4. Install lower version
5. Test update flow

### Testing Checklist

- [ ] App Store ID is correct
- [ ] iTunes API returns version info
- [ ] Dialog shows when update available
- [ ] App Store opens correctly
- [ ] Works on both iPhone and iPad
- [ ] Works in different regions
- [ ] Handles no internet gracefully
- [ ] Release notes display correctly

## Step 5: Handling Scenarios

### When Update Available

```dart
await AppUpdateManager.checkAndShowUpdate(
  context: context,
  uiConfig: UpdateUIConfig(
    title: 'Update Available',
    message: 'A new version is available on the App Store',
    updateButtonText: 'Open App Store',
  ),
);
```

### Force Updates

```dart
await AppUpdateManager.initialize(
  config: UpdateConfig(
    appStoreId: '123456789',
    strategy: UpdateStrategy.immediate,
  ),
);
```

Shows non-dismissible dialog for critical updates.

### Background Checks

```dart
await AppUpdateManager.initialize(
  config: UpdateConfig(
    appStoreId: '123456789',
    enableBackgroundCheck: true,
    backgroundCheckInterval: 24,
  ),
);
```

Note: iOS has strict background execution limits.

## Troubleshooting

### App Store doesn't open

**Problem:** Tapping update button doesn't open App Store

**Solutions:**
1. Verify App Store ID is correct
2. Check Info.plist has correct URL schemes
3. Test on physical device (not simulator)
4. Check iOS version is 12.0 or higher

### No version information

**Problem:** iTunes API returns no data

**Solutions:**
1. Verify app is published on App Store
2. Check App Store ID is correct
3. Wait 24 hours after app approval
4. Try different region code
5. Check internet connectivity

### Update dialog doesn't show

**Problem:** No dialog appears when update available

**Solutions:**
1. Check version comparison logic
2. Verify current version format
3. Check if user dismissed update
4. Clear cache and try again

### Background checks not working

**Problem:** Background checks don't run

**Solutions:**
1. Understand iOS background limitations
2. Use app lifecycle events instead
3. Check when app comes to foreground
4. Consider push notifications

## Best Practices

1. **Clear messaging** - Explain update is in App Store
2. **Respect user** - Don't force updates too often
3. **Handle offline** - Check network before showing dialog
4. **Test thoroughly** - Test on multiple iOS versions
5. **Monitor analytics** - Track update acceptance rate
6. **Use regions** - Consider different app stores
7. **TestFlight first** - Test with beta users

## Example Implementation

```dart
import 'package:app_update_manager/app_update_manager.dart';

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkForUpdates();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Check for updates when app resumes
      _checkForUpdates();
    }
  }

  Future<void> _checkForUpdates() async {
    await AppUpdateManager.checkAndShowUpdate(
      context: context,
      uiConfig: UpdateUIConfig(
        title: 'Update Available',
        message: 'Get the latest features and improvements',
        updateButtonText: 'Update in App Store',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('My App')),
        body: Center(child: Text('Hello')),
      ),
    );
  }
}
```

## Regional Considerations

### Different App Stores

```dart
await AppUpdateManager.initialize(
  config: UpdateConfig(
    appStoreId: '123456789',
    regionCode: 'jp', // For Japanese App Store
  ),
);
```

### Common Region Codes

- `us` - United States
- `gb` - United Kingdom
- `jp` - Japan
- `de` - Germany
- `fr` - France
- `cn` - China
- `kr` - South Korea
- `au` - Australia

## Limitations

1. **No in-app updates** - Must go through App Store
2. **Manual process** - User must update manually
3. **Review required** - All updates need App Store approval
4. **Background limits** - iOS restricts background execution
5. **No forced install** - Can't force user to update
6. **Network required** - Requires internet for checks

## Support

For iOS-specific issues:
- Check App Store Connect
- Review Apple guidelines
- Test on different iOS versions
- Check App Store review status
