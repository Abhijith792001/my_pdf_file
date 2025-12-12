import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class ToolsController extends GetxController {
  final ImagePicker _picker = ImagePicker();

  Future<void> convertImageToPdf() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isEmpty) return;

      Get.loadingSnackbar();
      
      final pdf = pw.Document();

      for (var img in images) {
        final imageFile = File(img.path);
        final image = pw.MemoryImage(imageFile.readAsBytesSync());

        pdf.addPage(pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
                return pw.Center(child: pw.Image(image));
            }
        ));
      }

      // Save
      final output = await getExternalStorageDirectory();
      // On Android 11+ we might need to save to specific public dir or use MediaStore. 
      // For now, save to app ext directory.
      if (output == null) throw "Cannot access storage";
      
      final file = File("${output.path}/IMG_${DateTime.now().millisecondsSinceEpoch}.pdf");
      await file.writeAsBytes(await pdf.save());
      
      Get.back(); // Close loading
      Get.snackbar("Success", "Saved to ${file.path}");
      
      // Refresh file list (find logic in FileController)
      // Get.find<FileController>().fetchPdfs();
      
    } catch (e) {
      Get.back();
      Get.snackbar("Error", e.toString());
    }
  }

  void mergePdfs() {
    Get.snackbar("Upcoming", "Merge PDF feature coming soon");
  }

  void splitPdf() {
    Get.snackbar("Upcoming", "Split PDF feature coming soon");
  }
}

extension SnackbarExt on GetInterface {
    void loadingSnackbar() {
        Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    }
}
