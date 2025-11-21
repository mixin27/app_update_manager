import 'package:flutter/material.dart';

import '../models/update_config.dart';
import '../models/update_info.dart';

/// Dialog for showing update information
class UpdateDialog extends StatelessWidget {
  final UpdateInfo updateInfo;
  final UpdateUIConfig? uiConfig;
  final VoidCallback? onUpdate;
  final VoidCallback? onCancel;
  final VoidCallback? onLater;
  final bool isForced;

  const UpdateDialog({
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
      onPopInvokedWithResult: (didPop, result) async => !isForced,
      child: AlertDialog(
        backgroundColor:
            config.backgroundColor ?? theme.dialogTheme.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            if (config.customIcon != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: config.customIcon,
              )
            else
              Icon(
                Icons.system_update,
                color: config.primaryColor ?? theme.primaryColor,
                size: 28,
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _getTitle(config),
                style:
                    config.titleStyle ??
                    theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getMessage(config),
                style: config.messageStyle ?? theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              _buildVersionInfo(theme, config),
              if (config.showReleaseNotes && updateInfo.releaseNotes != null)
                _buildReleaseNotes(theme, config),
              if (config.showFileSize && updateInfo.fileSizeBytes != null)
                _buildFileSize(theme),
              if (updateInfo.isCritical) _buildCriticalBadge(theme, config),
            ],
          ),
        ),
        actions: _buildActions(context, config),
      ),
    );
  }

  String _getTitle(UpdateUIConfig config) {
    if (config.title != null) return config.title!;
    if (isForced || updateInfo.isForced) return 'Update Required';
    if (updateInfo.isCritical) return 'Critical Update Available';
    return 'Update Available';
  }

  String _getMessage(UpdateUIConfig config) {
    if (config.message != null) return config.message!;
    if (isForced || updateInfo.isForced) {
      return 'A new version is required to continue using the app. Please update now.';
    }
    return 'A new version of the app is available. Would you like to update?';
  }

  Widget _buildVersionInfo(ThemeData theme, UpdateUIConfig config) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (config.primaryColor ?? theme.primaryColor).withValues(
          alpha: 0.1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Version',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                updateInfo.currentVersion.toShortString(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Icon(
            Icons.arrow_forward,
            color: config.primaryColor ?? theme.primaryColor,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'New Version',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                updateInfo.latestVersion.toShortString(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: config.primaryColor ?? theme.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReleaseNotes(ThemeData theme, UpdateUIConfig config) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What\'s New',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: theme.dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              updateInfo.releaseNotes!,
              style: theme.textTheme.bodySmall,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileSize(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Icon(
            Icons.download,
            size: 16,
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
          Text(
            'Download size: ${updateInfo.formattedFileSize}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriticalBadge(ThemeData theme, UpdateUIConfig config) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.priority_high, size: 16, color: Colors.red),
            const SizedBox(width: 6),
            Text(
              'Critical Update',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context, UpdateUIConfig config) {
    final actions = <Widget>[];

    // Only show cancel/later if not forced
    if (!isForced && !updateInfo.isForced) {
      if (!updateInfo.isBelowMinimumVersion) {
        actions.add(
          TextButton(
            onPressed: () {
              onLater?.call();
              Navigator.of(context).pop(false);
            },
            child: Text(
              config.laterButtonText ?? 'Later',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
        );
      }

      actions.add(
        TextButton(
          onPressed: () {
            onCancel?.call();
            Navigator.of(context).pop(false);
          },
          child: Text(
            config.cancelButtonText ?? 'Cancel',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ),
      );
    }

    // Update button
    actions.add(
      ElevatedButton(
        onPressed: () {
          onUpdate?.call();
          Navigator.of(context).pop(true);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor:
              config.primaryColor ?? Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(config.updateButtonText ?? 'Update Now'),
      ),
    );

    return actions;
  }
}

/// Show update dialog
Future<bool?> showUpdateDialog({
  required BuildContext context,
  required UpdateInfo updateInfo,
  UpdateUIConfig? uiConfig,
  VoidCallback? onUpdate,
  VoidCallback? onCancel,
  VoidCallback? onLater,
  bool barrierDismissible = true,
}) {
  final isForced = updateInfo.isForced || updateInfo.isBelowMinimumVersion;

  return showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible && !isForced,
    builder: (context) => UpdateDialog(
      updateInfo: updateInfo,
      uiConfig: uiConfig,
      onUpdate: onUpdate,
      onCancel: onCancel,
      onLater: onLater,
      isForced: isForced,
    ),
  );
}
