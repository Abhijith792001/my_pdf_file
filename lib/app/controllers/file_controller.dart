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
        permissionGranted = await Permission.manageExternalStorage.request().isGranted;
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
      
      // Attempt to find external storage
      Directory? externalDir;
      if (Platform.isAndroid) {
          externalDir = Directory('/storage/emulated/0');
      }
      
      if (externalDir != null && externalDir.existsSync()) {
        directoriesToSearch.add(externalDir);
      }

      List<FileSystemEntity> files = [];
      
      for (var dir in directoriesToSearch) {
         await _searchFiles(dir, files);
      }
      
      allFiles.assignAll(files);
      // Sort by date modified for recent
      recentFiles.assignAll(List.from(files)..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified)));
      
    } catch (e) {
      print("Error scanning files: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _searchFiles(Directory dir, List<FileSystemEntity> files) async {
    try {
      // recursive search with depth limit logic would be better for performance
      // For this MVP, we will try to safe list
      Stream<FileSystemEntity> stream = dir.list(recursive: true, followLinks: false);
      await stream.forEach((entity) {
         if (entity is File && entity.path.toLowerCase().endsWith('.pdf')) {
           files.add(entity);
         }
      });
    } catch (e) {
      // Ignore access errors
    }
  }
}
