import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../services/update_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';

class UpdatePage extends ConsumerStatefulWidget {
  const UpdatePage({super.key});

  @override
  ConsumerState<UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends ConsumerState<UpdatePage> {
  bool _isChecking = false;
  bool _isUpdating = false;
  UpdateInfo? _updateInfo;
  String? _currentVersion;
  String? _errorMessage;
  bool _isSquirrelInstall = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _isSquirrelInstall = UpdateService.isSquirrelInstall;
    await _loadCurrentVersion();
    await _checkForUpdates();
  }

  Future<void> _loadCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _currentVersion = packageInfo.version;
      });
    }
  }

  Future<void> _checkForUpdates() async {
    if (!mounted) return;
    
    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    try {
      final updateInfo = await UpdateService.checkForUpdates();
      
      if (mounted) {
        setState(() {
          _updateInfo = updateInfo;
          _isChecking = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to check for updates: ${e.toString()}';
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _downloadAndInstall() async {
    if (_updateInfo == null || !mounted) return;
    
    if (!_isSquirrelInstall) {
      _showManualUpdateDialog();
      return;
    }

    setState(() {
      _isUpdating = true;
      _errorMessage = null;
    });

    try {
      final success = await UpdateService.downloadAndInstallUpdate();
      
      if (!mounted) return;
      
      if (success) {
        setState(() {
          _isUpdating = false;
        });
        _showRestartDialog();
      } else {
        setState(() {
          _errorMessage = 'Update failed. Please try again or download manually.';
          _isUpdating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Update error: ${e.toString()}';
          _isUpdating = false;
        });
      }
    }
  }

  void _showRestartDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            const Text('Update Ready'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The update has been downloaded successfully.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            const Text(
              'Restart the application to apply the update and use the new version.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Version ${_updateInfo!.version} will be active after restart.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              UpdateService.restartApplication();
            },
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Restart Now'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Later'),
          ),
        ],
      ),
    );
  }

  void _showManualUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manual Update Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version ${_updateInfo!.version} is available.'),
            const SizedBox(height: 16),
            const Text(
              'Automatic updates are only available for Squirrel-installed versions. '
              'Please download the latest version from GitHub.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();

              Process.run('cmd', [
                '/c',
                'start',
                'https://github.com/i-iz-adam/spawnpk_market_dashboard/releases/latest'
              ]);
            },
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Open Releases'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.system_update,
                size: 28,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Application Updates',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              if (_isSquirrelInstall && Platform.isWindows)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 6),
                      Text(
                        'Auto-Update Enabled',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCurrentVersionCard(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildUpdateStatusCard(),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _buildErrorCard(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentVersionCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Current Version',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _currentVersion != null ? 'v$_currentVersion' : 'Loading...',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateStatusCard() {
    if (_isChecking) {
      return _buildCheckingCard();
    }

    if (_updateInfo == null) {
      return _buildUpToDateCard();
    }

    return _buildUpdateAvailableCard();
  }

  Widget _buildCheckingCard() {
    return AppCard(
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Checking for updates...',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildUpToDateCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'You\'re up to date!',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'You have the latest version of SpawnPK Market Dashboard.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: _isChecking ? null : _checkForUpdates,
            icon: const Icon(Icons.refresh),
            label: const Text('Check Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateAvailableCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.new_releases,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Update Available: ${_updateInfo!.version}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (_updateInfo!.releaseNotes.isNotEmpty) ...[
            Text(
              'Release Notes:',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                _updateInfo!.releaseNotes,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (_isUpdating) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Downloading and installing update...',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (!_isUpdating) ...[
            ElevatedButton.icon(
              onPressed: _downloadAndInstall,
              icon: const Icon(Icons.download),
              label: Text(_isSquirrelInstall ? 'Download & Install' : 'View Update'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onSurface,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Error',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _errorMessage!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.red,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: _checkForUpdates,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}