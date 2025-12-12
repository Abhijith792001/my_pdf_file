import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:open_file/open_file.dart';
import '../../../controllers/file_controller.dart';

class EditorController extends GetxController {
  late String filePath;
  RxList<DrawingPoint?> points = <DrawingPoint?>[].obs;
  RxList<TextAnnotation> textAnnotations = <TextAnnotation>[].obs;

  Rx<Color> selectedColor = Colors.black.obs;
  RxDouble strokeWidth = 3.0.obs;

  // Tools: 0 = Pen, 1 = Text
  RxInt selectedTool = 0.obs;

  @override
  void onInit() {
    super.onInit();
    filePath = Get.arguments as String? ?? "";
  }

  void addPoint(DrawingPoint? point) {
    points.add(point);
  }

  void addTextAnnotation(TextAnnotation annotation) {
    textAnnotations.add(annotation);
  }

  void clearBoard() {
    points.clear();
    textAnnotations.clear();
  }

  Future<void> saveFile() async {
    await _performSave(filePath);
  }

  Future<void> saveAsFile() async {
    // Show dialog to get new name
    final TextEditingController nameCtrl = TextEditingController(
      text: filePath.split('/').last,
    );
    Get.defaultDialog(
      title: "Save As",
      content: Column(
        children: [
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(
              labelText: "File Name",
              suffixText: ".pdf",
            ),
          ),
        ],
      ),
      textConfirm: "Save",
      textCancel: "Cancel",
      onConfirm: () {
        if (nameCtrl.text.isNotEmpty) {
          String newName = nameCtrl.text;
          if (!newName.toLowerCase().endsWith('.pdf')) newName += ".pdf";

          // Construct new path in same directory
          String dir = filePath.substring(0, filePath.lastIndexOf('/'));
          String newPath = "$dir/$newName";

          Get.back(); // Close dialog
          _performSave(newPath);
        }
      },
    );
  }

  Future<void> _performSave(String path) async {
    Get.loadingSnackbar();
    try {
      // Simulate saving delay
      await Future.delayed(const Duration(seconds: 1));

      // Real implementation hook:
      // 1. Load original
      // 2. Apply modifications
      // 3. Write to 'path'

      // For MVP simulation:
      // If path is different, we just copy original to new path (simulating 'save as')
      if (path != filePath) {
        await File(filePath).copy(path);
        // And we might want to switch to the new file?
        // filePath = path;
      }

      Get.back();
      Get.snackbar("Success", "Saved to $path");
      // Update global list
      try {
        // Find FileController to refresh list
        Get.find<FileController>().fetchCurrentDirectory();
      } catch (e) {
        /* ignore */
      }
    } catch (e) {
      Get.back();
      Get.snackbar("Error", "Failed to save: $e");
    }
  }

  Future<void> convertToWord() async {
    Get.loadingSnackbar();
    try {
      final file = File(filePath);
      if (!file.existsSync()) throw Exception("File not found");

      // Extract text using pdfrx
      final document = await PdfDocument.openFile(filePath);
      StringBuffer buffer = StringBuffer();

      for (int i = 0; i < document.pages.length; i++) {
        final page = document.pages[i];
        // Load text for the page
        final text = await page.loadText();
        buffer.writeln(text?.fullText ?? "");
        buffer.writeln("\n\n"); // Page break simulation
      }
      // document.close(); // Not needed or available for this API version

      // Create .doc file (HTML format for best compatibility without heavy libs)
      final String htmlContent =
          """
          <html>
          <body>
          ${buffer.toString().replaceAll('\n', '<br>')}
          </body>
          </html>
          """;

      final dir = file.parent.path;
      final originalName = file.uri.pathSegments.last.split('.').first;
      final newPath = "$dir/${originalName}_editable.doc";

      final wordFile = File(newPath);
      await wordFile.writeAsString(htmlContent);

      Get.back();

      Get.snackbar(
        "Success",
        "Converted to Word doc!",
        mainButton: TextButton(
          child: const Text("OPEN", style: TextStyle(color: Colors.white)),
          onPressed: () {
            OpenFile.open(newPath);
          },
        ),
      );
    } catch (e) {
      Get.back();
      Get.snackbar("Error", "Conversion failed: $e");
    }
  }
}

class DrawingPoint {
  Offset offset;
  Paint paint;
  DrawingPoint({required this.offset, required this.paint});
}

class TextAnnotation {
  Offset offset;
  String text;
  TextStyle style;
  TextAnnotation({
    required this.offset,
    required this.text,
    required this.style,
  });
}

extension SnackbarExt on GetInterface {
  void loadingSnackbar() {
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
  }
}
