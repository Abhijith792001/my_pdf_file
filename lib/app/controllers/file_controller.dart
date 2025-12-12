import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class FileController extends GetxController {
  RxList<FileSystemEntity> allFiles = <FileSystemEntity>[].obs;
  RxList<FileSystemEntity> recentFiles = <FileSystemEntity>[].obs;
  RxBool isLoading = true.obs;
  RxBool hasPermission = false.obs;

  @override
  void onInit() {
    super.onInit();
    requestPermission();
  }

  Future<void> requestPermission() async {
    bool permissionGranted = false;
    if (Platform.isAndroid) {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      if (deviceInfo.version.sdkInt >= 30) {
        permissionGranted = await Permission.manageExternalStorage
            .request()
            .isGranted;
      } else {
        permissionGranted = await Permission.storage.request().isGranted;
      }
    } else {
      permissionGranted = await Permission.storage.request().isGranted;
    }

    hasPermission.value = permissionGranted;
    if (permissionGranted) {
      fetchPdfs();
    }
  }

  Future<void> fetchPdfs() async {
    isLoading.value = true;
    try {
      // Basic implementation: Scan common directories
      // In a real production app with all file access, we might use a recursive scanner or media store
      // specific to the requirement. For now, let's look in Downloads and Documents.

      List<Directory> directoriesToSearch = [];

      // Scan external storage recursively (with depth limit)
      Directory? externalDir;
      if (Platform.isAndroid) {
        externalDir = Directory('/storage/emulated/0');
      }

      if (externalDir != null && externalDir.existsSync()) {
        // We will scan specific high-probability folders to be efficient
        List<String> validFolders = ['Download', 'Documents', 'Books', 'Music'];
        for (var folder in validFolders) {
          var dir = Directory("${externalDir.path}/$folder");
          if (dir.existsSync()) {
            directoriesToSearch.add(dir);
          }
        }
        // Also add root just in case, but rely on recursive to hit others if needed?
        // Actually, scanning root /storage/emulated/0 recursively is very slow and permission heavy.
        // Let's stick to known folders first, or just one broad scan if user wants "all".
        // Use a safe recursive scanner.
      }

      List<FileSystemEntity> files = [];

      for (var dir in directoriesToSearch) {
        await _searchFilesRecursive(dir, files, 0);
      }

      allFiles.assignAll(files);
      // Sort by date modified for recent
      recentFiles.assignAll(
        List.from(files)..sort(
          (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
        ),
      );
    } catch (e) {
      print("Error scanning files: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _searchFilesRecursive(
    Directory dir,
    List<FileSystemEntity> files,
    int depth,
  ) async {
    if (depth > 5) return; // Prevent too deep recursion

    try {
      final List<FileSystemEntity> entities = dir.listSync(
        recursive: false,
        followLinks: false,
      );
      for (final entity in entities) {
        if (entity is File) {
          if (entity.path.toLowerCase().endsWith('.pdf')) {
            files.add(entity);
          }
        } else if (entity is Directory) {
          // Skip hidden folders
          if (!entity.path.split('/').last.startsWith('.')) {
            await _searchFilesRecursive(entity, files, depth + 1);
          }
        }
      }
    } catch (e) {
      // Access denied or other error
    }
  }
}
