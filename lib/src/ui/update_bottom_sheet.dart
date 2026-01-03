import 'package:flutter/material.dart';

import '../models/update_config.dart';
import '../models/update_info.dart';

/// Bottom sheet for showing update information
class UpdateBottomSheet extends StatelessWidget {
  /// Update information
  final UpdateInfo updateInfo;

  /// UI configuration
  final UpdateUIConfig? uiConfig;

  /// Callback for update action
  final VoidCallback? onUpdate;

  /// Callback for cancel action
  final VoidCallback? onCancel;

  /// Callback for later action
  final VoidCallback? onLater;

  /// Whether the update is forced
  final bool isForced;

  /// Creates an [UpdateBottomSheet] instance.
  const UpdateBottomSheet({
    super.key,
    required this.updateInfo,
    this.uiConfig,
    this.onUpdate,
    this.onCancel,
    this.onLater,
    this.isForced = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = uiConfig ?? const UpdateUIConfig();

    return PopScope(
      onPopInvokedWithResult: (didPop, result) => !isForced,
      child: Container(
        decoration: BoxDecoration(
          color: config.backgroundColor ?? theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isForced && !updateInfo.isForced)
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                _buildHeader(theme, config),
                const SizedBox(height: 20),
                _buildContent(theme, config),
                const SizedBox(height: 24),
                _buildActions(context, config),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, UpdateUIConfig config) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (config.primaryColor ?? theme.primaryColor).withValues(
              alpha: 0.1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child:
              config.customIcon ??
              Icon(
                Icons.system_update,
                color: config.primaryColor ?? theme.primaryColor,
                size: 32,
              ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getTitle(config),
                style:
                    config.titleStyle ??
                    theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Version ${updateInfo.latestVersion.toShortString()}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: config.primaryColor ?? theme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent(ThemeData theme, UpdateUIConfig config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getMessage(config),
          style: config.messageStyle ?? theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        if (config.showReleaseNotes && updateInfo.releaseNotes != null)
          _buildReleaseNotes(theme, config),
        if (config.showFileSize && updateInfo.fileSizeBytes != null)
          _buildFileSize(theme),
        if (updateInfo.isCritical) ...[
          const SizedBox(height: 12),
          _buildCriticalBanner(theme, config),
        ],
      ],
    );
  }

  Widget _buildReleaseNotes(ThemeData theme, UpdateUIConfig config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What\'s New',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (config.primaryColor ?? theme.primaryColor).withValues(
              alpha: 0.05,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (config.primaryColor ?? theme.primaryColor).withValues(
                alpha: 0.2,
              ),
            ),
          ),
          child: Text(
            updateInfo.releaseNotes!,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildFileSize(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(
            Icons.download_outlined,
            size: 18,
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
          Text(
            'Download size: ${updateInfo.formattedFileSize}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriticalBanner(ThemeData theme, UpdateUIConfig config) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This is a critical security update',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, UpdateUIConfig config) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              onUpdate?.call();
              Navigator.of(context).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  config.primaryColor ?? Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              config.updateButtonText ?? 'Update Now',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        if (!isForced && !updateInfo.isForced) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              if (!updateInfo.isBelowMinimumVersion) ...[
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
                        onLater?.call();
                        Navigator.of(context).pop(false);
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      child: Text(
                        config.laterButtonText ?? 'Later',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: TextButton(
                    onPressed: () {
                      onCancel?.call();
                      Navigator.of(context).pop(false);
                    },
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      config.cancelButtonText ?? 'Cancel',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _getTitle(UpdateUIConfig config) {
    if (config.title != null) return config.title!;
    if (isForced || updateInfo.isForced) return 'Update Required';
    if (updateInfo.isCritical) return 'Critical Update';
    return 'Update Available';
  }

  String _getMessage(UpdateUIConfig config) {
    if (config.message != null) return config.message!;
    if (isForced || updateInfo.isForced) {
      return 'A new version is required to continue using the app.';
    }
    return 'A new version is available with improvements and bug fixes.';
  }
}

/// Show update bottom sheet
Future<bool?> showUpdateBottomSheet({
  required BuildContext context,
  required UpdateInfo updateInfo,
  UpdateUIConfig? uiConfig,
  VoidCallback? onUpdate,
  VoidCallback? onCancel,
  VoidCallback? onLater,
  bool isDismissible = true,
}) {
  final isForced = updateInfo.isForced || updateInfo.isBelowMinimumVersion;

  return showModalBottomSheet<bool>(
    context: context,
    isDismissible: isDismissible && !isForced,
    enableDrag: isDismissible && !isForced,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => UpdateBottomSheet(
      updateInfo: updateInfo,
      uiConfig: uiConfig,
      onUpdate: onUpdate,
      onCancel: onCancel,
      onLater: onLater,
      isForced: isForced,
    ),
  );
}
