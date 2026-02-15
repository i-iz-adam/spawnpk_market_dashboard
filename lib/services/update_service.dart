import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;



class UpdateService {
  static const String _repoOwner = 'i-iz-adam';
  static const String _repoName = 'spawnpk_market_dashboard';
  

  static bool get isSquirrelInstall {
    if (!Platform.isWindows) return false;
    
    try {
      final exePath = Platform.resolvedExecutable;
      final exeDir = p.dirname(exePath);
      

      final updateExe = File(p.join(exeDir, '..', 'Update.exe'));
      return updateExe.existsSync();
    } catch (e) {
      return false;
    }
  }
  

  static String? get updateExePath {
    if (!isSquirrelInstall) return null;
    
    try {
      final exePath = Platform.resolvedExecutable;
      final exeDir = p.dirname(exePath);
      final updateExe = p.normalize(p.join(exeDir, '..', 'Update.exe'));
      
      if (File(updateExe).existsSync()) {
        return updateExe;
      }
    } catch (e) {
      print('Error finding Update.exe: $e');
    }
    return null;
  }
  

  static Future<UpdateInfo?> checkForUpdates() async {
    try {

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = _normalizeVersion(packageInfo.version);
      

      final response = await http.get(
        Uri.parse('https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest'),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'SpawnPK-Market-Dashboard',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode != 200) {
        print('Failed to check for updates: ${response.statusCode}');
        return null;
      }
      
      final release = json.decode(response.body) as Map<String, dynamic>;
      final latestVersion = _normalizeVersion(release['tag_name']);
      
      if (_isNewerVersion(latestVersion, currentVersion)) {
        print('Update available: $latestVersion > $currentVersion');
        
        return UpdateInfo(
          version: release['tag_name'],
          releaseNotes: release['body'] ?? '',
          publishedAt: DateTime.parse(release['published_at']),
        );
      }
      
      print('Already on latest version: $currentVersion');
      return null;
    } catch (e) {
      print('Error checking for updates: $e');
      return null;
    }
  }
  

  static Future<bool> downloadAndInstallUpdate() async {
    if (!isSquirrelInstall) {
      print('Not a Squirrel install - cannot update');
      return false;
    }
    
    final updateExe = updateExePath;
    if (updateExe == null) {
      print('Update.exe not found');
      return false;
    }
    
    try {
      print('Starting Squirrel update process...');
      


      final releasesUrl = 'https://github.com/$_repoOwner/$_repoName/releases/latest/download';
      
      print('Checking for updates at: $releasesUrl');
      


      final result = await Process.run(
        updateExe,
        ['--update', releasesUrl],
      );
      
      print('Update.exe exit code: ${result.exitCode}');
      if (result.stdout.toString().isNotEmpty) {
        print('stdout: ${result.stdout}');
      }
      if (result.stderr.toString().isNotEmpty) {
        print('stderr: ${result.stderr}');
      }
      
      if (result.exitCode == 0) {
        print('✓ Update downloaded successfully');
        


        return true;
      } else {
        print('✗ Update failed with exit code: ${result.exitCode}');
        return false;
      }
    } catch (e) {
      print('Error during update: $e');
      return false;
    }
  }
  

  static Future<void> restartApplication() async {
    if (!Platform.isWindows) return;
    
    try {
      final exePath = Platform.resolvedExecutable;
      

      await Process.start(
        exePath,
        [],
        mode: ProcessStartMode.detached,
      );
      

      await Future.delayed(const Duration(milliseconds: 500));
      

      exit(0);
    } catch (e) {
      print('Error restarting application: $e');
    }
  }
  

  static String _normalizeVersion(String version) {
    return version.trim().toLowerCase().replaceFirst(RegExp(r'^v'), '');
  }
  

  static bool _isNewerVersion(String latest, String current) {
    try {
      final latestParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      

      while (latestParts.length < 3) latestParts.add(0);
      while (currentParts.length < 3) currentParts.add(0);
      

      for (int i = 0; i < 3; i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      
      return false; // Equal
    } catch (e) {
      print('Error comparing versions: $e');
      return false;
    }
  }
}


class UpdateInfo {
  final String version;
  final String releaseNotes;
  final DateTime publishedAt;
  
  UpdateInfo({
    required this.version,
    required this.releaseNotes,
    required this.publishedAt,
  });
}