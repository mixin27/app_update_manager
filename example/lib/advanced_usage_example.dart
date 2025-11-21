import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:app_update_manager/app_update_manager.dart';

/// Example showing advanced features:
/// - Custom UI styling
/// - Force updates
/// - Background checks
/// - Analytics integration
/// - Regional rollouts
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize with advanced configuration
  await AppUpdateManager.initialize(
    config: UpdateConfig(
      playStoreId: 'com.yourapp.example',
      appStoreId: '123456789',
      customUpdateUrl: 'https://api.yourapp.com/version',

      // Update strategy
      strategy: UpdateStrategy.flexible,

      // Background checks
      enableBackgroundCheck: true,
      backgroundCheckInterval: 12, // Every 12 hours
      // Network preferences
      wifiOnly: false,
      requestTimeout: 30,

      // Caching
      enableCaching: true,
      cacheDuration: 6,

      // Regional rollout
      regionCode: 'US',
      testGroup: 'beta',

      // Analytics
      enableAnalytics: true,
      onAnalyticsEvent: (event, data) {
        // Integrate with your analytics service (Firebase, Mixpanel, etc.)
        log('Analytics Event: ${event.name}');

        // Example: Send to Firebase Analytics
        // FirebaseAnalytics.instance.logEvent(
        //   name: 'app_update_${event.name}',
        //   parameters: data,
        // );
      },

      // Custom headers for API authentication
      customHeaders: {
        'Authorization': 'Bearer YOUR_TOKEN',
        'X-App-Version': '1.0.0',
      },
    ),
  );

  runApp(const AdvancedExampleApp());
}

class AdvancedExampleApp extends StatelessWidget {
  const AdvancedExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Advanced Update Manager',
      theme: ThemeData(primarySwatch: Colors.purple, useMaterial3: true),
      darkTheme: ThemeData.dark().copyWith(primaryColor: Colors.purpleAccent),
      home: const AdvancedHomePage(),
    );
  }
}

class AdvancedHomePage extends StatefulWidget {
  const AdvancedHomePage({super.key});

  @override
  State<AdvancedHomePage> createState() => _AdvancedHomePageState();
}

class _AdvancedHomePageState extends State<AdvancedHomePage> {
  bool _hasBackgroundUpdate = false;

  @override
  void initState() {
    super.initState();
    _checkBackgroundUpdate();
    _checkForUpdates();
  }

  Future<void> _checkBackgroundUpdate() async {
    final hasUpdate = await AppUpdateManager.hasBackgroundUpdate();
    setState(() {
      _hasBackgroundUpdate = hasUpdate;
    });
  }

  Future<void> _checkForUpdates() async {
    // Wait a bit before checking
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      await AppUpdateManager.checkAndShowUpdate(
        context: context,
        useBottomSheet: true,
        uiConfig: _buildCustomUI(),
      );
    }
  }

  UpdateUIConfig _buildCustomUI() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return UpdateUIConfig(
      title: 'New Version Available! 🎉',
      message: 'We\'ve added amazing new features and fixed some bugs.',
      updateButtonText: 'Update Now',
      laterButtonText: 'Maybe Later',
      cancelButtonText: 'Skip',
      primaryColor: Colors.purple,
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      titleStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      messageStyle: const TextStyle(fontSize: 14, height: 1.5),
      showReleaseNotes: true,
      showFileSize: true,
      customIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.purple, Colors.purpleAccent],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.rocket_launch, color: Colors.white, size: 24),
      ),
    );
  }

  Future<void> _manualUpdateCheck() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final updateInfo = await AppUpdateManager.checkForUpdate();
      if (mounted) {
        Navigator.pop(context);
      }

      if (updateInfo == null || !updateInfo.isUpdateAvailable) {
        _showSnackBar('You\'re on the latest version! ✨');
        return;
      }

      if (mounted) {
        await AppUpdateManager.checkAndShowUpdate(
          context: context,
          useBottomSheet: true,
          uiConfig: _buildCustomUI(),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showSnackBar('Failed to check for updates: $e', isError: true);
    }
  }

  Future<void> _showForceUpdateDialog() async {
    // Simulate a forced update scenario
    final updateInfo = UpdateInfo(
      latestVersion: AppVersion.parse('2.0.0'),
      currentVersion: AppVersion.parse('1.0.0'),
      isForced: true,
      isCritical: true,
      releaseNotes: 'Critical security update. Please update immediately.',
    );

    await showUpdateDialog(
      context: context,
      updateInfo: updateInfo,
      uiConfig: _buildCustomUI(),
      barrierDismissible: false,
      onUpdate: () {
        log('User accepted force update');
      },
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Advanced Features'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_hasBackgroundUpdate)
            Card(
              color: Colors.orange.shade50,
              child: ListTile(
                leading: const Icon(
                  Icons.notifications_active,
                  color: Colors.orange,
                ),
                title: const Text('Background Update Available'),
                subtitle: const Text('An update was found in the background'),
                trailing: ElevatedButton(
                  onPressed: _checkForUpdates,
                  child: const Text('View'),
                ),
              ),
            ),
          _buildFeatureCard(
            'Manual Update Check',
            'Check for updates with custom UI',
            Icons.refresh,
            _manualUpdateCheck,
          ),
          _buildFeatureCard(
            'Force Update Demo',
            'Simulate a required update',
            Icons.lock,
            _showForceUpdateDialog,
          ),
          _buildFeatureCard(
            'Clear Cache',
            'Clear all cached update data',
            Icons.clear_all,
            () async {
              await AppUpdateManager.clearCache();
              _showSnackBar('Cache cleared');
            },
          ),
          _buildFeatureCard(
            'Cancel Background Checks',
            'Stop automatic update checks',
            Icons.cancel,
            () async {
              await AppUpdateManager.cancelBackgroundChecks();
              _showSnackBar('Background checks cancelled');
            },
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          _buildInfoSection(),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple.shade100,
          child: Icon(icon, color: Colors.purple),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Features Demonstrated',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoItem('✓ Custom UI styling'),
            _buildInfoItem('✓ Background update checks'),
            _buildInfoItem('✓ Force update scenarios'),
            _buildInfoItem('✓ Analytics integration'),
            _buildInfoItem('✓ Cache management'),
            _buildInfoItem('✓ Regional rollouts'),
            _buildInfoItem('✓ A/B testing support'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(text),
    );
  }
}
