import 'package:app_update_manager/app_update_manager.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the update manager
  await AppUpdateManager.initialize(
    config: UpdateConfig(
      playStoreId: 'dev.mixin27.mmcalendar',
      appStoreId: '123456789',
      customUpdateUrl: 'https://api.yourapp.com/version',
      strategy: UpdateStrategy.flexible,
      enableBackgroundCheck: true,
      backgroundCheckInterval: 24,
      enableCaching: true,
      wifiOnly: false,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Update Manager Demo',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _currentVersion = 'Loading...';
  bool _isChecking = false;
  UpdateInfo? _updateInfo;

  @override
  void initState() {
    super.initState();
    _loadCurrentVersion();
    _checkForUpdatesOnStart();
  }

  Future<void> _loadCurrentVersion() async {
    final version = await AppUpdateManager.getCurrentVersion();
    setState(() {
      _currentVersion = version;
    });
  }

  Future<void> _checkForUpdatesOnStart() async {
    // Check for updates when app starts
    await Future.delayed(const Duration(seconds: 2));
    await _checkForUpdates(showDialog: true);
  }

  Future<void> _checkForUpdates({bool showDialog = false}) async {
    setState(() {
      _isChecking = true;
    });

    try {
      final updateInfo = await AppUpdateManager.checkForUpdate();

      setState(() {
        _updateInfo = updateInfo;
        _isChecking = false;
      });

      if (updateInfo != null && updateInfo.isUpdateAvailable) {
        if (showDialog) {
          if (mounted) {
            await AppUpdateManager.checkAndShowUpdate(
              context: context,
              useBottomSheet: false,
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Update available!'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } else if (showDialog) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You are on the latest version'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isChecking = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to check for updates: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App Update Manager'), elevation: 2),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Version',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentVersion,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_updateInfo != null && _updateInfo!.isUpdateAvailable) ...[
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Update Available',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Version ${_updateInfo!.latestVersion}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (_updateInfo!.releaseNotes != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _updateInfo!.releaseNotes!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton.icon(
              onPressed: _isChecking
                  ? null
                  : () => _checkForUpdates(showDialog: true),
              icon: _isChecking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(_isChecking ? 'Checking...' : 'Check for Updates'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                await AppUpdateManager.clearCache();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cache cleared'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear Cache'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const Spacer(),
            const Text(
              'The app will automatically check for updates in the background '
              'every 24 hours if enabled.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
