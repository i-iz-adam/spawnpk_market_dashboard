import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

class GitHubRelease {
  final String tagName;
  final String name;
  final String body;
  final String downloadUrl;
  final DateTime publishedAt;

  GitHubRelease({
    required this.tagName,
    required this.name,
    required this.body,
    required this.downloadUrl,
    required this.publishedAt,
  });

  factory GitHubRelease.fromJson(Map<String, dynamic> json) {
    return GitHubRelease(
      tagName: json['tag_name'] ?? '',
      name: json['name'] ?? '',
      body: json['body'] ?? '',
      downloadUrl: _getInstallerUrl(json['assets'] ?? []),
      publishedAt: DateTime.parse(json['published_at']),
    );
  }

  static String _getInstallerUrl(List<dynamic> assets) {
    for (var asset in assets) {
      if (asset['name'] == 'SpawnPKMarketDashboardSetup.exe') {
        return asset['browser_download_url'] ?? '';
      }
    }
    return '';
  }
}

class UpdateService {
  static const String _repoOwner = 'i-iz-adam';
  static const String _repoName = 'spawnpk_market_dashboard';
  static const String _lastCheckKey = 'last_update_check';
  static const String _dismissedVersionKey = 'dismissed_update_version';
  static const String _installedVersionKey = 'installed_update_version';
  static const String _updateInProgressKey = 'update_in_progress';

  static Future<GitHubRelease?> checkForUpdates() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest'),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'SpawnPK-Market-Dashboard',
        },
      );

      if (response.statusCode == 200) {
        final release = GitHubRelease.fromJson(json.decode(response.body));
        

        final installedVersion = await getInstalledVersion();
        if (installedVersion != null && installedVersion == release.tagName) {

          await clearInstalledVersion();
          return null;
        }

        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = 'v${packageInfo.version}';
        

        final isUpdating = await isUpdateInProgress();
        if (isUpdating) {

          final attemptedVersion = await getInstalledVersion();
          if (attemptedVersion != null && attemptedVersion == release.tagName) {
            return null; // Don't show the same version we just tried to install
          }
        }
        
        if (_isNewerVersion(release.tagName, currentVersion)) {
          return release;
        }
      }
    } catch (e) {
      print('Error checking for updates: $e');
    }
    return null;
  }

  static bool _isNewerVersion(String latest, String current) {
    try {
      final latestClean = latest.startsWith('v') ? latest.substring(1) : latest;
      final currentClean = current.startsWith('v') ? current.substring(1) : current;
      

      if (latestClean.isEmpty || currentClean.isEmpty) {
        print('Warning: Empty version string detected - latest: "$latestClean", current: "$currentClean"');
        return false;
      }
      
      final latestParts = latestClean.split('.').map((part) {
        try {
          return int.parse(part);
        } catch (e) {
          print('Warning: Invalid version part "$part" in version "$latestClean"');
          return 0;
        }
      }).toList();
      
      final currentParts = currentClean.split('.').map((part) {
        try {
          return int.parse(part);
        } catch (e) {
          print('Warning: Invalid version part "$part" in version "$currentClean"');
          return 0;
        }
      }).toList();
      

      while (latestParts.length < 3) {
        latestParts.add(0);
      }
      while (currentParts.length < 3) {
        currentParts.add(0);
      }
      

      for (int i = 0; i < 3; i++) {
        if (latestParts[i] > currentParts[i]) {
          print('Update available: $latest > $current');
          return true;
        }
        if (latestParts[i] < currentParts[i]) {
          return false;
        }
      }
      
      return false; // Versions are equal
    } catch (e) {
      print('Error comparing versions: $e');
      return false;
    }
  }

  static Future<String> downloadUpdate(String downloadUrl, String savePath) async {
    try {
      final response = await http.get(Uri.parse(downloadUrl));
      
      if (response.statusCode == 200) {
        final file = File(savePath);
        await file.writeAsBytes(response.bodyBytes);
        return savePath;
      } else {
        throw Exception('Failed to download: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Download failed: $e');
    }
  }

  static Future<bool> installUpdate(String installerPath, String targetVersion) async {
    try {

      await setInstalledVersion(targetVersion);
      await setUpdateInProgress(true);
      
      if (Platform.isWindows) {


        final result = await Process.run(installerPath, ['/SILENT']);
        

        await Future.delayed(const Duration(seconds: 2));
        

        if (result.exitCode == 0 || result.exitCode == null) {
          return true;
        } else {

          await clearInstalledVersion();
          await setUpdateInProgress(false);
          print('Installer failed with exit code: ${result.exitCode}');
          return false;
        }
      }
      return false;
    } catch (e) {
      print('Error installing update: $e');

      await clearInstalledVersion();
      await setUpdateInProgress(false);
      return false;
    }
  }

  static Future<void> saveLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastCheckKey, DateTime.now().toIso8601String());
  }

  static Future<DateTime?> getLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = prefs.getString(_lastCheckKey);
    return timeString != null ? DateTime.parse(timeString) : null;
  }

  static Future<void> dismissVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dismissedVersionKey, version);
  }

  static Future<String?> getDismissedVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_dismissedVersionKey);
  }

  static Future<void> setInstalledVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_installedVersionKey, version);
  }

  static Future<String?> getInstalledVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_installedVersionKey);
  }

  static Future<void> clearInstalledVersion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_installedVersionKey);
  }

  static Future<void> setUpdateInProgress(bool inProgress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_updateInProgressKey, inProgress);
  }

  static Future<bool> isUpdateInProgress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_updateInProgressKey) ?? false;
  }

  static Future<bool> shouldCheckForUpdates() async {
    final lastCheck = await getLastCheckTime();
    if (lastCheck == null) return true;
    

    final isUpdating = await isUpdateInProgress();
    if (isUpdating) {
      return true; // Always check when in update mode
    }
    
    final now = DateTime.now();
    final difference = now.difference(lastCheck);
    return difference.inHours >= 24;
  }

  static Future<void> verifyUpdateCompletion() async {
    final installedVersion = await getInstalledVersion();
    if (installedVersion != null) {
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = 'v${packageInfo.version}';
        
        if (installedVersion == currentVersion) {

          await clearInstalledVersion();
          await setUpdateInProgress(false);
          print('✓ Update verification successful: now running $currentVersion');
        }
      } catch (e) {
        print('Error verifying update completion: $e');
      }
    }
  }

  static String getInstallerDownloadPath() {
    final tempDir = Directory.systemTemp;
    return path.join(tempDir.path, 'SpawnPKMarketDashboardSetup.exe');
  }
}
