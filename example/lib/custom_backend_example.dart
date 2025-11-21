import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:app_update_manager/app_update_manager.dart';

/// Example showing custom backend integration
///
/// Your backend should return JSON in this format:
/// ```json
/// {
///   "latest_version": "1.2.0",
///   "current_version": "1.0.0",  // Optional, will use app version if not provided
///   "release_notes": "Bug fixes and improvements",
///   "download_url": "https://...",  // For custom updates
///   "is_forced": false,
///   "is_critical": false,
///   "minimum_supported_version": "1.0.0",  // Optional
///   "file_size_bytes": 25600000,  // Optional
///   "release_date": "2024-01-15T10:30:00Z"  // Optional
/// }
/// ```
class CustomBackendExample extends StatelessWidget {
  const CustomBackendExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Custom Backend Example')),
        body: const UpdateCheckWidget(),
      ),
    );
  }
}

class UpdateCheckWidget extends StatefulWidget {
  const UpdateCheckWidget({super.key});

  @override
  State<UpdateCheckWidget> createState() => _UpdateCheckWidgetState();
}

class _UpdateCheckWidgetState extends State<UpdateCheckWidget> {
  @override
  void initState() {
    super.initState();
    _initializeUpdateManager();
  }

  Future<void> _initializeUpdateManager() async {
    await AppUpdateManager.initialize(
      config: UpdateConfig(
        // Your custom API endpoint
        customUpdateUrl: 'https://api.yourapp.com/v1/version/check',

        // Optional: Add custom headers for authentication
        customHeaders: {
          'Authorization': 'Bearer YOUR_API_TOKEN',
          'X-App-Platform': 'mobile',
        },

        // Optional: Region code for regional rollouts
        regionCode: 'US',

        // Optional: A/B test group
        testGroup: 'beta',

        // Strategy configuration
        strategy: UpdateStrategy.flexible,

        // Enable analytics
        enableAnalytics: true,
        onAnalyticsEvent: (event, data) {
          log('Update Event: ${event.name}');
          log('Data: $data');
        },

        // Cache settings
        enableCaching: true,
        cacheDuration: 6,

        // Network settings
        requestTimeout: 30,
        wifiOnly: false,
      ),
    );

    // Check for updates
    await _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    try {
      final updated = await AppUpdateManager.checkAndShowUpdate(
        context: context,
        useBottomSheet: true,
        uiConfig: const UpdateUIConfig(
          title: 'New Version Available',
          message: 'We\'ve made some improvements!',
          updateButtonText: 'Update',
          laterButtonText: 'Remind Me Later',
          showReleaseNotes: true,
          showFileSize: true,
        ),
      );

      if (updated) {
        log('User accepted update');
      }
    } catch (e) {
      log('Error checking for update: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: _checkForUpdate,
        child: const Text('Check for Updates'),
      ),
    );
  }
}

/// Example backend implementation (Node.js/Express)
///
/// app.get('/v1/version/check', (req, res) => {
///   const { platform, current_version, region, test_group } = req.query;
///
///   // Your version logic here
///   const latestVersion = '1.2.0';
///   const currentVersion = current_version || '1.0.0';
///
///   // Check if update is available
///   if (compareVersions(latestVersion, currentVersion) > 0) {
///     res.json({
///       latest_version: latestVersion,
///       current_version: currentVersion,
///       release_notes: 'Bug fixes and performance improvements',
///       is_forced: false,
///       is_critical: false,
///       minimum_supported_version: '1.0.0',
///       file_size_bytes: 25600000,
///       release_date: new Date().toISOString()
///     });
///   } else {
///     res.json({
///       latest_version: currentVersion,
///       current_version: currentVersion
///     });
///   }
/// });
