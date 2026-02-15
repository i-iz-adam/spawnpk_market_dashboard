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
  bool _isDownloading = false;
  bool _isInstalling = false;
  double _downloadProgress = 0.0;
  GitHubRelease? _latestRelease;
  String? _currentVersion;
  String? _errorMessage;
  String? _dismissedVersion;

  @override
  void initState() {
    super.initState();
    _initializeUpdateState();
    _loadCurrentVersion();
    _loadDismissedVersion();
    _checkForUpdates();
  }

  Future<void> _initializeUpdateState() async {

    await UpdateService.verifyUpdateCompletion();
    

    final isUpdating = await UpdateService.isUpdateInProgress();
    if (isUpdating) {

      await UpdateService.setUpdateInProgress(false);
      print('⚠ Update process cleared - likely failed or interrupted');
    }
  }

  Future<void> _loadCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _currentVersion = packageInfo.version;
    });
  }

  Future<void> _loadDismissedVersion() async {
    final dismissed = await UpdateService.getDismissedVersion();
    setState(() {
      _dismissedVersion = dismissed;
    });
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    try {
      final release = await UpdateService.checkForUpdates();
      setState(() {
        _latestRelease = release;
        _isChecking = false;
      });

      if (release != null) {
        await UpdateService.saveLastCheckTime();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isChecking = false;
      });
    }
  }

  Future<void> _downloadAndInstall() async {
    if (_latestRelease == null) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _errorMessage = null;
    });

    try {
      final downloadPath = UpdateService.getInstallerDownloadPath();
      

      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(Duration(milliseconds: 200));
        if (mounted) {
          setState(() {
            _downloadProgress = i / 100.0;
          });
        }
      }

      final downloadedPath = await UpdateService.downloadUpdate(
        _latestRelease!.downloadUrl,
        downloadPath,
      );

      setState(() {
        _isDownloading = false;
        _isInstalling = true;
      });

      final success = await UpdateService.installUpdate(downloadedPath, _latestRelease!.tagName);
      
      if (success) {
        _showInstallSuccessDialog();
      } else {
        setState(() {
          _errorMessage = 'Failed to start installation';
          _isInstalling = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Download failed: ${e.toString()}';
        _isDownloading = false;
      });
    }
  }

  void _showInstallSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Update Started'),
        content: const Text(
          'The update installer has started. The application will now close '
          'to complete the installation. Please restart the application after '
          'the installation finishes.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              

              await UpdateService.setUpdateInProgress(false);
              
              if (Platform.isWindows) {
                exit(0);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _dismissUpdate() async {
    if (_latestRelease != null) {
      await UpdateService.dismissVersion(_latestRelease!.tagName);
      setState(() {
        _dismissedVersion = _latestRelease!.tagName;
      });
    }
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

    if (_latestRelease == null) {
      return _buildUpToDateCard();
    }

    if (_dismissedVersion == _latestRelease!.tagName) {
      return _buildDismissedUpdateCard();
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
            onPressed: _checkForUpdates,
            icon: const Icon(Icons.refresh),
            label: const Text('Check Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildDismissedUpdateCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_off,
                color: AppColors.onSurfaceVariant,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Update Dismissed',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Version ${_latestRelease!.tagName} is available but was dismissed.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _dismissedVersion = null;
                  });
                },
                icon: const Icon(Icons.notifications_active),
                label: const Text('Show Update'),
              ),
              const SizedBox(width: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: _checkForUpdates,
                icon: const Icon(Icons.refresh),
                label: const Text('Check Again'),
              ),
            ],
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
                  'Update Available: ${_latestRelease!.tagName}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (_latestRelease!.body.isNotEmpty) ...[
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
                _latestRelease!.body,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (_isDownloading) ...[
            LinearProgressIndicator(value: _downloadProgress),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Downloading update... ${(_downloadProgress * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (_isInstalling) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Starting installer...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (!_isDownloading && !_isInstalling) ...[
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _downloadAndInstall,
                  icon: const Icon(Icons.download),
                  label: const Text('Download & Install'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onSurface,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: _dismissUpdate,
                  icon: const Icon(Icons.close),
                  label: const Text('Dismiss'),
                ),
              ],
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
