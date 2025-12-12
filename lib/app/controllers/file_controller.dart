import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';

class FileController extends GetxController {
  RxList<FileSystemEntity> fileList = <FileSystemEntity>[].obs; // For Browser
  RxList<FileSystemEntity> recentFiles =
      <FileSystemEntity>[].obs; // For Dashboard
  RxList<FileSystemEntity> appFiles =
      <FileSystemEntity>[].obs; // For PDFManager specific folder
  RxBool isLoading = true.obs;
  RxBool hasPermission = false.obs;

  // File Management State
  Rx<FileSystemEntity?> clipboardItem = Rx<FileSystemEntity?>(null);
  RxBool isMoveMode = false.obs; // true = Move, false = Copy

  static const String appDirectoryName = "PDFManager";
  String get appPath => "/storage/emulated/0/$appDirectoryName";

  RxString currentPath = "/storage/emulated/0".obs;

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
        var status = await Permission.manageExternalStorage.request();
        if (status.isPermanentlyDenied) {
          openAppSettings();
        }
        permissionGranted = status.isGranted;
      } else {
        var status = await Permission.storage.request();
        if (status.isPermanentlyDenied) {
          openAppSettings();
        }
        permissionGranted = status.isGranted;
      }
    } else {
      var status = await Permission.storage.request();
      if (status.isPermanentlyDenied) {
        openAppSettings();
      }
      permissionGranted = status.isGranted;
    }

    hasPermission.value = permissionGranted;
    if (permissionGranted) {
      await _initAppDirectory();
      // Keep current path if it's already set to something valid, otherwise root
      if (currentPath.value.isEmpty) {
        currentPath.value = "/storage/emulated/0";
      }

      // Load everything
      _refreshAllData();
    }
  }

  void _refreshAllData() {
    fetchCurrentDirectory();
    _fetchAppFiles();
    _fetchRecentPdfsBackground();
  }

  Future<void> _initAppDirectory() async {
    try {
      final dir = Directory(appPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    } catch (e) {
      print("Error creating app directory: $e");
    }
  }

  Future<void> _fetchAppFiles() async {
    try {
      final dir = Directory(appPath);
      if (await dir.exists()) {
        List<FileSystemEntity> entities = dir.listSync();
        entities.sort((a, b) {
          if (a is Directory && b is File) return -1;
          if (a is File && b is Directory) return 1;
          return a.path.compareTo(b.path);
        });

        appFiles.assignAll(
          entities.where((e) {
            if (e is Directory) return true;
            if (e is File) {
              final ext = e.path.split('.').last.toLowerCase();
              return [
                'pdf',
                'doc',
                'docx',
                'txt',
                'ppt',
                'pptx',
                'xls',
                'xlsx',
              ].contains(ext);
            }
            return false;
          }).toList(),
        );
      } else {
        appFiles.clear();
      }
    } catch (e) {
      print("Error fetching app files: $e");
    }
  }

  // Browse specific directory
  Future<void> fetchCurrentDirectory() async {
    isLoading.value = true;
    try {
      final dir = Directory(currentPath.value);
      if (await dir.exists()) {
        List<FileSystemEntity> entities = dir.listSync();
        // Sort: Folders first, then files
        entities.sort((a, b) {
          if (a is Directory && b is File) return -1;
          if (a is File && b is Directory) return 1;
          return a.path.compareTo(b.path);
        });

        // Show all files and folders
        fileList.assignAll(entities);
      } else {
        fileList.clear();
      }
    } catch (e) {
      print("Error listing directory: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void navigateTo(String path) {
    currentPath.value = path;
    fetchCurrentDirectory();
  }

  void navigateUp() {
    if (currentPath.value == appPath)
      return; // Don't go above app root (optional constraint)
    final parent = Directory(currentPath.value).parent;
    currentPath.value = parent.path;
    fetchCurrentDirectory();
  }

  // Background scan for "Recent Files" (All PDFs)
  Future<void> _fetchRecentPdfsBackground() async {
    try {
      List<FileSystemEntity> allPdfs = [];

      // Scans common folders recursively
      List<String> validFolders = [appDirectoryName, 'Download', 'Documents'];

      Directory? externalDir;
      if (Platform.isAndroid) {
        externalDir = Directory('/storage/emulated/0');
      }

      if (externalDir != null) {
        for (var folder in validFolders) {
          var dir = Directory("${externalDir.path}/$folder");
          if (dir.existsSync()) {
            await _searchFilesRecursive(dir, allPdfs, 0);
          }
        }
      }

      recentFiles.assignAll(
        List.from(allPdfs)..sort(
          (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
        ),
      );
    } catch (e) {
      print("Error fetching recent files: $e");
    }
  }

  Future<void> moveFile(FileSystemEntity file, String newPath) async {
    try {
      if (file is File) {
        await file.rename(newPath);
        fetchCurrentDirectory();
        _fetchRecentPdfsBackground();
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to move file: $e");
    }
  }

  Future<void> createFolder(String folderName) async {
    try {
      // Create in current browsing directory
      final String path = "${currentPath.value}/$folderName";
      final Directory newDir = Directory(path);
      if (!await newDir.exists()) {
        await newDir.create(recursive: true);
        Get.snackbar("Success", "Folder '$folderName' created!");
        fetchCurrentDirectory();
      } else {
        Get.snackbar("Error", "Folder already exists.");
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to create folder: $e");
    }
  }

  Future<void> _searchFilesRecursive(
    Directory dir,
    List<FileSystemEntity> files,
    int depth,
  ) async {
    if (depth > 5) return;

    try {
      final List<FileSystemEntity> entities = dir.listSync(
        recursive: false,
        followLinks: false,
      );
      for (final entity in entities) {
        if (entity is File) {
          final ext = entity.path.split('.').last.toLowerCase();
          if ([
            'pdf',
            'doc',
            'docx',
            'txt',
            'ppt',
            'pptx',
            'xls',
            'xlsx',
          ].contains(ext)) {
            files.add(entity);
          }
        } else if (entity is Directory) {
          if (!entity.path.split('/').last.startsWith('.')) {
            await _searchFilesRecursive(entity, files, depth + 1);
          }
        }
      }
    } catch (e) {}
  }

  Future<void> openFile(FileSystemEntity file) async {
    if (file is File) {
      final ext = file.path.split('.').last.toLowerCase();
      if (ext == 'pdf') {
        Get.toNamed('/viewer', arguments: file.path);
      } else {
        await OpenFile.open(file.path);
      }
    }
  }

  // Stateless fetch for independent folder browsing
  Future<List<FileSystemEntity>> getDirectoryContents(String path) async {
    try {
      final dir = Directory(path);
      if (await dir.exists()) {
        List<FileSystemEntity> entities = dir.listSync();
        entities.sort((a, b) {
          if (a is Directory && b is File) return -1;
          if (a is File && b is Directory) return 1;
          return a.path.compareTo(b.path);
        });
        return entities;
      }
    } catch (e) {
      print("Error listing directory: $e");
    }
    return [];
  }

  // File Management Actions

  Future<void> deleteFile(FileSystemEntity item) async {
    try {
      if (await item.exists()) {
        await item.delete(recursive: true);
        Get.snackbar("Success", "Item deleted");
        _refreshAllData();
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to delete: $e");
    }
  }

  void copyToClipboard(FileSystemEntity item, {required bool isMove}) {
    clipboardItem.value = item;
    isMoveMode.value = isMove;
    Get.snackbar(
      isMove ? "Move" : "Copy",
      "Item selected. Go to destination and paste.",
    );
  }

  Future<void> pasteItem(String destinationFolder) async {
    final item = clipboardItem.value;
    if (item == null) return;

    try {
      final String fileName = item.path.split('/').last;
      final String newPath = "$destinationFolder/$fileName";

      if (item.path == newPath) {
        Get.snackbar("Error", "Source and destination are the same");
        return;
      }

      if (isMoveMode.value) {
        await item.rename(newPath);
        clipboardItem.value = null; // Clear clipboard after move
        Get.snackbar("Success", "Moved to $newPath");
      } else {
        if (item is File) {
          await item.copy(newPath);
        } else if (item is Directory) {
          // Simple directory copy logic (recursive)
          await _copyDirectory(item, Directory(newPath));
        }
        Get.snackbar("Success", "Copied to $newPath");
      }
      _refreshAllData();
    } catch (e) {
      Get.snackbar("Error", "Failed to paste: $e");
    }
  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await destination.create(recursive: true);
    await for (var entity in source.list(recursive: false)) {
      final newPath = "${destination.path}/${entity.path.split('/').last}";
      if (entity is Directory) {
        await _copyDirectory(entity, Directory(newPath));
      } else if (entity is File) {
        await entity.copy(newPath);
      }
    }
  }
}
