import 'dart:io';
import 'package:get/get.dart';
import 'package:pdfrx/pdfrx.dart';

class ViewerController extends GetxController {
  final PdfViewerController pdfViewerController = PdfViewerController();
  late String filePath;
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 0.obs;
  final RxBool isReady = false.obs;

  @override
  void onInit() {
    super.onInit();
    filePath = Get.arguments as String? ?? "";
    if (filePath.isEmpty) {
      Get.snackbar("Error", "No file selected");
      Get.back();
      return;
    }

    // Check if file exists to solve "id not working" issue if path is bad
    final file = File(filePath);
    if (!file.existsSync()) {
      Get.snackbar("Error", "File does not exist: $filePath");
      Get.back();
      return;
    }
  }

  void onPageChanged(int page, int total) {
    currentPage.value = page;
    totalPages.value = total;
  }
}
